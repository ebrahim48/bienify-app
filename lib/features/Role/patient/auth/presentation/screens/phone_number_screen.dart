import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_phone_field.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/auth_flow.dart';
import '../controllers/phone_auth_controller.dart';

/// "Enter Phone Number" → **Get OTP**.
///
/// Serves both the sign-up entry point and "Forgot password"; [flow] is read
/// from the route so the same screen covers the two paths in the designs.
class PhoneNumberScreen extends GetView<PhoneAuthController> {
  const PhoneNumberScreen({super.key, this.flow = AuthFlow.signUp});

  final AuthFlow flow;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.enterPhoneNumberTitle.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Obx(
            () => AppPhoneField(
              controller: controller.phoneController,
              country: controller.country.value,
              onCountryChanged: controller.selectCountry,
              onChanged: controller.onPhoneChanged,
              errorText: controller.errorOf(PhoneAuthController.phoneField),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.sendOtp(flow),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => AppButton(
              label: AppStrings.getOtp.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: () => controller.sendOtp(flow),
            ),
          ),
        ],
      ),
    );
  }
}
