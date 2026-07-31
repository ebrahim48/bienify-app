import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../../booking/domain/entities/payment_method.dart';
import '../../../booking/presentation/widgets/payment_method_tile.dart';
import '../controllers/account_controller.dart';

/// Choose how to fund the wallet.
///
/// Reuses the booking flow's `PaymentMethodTile` and its method list rather
/// than a third copy of the same six rows.
class PaymentOptionsScreen extends GetView<AccountController> {
  const PaymentOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.paymentOptions.tr),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.choosePaymentMethod.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Expanded(
            child: SingleChildScrollView(
              child: Obx(
                () => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (
                      var index = 0;
                      index < PaymentMethod.values.length;
                      index++
                    ) ...[
                      PaymentMethodTile(
                        method: PaymentMethod.values[index],
                        isSelected:
                            index == controller.selectedMethodIndex.value,
                        onTap: () => controller.selectMethod(index),
                      ),
                      AppSpacing.gapV(AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
          ),
          AppButton(
            label: AppStrings.next.tr,
            onPressed: controller.continueToCardForm,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}
