/// An item in the pharmacy catalogue.
class Medicine {
  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.price,
    this.requiresPrescription = false,
    this.isInStock = true,
  });

  final String id;
  final String name;

  /// e.g. `500 mg · 20 tablets`.
  final String dosage;

  final double price;
  final bool requiresPrescription;
  final bool isInStock;

  String get priceLabel => '\$${price.toStringAsFixed(2)}';
}
