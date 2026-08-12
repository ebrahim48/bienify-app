/// Who the patient is talking to, shown in the chat header.
class ConversationPeer {
  const ConversationPeer({
    required this.id,
    required this.name,
    required this.specialty,
    this.appointmentId,
    this.photoUrl,
    this.photoAsset,
    this.isOnline = false,
  });

  final String id;

  /// The consultation this thread belongs to.
  ///
  /// Messages are keyed by appointment on the server — there is no general
  /// inbox — so a thread opened outside one (a courier, support, a doctor the
  /// patient has not booked) has nowhere to send to and shows the sample
  /// conversation instead. See `docs/API-GAPS.md`.
  final String? appointmentId;
  final String name;
  final String specialty;
  final String? photoUrl;

  /// Bundled headshot to fall back to when [photoUrl] is absent or fails.
  /// The rider thread sets it so the courier is not shown a doctor's photo.
  final String? photoAsset;

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
