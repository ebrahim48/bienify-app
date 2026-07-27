import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// Icon + label selection card, used for Gender on the profile-setup screen.
///
/// Selected cards invert to the primary fill; unselected ones stay white with
/// the shared 1px `gray100` outline.
///
/// ```dart
/// Row(children: [
///   Expanded(child: AppOptionCard(
///     label: AppStrings.male.tr,
///     icon: Icons.person,
///     isSelected: c.gender.value == Gender.male,
///     onTap: () => c.selectGender(Gender.male),
///   )),
///   AppSpacing.gapH(AppSpacing.xs),
///   ...
/// ])
/// ```
class AppOptionCard extends StatelessWidget {
  const AppOptionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.height = AppSizes.optionCardHeight,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ink = isSelected ? AppColors.white : AppColors.authInk;

    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.fieldFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: height.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: isSelected ? AppColors.actionFill : AppColors.fieldBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.xl2.w, color: ink),
                AppSpacing.gapH(AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
