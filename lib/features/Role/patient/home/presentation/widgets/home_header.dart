import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/services/notification_inbox_service.dart';
import '../../../../../../core/widgets/unread_badge.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/app_avatar.dart';

/// Home greeting bar: avatar, name over a tappable location, and the three
/// header actions on the right.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.location,
    this.photoUrl,
    required this.onProfileTap,
    required this.onLocationTap,
    required this.onCartTap,
    required this.onMessagesTap,
    required this.onNotificationsTap,
  });

  final String name;

  /// The patient's own picture. Null until the feed lands, and for an account
  /// that has never set one.
  final String? photoUrl;

  final String location;
  final VoidCallback onProfileTap;
  final VoidCallback onLocationTap;
  final VoidCallback onCartTap;
  final VoidCallback onMessagesTap;
  final VoidCallback onNotificationsTap;

  /// Avatar diameter from the design.
  static const double _avatarSize = 40;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onProfileTap,
          // With a picture, the patient's own; without one, `profile.svg`
          // already ships as the finished 40pt avatar — navy disc and white
          // figure — so it is drawn untinted and unwrapped.
          child: photoUrl == null
              ? AppSvgIcon(AppIcons.profile, size: _avatarSize)
              : AppAvatar(
                  imageUrl: photoUrl,
                  name: name,
                  size: _avatarSize,
                  fallbackAsset: null,
                ),
        ),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The name opens the profile too, not only the picture beside
              // it: the two read as one control, and half of it answering a
              // tap while the other half does nothing is the sort of thing
              // people blame on the tap rather than the app.
              GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.rc(AppColors.authInk),
                ),
              ),
              AppSpacing.gapV(AppSpacing.xxs),
              _LocationRow(label: location, onTap: onLocationTap),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        _HeaderAction(icon: AppIcons.shoppingBag, onTap: onCartTap),
        _HeaderAction(icon: AppIcons.message, onTap: onMessagesTap),
        // Read inside an `Obx` so the count changes without the header being
        // rebuilt from above — a notification arriving on the socket has to
        // move this badge while the patient is looking at it.
        Obx(
          () => UnreadBadge(
            count: Get.isRegistered<NotificationInboxService>()
                ? Get.find<NotificationInboxService>().unread.value
                : 0,
            child: _HeaderAction(
              icon: AppIcons.notification,
              onTap: onNotificationsTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: AppSizes.lg.w,
            color: AppColors.authInk,
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: AppSizes.xl.w,
            color: AppColors.authInk,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: AppSizes.xl2.r,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.w + 1),
        child: AppSvgIcon(icon, color: AppColors.authInk),
      ),
    );
  }
}
