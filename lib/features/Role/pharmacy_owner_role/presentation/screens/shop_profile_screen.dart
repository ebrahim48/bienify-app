import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/widgets/app_menu_row.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/destructive_bar.dart';
import '../../../../../core/widgets/role_profile_card.dart';
import '../controllers/shop_profile_controller.dart';

/// The shop owner's account: their card, two rows, and the way out.
class ShopProfileScreen extends GetView<ShopProfileController> {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // Not scrollable, so the log-out bar sits at the foot of the page the
      // way the design places it.
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Text(
            AppStrings.profileTitle.tr,
            style: AppTextStyles.headlineLarge.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => RoleProfileCard(
              name: controller.shop.value.ownerName,
              phone: controller.shop.value.phone,
              onEdit: controller.edit,
              onChangePhoto: controller.changePhoto,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          // Payments and Credit is the patient app's own wallet — a shop
          // keeps its money in the same place, so it is navigated to.
          AppMenuRow(
            label: AppStrings.paymentsAndCredit.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openPayments,
          ),
          AppMenuRow(
            label: AppStrings.settings.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openSettings,
          ),
          const Spacer(),
          DestructiveBar(
            iconAsset: AppIcons.logout,
            label: AppStrings.logOut.tr,
            onTap: () => _confirmLogOut(context),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      question: AppStrings.readyToLogOut.tr,
      confirmLabel: AppStrings.logOut.tr,
      denyLabel: AppStrings.cancel.tr,
      confirmColor: AppColors.logoutFill,
    );
    if (confirmed ?? false) controller.logOut();
  }
}
