import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/auth_bindings.dart';
import '../../features/auth/presentation/controllers/auth_flow.dart';
import '../../features/auth/presentation/screens/auth_status_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/phone_number_screen.dart';
import '../../features/auth/presentation/screens/profile_credentials_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/location_permission_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

/// The route table handed to `GetMaterialApp`.
///
/// Each entry pairs a screen with the binding that provides its controller,
/// so a route is the only place that knows how a screen is assembled.
abstract class AppPages {
  AppPages._();

  static const Transition _transition = Transition.cupertino;
  static const Duration _transitionDuration = Duration(milliseconds: 280);

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.locationPermission,
      page: () => const LocationPermissionScreen(),
      binding: LocationPermissionBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),

    // ─── Sign up ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.phoneNumber,
      page: () => const PhoneNumberScreen(),
      binding: PhoneNumberBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      binding: OtpBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.profileCredentials,
      page: () => const ProfileCredentialsScreen(),
      binding: ProfileSetupBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupSuccess,
      page: () => AuthStatusScreen.signUpComplete(),
      transition: Transition.fadeIn,
    ),

    // ─── Sign in ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Password recovery ─────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const PhoneNumberScreen(flow: AuthFlow.passwordReset),
      binding: PhoneNumberBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.newPassword,
      page: () => const NewPasswordScreen(),
      binding: NewPasswordBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.passwordUpdated,
      page: () => AuthStatusScreen.passwordUpdated(),
      transition: Transition.fadeIn,
    ),

    // ─── App ───────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
