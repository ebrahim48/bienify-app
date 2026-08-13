import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/chat_mock_data.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';

/// Backs the message thread.
///
/// Messages are keyed by appointment on the server, so a thread opened for a
/// consultation is real. One opened outside one — a courier, support, a doctor
/// the patient has not booked — has nowhere to send to and falls back to the
/// sample conversation. See `docs/API-GAPS.md`.
class ChatController extends GetxController {
  ChatController({required this.peer, ConversationRepository? repository})
    : _repository = repository ?? Get.find<ConversationRepository>();

  final ConversationPeer peer;

  final ConversationRepository _repository;

  /// True when this thread has a consultation behind it.
  bool get isLive =>
      peer.appointmentId != null && peer.appointmentId!.isNotEmpty;

  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxnString error = RxnString();

  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool canSend = false.obs;

  Timer? _replyTimer;
  Timer? _poll;
  bool _isRefreshing = false;

  /// How often an open thread re-reads the server.
  ///
  /// There is no push channel and no socket, so the other side's messages
  /// arrive only when this asks for them. Three seconds is close enough to
  /// feel like a conversation without hammering a thread nobody is typing in.
  static const Duration _pollInterval = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();
    inputController.addListener(_onInputChanged);
    load();
    // The thread opens at the newest message, as a chat should.
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToLatest());
    if (isLive) {
      _poll = Timer.periodic(_pollInterval, (_) => _refresh());
    }
  }

  /// Pulls in whatever the other side has said since the last look.
  ///
  /// Appends rather than replacing the list: rebuilding it every few seconds
  /// would flicker and fight the scroll position for no gain, since a live
  /// thread holds nothing the server does not.
  Future<void> _refresh() async {
    if (_isRefreshing || isSending.value) return;
    _isRefreshing = true;
    try {
      final latest = await _repository.messages(peer.appointmentId!);
      final known = messages.map((m) => m.id).toSet();
      final arrived = latest.where((m) => !known.contains(m.id)).toList();
      if (arrived.isEmpty) return;

      // Whether to follow the conversation down is decided before the list
      // grows: a reader who has scrolled up to re-read something should not
      // be yanked to the bottom by someone else's message.
      final shouldFollow = _isNearBottom;
      messages.addAll(arrived);
      if (shouldFollow) _scrollToLatest();
    } on AppException {
      // A poll that fails is not worth a snackbar over an open thread — the
      // next one is three seconds away, and the messages already read are
      // still on screen.
    } finally {
      _isRefreshing = false;
    }
  }

  /// Within a screenful of the newest message.
  bool get _isNearBottom {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return position.maxScrollExtent - position.pixels < 120;
  }

  Future<void> load() async {
    if (!isLive) {
      messages.value = ChatMockData.thread();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    error.value = null;
    try {
      messages.value = await _repository.messages(peer.appointmentId!);
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
    _scrollToLatest();
  }

  @override
  void onClose() {
    _poll?.cancel();
    _replyTimer?.cancel();
    inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onInputChanged() =>
      canSend.value = inputController.text.trim().isNotEmpty;

  Future<void> send() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isSending.value) return;

    if (!isLive) {
      _sendLocally(text);
      return;
    }

    // The bubble is added only once the server has the message. Adding it
    // first and reconciling later is what makes a chat show a message that was
    // never delivered.
    isSending.value = true;
    try {
      messages.add(
        await _repository.send(
          appointmentId: peer.appointmentId!,
          body: text,
        ),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSending.value = false;
    }

    inputController.clear();
    _scrollToLatest();
  }

  /// The sample thread's behaviour: append the outgoing bubble and schedule a
  /// reply, so a chat with nothing behind it still exercises both styles.
  void _sendLocally(String text) {
    messages.add(
      ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        sentAt: DateTime.now(),
        author: MessageAuthor.patient,
      ),
    );
    inputController.clear();
    _scrollToLatest();

    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 900), () {
      messages.add(ChatMockData.autoReply());
      _scrollToLatest();
    });
  }

  /// Attachment capture needs a platform picker; the affordance stays live so
  /// the layout is exercised, and sends a placeholder line meanwhile.
  void attach() {
    messages.add(
      ChatMessage(
        id: 'attach-${DateTime.now().microsecondsSinceEpoch}',
        text: '📎 Attachment shared',
        sentAt: DateTime.now(),
        author: MessageAuthor.patient,
      ),
    );
    _scrollToLatest();
  }

  void jumpToLatest() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}
