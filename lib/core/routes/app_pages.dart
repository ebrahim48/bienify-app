import 'package:get/get.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/forgot_password_page.dart';
import '../../features/auth/presentation/verify_email_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/password_changed_page.dart';
import '../../features/auth/presentation/get_started_page.dart';
import '../../features/auth/presentation/setup_plan_page.dart';
import '../../features/auth/presentation/generating_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/screens/plan_next_meals_screen.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/account/presentation/screens/paywall_screen.dart';
import '../../features/account/presentation/screens/privacy_policy_screen.dart';
import '../../features/account/presentation/screens/about_us_screen.dart';
import '../../features/account/presentation/screens/contact_us_screen.dart';
import '../../features/account/presentation/screens/edit_profile_screen.dart';
import 'app_routes.dart';

abstract class AppPages {
  AppPages._();

  static final List<GetPage> routes = [
    GetPage(name: AppRoutes.splash,      page: () => const SplashPage()),
    GetPage(name: AppRoutes.onboarding,  page: () => const OnboardingPage()),
    GetPage(name: AppRoutes.login,       page: () => const LoginPage()),
    GetPage(name: AppRoutes.register,    page: () => const RegisterPage()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordPage()),
    GetPage(name: AppRoutes.verifyEmail,    page: () => const VerifyEmailPage()),
    GetPage(name: AppRoutes.resetPassword,  page: () => const ResetPasswordPage()),
    GetPage(name: AppRoutes.passwordChanged, page: () => const PasswordChangedPage()),
    GetPage(name: AppRoutes.getStarted,  page: () => const GetStartedPage()),
    GetPage(name: AppRoutes.setupPlan,   page: () => const SetupPlanPage()),
    GetPage(name: AppRoutes.generating,  page: () => const GeneratingPage()),
    GetPage(name: AppRoutes.planNextMeals, page: () => const PlanNextMealsScreen()),
    GetPage(name: AppRoutes.paywall,       page: () => const PaywallScreen()),
    GetPage(name: AppRoutes.privacyPolicy, page: () => const PrivacyPolicyScreen()),
    GetPage(name: AppRoutes.aboutUs,       page: () => const AboutUsScreen()),
    GetPage(name: AppRoutes.contactUs,     page: () => const ContactUsScreen()),
    GetPage(name: AppRoutes.editProfile,   page: () => const EditProfileScreen()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
  ];
}
