import 'package:flutter/material.dart';
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
    return AppScaffold(
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
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() {
            final rows = controller.visible;
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
    );
  }
}
