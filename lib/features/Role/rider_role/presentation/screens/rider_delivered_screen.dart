import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_orders_controller.dart';

/// The receipt: the package has changed hands.
class RiderDeliveredScreen extends StatelessWidget {
  const RiderDeliveredScreen({super.key});

  static const double _hero = 180;

  /// The job the courier just finished.
  ///
  /// Read off the live orders controller rather than through `GetView`: this
  /// page is also reachable with no courier session behind it — a deep link,
  /// or a reload that dropped the controller — and there is nothing to draw
  /// then.
  ///
  /// It used to fall back to the design's sample: a handover to "John Doe" at
  /// "Banani, Dhaka" on order #45892. A courier arriving here without a session
  /// was shown a completed delivery they had never made, with somebody else's
  /// customer on it.
  DeliveryReceipt? get _receipt {
    if (!Get.isRegistered<RiderOrdersController>()) return null;
    return Get.find<RiderOrdersController>().receipt.value;
  }

  @override
  Widget build(BuildContext context) {
    final receipt = _receipt;

    return AppScaffold(
      // The photograph runs edge to edge, so the page owns its own gutters.
      padded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapV(AppSpacing.sm),
                Row(
                  children: [
                    InkResponse(
                      // Closing lands back in the shell rather than on the
                      // map that is now finished with.
                      onTap: () => AppNavigator.resetTo(AppRoutes.riderHome),
                      radius: AppSizes.xl2.r,
                      child: Icon(
                        Icons.close_rounded,
                        size: AppSizes.xl2.w,
                        color: AppColors.gray900,
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.sm),
                    Text(
                      AppStrings.arrived.tr,
                      style: AppTextStyles.titleMedium.rc(AppColors.authInk),
                    ),
                  ],
                ),
                AppSpacing.gapV(AppSpacing.sm),
                const _CompletedBanner(),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          SizedBox(
            height: _hero.h,
            child: Image.asset(AppAssets.deliveredHero, fit: BoxFit.cover),
          ),
          Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapV(AppSpacing.base),
                Text(
                  AppStrings.orderDeliveredTitle.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.rc(AppColors.authInk),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  AppStrings.orderDeliveredBody.tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                ),
                AppSpacing.gapV(AppSpacing.base),
                // Omitted rather than substituted when there is no session
                // behind the page. The confirmation still reads correctly;
                // there is simply no handover to itemise.
                if (receipt != null) ...[
                  _Receipt(receipt: receipt),
                  AppSpacing.gapV(AppSpacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The white strip that says the job is done.
class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  static const double _thumb = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.xs.w),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.rMd,
            child: Image.asset(
              AppAssets.deliveredHero,
              width: _thumb.w,
              height: _thumb.w,
              fit: BoxFit.cover,
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Text(
              AppStrings.deliveryCompleted.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.rc(AppColors.authInk),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dark-green receipt: the order number over three facts.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.receipt});

  final DeliveryReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.base.w),
            color: AppColors.deliveredSurface,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.deliveryCompleted.tr.toUpperCase(),
                        style: AppTextStyles.labelLarge.rw(
                          AppColors.deliveredCaption,
                          FontWeight.w500,
                        ),
                      ),
                      AppSpacing.gapV(AppSpacing.xs),
                      Text(
                        AppStrings.orderIdLabel.tr,
                        style: AppTextStyles.bodyMedium.rc(
                          AppColors.deliveredCaption,
                        ),
                      ),
                      Text(
                        receipt.orderId,
                        style: AppTextStyles.headlineSmall.rc(AppColors.white),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: AppSizes.xl2.w,
                  color: AppColors.deliveredCaption,
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.all(AppSpacing.base.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Fact(
                  icon: Icons.inventory_2_outlined,
                  caption: AppStrings.deliveredTo.tr,
                  value: receipt.customerName,
                ),
                _Divider(),
                _Fact(
                  icon: Icons.location_on_outlined,
                  caption: AppStrings.locationLabel.tr.toUpperCase(),
                  value: receipt.location,
                ),
                _Divider(),
                _Fact(
                  icon: Icons.schedule_rounded,
                  caption: AppStrings.deliveryTime.tr,
                  value: receipt.timeLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: AppSpacing.base.h,
    thickness: AppSizes.borderWidth,
    color: AppColors.chipSurface,
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.caption, required this.value});

  final IconData icon;
  final String caption;
  final String value;

  static const double _disc = 36;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _disc.w,
          height: _disc.w,
          decoration: BoxDecoration(
            color: AppColors.feeSurface,
            borderRadius: AppRadius.rLg,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: AppSizes.lg.w, color: AppColors.feeInk),
        ),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                caption,
                style: AppTextStyles.labelMedium.rw(
                  AppColors.gray500,
                  FontWeight.w500,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
