import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/entities/auth_session.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/bindings/auth_bindings.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/controllers/auth_flow.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/controllers/otp_controller.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/auth_status_screen.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/login_screen.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/new_password_screen.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/otp_screen.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/phone_number_screen.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/profile_credentials_screen.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/profile_setup_screen.dart';
import 'package:bienify_app/features/Role/patient/onboarding/presentation/screens/location_permission_screen.dart';
import 'package:bienify_app/features/Role/patient/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Renders every auth and onboarding screen at the design viewport and fails
/// on any layout overflow or build error.
///
/// Cheap insurance: these screens are almost entirely layout, so "it lays out
/// at 390×876 with the real theme, bindings and translations" is the
/// assertion that matters most.
void main() {
  const String testRoute = '/screen-under-test';

  const OtpArguments otpArguments = OtpArguments(
    challenge: OtpChallenge(
      verificationId: 'test-verification',
      phoneNumber: '+27821234567',
    ),
    flow: AuthFlow.signUp,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(useMocks: true);
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  /// Boots the app on a blank route, then navigates to [screen] so bindings
  /// see `Get.arguments` exactly as they do in production.
  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Bindings? binding,
    Object? arguments,
  }) async {
    tester.view.physicalSize = BienifyApp.designSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: testRoute,
              page: () => screen,
              binding: binding,
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    Get.toNamed<void>(testRoute, arguments: arguments);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('Location permission screen renders', (tester) async {
    await pump(
      tester,
      const LocationPermissionScreen(),
      binding: LocationPermissionBinding(),
    );
    expect(find.text('Allow your Location'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
  });

  testWidgets('Onboarding screen renders slide one and the auth panel', (
    tester,
  ) async {
    await pump(tester, const OnboardingScreen(), binding: OnboardingBinding());
    expect(find.text('Find the Right Doctor'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Continue With Phone Number'), findsOneWidget);
    expect(find.text('Join as a Doctor'), findsOneWidget);
  });

  testWidgets('Phone number screen renders', (tester) async {
    await pump(
      tester,
      const PhoneNumberScreen(),
      binding: PhoneNumberBinding(),
    );
    expect(find.text('Enter Phone Number'), findsWidgets); // title + hint
    expect(find.text('Get OTP'), findsOneWidget);
    expect(find.text('+27'), findsOneWidget);
  });

  testWidgets('OTP screen renders the sign-up variant', (tester) async {
    await pump(
      tester,
      const OtpScreen(),
      binding: OtpBinding(),
      arguments: otpArguments,
    );
    expect(find.text('Code sent-Check your text messages'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Releases the resend-cooldown timer before the framework checks for
    // pending timers.
    Get.delete<OtpController>();
    await tester.pump();
  });

  testWidgets('Profile setup step one renders every choice', (tester) async {
    await pump(
      tester,
      const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
    );
    expect(find.text('Set Up Your Profile'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('18-25'), findsOneWidget);
    expect(find.text('75+'), findsOneWidget);
  });

  testWidgets('Profile setup step two renders', (tester) async {
    await pump(
      tester,
      const ProfileCredentialsScreen(),
      binding: ProfileSetupBinding(),
    );
    expect(find.text('Save & Continue'), findsOneWidget);
    expect(find.text('example@gmail.com'), findsOneWidget);
  });

  testWidgets('Login screen renders', (tester) async {
    await pump(tester, const LoginScreen(), binding: LoginBinding());
    expect(find.text('Forgot your password?'), findsOneWidget);
    expect(find.text('Sign Up Now'), findsOneWidget);
  });

  testWidgets('New password screen renders', (tester) async {
    await pump(
      tester,
      const NewPasswordScreen(),
      binding: NewPasswordBinding(),
      arguments: const NewPasswordArguments(resetToken: 'test-token'),
    );
    expect(find.text('Enter New Password'), findsOneWidget);
    expect(find.text('Reset Password'), findsOneWidget);
  });

  testWidgets('Sign-up success screen renders', (tester) async {
    await pump(tester, AuthStatusScreen.signUpComplete());
    expect(find.text('You’re all set up !'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Password updated screen renders', (tester) async {
    await pump(tester, AuthStatusScreen.passwordUpdated());
    expect(find.text('Password Updated!'), findsOneWidget);
    expect(find.text('Login Now'), findsOneWidget);
  });
}
