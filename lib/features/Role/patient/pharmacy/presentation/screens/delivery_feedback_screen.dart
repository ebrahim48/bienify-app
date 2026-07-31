import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../../appointments/presentation/widgets/review_dialog.dart';

/// Shown once the courier marks the order delivered.
///
/// The rating itself reuses the appointments `ReviewDialog`, so both flows
/// collect feedback through the same blurred popup.
class DeliveryFeedbackScreen extends StatelessWidget {
  const DeliveryFeedbackScreen({super.key});

  static const double _photoHeight = 190;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(
        title: AppStrings.feedback.tr,
        // Dismissed rather than popped: the delivery is finished.
        onBack: () => AppNavigator.resetTo(AppRoutes.home),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          AppCard(
            hasShadow: false,
            padding: EdgeInsets.all(AppSpacing.sm.w),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.rLg,
                  child: Image.asset(
                    AppAssets.deliveryFeedback,
                    width: AppSizes.xl5.w,
                    height: AppSizes.xl4.h,
                    fit: BoxFit.cover,
                  ),
                ),
                AppSpacing.gapH(AppSpacing.sm),
                Expanded(
                  child: Text(
                    AppStrings.contactlessDelivered.tr,
                    style: AppTextStyles.titleSmall.rc(AppColors.authInk),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          ClipRRect(
            borderRadius: AppRadius.rXl,
            child: SizedBox(
              height: _photoHeight.h,
              child: Image.asset(
                AppAssets.deliveryFeedback,
                fit: BoxFit.cover,
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.couriersResponsible.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
          AppSpacing.gapV(AppSpacing.xl4),
          AppButton(
            label: AppStrings.writeOrderFeedback.tr,
            radius: AppRadius.lg,
            onPressed: () => _review(context),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AppNavigator.resetTo(AppRoutes.home),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.skipToOrderFeedback.tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.authInk),
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.authInk,
                ),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context) async {
    final stars = await ReviewDialog.show(context);
    if (stars != null) AppNavigator.resetTo(AppRoutes.home);
  }
}
