/// The age brackets shown as chips on the profile-setup screen.
///
/// Labels are numeric, so they need no translation — the enum carries them
/// directly and doubles as the wire format.
enum AgeRange {
  age18to25('18-25'),
  age25to32('25-32'),
  age32to40('32-40'),
  age40to48('40-48'),
  age48to60('48-60'),
  age60to75('60-75'),
  age75plus('75+');

  const AgeRange(this.label);

  final String label;

  static AgeRange? fromLabel(String? label) {
    if (label == null) return null;
    for (final range in AgeRange.values) {
      if (range.label == label) return range;
    }
    return null;
  }
}
