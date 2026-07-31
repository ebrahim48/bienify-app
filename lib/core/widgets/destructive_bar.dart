import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'app_svg_icon.dart';

/// Full-width white bar with a red glyph and label centred in it.
///
/// The designs draw the identical shape three times — Profile's "Log out",
/// My Health profile's "Delete Account" and Settings' — so it is one widget.
///
/// Both glyphs ship stroked in [AppColors.logoutFill], which is why the icon
/// is drawn untinted and the label simply repeats that colour.
///
/// ```dart
/// DestructiveBar(
///   iconAsset: AppIcons.delete,
///   label: AppStrings.deleteAccount.tr,
///   onTap: () => _confirmDelete(context),
/// )
/// ```
class DestructiveBar extends StatelessWidget {
  const DestructiveBar({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.controlHeight.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 16pt: the design draws 14px of ink inside the 48pt bar.
              AppSvgIcon(iconAsset, size: AppSizes.lg),
              AppSpacing.gapH(AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.logoutFill),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
