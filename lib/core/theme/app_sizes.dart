/// Size tokens (`size`, 11 tokens) from the Bienify token board, plus the
/// fixed component measurements taken from the screens.
///
/// Anything with a hard-coded height in a design (button, field, chip …)
/// belongs here so a spec change is a one-line edit.
class AppSizes {
  AppSizes._();

  // ─── Raw scale ───────────────────────────────────────────────────────────
  static const double zero = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double base = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 32;
  static const double xl4 = 40;
  static const double xl5 = 48;

  // ─── Component sizes ─────────────────────────────────────────────────────

  /// Width of every full-bleed control (390 − 2×16).
  static const double contentWidth = 358;

  /// Buttons and inputs share the same 50pt height across the design.
  static const double controlHeight = 50;

  /// Custom app bar height (below the status bar).
  static const double appBarHeight = 56;

  /// Gender / choice option card.
  static const double optionCardHeight = 64;

  /// Age chip.
  static const double choiceChipHeight = 36;

  /// Language segmented toggle.
  static const double languageToggleHeight = 32;
  static const double languageToggleWidth = 80;

  /// Page-indicator dots.
  static const double dotSize = 8;
  static const double dotActiveWidth = 18;
  static const double dotGap = 5;

  /// Starburst status badge on the success screens.
  static const double statusBadgeSize = 176;

  /// Leading icon inside inputs and buttons.
  static const double fieldIcon = 20;
  static const double buttonIcon = 24;

  /// Location-permission pin illustration.
  static const double locationPinWidth = 64;
  static const double locationPinHeight = 79;

  /// Border width for outlined surfaces.
  static const double borderWidth = 1;
}
