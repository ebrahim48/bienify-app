import '../../../../../../core/models/chat_thread.dart';
import '../../domain/entities/conversation.dart';

/// The sample thread shown in the Message design.
class ChatMockData {
  ChatMockData._();

  static const ConversationPeer peer = ConversationPeer(
    id: 'doc-2',
    name: 'Dr. Emmanuel Okafor',
    specialty: 'Cardiologist',
  );

  /// "Chat With Us" on the health profile opens this same screen with Bienify
  /// on the other end, rather than a second messaging UI.
  static const ConversationPeer support = ConversationPeer(
    id: 'bienify-support',
    name: 'Bienify Support',
    specialty: 'Here to help',
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
    thread: ChatThread.consultation('appt-mock-1'),
    name: 'Dr. Emmanuel Okafor',
    specialty: 'Cardiologist',
  );

  /// A doctor the patient has consulted before, so the list is not one row.
  static const ConversationPeer _pastPeer = ConversationPeer(
    id: 'doc-5',
    thread: ChatThread.consultation('appt-mock-2'),
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

  /// The courier's sample conversation.
  ///
  /// Separate from [thread] because that one is a consultation: shown under a
  /// courier's name it had them quoting a consultation fee and offering to
  /// book a video call, which is not a thing a courier does.
  static List<ChatMessage> deliveryThread() {
    final day = DateTime(2026, 4, 1);
    DateTime at(int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute);

    return [
      ChatMessage(
        id: 'd1',
        text: 'I have collected your order and I am on the way.',
        sentAt: at(12, 37),
        author: MessageAuthor.peer,
      ),
      ChatMessage(
        id: 'd2',
        text: 'Thank you. Please use the side gate, the front bell is broken.',
        sentAt: at(12, 38),
        author: MessageAuthor.me,
        readAt: at(12, 38),
      ),
      ChatMessage(
        id: 'd3',
        text: 'Noted. Around ten minutes away.',
        sentAt: at(12, 39),
        author: MessageAuthor.peer,
      ),
    ];
  }

  static List<ChatMessage> thread() {
    final day = DateTime(2026, 4, 1);
    DateTime at(int hour, int minute) =>
        DateTime(day.year, day.month, day.day, hour, minute);

    return [
      ChatMessage(
        id: 'm1',
        text: 'Hello! How can I help you today?',
        sentAt: at(12, 37),
        author: MessageAuthor.peer,
      ),
      ChatMessage(
        id: 'm2',
        text: 'ok',
        sentAt: at(12, 37),
        author: MessageAuthor.me,
      ),
      ChatMessage(
        id: 'm3',
        text: _reply,
        sentAt: at(12, 37),
        author: MessageAuthor.peer,
      ),
      ChatMessage(
        id: 'm4',
        text: 'consultation fee ?',
        sentAt: at(12, 38),
        author: MessageAuthor.me,
      ),
      ChatMessage(
        id: 'm5',
        text: _reply,
        sentAt: at(12, 38),
        author: MessageAuthor.peer,
      ),
      ChatMessage(
        id: 'm6',
        text:
            "I've set the consultation fee at 12 XAF for a 30-minute video "
            'consultation. This includes follow-up messages for 24 hours.',
        sentAt: at(12, 38),
        author: MessageAuthor.peer,
      ),
    ];
  }

  /// Canned reply used so sending a message produces a visible exchange.
  static ChatMessage autoReply() => ChatMessage(
    id: 'auto-${DateTime.now().microsecondsSinceEpoch}',
    text: _reply,
    sentAt: DateTime.now(),
    author: MessageAuthor.peer,
  );
}
