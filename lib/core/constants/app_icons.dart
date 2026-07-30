/// Type-safe handles for the SVG icon set in `assets/icons`.
///
/// Render them with `AppSvgIcon`, which handles sizing and tinting — the
/// source files carry their own fills, so a raw `SvgPicture.asset` would
/// ignore the theme.
class AppIcons {
  AppIcons._();

  static const String _path = 'assets/icons';

  // ─── Bottom navigation ───────────────────────────────────────────────────
  static const String home = '$_path/home.svg';
  static const String appointments = '$_path/appointments.svg';
  static const String doctors = '$_path/doctors.svg';
  static const String pharmacy = '$_path/pharmacy.svg';

  // ─── Home header ─────────────────────────────────────────────────────────
  static const String profile = '$_path/profile.svg';
  static const String person = '$_path/person.svg';
  static const String shoppingBag = '$_path/shoppingbag.svg';

  /// Cart glyph in the Pharmacy header.
  static const String cart = '$_path/shopping-bag.svg';
  static const String message = '$_path/message.svg';
  static const String notification = '$_path/notification.svg';

  // ─── Content ─────────────────────────────────────────────────────────────
  static const String heart = '$_path/heart.svg';
  static const String clock = '$_path/clock.svg';

  // ─── Booking & chat ──────────────────────────────────────────────────────
  //
  // The two file names are the reverse of their artwork: `attach.svg` draws a
  // cloud-upload and `upload.svg` draws a paperclip. These aliases name what
  // is actually rendered, so call sites read correctly.
  static const String cloudUpload = '$_path/attach.svg';
  static const String paperclip = '$_path/upload.svg';

  /// Sliders glyph on the doctor-list app bar.
  static const String filter = '$_path/pricerange.svg';

  /// Finished 80pt badge — a green disc with a check — for the consultation
  /// summary. Draw it untinted; recolouring flattens the whole mark.
  static const String consultationComplete = '$_path/consultationhistory.svg';

  static const String camera = '$_path/camera.svg';
  static const String wallet = '$_path/wallet.svg';
  static const String send = '$_path/send.svg';

  // ─── Profile & partner ───────────────────────────────────────────────────
  //
  // All three ship pre-coloured — the partner marks in `authInk`, the log-out
  // arrow in `logoutFill`. Draw them untinted, as with `profile.svg`.
  static const String pharmacyOwner = '$_path/pharmacyowner.svg';
  static const String rider = '$_path/rider.svg';
  static const String logout = '$_path/log-out.svg';

  /// Filled speech bubble for the doctor shell's Message tab. `message.svg` is
  /// the outlined header glyph and reads too light at nav size.
  static const String bottomMessage = '$_path/bottommessage.svg';
}
