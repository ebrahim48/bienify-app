import '../../domain/entities/conversation.dart';

/// The sample thread shown in the Message design.
class ChatMockData {
  ChatMockData._();

  static const ConversationPeer peer = ConversationPeer(
    id: 'doc-2',
    name: 'Dr. Emmanuel Okafor',
    specialty: 'Cardiologist',
    isOnline: true,
  );

  static const String _reply =
      'I understand your concern. Let me help you with that. Would you like '
      'to schedule a video consultation?';

  static List<ChatMessage> thread() {
    final day = DateTime(2026, 4, 1);
    DateTime at(int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute);

    return [
      ChatMessage(
        id: 'm1',
        text: 'Hello! How can I help you today?',
        sentAt: at(12, 37),
        author: MessageAuthor.doctor,
      ),
      ChatMessage(
        id: 'm2',
        text: 'ok',
        sentAt: at(12, 37),
        author: MessageAuthor.patient,
      ),
      ChatMessage(
        id: 'm3',
        text: _reply,
        sentAt: at(12, 37),
        author: MessageAuthor.doctor,
      ),
      ChatMessage(
        id: 'm4',
        text: 'consultation fee ?',
        sentAt: at(12, 38),
        author: MessageAuthor.patient,
      ),
      ChatMessage(
        id: 'm5',
        text: _reply,
        sentAt: at(12, 38),
        author: MessageAuthor.doctor,
      ),
      ChatMessage(
        id: 'm6',
        text:
            "I've set the consultation fee at 12 XAF for a 30-minute video "
            'consultation. This includes follow-up messages for 24 hours.',
        sentAt: at(12, 38),
        author: MessageAuthor.doctor,
      ),
    ];
  }

  /// Canned reply used so sending a message produces a visible exchange.
  static ChatMessage autoReply() => ChatMessage(
    id: 'auto-${DateTime.now().microsecondsSinceEpoch}',
    text: _reply,
    sentAt: DateTime.now(),
    author: MessageAuthor.doctor,
  );
}
