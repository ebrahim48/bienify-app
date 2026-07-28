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

  static const String camera = '$_path/camera.svg';
  static const String wallet = '$_path/wallet.svg';
  static const String send = '$_path/send.svg';
}
