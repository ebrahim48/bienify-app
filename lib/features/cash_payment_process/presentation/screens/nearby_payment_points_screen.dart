import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/cash_payment_controller.dart';
import '../controllers/payment_points_controller.dart';
import '../widgets/featured_payment_point_card.dart';
import '../widgets/map_list_toggle.dart';
import '../widgets/payment_point_tile.dart';
import '../widgets/payment_points_map.dart';

/// Step 2: where the code can be paid.
///
/// Map and List are the same data in two presentations; the List pane simply
/// drops the map and the featured card.
class NearbyPaymentPointsScreen extends GetView<PaymentPointsController> {
  const NearbyPaymentPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cashPayment = Get.find<CashPaymentController>();

    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.nearbyPaymentPoints.tr),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.xs),
            MapListToggle(
              isMapSelected: controller.isMap,
              onMap: controller.showMap,
              onList: controller.showList,
            ),
            AppSpacing.gapV(AppSpacing.base),

            if (controller.isMap) ...[
              PaymentPointsMap(
                points: controller.points.toList(),
                selectedId: controller.selectedId.value,
                onSelected: controller.select,
              ),
              AppSpacing.gapV(AppSpacing.base),
              if (controller.featured != null)
                FeaturedPaymentPointCard(
                  point: controller.featured!,
                  onDirections: () => controller.select(controller.featured!),
                ),
              AppSpacing.gapV(AppSpacing.md),
              Text(
                AppStrings.allNearby.tr,
                style: AppTextStyles.labelLarge
                    .rc(AppColors.gray400)
                    .copyWith(letterSpacing: 1.2),
              ),
              AppSpacing.gapV(AppSpacing.xs),
            ],

            for (final point in controller.points) ...[
              PaymentPointTile(
                point: point,
                isSelected: controller.isSelected(point),
                onTap: () => controller.select(point),
                onGo: () => controller.select(point),
              ),
              AppSpacing.gapV(AppSpacing.xs),
            ],

            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.foundALocation.tr,
              trailingIcon: Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.actionLabel,
              ),
              onPressed: cashPayment.confirmLocationChosen,
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
