import '../../../../../../core/models/chat_thread.dart';
import '../../../../../../core/utils/time_format.dart';

/// Who the patient is talking to, shown in the chat header.
class ConversationPeer {
  const ConversationPeer({
    required this.id,
    required this.name,
    required this.specialty,
    this.thread,
    this.photoUrl,
    this.photoAsset,
  });

  final String id;

  /// The conversation this thread belongs to — a consultation, or a delivery
  /// the patient and their courier are both on.
  ///
  /// Null when the screen was opened outside any conversation (support, a
  /// doctor the patient has not booked), which has nowhere to send to.
  final ChatThread? thread;
  final String name;
  final String specialty;
  final String? photoUrl;

  /// Bundled headshot to fall back to when [photoUrl] is absent or fails.
  /// The rider thread sets it so the courier is not shown a doctor's photo.
  final String? photoAsset;

  // No `isOnline` here. It was a seeded flag every caller passed as `true`,
  // which is presence asserted on no evidence — the header now draws the dot
  // from the socket alone, and nothing at all until the socket has answered.
}

/// One row of the message list.
///
/// `GET /consultations/threads` groups messages by appointment, so a row in
/// this list is always a consultation; [peer] carries the thread the chat
/// screen sends to.
class ConversationThread {
  const ConversationThread({
    required this.peer,
    required this.preview,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  final ConversationPeer peer;

  /// The last message's body, shown under the name.
  final String preview;

  final DateTime lastMessageAt;

  final int unreadCount;

  /// The same row with a newer last message.
  ///
  /// Every field is carried across deliberately: an omitted one silently
  /// reverts to its default, which is how a courier's masthead once reset
  /// itself to zero.
  ConversationThread withLastMessage({
    required String preview,
    required DateTime at,
    int? unreadCount,
  }) => ConversationThread(
    peer: peer,
    preview: preview,
    lastMessageAt: at,
    unreadCount: unreadCount ?? this.unreadCount,
  );

  String get appointmentId => peer.thread?.id ?? '';

  bool get hasUnread => unreadCount > 0;

  /// `2:32 PM` today, `Yesterday`, the weekday within the week, then a date.
  ///
  /// It used to print a bare 24-hour clock for every row, so a thread last
  /// answered a fortnight ago read as though it had been answered this
  /// morning.
  String get timeLabel => TimeFormat.threadStamp(lastMessageAt);
}

/// Which side of the thread a message sits on.
///
/// Not `patient`/`doctor`: the same bubble serves a consultation and a
/// courier thread, and which side a message lands on is decided by comparing
/// its sender to the signed-in user — never by anyone's role.
enum MessageAuthor { me, peer }

/// What a bubble is carrying, which decides how it draws.
enum MessageKind { text, image, video, audio, file }

/// The reactions offered on the quick row, before "More" opens the full
/// keyboard.
///
/// These are the five the design called for plus the two most asked for
/// afterwards. They are a *shortcut*, not the allowed set: any emoji the
/// picker can produce is a valid reaction, so this list can be reordered or
/// replaced without touching stored data.
class QuickReactions {
  QuickReactions._();

  static const List<String> emojis = ['❤️', '😆', '🥰', '😠', '😘', '😢', '😮'];

  /// The names the first five used to be stored under.
  ///
  /// Reactions were an enum sent by name; messages written then still come
  /// back as `love` or `haha`, and would draw as raw words in the bubble.
  /// Reading maps them forward — nothing has to be migrated on the server.
  static const Map<String, String> legacyNames = {
    'love': '❤️',
    'haha': '😆',
    'care': '🥰',
    'angry': '😠',
    'kiss': '😘',
  };

  /// The glyph to draw for whatever the server sent, old name or new emoji.
  static String resolve(String wire) => legacyNames[wire] ?? wire;
}

/// One person's reaction to a message.
///
/// [emoji] is the glyph itself rather than a name from a fixed list: the set
/// of reactions people want is open-ended, and a closed enum meant every new
/// one needed a release on both sides.
class MessageReaction {
  const MessageReaction({required this.userId, required this.emoji});

  final String userId;
  final String emoji;
}

/// A file sent in a consultation.
class MessageAttachment {
  const MessageAttachment({
    required this.name,
    required this.mime,
    required this.size,
    this.url,
    this.width,
    this.height,
    this.durationMs,
  });

  final String name;
  final String mime;
  final int size;

  /// Time-limited, signed by the server on read. Null when signing failed —
  /// the bubble then says the file is unavailable rather than showing a
  /// broken image.
  final String? url;

  final int? width;
  final int? height;
  final int? durationMs;

  /// `2.4 MB`, or `812 KB` — what a document row prints under its name.
  String get sizeLabel {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (size >= 1024) return '${(size / 1024).round()} KB';
    return '$size B';
  }

  /// The shape to reserve before the image arrives, so the thread does not
  /// jump as pictures load. Falls back to 4:3 when the server has no
  /// dimensions.
  double get aspectRatio {
    final w = width, h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return 4 / 3;
    return w / h;
  }
}

/// How far an outgoing message has got.
///
/// Only meaningful on your own bubbles — the other side's arrival is the
/// receipt. [sending] is the optimistic state before the server has confirmed.
enum DeliveryState { sending, sent, delivered, read }

/// A single chat bubble.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.author,
    this.deliveredAt,
    this.readAt,
    this.isPending = false,
    this.clientId,
    this.kind = MessageKind.text,
    this.attachment,
    this.uploadProgress,
    this.reactions = const [],
    this.editedAt,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final MessageAuthor author;

  final DateTime? deliveredAt;
  final DateTime? readAt;

  /// True for a bubble shown before the server has acknowledged it.
  final bool isPending;

  /// The sender's own id for this message, used to replace the optimistic
  /// bubble with the stored row rather than showing the message twice.
  final String? clientId;

  final MessageKind kind;
  final MessageAttachment? attachment;

  /// At most one per person, so this doubles as the row shown under a bubble.
  final List<MessageReaction> reactions;

  /// When the sender last rewrote this, or null if they never did. A reader
  /// who saw the first version is owed the word `Edited` under the new one.
  final DateTime? editedAt;

  /// 0–1 while this device is still uploading, null once the server has it.
  /// Kept on the message so the progress bar lives on the bubble it belongs
  /// to rather than in a banner that cannot say which file it means.
  final double? uploadProgress;

  bool get isMine => author == MessageAuthor.me;

  bool get wasEdited => editedAt != null;

  /// Messenger's window, which is the rule people already know. Only your own
  /// words, only text — an attachment's body is a caption for a file that
  /// would no longer match — and only while it is fresh.
  static const Duration editWindow = Duration(minutes: 15);

  /// Whether this can still be rewritten, as of [now].
  bool canEditAt(DateTime now) =>
      isMine &&
      !isPending &&
      kind == MessageKind.text &&
      !hasAttachment &&
      now.difference(sentAt) <= editWindow;

  bool get hasAttachment => attachment != null;

  /// A caption is optional on an attachment, so an empty body is normal.
  bool get hasText => text.trim().isNotEmpty;

  DeliveryState get deliveryState {
    if (isPending) return DeliveryState.sending;
    if (readAt != null) return DeliveryState.read;
    if (deliveredAt != null) return DeliveryState.delivered;
    return DeliveryState.sent;
  }

  ChatMessage copyWith({
    String? id,
    DateTime? deliveredAt,
    DateTime? readAt,
    bool? isPending,
    MessageAttachment? attachment,
    List<MessageReaction>? reactions,
    String? text,
    DateTime? editedAt,
    // Nullable-and-meaningful: passing null must be able to *clear* progress
    // once the upload finishes, which `?? this.uploadProgress` cannot express.
    Object? uploadProgress = _unset,
  }) => ChatMessage(
    id: id ?? this.id,
    text: text ?? this.text,
    sentAt: sentAt,
    author: author,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    readAt: readAt ?? this.readAt,
    isPending: isPending ?? this.isPending,
    clientId: clientId,
    kind: kind,
    attachment: attachment ?? this.attachment,
    reactions: reactions ?? this.reactions,
    editedAt: editedAt ?? this.editedAt,
    uploadProgress: uploadProgress == _unset
        ? this.uploadProgress
        : uploadProgress as double?,
  );

  /// Sentinel distinguishing "not passed" from "passed as null".
  static const Object _unset = Object();

  /// `12:37 PM`, matching the design's bubble timestamps.
  String get timeLabel => TimeFormat.clock(sentAt);
}
