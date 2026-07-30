import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';

/// `[icon] Title / subtitle` card, used by the medical-vault and test-report
/// lists — the two designs draw the same row with a different tint.
class RecordRow extends StatelessWidget {
  const RecordRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.description_outlined,
    this.iconSurface = AppColors.accentSurface,
    this.iconInk = AppColors.link,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconSurface;
  final Color iconInk;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _disc.w,
            height: _disc.w,
            decoration: BoxDecoration(
              color: iconSurface,
              borderRadius: AppRadius.rLg,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: AppSizes.xl.w, color: iconInk),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
