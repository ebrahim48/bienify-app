import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/pharmacy.dart';
import '../../../booking/domain/entities/payment_method.dart';
import '../../../booking/presentation/widgets/payment_method_tile.dart';
import '../controllers/pharmacy_cart_controller.dart';
import '../widgets/location_dialog.dart';

/// Choose how to pay for the medicines and where they go.
///
/// Reuses the booking flow's `PaymentMethodTile` rather than a second
/// method list.
class PharmacyPaymentScreen extends GetView<PharmacyCartController> {
  const PharmacyPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.payment.tr),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            _OrderHeader(controller: controller),
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.choosePaymentMethod.tr,
              style: AppTextStyles.titleMedium.rc(AppColors.gray900),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            for (var index = 0; index < PaymentMethod.values.length; index++)
              ...[
                PaymentMethodTile(
                  method: PaymentMethod.values[index],
                  isSelected: controller.selectedMethodIndex.value == index,
                  onTap: () => controller.selectMethod(index),
                ),
                AppSpacing.gapV(AppSpacing.sm),
              ],
            AppSpacing.gapV(AppSpacing.xs),
            Text(
              AppStrings.deliveryAddress.tr,
              style: AppTextStyles.labelLarge
                  .rc(AppColors.gray400)
                  .copyWith(letterSpacing: 1.2),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            _AddressCard(
              address: controller.address.value,
              isEditing: controller.hasSavedAddress.value,
              onSaved: controller.saveAddress,
            ),
            AppSpacing.gapV(AppSpacing.lg),
            AppButton(
              label: AppStrings.placeOrder.trParams({
                'amount': controller.totalLabel,
              }),
              onPressed: controller.placeOrder,
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Text(
              AppStrings.securedNote.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.rc(AppColors.gray400),
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.controller});

  final PharmacyCartController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: AppSizes.xl.w,
            color: AppColors.gray400,
          ),
          AppSpacing.gapH(AppSpacing.xs),
          // Scaled rather than ellipsized, for the same reason as the cart's
          // delivery banner: the store name is the payload of this line.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.orderHeadline.trParams({
                  'count': '${controller.itemCount}',
                  'store': controller.store.value?.name ?? '',
                }),
                maxLines: 1,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              ),
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(
            controller.checkoutLabel,
            style: AppTextStyles.titleSmall.rc(AppColors.gray900),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isEditing,
    required this.onSaved,
  });

  /// Plain values, so the caller's `Obx` is what tracks them.
  final DeliveryAddress address;
  final bool isEditing;
  final ValueChanged<DeliveryAddress> onSaved;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: AppSizes.xl.w,
            color: AppColors.primary600,
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address.line1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  address.line2,
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
            onTap: () async {
              final saved = await LocationDialog.show(
                context,
                address: address,
                isEditing: isEditing,
              );
              if (saved != null) onSaved(saved);
            },
            child: Text(
              // "Add" until an address has been saved once, then "Change".
              (isEditing ? AppStrings.change : AppStrings.add).tr,
              style: AppTextStyles.bodyLarge.rc(AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}
