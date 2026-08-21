import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../static/chat_mock_data.dart';

/// The thread, served from the design's sample conversation.
class MockConversationRepository implements ConversationRepository {
  const MockConversationRepository();

  @override
  Future<List<ConversationThread>> threads() async => ChatMockData.threads();

  @override
  Future<List<ChatMessage>> messages(String appointmentId) async =>
      ChatMockData.thread();

  @override
  Future<ChatMessage> send({
    required String appointmentId,
    required String body,
    String? clientId,
    Map<String, dynamic>? attachment,
  }) async => ChatMessage(
    id: 'local-${DateTime.now().microsecondsSinceEpoch}',
    text: body,
    sentAt: DateTime.now(),
    author: MessageAuthor.patient,
  );
}
