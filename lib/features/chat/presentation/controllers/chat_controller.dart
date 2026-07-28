import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../data/static/chat_mock_data.dart';
import '../../domain/entities/conversation.dart';

/// Backs the message thread.
///
/// Sending appends the outgoing bubble immediately and schedules the doctor's
/// reply, so the screen exercises both bubble styles without a backend.
class ChatController extends GetxController {
  ChatController({required this.peer});

  final ConversationPeer peer;

  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool canSend = false.obs;

  Timer? _replyTimer;

  @override
  void onInit() {
    super.onInit();
    messages.value = ChatMockData.thread();
    inputController.addListener(_onInputChanged);
    // The thread opens at the newest message, as a chat should.
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToLatest());
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

  void send() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

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
