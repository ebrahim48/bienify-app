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
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/pharmacy.dart';
import '../controllers/pharmacy_cart_controller.dart';
import '../widgets/quantity_stepper.dart';

/// Choose which of the prescription's medicines to buy from the selected
/// pharmacy. Lines the store cannot supply are shown greyed and locked.
class SelectMedicinesScreen extends GetView<PharmacyCartController> {
  const SelectMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      topBar: AppTopBar(title: AppStrings.selectMedicines.tr),
      // Values are read here, inside the `Obx`; handing the controller down
      // would leave nothing for it to track.
      bottomBar: Obx(
        () => _CheckoutBar(
          selectedCount: controller.selectedIds.length,
          totalCount: controller.totalCount,
          totalLabel: controller.format(controller.selectionTotal),
          onAddToCart: controller.addSelectionToCart,
        ),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.xs),
            _StoreHeader(store: controller.store.value),
            AppSpacing.gapV(AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    AppStrings.medicinesAvailable.trParams({
                      'available': '${controller.availableCount}',
                      'total': '${controller.totalCount}',
                    }),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.toggleSelectAll,
                  child: Text(
                    (controller.allSelected
                            ? AppStrings.deselectAll
                            : AppStrings.selectAll)
                        .tr,
                    style: AppTextStyles.bodyMedium.rc(AppColors.primary600),
                  ),
                ),
              ],
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Expanded(
              child: controller.isLoadingMedicines.value
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                      itemCount: controller.prescribed.length,
                      separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final medicine = controller.prescribed[index];
                        return _MedicineRow(
                          medicine: medicine,
                          isSelected: controller.isSelected(medicine),
                          onToggle: () => controller.toggle(medicine),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store});

  final PharmacyStore? store;

  static const double _badge = 40;

  @override
  Widget build(BuildContext context) {
    final name = store?.name ?? '';

    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: const BoxDecoration(
              color: AppColors.actionFill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              store?.initial ?? '?',
              style: AppTextStyles.titleSmall.rc(AppColors.white),
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.authInk),
                ),
                Text(
                  store?.address ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: Get.back<void>,
            child: Text(
              AppStrings.change.tr,
              style: AppTextStyles.bodyLarge.rc(AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({
    required this.medicine,
    required this.isSelected,
    required this.onToggle,
  });

  final Medicine medicine;
  final bool isSelected;
  final VoidCallback onToggle;

  static const double _box = 26;

  @override
  Widget build(BuildContext context) {
    final available = medicine.isAvailable;
    final ink = available ? AppColors.authInk : AppColors.gray300;

    return AppCard(
      onTap: available ? onToggle : null,
      hasShadow: false,
      color: available ? AppColors.surface : AppColors.chatFieldFill,
      borderColor: isSelected && available
          ? AppColors.primary600
          : AppColors.surfaceBorder,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _box.w,
            height: _box.w,
            decoration: BoxDecoration(
              color: isSelected && available
                  ? AppColors.actionFill
                  : AppColors.surface,
              borderRadius: AppRadius.rMd,
              border: Border.all(
                color: isSelected && available
                    ? AppColors.actionFill
                    : AppColors.gray200,
                width: AppSizes.borderWidth,
              ),
            ),
            child: isSelected && available
                ? Icon(
                    Icons.check_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.white,
                  )
                : null,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        medicine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(ink),
                      ),
                    ),
                    if (!available) ...[
                      AppSpacing.gapH(AppSpacing.xs),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs.w,
                          vertical: AppSpacing.xxs.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error50,
                          borderRadius: AppRadius.rFull,
                        ),
                        child: Text(
                          AppStrings.notAvailable.tr,
                          style: AppTextStyles.labelSmall.rc(
                            AppColors.error500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  medicine.detailLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
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
                medicine.priceLabel,
                style: AppTextStyles.titleSmall.rc(
                  available ? AppColors.gray900 : AppColors.gray400,
                ),
              ),
              if (available) ...[
                AppSpacing.gapV(AppSpacing.xs2),
                QuantityStepper(
                  quantity: 1,
                  onIncrement: () {},
                  onDecrement: () {},
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Total and the Add to Cart action, pinned above the safe area.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.selectedCount,
    required this.totalCount,
    required this.totalLabel,
    required this.onAddToCart,
  });

  final int selectedCount;
  final int totalCount;
  final String totalLabel;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.selectedCount.trParams({
                'selected': '$selectedCount',
                'total': '$totalCount',
              }),
              style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
            ),
            Text(
              totalLabel,
              style: AppTextStyles.titleLarge.rc(AppColors.authInk),
            ),
          ],
        ),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(
          child: Material(
            color: AppColors.actionFill,
            borderRadius: AppRadius.rLg,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAddToCart,
              child: Container(
                height: AppSizes.controlHeight.h,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: AppSizes.xl.w,
                      color: AppColors.actionLabel,
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    Text(
                      AppStrings.addToCart.tr,
                      style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
