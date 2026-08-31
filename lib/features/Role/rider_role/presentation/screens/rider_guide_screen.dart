import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_guide_controller.dart';
import '../widgets/rider_widgets.dart';

/// How It Works — the five steps, then the invitation to apply.
class RiderGuideScreen extends GetView<RiderGuideController> {
  const RiderGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = RiderData.guideSteps();

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.sm),
          // The signed-in account, not the design's sample courier — and the
          // account rather than the courier profile, which does not exist for
          // anyone reading this page. No location: an applicant has no
          // courier city yet, and the masthead leaves the line out.
          Obx(
            () => RiderMasthead(
              name: controller.name.value,
              location: '',
              photoUrl: controller.photoUrl.value,
              onNotifications: () =>
                  Get.toNamed<void>(AppRoutes.shopNotifications),
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.riderGuide.tr,
            style: AppTextStyles.labelLarge.rw(
              AppColors.gray500,
              FontWeight.w500,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.howItWorks.tr,
            style: AppTextStyles.displaySmall.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            AppStrings.howItWorksBody.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
          AppSpacing.gapV(AppSpacing.base),
          for (var index = 0; index < steps.length; index++)
            _TimelineRow(
              number: index + 1,
              step: steps[index],
              isLast: index == steps.length - 1,
            ),
          AppSpacing.gapV(AppSpacing.sm),
          const _ApplyPanel(),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// A numbered disc joined to the next by a rule, with the step's card beside
/// it.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.number,
    required this.step,
    required this.isLast,
  });

  final int number;
  final GuideStep step;
  final bool isLast;

  static const double _disc = 34;
  static const double _rule = 2;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: _disc.w,
                height: _disc.w,
                decoration: const BoxDecoration(
                  color: AppColors.stepDiscSurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number.toString().padLeft(2, '0'),
                  style: AppTextStyles.labelLarge.rc(AppColors.stepDiscInk),
                ),
              ),
              // The rule runs from this disc to the next, so the last step
              // does not trail one into empty space.
              if (!isLast)
                Expanded(
                  child: Container(
                    width: _rule.w,
                    color: AppColors.timelineRule,
                  ),
                ),
            ],
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: _StepCard(step: step),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});

  final GuideStep step;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.title,
            style: AppTextStyles.titleMedium.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(step.body, style: AppTextStyles.bodyLarge.rc(AppColors.gray700)),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            step.note,
            style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
          ),
        ],
      ),
    );
  }
}

/// The pale-blue invitation, with the cyclist alongside it.
class _ApplyPanel extends StatelessWidget {
  const _ApplyPanel();

  static const double _artWidth = 150;
  static const double _buttonHeight = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.base.w,
        top: AppSpacing.base.h,
        bottom: AppSpacing.base.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.applyPanel,
        borderRadius: AppRadius.rXl2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.applyRiderTitle.tr,
                  style: AppTextStyles.titleLarge.rc(AppColors.authInk),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  AppStrings.applyRiderBody.tr,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray700),
                ),
                AppSpacing.gapV(AppSpacing.sm),
                AppButton(
                  label: AppStrings.applyNow.tr,
                  expanded: false,
                  // 44, not the 36 of a chip: `AppButton` sets a 16pt label
                  // inside 10pt of padding and clips what does not fit, so a
                  // shorter box cuts the label in half.
                  height: _buttonHeight,
                  radius: AppRadius.lg,
                  onPressed: () => Get.toNamed<void>(AppRoutes.riderApply),
                ),
              ],
            ),
          ),
          Image.asset(
            AppAssets.cycleRider,
            width: _artWidth.w,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
