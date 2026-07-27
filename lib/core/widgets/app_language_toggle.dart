import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../localization/localization_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// The `En | Spa` segmented control pinned to the top-right of onboarding.
///
/// Reads and writes [LocalizationController], so switching it re-renders
/// every `.tr` string in the app and persists the choice.
class AppLanguageToggle extends StatelessWidget {
  const AppLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LocalizationController>();

    return Obx(
      () => Container(
        width: AppSizes.languageToggleWidth.w,
        height: AppSizes.languageToggleHeight.h,
        padding: EdgeInsets.all(AppSizes.xs.w * 0.5),
        decoration: BoxDecoration(
          color: AppColors.actionFill,
          borderRadius: AppRadius.rFull,
        ),
        child: Row(
          children: [
            for (final language in AppLanguage.values)
              Expanded(
                child: _Segment(
                  label: language.shortLabel,
                  isSelected: controller.isSelected(language),
                  onTap: () => controller.change(language),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : AppColors.transparent,
          borderRadius: AppRadius.rFull,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.rc(
            isSelected ? AppColors.authInk : AppColors.white,
          ),
        ),
      ),
    );
  }
}
