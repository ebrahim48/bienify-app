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
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_menu_row.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_card.dart';

/// The account hub, reached from the Home header's avatar.
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // No `AppTopBar`: the design gives this screen a page heading rather
      // than a titled bar with a back chevron, like the Pharmacy tab. The
      // platform back gesture and button still pop it.
      //
      // Not scrollable, so the log-out card can be pinned to the foot of the
      // page with a `Spacer` the way the design places it. The content is a
      // fixed heading, card and five rows; `profile_golden_test.dart` guards
      // that it still fits at 320pt with 1.3× text.
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Text(
            AppStrings.profileTitle.tr,
            style: AppTextStyles.headlineLarge.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => ProfileCard(
              patient: controller.patient.value,
              onEdit: controller.edit,
              onChangePhoto: controller.changePhoto,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
          AppMenuRow(
            label: AppStrings.myHealthProfile.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openHealthProfile,
          ),
          AppMenuRow(
            label: AppStrings.myTestsAndResults.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openTestsAndResults,
          ),
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
          AppMenuRow(
            label: AppStrings.partnerWithBienify.tr,
            labelColor: AppColors.authInk,
            onTap: controller.openPartner,
          ),
          const Spacer(),
          _LogOutBar(onTap: () => _confirmLogOut(context)),
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

/// Full-width white card with the red log-out label centred in it.
class _LogOutBar extends StatelessWidget {
  const _LogOutBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.controlHeight.h,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // `log-out.svg` is stroked in `logoutFill` already, so it is
              // drawn untinted — the label repeats that colour.
              AppSvgIcon(AppIcons.logout, size: AppSizes.lg),
              AppSpacing.gapH(AppSpacing.xs),
              Text(
                AppStrings.logOut.tr,
                style: AppTextStyles.titleSmall.rc(AppColors.logoutFill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
