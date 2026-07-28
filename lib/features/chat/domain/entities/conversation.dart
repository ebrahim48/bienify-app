/// Who the patient is talking to, shown in the chat header.
class ConversationPeer {
  const ConversationPeer({
    required this.id,
    required this.name,
    required this.specialty,
    this.photoUrl,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String specialty;
  final String? photoUrl;
  final bool isOnline;
}

/// Which side of the thread a message sits on.
enum MessageAuthor { patient, doctor }

/// A single chat bubble.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.author,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final MessageAuthor author;

  bool get isMine => author == MessageAuthor.patient;

  /// `12:37 PM`, matching the design's bubble timestamps.
  String get timeLabel {
    final hour12 = sentAt.hour % 12 == 0 ? 12 : sentAt.hour % 12;
    final minute = sentAt.minute.toString().padLeft(2, '0');
    return '$hour12:$minute ${sentAt.hour < 12 ? 'AM' : 'PM'}';
  }
}
