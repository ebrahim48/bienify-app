import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/models/country.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/email_auth_usecases.dart';
import '../../domain/usecases/password_recovery_usecases.dart';
import '../../domain/usecases/phone_auth_usecases.dart';
import 'auth_flow.dart';

/// Drives every place a phone number is entered: the onboarding panel, the
/// standalone "Enter Phone Number" screen, and "Forgot password".
///
/// It is registered permanently because the onboarding panel and the
/// standalone screen share the same draft number — a user who types a number
/// on onboarding and taps through finds it already filled in.
class PhoneAuthController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  PhoneAuthController({
    required RequestOtp requestOtp,
    required RequestPasswordResetOtp requestPasswordResetOtp,
    required SignInWithProvider signInWithProvider,
  }) : _requestOtp = requestOtp,
       _requestPasswordResetOtp = requestPasswordResetOtp,
       _signInWithProvider = signInWithProvider;

  final RequestOtp _requestOtp;
  final RequestPasswordResetOtp _requestPasswordResetOtp;
  final SignInWithProvider _signInWithProvider;

  static const String phoneField = 'phone';

  final TextEditingController phoneController = TextEditingController();
  final Rx<Country> country = Countries.defaultCountry.obs;

  /// Which provider is mid-handshake, so only that button spins.
  final Rxn<SocialProvider> pendingProvider = Rxn<SocialProvider>();

  /// The number in E.164 form, ready for the API.
  String get e164 =>
      '${country.value.dialCode}${phoneController.text.replaceAll(RegExp(r'\s+'), '')}';

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  void selectCountry(Country value) {
    country.value = value;
    clearError(phoneField);
  }

  void onPhoneChanged(String _) => clearError(phoneField);

  /// Sends an OTP for [flow] and, on success, opens the OTP screen.
  Future<void> sendOtp(AuthFlow flow) async {
    final isValid = validate({
      phoneField: Validators.phone(phoneController.text, country.value),
    });
    if (!isValid) return;

    await submit(() async {
      final challenge = flow.isSignUp
          ? await _requestOtp(e164)
          : await _requestPasswordResetOtp(e164);

      await Get.toNamed<void>(
        AppRoutes.otp,
        arguments: OtpArguments(challenge: challenge, flow: flow),
      );
    });
  }

  /// Onboarding: "Continue With Phone Number" → the standalone phone screen
  /// keeps the flow identical to tapping through from Login.
  Future<void> continueWithPhone() => sendOtp(AuthFlow.signUp);

  Future<void> signIn(SocialProvider provider) async {
    if (pendingProvider.value != null) return;
    pendingProvider.value = provider;
    try {
      await submit(() async {
        final session = await _signInWithProvider(provider);
        Get.offAllNamed<void>(
          session.requiresProfileSetup
              ? AppRoutes.profileSetup
              : AppRoutes.home,
        );
      });
    } finally {
      pendingProvider.value = null;
    }
  }

  /// "Join as a Doctor".
  ///
  /// Practitioner onboarding shares the phone-first registration entry point;
  /// the extra credentialing steps hang off the profile flow once designed.
  void joinAsDoctor() => Get.toNamed<void>(AppRoutes.phoneNumber);
}
