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
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../controllers/shop_home_controller.dart';
import '../controllers/shop_orders_controller.dart';
import '../widgets/shop_widgets.dart';

/// The shop dashboard: balance, four figures, recent orders and what is
/// running out.
class ShopHomeScreen extends GetView<ShopHomeController> {
  const ShopHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() => _Masthead(shop: controller.shop.value)),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => _BalanceCard(
              label: controller.shop.value.balanceLabel,
              onWithdraw: controller.withdraw,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Stats(controller: controller),
          AppSpacing.gapV(AppSpacing.base),
          _RecentOrders(onSeeAll: controller.openAllOrders),
          AppSpacing.gapV(AppSpacing.base),
          Obx(() => LowStockPanel(alerts: controller.alerts.toList())),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Avatar, shop name over its location, and the bell.
class _Masthead extends GetView<ShopHomeController> {
  const _Masthead({required this.shop});

  final Shop shop;

  static const double _avatar = 40;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The owner's own picture when the server has one; the design's
        // figure on its navy disc when it does not.
        if (shop.photoUrl != null)
          AppAvatar(
            imageUrl: shop.photoUrl,
            name: shop.ownerName,
            size: _avatar,
            fallbackAsset: null,
            backgroundColor: AppColors.authInk,
            foregroundColor: AppColors.white,
          )
        else
          Container(
            width: _avatar.w,
            height: _avatar.w,
            decoration: const BoxDecoration(
              color: AppColors.authInk,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              size: AppSizes.xl2.w,
              color: AppColors.white,
            ),
          ),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.rc(AppColors.authInk),
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: AppSizes.lg.w,
                    color: AppColors.gray600,
                  ),
                  Flexible(
                    child: Text(
                      shop.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.gray600,
                  ),
                ],
              ),
            ],
          ),
        ),
        InkResponse(
          onTap: controller.openNotifications,
          radius: AppSizes.xl2.r,
          child: Icon(
            Icons.notifications_none_rounded,
            size: AppSizes.xl2.w,
            color: AppColors.authInk,
          ),
        ),
      ],
    );
  }
}

/// The navy strip with the balance and the Withdraw pill.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.label, required this.onWithdraw});

  final String label;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rXl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.availableBalance2.tr,
                  style: AppTextStyles.bodyMedium.rc(AppColors.primary200),
                ),
                Text(
                  label,
                  style: AppTextStyles.headlineSmall.rc(AppColors.white),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Material(
            color: AppColors.white,
            borderRadius: AppRadius.rFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onWithdraw,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.base.w,
                  vertical: AppSpacing.xs.h,
                ),
                child: Text(
                  AppStrings.withdraw.tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two rows of two figures.
class _Stats extends StatelessWidget {
  const _Stats({required this.controller});

  final ShopHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final stats = controller.stats.value;
      return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ShopStatCard(
                icon: Icons.inventory_2_outlined,
                surface: AppColors.shopOrdersSurface,
                ink: AppColors.shopOrdersInk,
                value: '${stats.newOrders}',
                label: AppStrings.newOrdersStat.tr,
              ),
            ),
            AppSpacing.gapH(AppSpacing.sm),
            Expanded(
              child: ShopStatCard(
                icon: Icons.description_outlined,
                surface: AppColors.shopScriptsSurface,
                ink: AppColors.shopScriptsInk,
                value: '${stats.newPrescriptions}',
                label: AppStrings.newPrescriptionsStat.tr,
              ),
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ShopStatCard(
                icon: Icons.attach_money_rounded,
                surface: AppColors.shopEarningsSurface,
                ink: AppColors.shopEarningsInk,
                value: stats.todaysEarningsLabel,
                label: AppStrings.todaysEarnings.tr,
              ),
            ),
            AppSpacing.gapH(AppSpacing.sm),
            Expanded(
              child: ShopStatCard(
                icon: Icons.warning_amber_rounded,
                surface: AppColors.shopStockSurface,
                ink: AppColors.shopStockInk,
                value: '${stats.stockAlerts}',
                label: AppStrings.lowStockItems.tr,
              ),
            ),
          ],
        ),
        ],
      );
    });
  }
}

/// The six newest orders, under a heading that links to the tab.
class _RecentOrders extends GetView<ShopOrdersController> {
  const _RecentOrders({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.recentOrders.tr,
                style: AppTextStyles.titleMedium.rc(AppColors.gray900),
              ),
            ),
            InkResponse(
              onTap: onSeeAll,
              radius: AppSizes.xl2.r,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.seeAll.tr,
                    style: AppTextStyles.bodyLarge.rc(AppColors.link),
                  ),
                  AppSpacing.gapH(AppSpacing.xs2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.link,
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final order in controller.recent.toList()) ...[
                ShopOrderRow(
                  order: order,
                  statusLabel: controller.statusLabel(order.status),
                  onTap: () => controller.openDetails(order),
                ),
                AppSpacing.gapV(AppSpacing.xs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
