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
import '../../domain/entities/conversation.dart';

/// The `primary500` bar at the top of a thread: back, photo, name over
/// specialty, and the online pill.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.peer,
    required this.onBack,
    this.isOnline,
    this.lastSeen,
    this.isTyping = false,
  });

  final ConversationPeer peer;
  final VoidCallback onBack;

  /// Live presence. Null while unknown — before the socket has answered — so
  /// the line can stay on the specialty rather than claim someone is offline
  /// on no evidence.
  final bool? isOnline;
  final DateTime? lastSeen;

  /// Replaces the subtitle while it is true, as a chat header does.
  final bool isTyping;

  /// `Online`, `typing…`, `last seen 14:32`, or the specialty when nothing is
  /// known yet.
  String get _subtitle {
    if (isTyping) return AppStrings.typingNow.tr;
    if (isOnline == true) return AppStrings.online.tr;
    final seen = lastSeen;
    if (isOnline == false && seen != null) {
      final hh = seen.hour.toString().padLeft(2, '0');
      final mm = seen.minute.toString().padLeft(2, '0');
      return AppStrings.lastSeenAt.trParams({'time': '$hh:$mm'});
    }
    return peer.specialty;
  }

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
                fallbackAsset: peer.photoAsset,
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
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.rc(AppColors.primary100),
                    ),
                  ],
                ),
              ),
              // Driven by live presence when the socket has told us, and by
              // the seeded flag only until then.
              if (isOnline ?? peer.isOnline) ...[
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
