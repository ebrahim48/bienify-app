import '../entities/conversation.dart';

/// The messages exchanged during a consultation.
abstract class ConversationRepository {
  /// The thread for [appointmentId], oldest first.
  Future<List<ChatMessage>> messages(String appointmentId);

  /// Sends [body] and returns the message the server stored.
  Future<ChatMessage> send({
    required String appointmentId,
    required String body,
  });
}
