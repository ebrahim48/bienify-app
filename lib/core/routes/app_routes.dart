/// Every navigable destination in the app.
///
/// Screens navigate with `Get.toNamed(AppRoutes.login)` — never with a raw
/// string — so a renamed route is a compile error rather than a dead link.
abstract class AppRoutes {
  AppRoutes._();

  // ─── Boot ────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String locationPermission = '/location-permission';
  static const String onboarding = '/onboarding';

  // ─── Sign up ─────────────────────────────────────────────────────────────
  static const String phoneNumber = '/phone-number';
  static const String otp = '/otp';
  static const String profileSetup = '/profile-setup';
  static const String profileCredentials = '/profile-credentials';
  static const String signupSuccess = '/signup-success';

  // ─── Sign in ─────────────────────────────────────────────────────────────
  static const String login = '/login';

  // ─── Password recovery ───────────────────────────────────────────────────
  static const String forgotPassword = '/forgot-password';
  static const String newPassword = '/new-password';
  static const String passwordUpdated = '/password-updated';

  // ─── App ─────────────────────────────────────────────────────────────────
  static const String home = '/home';
}
