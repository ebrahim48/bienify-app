import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// A full-width `Label ›` navigation row.
///
/// Used by Profile, Settings and My Health profile — three screens whose whole
/// body is a stack of these. The tone is a parameter because it can vary: all
/// screens pass [AppColors.authInk], which is what the designs draw; the
/// muted [AppColors.menuLabel] default is there for a lower-emphasis list.
///
/// ```dart
/// AppMenuRow(label: AppStrings.myWallet.tr, onTap: controller.openWallet)
/// ```
class AppMenuRow extends StatelessWidget {
  const AppMenuRow({
    super.key,
    required this.label,
    required this.onTap,
    this.labelColor = AppColors.menuLabel,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Color labelColor;

  /// Optional glyph before the label; the designs use none.
  final Widget? leading;

  /// Row height from the design — the rows sit 40pt apart.
  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height.h,
        child: Row(
          children: [
            if (leading != null) ...[leading!, AppSpacing.gapH(AppSpacing.sm)],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.rc(labelColor),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: AppSizes.xl2.w,
              color: labelColor,
            ),
          ],
        ),
      ),
    );
  }
}
