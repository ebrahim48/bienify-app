import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_profile_controller.dart';
import '../widgets/rider_widgets.dart';

/// What the courier has made: today against the week, the next payout, and
/// every drop behind them.
class RiderEarningsScreen extends GetView<RiderProfileController> {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read inside the closure so the whole page repaints when the figures
    // land; everything below gets plain values.
    return Obx(() => _Body(earnings: controller.earnings.value));
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.earnings});

  final RiderEarnings earnings;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          RiderSectionLabel(AppStrings.overview.tr),
          Text(
            AppStrings.earnings.tr,
            style: AppTextStyles.headlineLarge.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          // No `stretch`: inside a scroll view that asks the Row for an
          // infinite height. The two cards size themselves.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PeriodCard(
                  caption: AppStrings.earningsToday.tr,
                  amount: earnings.todayLabel,
                  count: earnings.todayCount,
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: _PeriodCard(
                  caption: AppStrings.earningsThisWeek.tr,
                  amount: earnings.weekLabel,
                  count: earnings.weekCount,
                  isHighlighted: true,
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _PayoutCard(earnings: earnings),
          AppSpacing.gapV(AppSpacing.base),
          RiderSectionLabel(AppStrings.history.tr),
          for (final record in earnings.history) ...[
            DeliveryRecordRow(record: record, showOrderCode: true),
            AppSpacing.gapV(AppSpacing.xs),
          ],
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Today is a white card, the week is the filled one — the design inverts the
/// period it wants read first.
class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.caption,
    required this.amount,
    required this.count,
    this.isHighlighted = false,
  });

  final String caption;
  final String amount;
  final int count;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final captionInk = isHighlighted ? AppColors.primary200 : AppColors.gray500;
    final valueInk = isHighlighted ? AppColors.white : AppColors.gray900;

    return AppCard(
      hasShadow: false,
      color: isHighlighted ? AppColors.actionFill : AppColors.surface,
      borderColor: isHighlighted
          ? AppColors.actionFill
          : AppColors.surfaceBorder,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(caption, style: AppTextStyles.bodyMedium.rc(captionInk)),
          AppSpacing.gapV(AppSpacing.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: AppTextStyles.headlineMedium.rc(valueInk),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.deliveriesCount.trParams({'count': '$count'}),
            style: AppTextStyles.bodyMedium.rc(captionInk),
          ),
        ],
      ),
    );
  }
}

/// How close the week is to the payout threshold.
class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.earnings});

  final RiderEarnings earnings;

  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.nextPayout.tr,
                  style: AppTextStyles.titleMedium.rc(AppColors.gray900),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs.w,
                  vertical: AppSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.shopStateSurface,
                  borderRadius: AppRadius.rMd,
                ),
                child: Text(
                  earnings.payoutDay,
                  style: AppTextStyles.labelMedium.rw(
                    AppColors.shopStateInk,
                    FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.rFull,
            child: LinearProgressIndicator(
              value: earnings.payoutProgress,
              minHeight: _barHeight.h,
              backgroundColor: AppColors.uploadSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.actionFill,
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.accumulated.trParams({
                    'amount': earnings.weekLabel,
                  }),
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
              ),
              Text(
                AppStrings.minimumPayout.trParams({
                  'amount': earnings.minimumLabel,
                }),
                style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
              ),
              if (earnings.hasClearedMinimum) ...[
                AppSpacing.gapH(AppSpacing.xs2),
                Icon(
                  Icons.check_rounded,
                  size: AppSizes.base.w,
                  color: AppColors.feeInk,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
