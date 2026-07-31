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

  // ─── Appointments & consultation ─────────────────────────────────────────
  /// Illustration on the "Need Care?" banner.
  static const String appointmentCouple = '$_images/appointmentcouple.png';

  /// Remote party's video feed during a consultation.
  static const String doctorVideo = '$_images/doctorimage.png';

  /// The patient's own picture-in-picture feed.
  static const String clientVideo = '$_images/client.png';

  // ─── Pharmacy ────────────────────────────────────────────────────────────
  /// Product shot on catalogue tiles.
  static const String medicine = '$_images/medicine.png';

  /// Courier photo on the delivery feedback screen.
  static const String deliveryFeedback = '$_images/feedback.png';

  /// Storefront shot behind the "Stores Near You" row.
  static const String storesNear = '$_images/storesnear.png';

  /// The delivery rider's headshot.
  static const String rider = '$_images/riderarif.png';

  /// The cyclist on the "Apply Rider?" panel.
  static const String cycleRider = '$_images/cyclerider.png';

  /// The hand-over photograph on the courier's delivered screen. Shares the
  /// onboarding artwork — it is the same moment, and no separate export of it
  /// shipped with the designs.
  static const String deliveredHero = onboardingMedicine;

  // ─── Profile & medical vault ─────────────────────────────────────────────
  /// "Online Pharmacy" promo strip on the order-history screen.
  static const String promoBanner = '$_images/bannar.png';

  /// Empty state for a wallet with no saved card.
  static const String noPaymentMethod = '$_images/no paymentmethod.png';

  /// Uploaded test report — the chest X-ray thumbnail in the designs.
  static const String reportDocument = '$_images/report.png';

  // ─── People ──────────────────────────────────────────────────────────────
  /// Fallback headshot for doctors, used wherever a profile photo is missing.
  static const String doctorPlaceholder = '$_images/profile.png';

  /// Portrait on the Doctor Details hero.
  static const String doctorPortrait = doctorPlaceholder;

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
