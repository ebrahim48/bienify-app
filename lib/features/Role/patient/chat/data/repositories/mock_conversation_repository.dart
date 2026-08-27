import '../../../../../../core/models/chat_thread.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../static/chat_mock_data.dart';

/// A thread, served from the design's sample conversations — one for a
/// consultation, one for a delivery.
class MockConversationRepository implements ConversationRepository {
  const MockConversationRepository();

  @override
  Future<List<ConversationThread>> threads() async => ChatMockData.threads();

  @override
  Future<List<ChatMessage>> messages(ChatThread thread) async => thread.isDelivery
      ? ChatMockData.deliveryThread()
      : ChatMockData.thread();

  @override
  Future<ChatMessage> send({
    required ChatThread thread,
    required String body,
    String? clientId,
    Map<String, dynamic>? attachment,
  }) async => ChatMessage(
    id: 'local-${DateTime.now().microsecondsSinceEpoch}',
    text: body,
    sentAt: DateTime.now(),
    author: MessageAuthor.me,
  );
}
