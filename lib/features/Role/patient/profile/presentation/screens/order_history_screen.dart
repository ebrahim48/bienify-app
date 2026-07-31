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
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/profile.dart';
import '../controllers/account_controller.dart';

/// Past pharmacy orders, filtered by state.
class OrderHistoryScreen extends GetView<AccountController> {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.myOrderHistory.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // The active filter is read here so the chips repaint.
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in OrderFilter.values)
                  controller.filterLabel(value),
              ],
              selectedIndex: OrderFilter.values.indexOf(
                controller.filter.value,
              ),
              onSelected: (index) =>
                  controller.selectFilter(OrderFilter.values[index]),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(() {
            final orders = controller.visibleOrders;
            if (orders.isEmpty) {
              return AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: AppStrings.noOrdersYet.tr,
                body: AppStrings.noOrdersYetBody.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final order in orders) ...[
                  _OrderRow(
                    order: order,
                    summary: AppStrings.orderSummaryLine.trParams({
                      'reference': order.reference,
                      'date': controller.shortDateLabel(order.placedOn),
                      'count': '${order.itemCount}',
                    }),
                    stateLabel: controller.stateLabel(order.state),
                    onTap: () => controller.openOrder(order),
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

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.summary,
    required this.stateLabel,
    required this.onTap,
  });

  final OrderHistoryEntry order;
  final String summary;
  final String stateLabel;
  final VoidCallback onTap;

  static const double _disc = 40;

  (Color, Color) get _pill => switch (order.state) {
    OrderState.delivered => (
      AppColors.orderDeliveredSurface,
      AppColors.orderDeliveredInk,
    ),
    OrderState.inProgress => (
      AppColors.orderPendingSurface,
      AppColors.orderPendingInk,
    ),
    OrderState.cancelled => (
      AppColors.orderCancelledSurface,
      AppColors.orderCancelledInk,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (surface, ink) = _pill;

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
              color: AppColors.accentSurface,
              borderRadius: AppRadius.rLg,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.inventory_2_outlined,
              size: AppSizes.xl.w,
              color: AppColors.actionFill,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xs.w,
              vertical: AppSpacing.xxs.h + 1,
            ),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.rFull,
            ),
            child: Text(stateLabel, style: AppTextStyles.labelLarge.rc(ink)),
          ),
        ],
      ),
    );
  }
}
