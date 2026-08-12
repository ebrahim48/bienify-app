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
import '../../../../../core/widgets/app_empty_state.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../controllers/shop_notifications_controller.dart';

/// The shop's feed, reached from the dashboard's bell.
class ShopNotificationsScreen extends GetView<ShopNotificationsController> {
  const ShopNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Text(
            AppStrings.notifications.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // Read here so the list repaints; the cards get plain values.
          Obx(() {
            final items = controller.notifications.toList();
            if (items.isEmpty) {
              return AppEmptyState(
                icon: Icons.notifications_none_rounded,
                title: AppStrings.noNotificationsYet.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[
                  _NotificationCard(item: item),
                  AppSpacing.gapV(AppSpacing.xs),
                ],
                AppSpacing.gapV(AppSpacing.xs),
                const _SeeMore(),
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final ShopNotification item;

  static const double _tile = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _tile.w,
            height: _tile.w,
            decoration: BoxDecoration(
              color: AppColors.shopScriptsSurface,
              borderRadius: AppRadius.rLg,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.description_outlined,
              size: AppSizes.xl.w,
              color: AppColors.shopScriptsInk,
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    Text(
                      item.ageLabel,
                      style: AppTextStyles.bodySmall.rc(AppColors.gray500),
                    ),
                  ],
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  item.body,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                // Monospaced in the design; Satoshi carries tabular figures,
                // which is what keeps a reference legible without a second
                // font in the bundle.
                Text(
                  item.reference,
                  style: AppTextStyles.bodyMedium
                      .rc(AppColors.link)
                      .copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeeMore extends StatelessWidget {
  const _SeeMore();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppStrings.seeMore.tr,
          style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
        ),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: AppSizes.xl.w,
          color: AppColors.gray600,
        ),
      ],
    );
  }
}
