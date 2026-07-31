import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/conversation.dart';

/// The `primary500` bar at the top of a thread: back, photo, name over
/// specialty, and the online pill.
class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key, required this.peer, required this.onBack});

  final ConversationPeer peer;
  final VoidCallback onBack;

  static const double height = 72;
  static const double _avatar = 44;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary500,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height.h,
          child: Row(
            children: [
              AppSpacing.gapH(AppSpacing.xs),
              InkResponse(
                onTap: onBack,
                radius: AppSizes.xl2.r,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xs.w),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: AppSizes.xl.w,
                    color: AppColors.white,
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              AppAvatar(
                imageUrl: peer.photoUrl,
                name: peer.name,
                size: _avatar,
                fallbackAsset: peer.photoAsset ?? AppAssets.doctorPlaceholder,
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      peer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.rc(AppColors.white),
                    ),
                    Text(
                      peer.specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.rc(AppColors.primary100),
                    ),
                  ],
                ),
              ),
              if (peer.isOnline) ...[
                AppSpacing.gapH(AppSpacing.xs),
                const _OnlinePill(),
              ],
              AppSpacing.gapH(AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs2.h + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.online,
        borderRadius: AppRadius.rFull,
      ),
      child: Text(
        AppStrings.online.tr,
        style: AppTextStyles.bodyMedium.rc(AppColors.white),
      ),
    );
  }
}
