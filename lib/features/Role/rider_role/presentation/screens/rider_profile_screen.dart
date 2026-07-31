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
import '../../data/static/rider_data.dart';
import '../controllers/rider_profile_controller.dart';

/// The courier's account: their card, two rows, and the way out.
class RiderProfileScreen extends GetView<RiderProfileController> {
  const RiderProfileScreen({super.key});

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
          RoleProfileCard(
            name: RiderData.profileName,
            phone: RiderData.profilePhone,
            onEdit: controller.edit,
            onChangePhoto: controller.changePhoto,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          // My Wallet and Settings are the patient app's own screens — a
          // courier keeps their money in the same wallet and reads the same
          // legal pages, so both are navigated to rather than rebuilt.
          AppMenuRow(
            label: AppStrings.myWallet.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openWallet,
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
