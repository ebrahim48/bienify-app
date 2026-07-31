import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';

/// "Need Care?" prompt: copy and a book action on the left, the illustration
/// bleeding off the right edge.
class NeedCareBanner extends StatelessWidget {
  const NeedCareBanner({super.key, required this.onBook});

  final VoidCallback onBook;

  static const double height = 140;
  static const double _illustrationWidth = 174;
  static const double _copyWidth = 172;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: ColoredBox(
        color: AppColors.primary100,
        child: Stack(
          children: [
            // Width-constrained to the right ~45% so it never runs under the
            // copy, and stretched to whatever height that copy produces.
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _illustrationWidth.w,
              child: Image.asset(
                AppAssets.appointmentCouple,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
            ConstrainedBox(
              // A floor, not a fixed height: the box scales with `.h` while
              // its text scales with `.sp`, and pinning both overflows as
              // soon as they drift apart.
              constraints: BoxConstraints(minHeight: height.h),
              child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base.w,
                vertical: AppSpacing.sm.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.needCare.tr,
                    style: AppTextStyles.titleLarge.rc(AppColors.authInk),
                  ),
                  AppSpacing.gapV(AppSpacing.xs2),
                  SizedBox(
                    width: _copyWidth.w,
                    child: Text(
                      AppStrings.needCareBody.tr,
                      style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
                    ),
                  ),
                  AppSpacing.gapV(AppSpacing.xs),
                  _BookButton(onTap: onBook),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs.h + 2,
          ),
          child: Text(
            AppStrings.bookAppointmentCta.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.actionLabel),
          ),
        ),
      ),
    );
  }
}
