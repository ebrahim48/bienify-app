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
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../controllers/shop_orders_controller.dart';
import '../widgets/shop_widgets.dart';

/// One order: who it is for, what they sent, what it contains, and the two
/// answers the shop can give.
class ShopOrderDetailsScreen extends GetView<ShopOrdersController> {
  const ShopOrderDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.orderDetailsTitle.tr),
      child: Obx(() {
        final order = controller.selected.value;
        if (order == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CodeBanner(
              order: order,
              statusLabel: controller.statusLabel(order.status),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _CustomerCard(order: order),
            AppSpacing.gapV(AppSpacing.sm),
            if (order.prescriptionFile != null) ...[
              _PrescriptionCard(
                fileName: order.prescriptionFile!,
                onView: controller.viewPrescription,
              ),
              AppSpacing.gapV(AppSpacing.sm),
            ],
            _MedicineList(order: order),
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.acceptOrder.tr,
              radius: AppRadius.xl,
              onPressed: controller.accept,
            ),
            AppSpacing.gapV(AppSpacing.xs),
            _DeclineButton(onTap: controller.decline),
            AppSpacing.gapV(AppSpacing.md),
          ],
        );
      }),
    );
  }
}

/// The navy strip carrying the order number and its state.
class _CodeBanner extends StatelessWidget {
  const _CodeBanner({required this.order, required this.statusLabel});

  final ShopOrder order;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
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
                  order.code,
                  style: AppTextStyles.titleLarge.rc(AppColors.white),
                ),
                Text(
                  '${order.placedAtLabel} • ${AppStrings.today.tr}',
                  style: AppTextStyles.bodyMedium.rc(AppColors.primary200),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          // Lighter than the strip rather than tinted like the list's pills —
          // on navy, the list colours would disappear.
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs2.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.22),
              borderRadius: AppRadius.rFull,
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.labelLarge.rc(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final ShopOrder order;

  static const double _disc = 48;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShopSectionLabel(AppStrings.patientInfo.tr),
          Row(
            children: [
              AppAvatar(
                imageUrl: order.customerPhotoUrl,
                name: order.customerName,
                size: _disc,
                fallbackAsset: null,
                backgroundColor: AppColors.customerInitials,
                foregroundColor: AppColors.white,
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.rc(AppColors.gray900),
                    ),
                    _IconLine(icon: Icons.call_outlined, label: order.phone),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.chipSurface,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _IconLine(
            icon: Icons.location_on_outlined,
            label: order.address,
            isLarge: true,
          ),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({
    required this.icon,
    required this.label,
    this.isLarge = false,
  });

  final IconData icon;
  final String label;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.lg.w, color: AppColors.gray500),
        AppSpacing.gapH(AppSpacing.xs2),
        Expanded(
          child: Text(
            label,
            style:
                (isLarge ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium)
                    .rc(AppColors.gray600),
          ),
        ),
      ],
    );
  }
}

/// The attached file, with the button that opens it.
class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({required this.fileName, required this.onView});

  final String fileName;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShopSectionLabel(AppStrings.prescriptionSection.tr),
          Container(
            padding: EdgeInsets.all(AppSpacing.xs.w),
            decoration: BoxDecoration(
              color: AppColors.tagInfoSurface,
              borderRadius: AppRadius.rLg,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: AppSizes.xl.w,
                  color: AppColors.actionFill,
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                  ),
                ),
                AppSpacing.gapH(AppSpacing.xs),
                // Its own pill rather than `AppButton`: at the design's 32pt
                // the shared button's 16pt label and fixed padding clip.
                _ViewPill(onTap: onView),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The small filled pill that opens the attachment.
class _ViewPill extends StatelessWidget {
  const _ViewPill({required this.onTap});

  final VoidCallback onTap;

  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: AppSizes.lg.w,
                color: AppColors.actionLabel,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                AppStrings.view.tr,
                style: AppTextStyles.labelLarge.rc(AppColors.actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What was ordered, and what it comes to.
class _MedicineList extends StatelessWidget {
  const _MedicineList({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShopSectionLabel(AppStrings.medicineList.tr),
          for (final line in order.lines) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        line.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                      ),
                      Text(
                        line.quantityLabel,
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Text(
                  line.totalLabel,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
              ],
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: AppColors.chipSurface,
            ),
            AppSpacing.gapV(AppSpacing.xs),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.total.tr,
                  style: AppTextStyles.titleMedium.rc(AppColors.gray900),
                ),
              ),
              Text(
                order.totalLabel,
                style: AppTextStyles.titleLarge.rc(AppColors.actionFill),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The refusal: a pale-red bar rather than a second filled button.
class _DeclineButton extends StatelessWidget {
  const _DeclineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.outOfStockSurface,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.controlHeight.h,
          alignment: Alignment.center,
          child: Text(
            AppStrings.declineOrder.tr,
            style: AppTextStyles.buttonLarge.rc(AppColors.outOfStockInk),
          ),
        ),
      ),
    );
  }
}
