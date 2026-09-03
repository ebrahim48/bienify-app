import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// The count on a header icon — how many are waiting, not merely that some are.
///
/// Shared so the patient's bell and the doctor's cannot disagree about how a
/// count is drawn, and so "99+" is decided once rather than at each call site.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, required this.child});

  final int count;

  /// The icon the badge sits on.
  final Widget child;

  /// Identifies the badge for tests.
  static const Key badgeKey = ValueKey('unread-badge');

  /// Above this the exact number stops being useful and starts being wide.
  static const int _max = 99;

  static String label(int count) => count > _max ? '$_max+' : '$count';

  @override
  Widget build(BuildContext context) {
    // Nothing waiting draws nothing at all: a zero badge is a permanent mark
    // that says there is something to look at when there is not.
    if (count <= 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6.w,
          top: -4.h,
          child: Container(
            key: badgeKey,
            constraints: BoxConstraints(minWidth: 18.w),
            padding: EdgeInsets.symmetric(
              horizontal: 5.w,
              vertical: 1.h,
            ),
            decoration: BoxDecoration(
              color: AppColors.error500,
              borderRadius: AppRadius.rFull,
              // A ring in the header's own colour, so the badge reads as
              // sitting on the icon rather than being cut out of it.
              border: Border.all(color: AppColors.authBackground, width: 1.5),
            ),
            child: Text(
              label(count),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.rc(AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}
