import '../../../../../core/models/chat_thread.dart';
import '../../../../../core/network/token_store.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/time_format.dart';
import '../../../../../core/network/mappers.dart';
import 'dart:async';

import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/network/socket_service.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../patient/chat/domain/entities/conversation.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the doctor's Message tab.
///
/// Opening a thread reuses the patient app's `ChatScreen` with the patient as
/// its `ConversationPeer` — one messaging screen serves both roles.
class DoctorMessagesController extends GetxController {
  DoctorMessagesController({
    DoctorPracticeRepository? repository,
    SocketService? socket,
    TokenStore? tokens,
  }) : _repository = repository ?? Get.find<DoctorPracticeRepository>(),
       _socket = socket ?? Get.find<SocketService>(),
       _tokens = tokens ?? Get.find<TokenStore>();

  final DoctorPracticeRepository _repository;
  final SocketService _socket;

  /// Whose messages count as ours, read from the signed-in token.
  final TokenStore _tokens;

  final RxList<PatientThread> threads = <PatientThread>[].obs;

  final RxString query = ''.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Which patients are connected right now, keyed by their user id. Mirrors
  /// the patient list's own dots — the same fact, read the same way.
  final RxMap<String, bool> presence = <String, bool>{}.obs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Whether the socket has dropped since this tab opened, so a later connect
  /// is a recovery to catch up from rather than the first one.
  bool _hasDropped = false;

  @override
  void onInit() {
    super.onInit();
    load();
    _watchPresence();
  }

  void _watchPresence() {
    _socket.connect();
    _subscriptions.addAll([
      _socket.presence.listen(
        (state) => presence[state.userId] = state.isOnline,
      ),
      // A reconnect drops room membership, and re-joining is what restores
      // the presence feed for these threads.
      _socket.connectionState.listen((isUp) {
        if (!isUp) {
          _hasDropped = true;
          return;
        }
        _subscribeToThreads();
        // Only after a genuine drop: whatever arrived while the socket was
        // down cannot be replayed. The first connect of the session has
        // nothing to catch up on, and reloading there would put a spinner over
        // a list that had just loaded.
        if (_hasDropped) {
          _hasDropped = false;
          unawaited(load(quietly: true));
        }
      }),
      // The rows were joined to their rooms and every message they carried was
      // thrown away: the preview, its time and the order of the list stayed as
      // they were when the tab opened. A patient could reply, the doctor could
      // read it inside the thread, and the list above it never moved.
      _socket.messages.listen(_onMessage),
    ]);
  }

  /// Moves a thread to the top with what was just said in it.
  ///
  /// Both directions land here: the server echoes a send back to the room, so
  /// the doctor's own list moves too rather than only on the patient's reply.
  void _onMessage(Map<String, dynamic> json) {
    final thread = ChatThread.fromJson(json);
    if (thread == null || !thread.isConsultation) return;

    final index = threads.indexWhere((row) => row.id == thread.id);
    // A consultation this list has never seen — its first message. Re-reading
    // is the only way to learn whose it is.
    if (index == -1) {
      unawaited(load(quietly: true));
      return;
    }

    final row = threads[index];
    final body = '${json['body'] ?? ''}';
    final at = Api.date(json['createdAt']);
    // Against our own id, not the patient's. `patientUserId` is empty whenever
    // the thread endpoint did not populate its counterpart, and then every
    // message read as ours and nothing was ever counted unread.
    final isMine = '${json['senderId'] ?? ''}' == _tokens.userId;

    threads[index] = row.withLastMessage(
      // An attachment with no caption has no text to preview; naming the file
      // beats a blank line that reads as an empty message.
      preview: body.trim().isEmpty ? _attachmentName(json) : body,
      timeLabel: TimeFormat.threadStamp(at),
      at: at,
      unreadCount: isMine ? row.unreadCount : row.unreadCount + 1,
    );

    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
  }

  /// Drops a row's unread count to nought, in place.
  void _clearUnread(String threadId) {
    final index = threads.indexWhere((row) => row.id == threadId);
    if (index == -1 || threads[index].unreadCount == 0) return;
    final row = threads[index];
    threads[index] = row.withLastMessage(
      preview: row.preview,
      timeLabel: row.timeLabel,
      at: row.lastMessageAt,
      unreadCount: 0,
    );
  }

  /// What to show for a message that is only a file.
  String _attachmentName(Map<String, dynamic> json) {
    final attachment = json['attachment'];
    if (attachment is Map) {
      final name = '${attachment['name'] ?? ''}';
      if (name.isNotEmpty) return name;
    }
    return AppStrings.attachment.tr;
  }

  /// Joins each thread's room, then reads its patient's presence once —
  /// presence is only published on change, so somebody already online when
  /// this tab opened would otherwise never report in.
  void _subscribeToThreads() {
    for (final thread in threads) {
      if (thread.id.isNotEmpty) {
        _socket.joinThread(ChatThread.consultation(thread.id));
      }

      final patientId = thread.patientUserId;
      if (patientId.isEmpty) continue;
      unawaited(
        _socket.queryPresence(patientId).then((state) {
          if (state != null) presence[state.userId] = state.isOnline;
        }),
      );
    }
  }

  /// Null while unknown, so the row draws no dot rather than claiming the
  /// patient is offline.
  bool? isPatientOnline(PatientThread thread) => presence[thread.patientUserId];

  /// Reads the threads.
  ///
  /// [quietly] leaves the spinner alone, for a refresh nobody asked for — a
  /// list that blanks itself because the network hiccupped is worse than one
  /// that updates under the reader.
  Future<void> load({bool quietly = false}) async {
    if (!quietly) isLoading.value = true;
    error.value = null;
    try {
      threads.value = await _repository.threads();
      _subscribeToThreads();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.onClose();
  }

  List<PatientThread> get visible {
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return threads.toList();
    return threads
        .where((t) => t.patientName.toLowerCase().contains(search))
        .toList();
  }

  void openThread(PatientThread thread) {
    // Opening the conversation reads it, so the badge goes now rather than
    // waiting for the list to be fetched again. Without this the number sat
    // on the row after the messages had plainly been read, which is the one
    // thing an unread count must never do.
    _clearUnread(thread.id);
    Get.toNamed<void>(
      AppRoutes.chat,
      arguments: ConversationPeer(
        // The patient's user id, not the appointment's: presence and typing
        // are addressed per user, and passing the thread id here made the
        // header ask about a user that does not exist.
        id: thread.patientUserId.isEmpty ? thread.id : thread.patientUserId,
        // A thread is keyed by its consultation, which is what makes the
        // messages behind it real rather than the sample conversation.
        thread: ChatThread.consultation(thread.id),
        name: thread.patientName,
        // The doctor's side of the header shows why the patient is here, and
        // the preview is the nearest thing the list carries.
        specialty: thread.preview,
        photoUrl: thread.photoUrl,
        photoAsset: thread.photoAsset,
        // Left to the socket rather than asserted here: the header reads live
        // presence, and seeding it `true` made every patient look online.
      ),
    );
  }
}
