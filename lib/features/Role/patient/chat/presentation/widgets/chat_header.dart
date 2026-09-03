import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/utils/time_format.dart';
import '../../../../../../core/widgets/presence_avatar.dart';
import '../../domain/entities/conversation.dart';

/// The `primary500` bar at the top of a thread: back, photo with its presence
/// dot, name over `online` / `last seen …`, and the call button.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.peer,
    required this.onBack,
    this.isOnline,
    this.lastSeen,
    this.isTyping = false,
    this.onVideoCall,
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

  /// Rings the other party. Null on a thread with no consultation behind it
  /// — support, or a doctor who has not been booked — where there is no room
  /// to call into and a dialler would be a control that does nothing.
  final VoidCallback? onVideoCall;

  /// Identifies the call button for tests.
  static const Key callButtonKey = ValueKey('chat-header-call');

  /// `Online`, `typing…`, `last seen today at 2:32 PM`, or the specialty when
  /// nothing is known yet.
  ///
  /// The clock used to be read straight off the `DateTime` the socket parsed,
  /// which is UTC — so "last seen 14:32" was someone else's afternoon.
  String get _subtitle {
    if (isTyping) return AppStrings.typingNow.tr;
    if (isOnline == true) return AppStrings.online.tr;
    final seen = lastSeen;
    if (isOnline == false && seen != null) return TimeFormat.lastSeen(seen);
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
              // The same dot the message list draws, for the same fact —
              // the header used to state presence only in words, so the row
              // and the thread it opened disagreed about how to show it.
              PresenceAvatar(
                isOnline: isOnline,
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
              if (onVideoCall != null) ...[
                AppSpacing.gapH(AppSpacing.xs),
                InkResponse(
                  key: callButtonKey,
                  onTap: onVideoCall,
                  radius: AppSizes.xl2.r,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xs.w),
                    child: Icon(
                      Icons.videocam_rounded,
                      size: AppSizes.xl2.w,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
              AppSpacing.gapH(AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}
