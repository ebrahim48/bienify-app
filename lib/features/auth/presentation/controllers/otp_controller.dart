import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_navigator.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/password_recovery_usecases.dart';
import '../../domain/usecases/phone_auth_usecases.dart';
import 'auth_flow.dart';

/// Backs the one OTP screen used by both the sign-up and password-reset
/// journeys, including the resend cool-down.
class OtpController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  OtpController({
    required OtpArguments arguments,
    required VerifyOtp verifyOtp,
    required RequestOtp requestOtp,
    required RequestPasswordResetOtp requestPasswordResetOtp,
    required VerifyPasswordResetOtp verifyPasswordResetOtp,
  }) : _verifyOtp = verifyOtp,
       _requestOtp = requestOtp,
       _requestPasswordResetOtp = requestPasswordResetOtp,
       _verifyPasswordResetOtp = verifyPasswordResetOtp,
       flow = arguments.flow,
       _challenge = arguments.challenge;

  final VerifyOtp _verifyOtp;
  final RequestOtp _requestOtp;
  final RequestPasswordResetOtp _requestPasswordResetOtp;
  final VerifyPasswordResetOtp _verifyPasswordResetOtp;

  static const String codeField = 'code';

  final AuthFlow flow;
  OtpChallenge _challenge;

  final TextEditingController codeController = TextEditingController();

  /// Seconds left before "Request New OTP" becomes tappable again.
  final RxInt secondsRemaining = 0.obs;

  Timer? _timer;

  bool get canResend => secondsRemaining.value == 0;

  String get phoneNumber => _challenge.phoneNumber;

  @override
  void onInit() {
    super.onInit();
    _startCooldown(_challenge.resendCooldown);
  }

  @override
  void onClose() {
    _timer?.cancel();
    codeController.dispose();
    super.onClose();
  }

  void onCodeChanged(String value) {
    clearError(codeField);
    // Submitting as soon as the sixth digit lands saves a tap; the button
    // stays available for anyone pasting a code.
    if (value.length == Validators.otpLength) verify();
  }

  Future<void> verify() async {
    final isValid = validate({codeField: Validators.otp(codeController.text)});
    if (!isValid) return;

    await submit(() async {
      if (flow.isSignUp) {
        final session = await _verifyOtp(
          challenge: _challenge,
          code: codeController.text.trim(),
        );
        AppNavigator.resetTo(
          session.requiresProfileSetup
              ? AppRoutes.profileSetup
              : AppRoutes.home,
        );
      } else {
        final resetToken = await _verifyPasswordResetOtp(
          challenge: _challenge,
          code: codeController.text.trim(),
        );
        Get.toNamed<void>(
          AppRoutes.newPassword,
          arguments: NewPasswordArguments(resetToken: resetToken),
        );
      }
    });
  }

  Future<void> resend() async {
    if (!canResend) return;
    await submit(() async {
      _challenge = flow.isSignUp
          ? await _requestOtp(_challenge.phoneNumber)
          : await _requestPasswordResetOtp(_challenge.phoneNumber);
      codeController.clear();
      clearError(codeField);
      _startCooldown(_challenge.resendCooldown);
      AppSnackbar.success(AppStrings.otpResent.tr);
    });
  }

  void _startCooldown(Duration duration) {
    _timer?.cancel();
    secondsRemaining.value = duration.inSeconds;
    if (secondsRemaining.value == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value <= 1) {
        secondsRemaining.value = 0;
        timer.cancel();
      } else {
        secondsRemaining.value--;
      }
    });
  }
}
