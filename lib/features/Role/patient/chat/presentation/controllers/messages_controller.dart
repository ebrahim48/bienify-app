import '../../../../../../core/models/chat_thread.dart';
import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/network/mappers.dart';
import '../../../../../../core/network/socket_service.dart';
import '../../../../../../core/network/token_store.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';

/// Backs the patient's message list — every consultation they have a thread
/// with, newest activity first.
///
/// The header's chat icon used to drop straight into one arbitrary thread
/// because no list existed. `GET /consultations/threads` was already there and
/// already served the doctor's side; this is the patient's half of it.
class MessagesController extends GetxController {
  MessagesController({
    ConversationRepository? repository,
    SocketService? socket,
    TokenStore? tokens,
  }) : _repository = repository ?? Get.find<ConversationRepository>(),
       _socket = socket ?? Get.find<SocketService>(),
       _tokens = tokens ?? Get.find<TokenStore>();

  final ConversationRepository _repository;
  final SocketService _socket;

  /// Whose messages count as ours, read from the signed-in token.
  final TokenStore _tokens;

  final RxList<ConversationThread> threads = <ConversationThread>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// The live query. The search field owns its text controller, so nothing
  /// here needs disposing.
  final RxString query = ''.obs;

  /// Who is online right now, keyed by the peer's user id.
  ///
  /// Held here rather than on [ConversationThread] because presence is not a
  /// property of the thread — it changes several times while the list sits on
  /// screen, and rebuilding every row's model on each change would throw away
  /// the list's identity for something only one dot depends on.
  final RxMap<String, bool> presence = <String, bool>{}.obs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Whether the socket has gone down since this screen opened, so a later
  /// connect is a recovery to catch up from rather than the first one.
  bool _hasDropped = false;

  @override
  void onInit() {
    super.onInit();
    load();
    _watchPresence();
  }

  /// Keeps the dots live for as long as the list is open.
  void _watchPresence() {
    _socket.connect();
    _subscriptions.addAll([
      _socket.presence.listen(
        (state) => presence[state.userId] = state.isOnline,
      ),
      // Rooms do not survive a reconnect, and a re-join is what re-subscribes
      // this screen to the other party's presence. Without it the dots freeze
      // at whatever they read when the socket dropped.
      _socket.connectionState.listen((isUp) {
        if (!isUp) {
          _hasDropped = true;
          return;
        }
        _subscribeToThreads();
        // Only after a genuine drop. Whatever arrived while the socket was
        // down cannot be replayed, so the rows are re-read rather than left
        // showing a preview that is quietly out of date — but the first
        // connect of the session has nothing to catch up on, and reloading
        // there would put a spinner over a list that had just loaded.
        if (_hasDropped) {
          _hasDropped = false;
          unawaited(load(quietly: true));
        }
      }),
      // The rows were joined to their rooms and every message they carried was
      // thrown away: the preview, its time and the order of the list were
      // whatever they had been when the screen opened. A reply could arrive,
      // be visible inside the thread, and leave the list above it unchanged.
      _socket.messages.listen(_onMessage),
    ]);
  }

  /// Joins each thread's room and reads its peer's presence once.
  ///
  /// The initial read matters as much as the subscription: presence is only
  /// published when it *changes*, so a doctor who came online before this
  /// screen opened would otherwise show as offline until they happened to
  /// disconnect.
  void _subscribeToThreads() {
    for (final thread in threads) {
      final id = thread.appointmentId;
      if (id.isNotEmpty) _socket.joinThread(ChatThread.consultation(id));

      final peerId = thread.peer.id;
      if (peerId.isEmpty) continue;
      unawaited(
        _socket.queryPresence(peerId).then((state) {
          if (state != null) presence[state.userId] = state.isOnline;
        }),
      );
    }
  }

  /// Moves a thread to the top with what was just said in it.
  ///
  /// Both directions land here: the server echoes a send back to the room, so
  /// the sender's own list moves too rather than only the recipient's.
  void _onMessage(Map<String, dynamic> json) {
    final thread = ChatThread.fromJson(json);
    if (thread == null) return;

    // Matched on the whole thread, not its bare id: this list now holds
    // courier conversations beside consultations, and two kinds sharing an id
    // would otherwise put a parcel's message on a doctor's row.
    final index = threads.indexWhere((row) => row.peer.thread == thread);
    // A thread this list has never seen — a first message on a consultation
    // that had none. Re-reading is the only way to learn who it is with.
    if (index == -1) {
      unawaited(load(quietly: true));
      return;
    }

    final row = threads[index];
    final body = '${json['body'] ?? ''}';
    final at = Api.date(json['createdAt']);
    // Against our own id, not the peer's. Asking "is the sender someone other
    // than the person I am talking to" gives the wrong answer whenever the
    // peer id is not populated — every message then reads as ours and nothing
    // is ever counted unread.
    final isMine = '${json['senderId'] ?? ''}' == _tokens.userId;

    threads[index] = row.withLastMessage(
      // An attachment with no caption has no text to preview; naming the file
      // is better than a blank line that reads as an empty message.
      preview: body.trim().isEmpty ? _attachmentName(json) : body,
      at: at,
      // Their message adds to the count; our own echo does not, and neither
      // does one in the thread the reader currently has open — that one is
      // marked read the moment it lands.
      unreadCount: isMine ? row.unreadCount : row.unreadCount + 1,
    );

    // Newest first, which is the order the list is built in.
    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
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

  /// True when this thread's peer is connected. Null while unknown — the row
  /// draws no dot rather than asserting they are offline.
  bool? isPeerOnline(ConversationThread thread) => presence[thread.peer.id];

  /// Reads the threads.
  ///
  /// [quietly] leaves the spinner alone, for a refresh the reader did not ask
  /// for — a list that blanks itself because the network hiccupped is worse
  /// than one that updates under them.
  Future<void> load({bool quietly = false}) async {
    if (!quietly) isLoading.value = true;
    error.value = null;
    try {
      final rows = await _repository.threads();
      // Newest first: the thread someone is waiting on is the one they opened
      // the screen to read.
      threads.value = rows
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
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
    // The rooms are deliberately left joined: the chat screen this list opens
    // into needs the same room, and leaving it here only to re-join a moment
    // later would drop events in the gap.
    super.onClose();
  }

  /// Threads narrowed by [query], matched on the doctor's name.
  List<ConversationThread> get visible {
    final term = query.value.trim().toLowerCase();
    if (term.isEmpty) return threads;
    return threads
        .where((thread) => thread.peer.name.toLowerCase().contains(term))
        .toList();
  }

  int get unreadTotal =>
      threads.fold(0, (sum, thread) => sum + thread.unreadCount);

  /// Opens the thread, handing `ChatBinding` the peer it expects.
  void openThread(ConversationThread thread) {
    // Opening the conversation reads it, so the badge goes now rather than
    // waiting for the list to be fetched again. Without this the number sat
    // on the row after the messages had plainly been read, which is the one
    // thing an unread count must never do.
    _clearUnread(thread);
    Get.toNamed<void>(AppRoutes.chat, arguments: thread.peer);
  }

  /// Drops a row's unread count to nought, in place.
  void _clearUnread(ConversationThread thread) {
    final index = threads.indexWhere((row) => row.peer.id == thread.peer.id);
    if (index == -1 || threads[index].unreadCount == 0) return;
    final row = threads[index];
    threads[index] = row.withLastMessage(
      preview: row.preview,
      at: row.lastMessageAt,
      unreadCount: 0,
    );
  }
}
