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

  @override
  void onInit() {
    super.onInit();
    inputController.addListener(_onInputChanged);
    load();
    // The thread opens at the newest message, as a chat should.
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToLatest());
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
