/// Which conversation a message belongs to.
///
/// A consultation and a courier thread are the same conversation to everyone
/// involved — text, attachments, receipts, typing, reactions — and the server
/// serves both from one set of events. They differ only in which id names the
/// thread, so that difference is held here rather than repeated at every call
/// site as a nullable `appointmentId` beside a nullable `deliveryId`.
class ChatThread {
  const ChatThread.consultation(this.id) : kind = consultationKind;
  const ChatThread.delivery(this.id) : kind = deliveryKind;

  const ChatThread._(this.kind, this.id);

  static const String consultationKind = 'appointment';
  static const String deliveryKind = 'delivery';

  final String kind;
  final String id;

  bool get isConsultation => kind == consultationKind;
  bool get isDelivery => kind == deliveryKind;

  /// True once there is a real thread behind this — an empty id means the
  /// screen was opened outside any conversation and has nowhere to send.
  bool get isLive => id.isNotEmpty;

  /// What every socket event and request body names the thread with.
  Map<String, dynamic> get payload =>
      isConsultation ? {'appointmentId': id} : {'deliveryId': id};

  /// Identifies a thread in a set, so two kinds sharing an id cannot collide.
  String get key => '$kind:$id';

  /// Reads the thread a server payload is about.
  ///
  /// Receipts and typing echo the thread's own id back, and a client watching
  /// a consultation and a delivery at once has to know which one moved.
  static ChatThread? fromJson(Map<String, dynamic> json) {
    final delivery = '${json['deliveryId'] ?? ''}';
    if (delivery.isNotEmpty) return ChatThread.delivery(delivery);
    final appointment = '${json['appointmentId'] ?? ''}';
    if (appointment.isNotEmpty) return ChatThread.consultation(appointment);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ChatThread && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => key;

  ChatThread copyWith({String? id}) => ChatThread._(kind, id ?? this.id);
}
