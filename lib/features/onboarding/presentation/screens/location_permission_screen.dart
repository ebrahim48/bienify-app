import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/location_pin.dart';
import '../controllers/location_permission_controller.dart';

/// "Allow your Location" — a centred pin with the Deny / Allow pair pinned to
/// the bottom of the screen.
class LocationPermissionScreen extends GetView<LocationPermissionController> {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      bottomBar: _ActionRow(controller: controller),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LocationPin(),
            AppSpacing.gapV(AppSpacing.md),
            Text(
              AppStrings.allowYourLocation.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.rc(AppColors.authInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller});

  final LocationPermissionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: AppButton(
              label: AppStrings.deny.tr,
              variant: AppButtonVariant.neutral,
              isEnabled: !controller.isRequesting.value,
              onPressed: controller.deny,
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: AppButton(
              label: AppStrings.allow.tr,
              isLoading: controller.isRequesting.value,
              onPressed: controller.allow,
            ),
          ),
        ],
      ),
    );
  }
}
