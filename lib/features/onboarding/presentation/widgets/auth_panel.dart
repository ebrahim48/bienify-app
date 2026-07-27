import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_inline_link.dart';
import '../../../../core/widgets/app_phone_field.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/phone_auth_controller.dart';

/// The tinted sign-in panel anchored to the bottom of onboarding.
///
/// Sits outside the `PageView` because it does not scroll with the slides —
/// only the illustration and copy above it change.
class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PhoneAuthController>();

    return Container(
      width: double.infinity,
      color: AppColors.authPanel,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding.w,
        AppSpacing.base.h,
        AppSpacing.screenPadding.w,
        AppSpacing.md.h,
      ),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: AppStrings.signInWithGoogle.tr,
              variant: AppButtonVariant.dark,
              iconAsset: AppAssets.googleLogo,
              isLoading:
                  controller.pendingProvider.value == SocialProvider.google,
              isEnabled: controller.pendingProvider.value == null,
              onPressed: () => controller.signIn(SocialProvider.google),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            AppButton(
              label: AppStrings.signInWithApple.tr,
              variant: AppButtonVariant.dark,
              iconAsset: AppAssets.appleLogo,
              isLoading:
                  controller.pendingProvider.value == SocialProvider.apple,
              isEnabled: controller.pendingProvider.value == null,
              onPressed: () => controller.signIn(SocialProvider.apple),
            ),
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.or.tr,
              style: AppTextStyles.titleSmall.rc(AppColors.authInk),
            ),
            AppSpacing.gapV(AppSpacing.base),
            AppPhoneField.panel(
              controller: controller.phoneController,
              country: controller.country.value,
              onCountryChanged: controller.selectCountry,
              onChanged: controller.onPhoneChanged,
              errorText: controller.errorOf(PhoneAuthController.phoneField),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.continueWithPhone(),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            AppButton(
              label: AppStrings.continueWithPhoneNumber.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.continueWithPhone,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            AppInlineLink(
              prompt: AppStrings.alreadyHaveAnAccount.tr,
              action: AppStrings.login.tr,
              onTap: onLoginTap,
            ),
            AppSpacing.gapV(AppSpacing.md),
            AppUnderlinedLink(
              label: AppStrings.joinAsADoctor.tr,
              onTap: controller.joinAsDoctor,
            ),
          ],
        ),
      ),
    );
  }
}
