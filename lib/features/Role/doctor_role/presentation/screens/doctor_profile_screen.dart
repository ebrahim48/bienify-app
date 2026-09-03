import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/widgets/app_menu_row.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../patient/profile/presentation/widgets/profile_card.dart';
import '../controllers/doctor_profile_controller.dart';

/// The practitioner's Profile tab.
///
/// Reuses the patient app's `ProfileCard`, `AppMenuRow` and log-out
/// confirmation; My Wallet, Settings and Partner with Bienify open the
/// patient screens themselves rather than practitioner copies.
class DoctorProfileScreen extends GetView<DoctorProfileController> {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // Not scrollable, so the log-out card pins to the foot of the page as
      // the design places it.
      //
      // The card and rows sit in their own scroll view rather than behind a
      // `Spacer`. A `Spacer` assumes the content always fits, and on a short
      // viewport it cannot shrink — the page overflowed by 34px on a landscape
      // phone. Scrolling the content while the bar stays a sibling of the
      // scroll view keeps the design's pinned foot without that assumption.
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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
                      patient: controller.profile.value,
                      onEdit: controller.edit,
                      onChangePhoto: () => controller.changePhoto(context),
                    ),
                  ),
                  AppSpacing.gapV(AppSpacing.md),
                  AppMenuRow(
                    label: AppStrings.myWallet.tr,
                    labelColor: AppColors.authInk,
                    onTap: controller.openWallet,
                  ),
                  AppMenuRow(
                    label: AppStrings.credentials.tr,
                    labelColor: AppColors.authInk,
                    onTap: controller.openCredentials,
                  ),
                  AppMenuRow(
                    label: AppStrings.resultsToReview.tr,
                    labelColor: AppColors.authInk,
                    onTap: controller.openResultsToReview,
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
                ],
              ),
            ),
          ),
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
              // Untinted: the file ships stroked in `logoutFill`.
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
