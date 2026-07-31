import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';

/// Home greeting bar: avatar, name over a tappable location, and the three
/// header actions on the right.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.name,
    required this.location,
    required this.onProfileTap,
    required this.onLocationTap,
    required this.onCartTap,
    required this.onMessagesTap,
    required this.onNotificationsTap,
  });

  final String name;
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
          // `profile.svg` already ships as the finished 40pt avatar — navy
          // disc and white figure — so it is drawn untinted and unwrapped.
          child: AppSvgIcon(AppIcons.profile, size: _avatarSize),
        ),
        AppSpacing.gapH(AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.rc(AppColors.authInk),
              ),
              AppSpacing.gapV(AppSpacing.xxs),
              _LocationRow(label: location, onTap: onLocationTap),
            ],
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        _HeaderAction(icon: AppIcons.shoppingBag, onTap: onCartTap),
        _HeaderAction(icon: AppIcons.message, onTap: onMessagesTap),
        _HeaderAction(icon: AppIcons.notification, onTap: onNotificationsTap),
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
