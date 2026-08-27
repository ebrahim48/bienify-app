/// Where a patient's orders go.
///
/// Lives in `core/models` rather than under the pharmacy feature because it
/// is no longer a checkout-only value: the account owns one saved address and
/// the checkout reads it. An *order* still keeps its own address string, so
/// a past order records where that parcel actually went even after the
/// patient moves.
class DeliveryAddress {
  const DeliveryAddress({
    required this.line1,
    this.line2 = '',
    this.city = '',
    this.note,
    this.doorImageKey,
  });

  /// Street and number. The only line that must be present — an address with
  /// no street cannot be delivered to.
  final String line1;

  final String line2;
  final String city;

  /// Standing instructions for the courier.
  final String? note;

  /// Storage key of the door photo, when one has been attached.
  final String? doorImageKey;

  /// True once there is enough here to deliver to.
  bool get isComplete => line1.trim().isNotEmpty;

  /// The two display lines, with the second falling back to the city so a
  /// one-line address does not print an empty row.
  String get secondLine => line2.trim().isNotEmpty ? line2 : city;

  /// What the order carries: one string, blank parts dropped so it never
  /// reads `"12 Oak St, , "`.
  String get singleLine =>
      [line1, line2, city].map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');

  DeliveryAddress copyWith({
    String? line1,
    String? line2,
    String? city,
    String? note,
    String? doorImageKey,
  }) {
    return DeliveryAddress(
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      note: note ?? this.note,
      doorImageKey: doorImageKey ?? this.doorImageKey,
    );
  }

  /// The body `PATCH /users/me` expects. Blank optionals are omitted rather
  /// than sent empty, so the server stores an absent field, not `''`.
  Map<String, dynamic> toJson() => {
    'line1': line1.trim(),
    if (line2.trim().isNotEmpty) 'line2': line2.trim(),
    if (city.trim().isNotEmpty) 'city': city.trim(),
    if ((note ?? '').trim().isNotEmpty) 'note': note!.trim(),
    if ((doorImageKey ?? '').isNotEmpty) 'doorImageKey': doorImageKey,
  };
}
