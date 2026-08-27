import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/pharmacy.dart';
import '../controllers/order_tracking_controller.dart';
import '../controllers/pharmacy_cart_controller.dart';

/// The placed order: current stage, delivery estimate and the full timeline.
class OrderStatusScreen extends GetView<OrderTrackingController> {
  const OrderStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<PharmacyCartController>();

    return AppScaffold(
      // The stage is read here so the `Obx` tracks it; the panel and timeline
      // receive plain values.
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.md),
            _StagePanel(
              progress: controller.progress,
              currentIndex: controller.currentIndex,
              // The heading names the stage the order is actually at. It was
              // pinned to "Being Prepared", so an order still awaiting payment
              // announced a pharmacist packing it.
              title: controller.currentStep.title,
              subtitle: controller.currentStep.subtitle,
              storeName: cart.store.value?.name ?? '',
              itemCount: cart.itemCount,
            ),
            AppSpacing.gapV(AppSpacing.base),
            AppSpacing.gapV(AppSpacing.base),
            _Timeline(
              steps: controller.steps,
              completedCount: controller.currentIndex - 1,
            ),
            AppSpacing.gapV(AppSpacing.base),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: AppStrings.backToHome.tr,
                    variant: AppButtonVariant.neutral,
                    radius: AppRadius.lg,
                    onPressed: controller.backToHome,
                  ),
                ),
                AppSpacing.gapH(AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: AppStrings.trackNow.tr,
                    radius: AppRadius.lg,
                    onPressed: controller.trackNow,
                  ),
                ),
              ],
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _StagePanel extends StatelessWidget {
  const _StagePanel({
    required this.progress,
    required this.currentIndex,
    required this.title,
    required this.subtitle,
    required this.storeName,
    required this.itemCount,
  });

  final double progress;
  final int currentIndex;
  final String title;
  final String subtitle;
  final String storeName;
  final int itemCount;

  static const double _badge = 64;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary100,
        borderRadius: AppRadius.rXl2,
      ),
      child: Column(
        children: [
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: BoxDecoration(
              color: AppColors.gray900.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.inventory_2_outlined,
              size: AppSizes.xl3.w,
              color: AppColors.gray900,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.rc(AppColors.black),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            // The packing line only makes sense while it is being packed;
            // every other stage says what that stage means.
            currentIndex == 3
                ? AppStrings.beingPreparedBody.trParams({
                    'store': storeName,
                    'count': '$itemCount',
                  })
                : subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
          AppSpacing.gapV(AppSpacing.base),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppSizes.sm.h,
              backgroundColor: AppColors.gray200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.gray900,
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            AppStrings.stepOf.trParams({
              'step': '$currentIndex',
              'total': '${OrderTrackingController.progressSteps}',
            }),
            style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

/// An "Estimated Delivery — 10:30 – 11:00 AM, 25 min" card used to sit above
/// the timeline, both figures from constants. Nothing estimates a delivery:
/// there is no routing engine behind this screen and no distance is measured,
/// so every order was quoted the same window whatever it was doing. The
/// timeline below says where the order actually is, which is true.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps, required this.completedCount});

  final List<OrderStep> steps;

  /// How many leading stages are finished; the next one is the current stage.
  final int completedCount;

  static const double _dot = 24;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.orderProgress.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.black),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          for (var index = 0; index < steps.length; index++)
            _Step(
              step: steps[index],
              isComplete: index < completedCount,
              isCurrent: index == completedCount,
              isLast: index == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.step,
    required this.isComplete,
    required this.isCurrent,
    required this.isLast,
  });

  final OrderStep step;
  final bool isComplete;
  final bool isCurrent;
  final bool isLast;

  bool get _isActive => isComplete || isCurrent;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _Marker(isComplete: isComplete, isCurrent: isCurrent),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: AppSizes.borderWidth,
                    color: isComplete
                        ? AppColors.actionFill
                        : AppColors.surfaceBorder,
                  ),
                ),
            ],
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.base.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    step.title,
                    style: AppTextStyles.titleSmall.rc(
                      _isActive ? AppColors.black : AppColors.gray300,
                    ),
                  ),
                  Text(
                    step.subtitle,
                    style: AppTextStyles.bodyMedium.rc(
                      _isActive ? AppColors.gray400 : AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.isComplete, required this.isCurrent});

  final bool isComplete;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return Container(
        width: _Timeline._dot.w,
        height: _Timeline._dot.w,
        decoration: const BoxDecoration(
          color: AppColors.actionFill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.check_rounded,
          size: AppSizes.lg.w,
          color: AppColors.white,
        ),
      );
    }

    if (isCurrent) {
      return Container(
        width: _Timeline._dot.w,
        height: _Timeline._dot.w,
        decoration: BoxDecoration(
          color: AppColors.gray900,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 4),
        ),
      );
    }

    return Container(
      width: _Timeline._dot.w,
      height: _Timeline._dot.w,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        shape: BoxShape.circle,
      ),
    );
  }
}
