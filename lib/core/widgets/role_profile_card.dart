import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_assets.dart';
import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'app_avatar.dart';
import 'app_card.dart';

/// Name and masked phone on the left, photo with its camera badge on the
/// right, and an Edit pill under the number.
///
/// The pharmacy owner and the courier are given the identical card, which is
/// the mirror of the patient's `ProfileCard` — that one puts the photo first.
class RoleProfileCard extends StatelessWidget {
  const RoleProfileCard({
    super.key,
    required this.name,
    required this.phone,
    required this.onEdit,
    required this.onChangePhoto,
    this.photoUrl,
  });

  final String name;
  final String phone;

  /// The signed-in owner's or courier's own picture. Every seeded account has
  /// one; the bundled placeholder is only for accounts that do not.
  final String? photoUrl;
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
                imageUrl: photoUrl,
                name: name,
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
