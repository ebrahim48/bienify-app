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
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/earnings_controller.dart';
import '../widgets/request_payout_dialog.dart';

/// Earning Withdraw: the balance, what it came from, and the payout request.
class EarningWithdrawScreen extends GetView<EarningsController> {
  const EarningWithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.earningWithdraw.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => _BalanceCard(
              amount: controller.availableBalance.value,
              onRequest: () => RequestPayoutDialog.show(context),
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _StatCard(
                    icon: Icons.trending_up_rounded,
                    ink: AppColors.payoutInk,
                    label: AppStrings.totalEarned.tr,
                    value: controller.totalEarned.value,
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Obx(
                  () => _StatCard(
                    icon: Icons.download_rounded,
                    ink: AppColors.paidOutInk,
                    label: AppStrings.paidOut.tr,
                    value: controller.paidOut.value,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.recentConsultations.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // Read here so the list repaints; the rows get plain values.
          Obx(() {
            final earnings = controller.earnings.toList();
            if (earnings.isEmpty) {
              return AppEmptyState(
                icon: Icons.payments_outlined,
                title: AppStrings.noTransactionsYet.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final earning in earnings) ...[
                  _EarningRow(
                    earning: earning,
                    dateLabel: controller.dateLabel(earning.earnedOn),
                    statusLabel: controller.stateLabel(earning.state),
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Navy card running a corner-to-corner gradient, with the payout action on
/// a white pill inside it.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.amount, required this.onRequest});

  final String amount;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rXl,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.earningsGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  AppStrings.availableBalance2.tr,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.white,
                    FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.attach_money_rounded,
                size: AppSizes.xl3.w,
                color: AppColors.white,
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: AppTextStyles.headlineMedium.rc(AppColors.white),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Material(
            color: AppColors.white,
            borderRadius: AppRadius.rFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onRequest,
              child: Container(
                height: AppSizes.controlHeight.h,
                alignment: Alignment.center,
                child: Text(
                  AppStrings.requestPayout.tr,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.ink,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color ink;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.symmetric(vertical: AppSpacing.base.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.xl2.w, color: ink),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.titleLarge.rw(
                AppColors.actionFill,
                FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({
    required this.earning,
    required this.dateLabel,
    required this.statusLabel,
  });

  final ConsultationEarning earning;
  final String dateLabel;
  final String statusLabel;

  static const double _disc = 44;

  bool get _isPending => earning.state == PayoutState.pending;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _disc.w,
            height: _disc.w,
            decoration: BoxDecoration(
              color: AppColors.payoutSurface,
              borderRadius: AppRadius.rLg,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.attach_money_rounded,
              size: AppSizes.xl2.w,
              color: AppColors.payoutInk,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  earning.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray500,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Expanded(
                      child: Text(
                        dateLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                earning.amountLabel,
                style: AppTextStyles.titleSmall.rc(AppColors.completedInk),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs.w,
                  vertical: AppSpacing.xxs.h + 1,
                ),
                decoration: BoxDecoration(
                  // Pending is a soft amber tag; a settled payout is stated
                  // firmly in the action colour.
                  color: _isPending
                      ? AppColors.tagWarningSurface
                      : AppColors.actionFill,
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.bodyMedium.rc(
                    _isPending
                        ? AppColors.tagWarningInk
                        : AppColors.actionLabel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
