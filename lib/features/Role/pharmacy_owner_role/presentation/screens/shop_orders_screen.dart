import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../controllers/shop_orders_controller.dart';
import '../widgets/shop_widgets.dart';

/// The order book, one state at a time.
class ShopOrdersScreen extends GetView<ShopOrdersController> {
  const ShopOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The controller is put once by the shell and lives as long as it, so the
    // book is only as fresh as its one `load()` — pulling is how an owner
    // sees an order placed since.
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary800,
      backgroundColor: AppColors.surface,
      child: AppScaffold(
        refreshable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenTopGap(),
            Text(
              AppStrings.ordersTitle.tr,
              style: AppTextStyles.headlineLarge.rc(AppColors.authInk),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            Obx(
              () => AppPillSelector(
                labels: [
                  for (final value in ShopOrderStatus.values)
                    controller.statusLabel(value),
                ],
                selectedIndex: ShopOrderStatus.values.indexOf(
                  controller.filter.value,
                ),
                onSelected: (index) =>
                    controller.selectFilter(ShopOrderStatus.values[index]),
                // Six states: one sideways row at the smaller size, as the
                // design draws it, rather than three wrapped lines of pills.
                isScrollable: true,
                isCompact: true,
                horizontalPadding: AppSpacing.sm,
              ),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            Obx(() {
              final rows = controller.visible;
              // Only while there is nothing to show: a refresh keeps the list
              // on screen, and the pull indicator is its spinner.
              if (controller.orders.isEmpty) {
                if (controller.isLoading.value) {
                  return Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xl2.h),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }
                // A failed read is not an empty book, and saying "no orders"
                // would tell the owner nobody has ordered.
                final error = controller.error.value;
                if (error != null) {
                  return AppEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: error,
                    actionLabel: AppStrings.retry.tr,
                    onAction: controller.load,
                  );
                }
              }
              if (rows.isEmpty) {
                return AppEmptyState(title: AppStrings.noOrdersHere.tr);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final order in rows) ...[
                    ShopOrderRow(
                      order: order,
                      statusLabel: controller.statusLabel(order.status),
                      onTap: () => controller.openDetails(order),
                    ),
                    AppSpacing.gapV(AppSpacing.xs),
                  ],
                ],
              );
            }),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
