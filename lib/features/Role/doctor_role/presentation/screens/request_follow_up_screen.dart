import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_top_bar.dart';

/// Asking the patient back in: one line and the button that sends it.
class RequestFollowUpScreen extends StatelessWidget {
  const RequestFollowUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.requestFollowUpTitle.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.followUpReason.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppButton(
            label: AppStrings.requestFollowUp.tr,
            radius: AppRadius.xl,
            icon: Icon(
              Icons.call_outlined,
              size: AppSizes.xl2.w,
              color: AppColors.actionLabel,
            ),
            onPressed: _request,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  /// Back to Results to Review; `isFirst` keeps a predicate that never
  /// matches from emptying the stack.
  void _request() {
    AppSnackbar.success(AppStrings.followUpRequested.tr);
    Get.until(
      (route) =>
          route.settings.name == AppRoutes.doctorResultsToReview ||
          route.isFirst,
    );
  }
}
