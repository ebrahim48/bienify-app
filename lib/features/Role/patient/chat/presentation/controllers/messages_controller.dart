import '../../../../../../core/models/chat_thread.dart';
import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/network/socket_service.dart';
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
  MessagesController({ConversationRepository? repository, SocketService? socket})
    : _repository = repository ?? Get.find<ConversationRepository>(),
      _socket = socket ?? Get.find<SocketService>();

  final ConversationRepository _repository;
  final SocketService _socket;

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
        if (isUp) _subscribeToThreads();
      }),
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

  /// True when this thread's peer is connected. Null while unknown — the row
  /// draws no dot rather than asserting they are offline.
  bool? isPeerOnline(ConversationThread thread) => presence[thread.peer.id];

  Future<void> load() async {
    isLoading.value = true;
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
  void openThread(ConversationThread thread) =>
      Get.toNamed<void>(AppRoutes.chat, arguments: thread.peer);
}
