/// A practitioner as shown in listings and on the details screen.
class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    this.photoUrl,
    this.rating = 0,
    this.reviewCount = 0,
    this.consultationFee = 0,
    this.isAvailable = true,
  });

  final String id;

  /// Display name including the honorific, e.g. `Dr.Anjelica Peacock,MD`.
  final String name;

  final String specialty;
  final String? photoUrl;

  /// Mean rating out of five.
  final double rating;

  final int reviewCount;

  /// Price per consultation in the account's currency.
  final double consultationFee;

  final bool isAvailable;

  /// `4.8` — one decimal, matching the design.
  String get ratingLabel => rating.toStringAsFixed(1);

  /// `(220)`.
  String get reviewCountLabel => '($reviewCount)';
}
