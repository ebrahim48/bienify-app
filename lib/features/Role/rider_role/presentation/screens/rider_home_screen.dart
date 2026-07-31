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
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_home_controller.dart';
import '../widgets/rider_widgets.dart';

/// The courier's dashboard: what today paid, whether they are online, two
/// quick actions and the last few drops.
class RiderHomeScreen extends GetView<RiderHomeController> {
  const RiderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.sm),
          RiderMasthead(
            name: RiderData.dashboardName,
            location: RiderData.rider.location,
            onNotifications: controller.openNotifications,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() => _EarningsCard(rider: controller.rider.value)),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.quickActions.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _QuickAction(
                  emoji: '📦',
                  label: AppStrings.viewOrders.tr,
                  note: AppStrings.ordersAvailable.trParams({
                    'count': '${controller.openRequests}',
                  }),
                  onTap: controller.openOrders,
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: _QuickAction(
                  emoji: '💰',
                  label: AppStrings.earnings.tr,
                  onTap: controller.openEarnings,
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.base),
          RiderSectionLabel(AppStrings.recentDeliveries.tr),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final record in controller.recent.toList()) ...[
                  DeliveryRecordRow(record: record),
                  AppSpacing.gapV(AppSpacing.xs),
                ],
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// The navy card: today's takings and count, then the availability line.
class _EarningsCard extends GetView<RiderHomeController> {
  const _EarningsCard({required this.rider});

  final Rider rider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  caption: AppStrings.todaysEarnings.tr,
                  value: rider.earningsLabel,
                ),
              ),
              _Figure(
                caption: AppStrings.deliveries.tr,
                value: '${rider.deliveriesToday}',
                alignEnd: true,
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.white.withValues(alpha: 0.24),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Row(
            children: [
              // Tapping the line goes on and off duty; it is the only
              // control on the card.
              Expanded(
                child: InkWell(
                  onTap: controller.toggleOnline,
                  child: Row(
                    children: [
                      Container(
                        width: AppSizes.sm.w,
                        height: AppSizes.sm.w,
                        decoration: BoxDecoration(
                          color: rider.isOnline
                              ? AppColors.onlineDot
                              : AppColors.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      AppSpacing.gapH(AppSpacing.xs),
                      Flexible(
                        child: Text(
                          rider.isOnline
                              ? AppStrings.onlineAcceptingOrders.tr
                              : AppStrings.offlineNotAccepting.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.rc(AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              Icon(
                Icons.star_rounded,
                size: AppSizes.lg.w,
                color: AppColors.star,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                rider.ratingLabel,
                style: AppTextStyles.titleSmall.rc(AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.caption,
    required this.value,
    this.alignEnd = false,
  });

  final String caption;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption, style: AppTextStyles.bodyMedium.rc(AppColors.primary200)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTextStyles.displaySmall.rc(AppColors.white),
          ),
        ),
      ],
    );
  }
}

/// One of the two white tiles under Quick Actions.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.note,
  });

  final String emoji;
  final String label;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: AppTextStyles.headlineSmall),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.rc(AppColors.gray900),
          ),
          if (note != null)
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.rc(AppColors.link),
            ),
        ],
      ),
    );
  }
}
