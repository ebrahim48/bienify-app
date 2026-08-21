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

  /// "Chat With Us" on the health profile opens this same screen with Bienify
  /// on the other end, rather than a second messaging UI.
  static const ConversationPeer support = ConversationPeer(
    id: 'bienify-support',
    name: 'Bienify Support',
    specialty: 'Here to help',
    isOnline: true,
  );

  static const String _reply =
      'I understand your concern. Let me help you with that. Would you like '
      'to schedule a video consultation?';

  /// The list's peers carry an `appointmentId`, unlike [peer], so tapping a row
  /// opens a thread that behaves like a real consultation. [peer] deliberately
  /// has none — it backs the header shortcut, which has no consultation behind
  /// it and so falls back to the read-only sample.
  static const ConversationPeer _listedPeer = ConversationPeer(
    id: 'doc-2',
    appointmentId: 'appt-mock-1',
    name: 'Dr. Emmanuel Okafor',
    specialty: 'Cardiologist',
    isOnline: true,
  );

  /// A doctor the patient has consulted before, so the list is not one row.
  static const ConversationPeer _pastPeer = ConversationPeer(
    id: 'doc-5',
    appointmentId: 'appt-mock-2',
    name: 'Dr. Linda Chen',
    specialty: 'Pediatric Dentist',
  );

  /// The message list's sample content.
  static List<ConversationThread> threads() => [
    ConversationThread(
      peer: _listedPeer,
      preview: 'I understand your concern. Let me help you with that.',
      lastMessageAt: DateTime(2026, 4, 1, 12, 38),
      unreadCount: 2,
    ),
    ConversationThread(
      peer: _pastPeer,
      preview: 'Your results look good — no follow-up needed.',
      lastMessageAt: DateTime(2026, 3, 28, 9, 12),
    ),
  ];

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
