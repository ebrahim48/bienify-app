import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/widgets/app_menu_row.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/destructive_bar.dart';
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
            () => _OwnerCard(
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

/// Name and masked phone on the left, photo with its camera badge on the
/// right — the mirror of the patient's `ProfileCard`, which puts the photo
/// first.
class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.name,
    required this.phone,
    required this.onEdit,
    required this.onChangePhoto,
  });

  final String name;
  final String phone;
  final VoidCallback onEdit;
  final VoidCallback onChangePhoto;

  static const double _avatar = 64;
  static const double _badge = 26;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  phone,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                _EditPill(onTap: onEdit),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                size: _avatar,
                fallbackAsset: AppAssets.doctorPlaceholder,
              ),
              Positioned(
                right: -2,
                bottom: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onChangePhoto,
                  child: Container(
                    width: _badge.w,
                    height: _badge.w,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.photo_camera_outlined,
                      size: AppSizes.base.w,
                      color: AppColors.photoBadgeInk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.rFull,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs2.h,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rFull,
              border: Border.all(
                color: AppColors.editBorder,
                width: AppSizes.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  size: AppSizes.base.w,
                  color: AppColors.actionFill,
                ),
                AppSpacing.gapH(AppSpacing.xs2),
                Text(
                  AppStrings.edit.tr,
                  style: AppTextStyles.bodyMedium.rc(AppColors.actionFill),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
