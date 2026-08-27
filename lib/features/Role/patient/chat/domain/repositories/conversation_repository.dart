import '../../../../../../core/models/chat_thread.dart';
import '../entities/conversation.dart';

/// The messages in a thread — a consultation, or a delivery between a
/// customer and their courier.
abstract class ConversationRepository {
  /// Every thread the patient has, most recently active first.
  Future<List<ConversationThread>> threads();

  /// The messages in [thread], oldest first.
  Future<List<ChatMessage>> messages(ChatThread thread);

  /// Sends [body] and returns the message the server stored.
  /// Sends [body], optionally carrying the sender's own [clientId].
  ///
  /// The id makes the send idempotent: this path is the fallback when the
  /// socket is down or its ack was lost, so the same message may already have
  /// reached the server. Passing the id lets it return that one instead of
  /// storing a duplicate.
  Future<ChatMessage> send({
    required ChatThread thread,
    required String body,
    String? clientId,
    Map<String, dynamic>? attachment,
  });
}
