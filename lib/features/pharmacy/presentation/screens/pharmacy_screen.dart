import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/app_tag.dart';
import '../../domain/entities/medicine.dart';
import '../controllers/pharmacy_controller.dart';

/// Pharmacy tab: browse and add medicines to the cart.
class PharmacyScreen extends GetView<PharmacyController> {
  const PharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xl),
          Text(
            AppStrings.pharmacyTitle.tr,
            style: AppTextStyles.titleLarge.rc(AppColors.black),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            AppStrings.pharmacySubtitle.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Both observables are read here rather than inside
              // `itemBuilder`, which runs lazily outside the `Obx` scope —
              // otherwise adding to the cart would never repaint the row.
              final medicines = controller.medicines.toList();
              final cart = controller.cart.toSet();

              return ListView.separated(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
                itemCount: medicines.length,
                separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.sm),
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  return _MedicineCard(
                    medicine: medicine,
                    isInCart: cart.contains(medicine.id),
                    onAdd: () => controller.addToCart(medicine),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({
    required this.medicine,
    required this.isInCart,
    required this.onAdd,
  });

  final Medicine medicine;
  final bool isInCart;
  final VoidCallback onAdd;

  static const double _badge = 48;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: const BoxDecoration(
              color: AppColors.accentSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(
              AppIcons.pharmacy,
              size: AppSizes.xl2,
              color: AppColors.primary600,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.rc(AppColors.authInk),
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  medicine.dosage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.rc(AppColors.textSecondary),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Text(
                      medicine.priceLabel,
                      style: AppTextStyles.labelLarge.rc(
                        AppColors.primary600,
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    AppTag(
                      medicine.isInStock
                          ? AppStrings.inStock.tr
                          : AppStrings.outOfStock.tr,
                      tone: medicine.isInStock
                          ? AppTagTone.success
                          : AppTagTone.pending,
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          _AddButton(
            isInCart: isInCart,
            isEnabled: medicine.isInStock,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.isInCart,
    required this.isEnabled,
    required this.onTap,
  });

  final bool isInCart;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = !isEnabled
        ? AppColors.gray100
        : isInCart
        ? AppColors.success
        : AppColors.actionFill;

    return Material(
      color: background,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled && !isInCart ? onTap : null,
        child: Container(
          height: AppSizes.xl3.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          alignment: Alignment.center,
          child: isInCart
              ? Icon(
                  Icons.check_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.white,
                )
              : Text(
                  AppStrings.addToCart.tr,
                  style: AppTextStyles.bodySmall.rc(
                    isEnabled ? AppColors.actionLabel : AppColors.gray400,
                  ),
                ),
        ),
      ),
    );
  }
}
