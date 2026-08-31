import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_avatar.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/photo_upload_box.dart';
import '../../domain/entities/profile.dart';

/// The patient card at the top of Profile: name, masked phone, an Edit pill,
/// and the photo with a camera badge overlapping its lower-right corner.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.patient,
    required this.onEdit,
    required this.onPhotoPicked,
    this.isUploadingPhoto = false,
  });

  final PatientProfile patient;
  final VoidCallback onEdit;
  final ValueChanged<File> onPhotoPicked;
  final bool isUploadingPhoto;

  static const double _badge = 32;

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
                  patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.rc(AppColors.gray900),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  patient.maskedPhone,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                _EditPill(onTap: onEdit),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          // `clipBehavior: none` so the badge can hang over the avatar's edge
          // the way the design draws it.
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                imageUrl: patient.photoUrl,
                name: patient.name,
                size: AppSizes.profileAvatar,
                fallbackAsset: patient.photoAsset,
              ),
              Positioned(
                right: -AppSpacing.xs2.w,
                bottom: 0,
                child: _CameraBadge(
                  onPicked: onPhotoPicked,
                  isBusy: isUploadingPhoto,
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
    return Material(
      color: AppColors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: AppColors.editBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs2.h + 1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: AppSizes.lg.w,
                color: AppColors.link,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                AppStrings.edit.tr,
                style: AppTextStyles.bodyMedium.rc(AppColors.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.onPicked, required this.isBusy});

  final ValueChanged<File> onPicked;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBusy
          ? null
          : () async {
              final file = await pickPhoto(context);
              if (file != null) onPicked(file);
            },
      child: Container(
        width: ProfileCard._badge.w,
        height: ProfileCard._badge.w,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gray900.withValues(alpha: 0.08),
              blurRadius: AppRadius.sm.r,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isBusy
            ? SizedBox(
                width: AppSizes.lg.w,
                height: AppSizes.lg.w,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            // Material's camera rather than `camera.svg`: the icon file draws
            // an outlined body with no lens, and the design's mark is a
            // filled navy silhouette with one.
            : Icon(
                Icons.photo_camera,
                size: AppSizes.xl.w,
                color: AppColors.authInk,
              ),
      ),
    );
  }
}
