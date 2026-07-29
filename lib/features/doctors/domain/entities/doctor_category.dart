/// A specialty tile on the "Find a doctor" screen.
///
/// Names only — this feature is UI-first, so there is no repository or API
/// behind it. [id] is what a future endpoint would filter on.
class DoctorCategory {
  const DoctorCategory({required this.id, required this.name});

  final String id;
  final String name;
}

/// The filters applied to a doctor list.
class DoctorFilter {
  const DoctorFilter({
    this.minPrice = 0,
    this.maxPrice = maxSupportedPrice,
    this.ratings = const {},
  });

  /// Upper bound of the price slider.
  static const double maxSupportedPrice = 500;

  final double minPrice;
  final double maxPrice;

  /// Selected star buckets, e.g. `{5, 4}`.
  final Set<int> ratings;

  bool get isDefault =>
      minPrice == 0 && maxPrice == maxSupportedPrice && ratings.isEmpty;

  String get minPriceLabel => '\$${minPrice.round()}';

  String get maxPriceLabel => '\$${maxPrice.round()}';

  DoctorFilter copyWith({
    double? minPrice,
    double? maxPrice,
    Set<int>? ratings,
  }) {
    return DoctorFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      ratings: ratings ?? this.ratings,
    );
  }
}
