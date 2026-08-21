import '../entities/conversation.dart';

/// The messages exchanged during a consultation.
abstract class ConversationRepository {
  /// Every thread the patient has, most recently active first.
  Future<List<ConversationThread>> threads();

  /// The thread for [appointmentId], oldest first.
  Future<List<ChatMessage>> messages(String appointmentId);

  /// Sends [body] and returns the message the server stored.
  /// Sends [body], optionally carrying the sender's own [clientId].
  ///
  /// The id makes the send idempotent: this path is the fallback when the
  /// socket is down or its ack was lost, so the same message may already have
  /// reached the server. Passing the id lets it return that one instead of
  /// storing a duplicate.
  Future<ChatMessage> send({
    required String appointmentId,
    required String body,
    String? clientId,
    Map<String, dynamic>? attachment,
  });
}
