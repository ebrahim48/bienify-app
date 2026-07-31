import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../controllers/main_nav_controller.dart';

/// The four-tab bottom navigation.
///
/// Geometry from the design: 72pt tall over a 1px `gray100` top rule, white
/// fill, 24pt icons with a 6pt gap to a 12pt label, and equal-width tabs.
/// The active tab tints both icon and label `primary800`; the rest sit in
/// `gray600`.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int currentIndex;
  final List<NavDestination> destinations;
  final ValueChanged<int> onSelected;

  /// Bar height above the safe-area inset.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceBorder,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height.h,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[index],
                    isSelected: index == currentIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = isSelected ? AppColors.navActive : AppColors.navInactive;

    return InkResponse(
      onTap: onTap,
      radius: AppSizes.xl4.r,
      containedInkWell: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Badged(
            count: destination.badgeCount,
            child: AppSvgIcon(
              destination.icon,
              color: tint,
              semanticsLabel: destination.labelKey.tr,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2 + 2),
          Text(
            destination.labelKey.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.rw(
              tint,
              isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Red unread bubble pinned to the top-right of an icon.
class _Badged extends StatelessWidget {
  const _Badged({required this.child, required this.count});

  final Widget child;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4.h,
          right: -6.w,
          child: Container(
            constraints: BoxConstraints(minWidth: AppSizes.lg.w),
            height: AppSizes.lg.w,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.w),
            decoration: BoxDecoration(
              color: AppColors.badge,
              borderRadius: AppRadius.rFull,
              border: Border.all(color: AppColors.surface, width: 1.5),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Text(
                count > 9 ? '9+' : '$count',
                style: AppTextStyles.labelSmall.rw(
                  AppColors.white,
                  FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
