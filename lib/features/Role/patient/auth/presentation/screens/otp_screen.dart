import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/utils/validators.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_inline_link.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/otp_controller.dart';

/// The verification-code screen.
///
/// One screen covers both designs — the title and the button label are the
/// only differences between "Get OTP → Next" (sign-up) and "Enter OTP →
/// Verify Now" (password reset).
class OtpScreen extends GetView<OtpController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSignUp = controller.flow.isSignUp;

    return AppScaffold(
      topBar: AppTopBar(
        title: (isSignUp ? AppStrings.getOtp : AppStrings.enterOtp).tr,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Text(
            AppStrings.codeSentHeading.tr,
            style: AppTextStyles.headlineSmall.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.codeSentSubtitle.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.bodyInk),
          ),
          AppSpacing.gapV(AppSpacing.lg),
          Obx(
            () => AppTextField(
              controller: controller.codeController,
              hint: AppStrings.enterSixDigitCode.tr,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: Validators.otpLength,
              autofocus: true,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: controller.errorOf(OtpController.codeField),
              onChanged: controller.onCodeChanged,
              onSubmitted: (_) => controller.verify(),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => AppInlineLink(
              prompt: AppStrings.codeNotReceived.tr,
              action: controller.canResend
                  ? AppStrings.requestNewOtp.tr
                  : AppStrings.resendIn.trParams({
                      'seconds': '${controller.secondsRemaining.value}',
                    }),
              isEnabled: controller.canResend,
              onTap: controller.resend,
            ),
          ),
          AppSpacing.gapV(AppSpacing.lg),
          Obx(
            () => AppButton(
              label: (isSignUp ? AppStrings.next : AppStrings.verifyNow).tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.verify,
            ),
          ),
        ],
      ),
    );
  }
}
