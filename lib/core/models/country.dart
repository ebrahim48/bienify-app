/// A dialling country shown by `AppPhoneField`'s picker.
///
/// Kept in `core` (rather than the auth feature) because the phone field is a
/// shared widget that any future feature — profile editing, doctor sign-up —
/// can reuse.
class Country {
  const Country({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.nationalNumberLength,
  });

  final String name;

  /// ISO 3166-1 alpha-2 code, e.g. `ZA`.
  final String isoCode;

  /// Dial prefix including the leading `+`, e.g. `+27`.
  final String dialCode;

  /// Expected digit count after the dial code; used by phone validation.
  final int nationalNumberLength;

  /// Regional-indicator flag rendered from [isoCode], so no image assets are
  /// needed and every country in the list is covered automatically.
  String get flagEmoji => isoCode
      .toUpperCase()
      .codeUnits
      .map((unit) => String.fromCharCode(unit + 0x1F1A5))
      .join();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Country && other.isoCode == isoCode);

  @override
  int get hashCode => isoCode.hashCode;
}

/// The dialling codes offered by the picker.
///
/// Ordered with the launch market first; extend the list as the app rolls out
/// to new regions.
class Countries {
  Countries._();

  /// Pre-selected in every design mock-up.
  static const Country defaultCountry = southAfrica;

  static const Country southAfrica = Country(
    name: 'South Africa',
    isoCode: 'ZA',
    dialCode: '+27',
    nationalNumberLength: 9,
  );

  static const List<Country> all = [
    southAfrica,
    Country(
      name: 'United States',
      isoCode: 'US',
      dialCode: '+1',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'United Kingdom',
      isoCode: 'GB',
      dialCode: '+44',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Spain',
      isoCode: 'ES',
      dialCode: '+34',
      nationalNumberLength: 9,
    ),
    Country(
      name: 'Mexico',
      isoCode: 'MX',
      dialCode: '+52',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Colombia',
      isoCode: 'CO',
      dialCode: '+57',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Argentina',
      isoCode: 'AR',
      dialCode: '+54',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Brazil',
      isoCode: 'BR',
      dialCode: '+55',
      nationalNumberLength: 11,
    ),
    Country(
      name: 'Nigeria',
      isoCode: 'NG',
      dialCode: '+234',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Kenya',
      isoCode: 'KE',
      dialCode: '+254',
      nationalNumberLength: 9,
    ),
    Country(
      name: 'India',
      isoCode: 'IN',
      dialCode: '+91',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Bangladesh',
      isoCode: 'BD',
      dialCode: '+880',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Pakistan',
      isoCode: 'PK',
      dialCode: '+92',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'United Arab Emirates',
      isoCode: 'AE',
      dialCode: '+971',
      nationalNumberLength: 9,
    ),
    Country(
      name: 'Saudi Arabia',
      isoCode: 'SA',
      dialCode: '+966',
      nationalNumberLength: 9,
    ),
    Country(
      name: 'Germany',
      isoCode: 'DE',
      dialCode: '+49',
      nationalNumberLength: 11,
    ),
    Country(
      name: 'France',
      isoCode: 'FR',
      dialCode: '+33',
      nationalNumberLength: 9,
    ),
    Country(
      name: 'Canada',
      isoCode: 'CA',
      dialCode: '+1',
      nationalNumberLength: 10,
    ),
    Country(
      name: 'Australia',
      isoCode: 'AU',
      dialCode: '+61',
      nationalNumberLength: 9,
    ),
  ];

  /// Case-insensitive search over country name and dial code.
  static List<Country> search(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return all;
    return all
        .where(
          (country) =>
              country.name.toLowerCase().contains(term) ||
              country.dialCode.contains(term) ||
              country.isoCode.toLowerCase().contains(term),
        )
        .toList();
  }
}
