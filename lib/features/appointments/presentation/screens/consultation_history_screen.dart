import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/app_top_bar.dart';

/// Shown after a consultation ends: confirmation, then where to go next.
class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.consultationHistory.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          const _CompletePanel(),
          AppSpacing.gapV(AppSpacing.lg),
          AppButton(
            label: AppStrings.checkMedicalVault.tr,
            radius: AppRadius.lg,
            onPressed: () => Get.offAllNamed<void>(AppRoutes.home),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppButton(
            label: AppStrings.backToHome.tr,
            variant: AppButtonVariant.outlined,
            radius: AppRadius.lg,
            onPressed: () => Get.offAllNamed<void>(AppRoutes.home),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _CompletePanel extends StatelessWidget {
  const _CompletePanel();

  static const double _badge = 88;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.xl.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.pendingSurface,
        borderRadius: AppRadius.rXl2,
      ),
      child: Column(
        children: [
          const AppSvgIcon(AppIcons.consultationComplete, size: _badge),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.consultationComplete.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            AppStrings.waitingForPrescriptions.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray700),
          ),
        ],
      ),
    );
  }
}
