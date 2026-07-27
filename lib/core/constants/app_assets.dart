/// Type-safe handles for every bundled asset.
///
/// Never write an asset path inline — add it here so a renamed file breaks at
/// one place instead of silently rendering an empty box at runtime.
class AppAssets {
  AppAssets._();

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';

  // ─── Brand ───────────────────────────────────────────────────────────────
  /// Full lock-up used on the splash screen.
  static const String logo = '$_images/splash.png';

  // ─── Onboarding illustrations ────────────────────────────────────────────
  static const String onboardingFindDoctor = '$_images/rightdoctor.png';
  static const String onboardingConsult = '$_images/consult.png';
  static const String onboardingMedicine = '$_images/medicinedelivered.png';

  // ─── Social providers ────────────────────────────────────────────────────
  static const String googleLogo = '$_images/Google logo.png';
  static const String appleLogo = '$_images/Apple logo.png';

  // ─── Status illustrations ────────────────────────────────────────────────
  /// Reserved for future use — the success badges are drawn with a painter so
  /// they can be recoloured per flow.
  static const String signupSuccess = '$_images/started.png';
  static const String passwordResetSuccess = '$_images/resetsuccess.png';

  // ─── Icons ───────────────────────────────────────────────────────────────
  static const String iconsPath = _icons;
}
