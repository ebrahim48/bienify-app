import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../../core/widgets/app_menu_row.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../../../../../core/widgets/destructive_bar.dart';
import '../controllers/settings_controller.dart';

/// Four rows — the password form and the three legal documents — with the
/// destructive account action at the foot.
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.settings.tr),
      // Not scrollable, so Delete Account can be pinned to the bottom of the
      // page the way the design places it. Four rows and one bar fit any
      // supported height.
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // Darker than Profile's rows: these are the leaves of the account
          // tree, not a hub, and the design draws them in the ink colour.
          AppMenuRow(
            label: AppStrings.changePassword.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openChangePassword,
          ),
          AppMenuRow(
            label: AppStrings.aboutUs.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openAboutUs,
          ),
          AppMenuRow(
            label: AppStrings.termsAndConditions.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openTerms,
          ),
          AppMenuRow(
            label: AppStrings.privacyPolicy.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openPrivacy,
          ),
          const Spacer(),
          DestructiveBar(
            iconAsset: AppIcons.delete,
            label: AppStrings.deleteAccount.tr,
            onTap: () => _confirmDelete(context),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      question: AppStrings.deleteAccountQuestion.tr,
      confirmLabel: AppStrings.delete.tr,
      denyLabel: AppStrings.cancel.tr,
      confirmColor: AppColors.logoutFill,
    );
    if (confirmed ?? false) controller.deleteAccount();
  }
}
