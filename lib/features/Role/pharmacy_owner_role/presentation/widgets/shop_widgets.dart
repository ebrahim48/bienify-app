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
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../domain/entities/pharmacy_shop.dart';

/// The pieces the shop's screens are assembled from.

/// One of the dashboard's four figures: a tinted disc, the number, the label.
class ShopStatCard extends StatelessWidget {
  const ShopStatCard({
    super.key,
    required this.icon,
    required this.surface,
    required this.ink,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color surface;
  final Color ink;
  final String value;
  final String label;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _disc.w,
            height: _disc.w,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.rXl,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: AppSizes.xl.w, color: ink),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.headlineSmall.rc(ink)),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
          ),
        ],
      ),
    );
  }
}

/// An order in a list: initials disc, customer, code and time, then the money
/// and its state.
class ShopOrderRow extends StatelessWidget {
  const ShopOrderRow({
    super.key,
    required this.order,
    required this.statusLabel,
    required this.onTap,
  });

  final ShopOrder order;
  final String statusLabel;
  final VoidCallback onTap;

  static const double _disc = 40;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Row(
        children: [
          // The customer's photo — every account has one — with the tinted
          // initials disc only as the failure fallback.
          AppAvatar(
            imageUrl: order.customerPhotoUrl,
            name: order.customerName,
            size: _disc,
            fallbackAsset: null,
            backgroundColor: AppColors.customerInitials,
            foregroundColor: AppColors.white,
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  order.summaryLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
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
                order.totalLabel,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              ShopStatePill(status: order.status, label: statusLabel),
            ],
          ),
        ],
      ),
    );
  }
}

/// The pill that says where an order stands.
class ShopStatePill extends StatelessWidget {
  const ShopStatePill({super.key, required this.status, required this.label});

  final ShopOrderStatus status;
  final String label;

  (Color, Color) get _tones => switch (status) {
    ShopOrderStatus.declined => (
      AppColors.shopDeclinedSurface,
      AppColors.shopDeclinedInk,
    ),
    ShopOrderStatus.preparing => (
      AppColors.shopPreparingSurface,
      AppColors.shopPreparingInk,
    ),
    ShopOrderStatus.delivered => (
      AppColors.shopDeliveredSurface,
      AppColors.shopDeliveredInk,
    ),
    // New, Accepted and Out of Delivery share the blue; the design only
    // separates the states that end an order.
    _ => (AppColors.shopStateSurface, AppColors.shopStateInk),
  };

  @override
  Widget build(BuildContext context) {
    final (surface, ink) = _tones;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(color: surface, borderRadius: AppRadius.rMd),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.labelMedium.rw(ink, FontWeight.w500),
      ),
    );
  }
}

/// The amber panel listing what is running out.
class LowStockPanel extends StatelessWidget {
  const LowStockPanel({super.key, required this.alerts});

  final List<StockAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.alertSurface,
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: AppColors.alertBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: AppSizes.xl.w,
                color: AppColors.shopStockInk,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                AppStrings.lowStockAlerts.tr,
                style: AppTextStyles.titleSmall.rc(AppColors.shopStockInk),
              ),
            ],
          ),
          for (final alert in alerts) ...[
            AppSpacing.gapV(AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    alert.medicineName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(AppColors.shopStockInk),
                  ),
                ),
                AppSpacing.gapH(AppSpacing.xs),
                _RemainingPill(alert: alert),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RemainingPill extends StatelessWidget {
  const _RemainingPill({required this.alert});

  final StockAlert alert;

  @override
  Widget build(BuildContext context) {
    final isOut = alert.isOut;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: isOut ? AppColors.outOfStockSurface : AppColors.stockLeftSurface,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        isOut
            ? AppStrings.outOfStock.tr
            : AppStrings.itemsLeft.trParams({'count': '${alert.remaining}'}),
        style: AppTextStyles.labelMedium.rw(
          isOut ? AppColors.outOfStockInk : AppColors.stockLeftInk,
          FontWeight.w500,
        ),
      ),
    );
  }
}

/// A small capitalised caption above a block on the order detail.
class ShopSectionLabel extends StatelessWidget {
  const ShopSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.rw(AppColors.gray500, FontWeight.w500),
      ),
    );
  }
}
