import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/utils/time_format.dart';

/// `Today` / `Yesterday` / `Saturday` / `21/08/2026`, above the first message
/// of each day.
///
/// Without it a bubble carries only a clock, so a thread spanning two days
/// reads as though it were out of order: a message at 3:57 PM yesterday sits
/// above one at 3:46 PM today, and the only honest conclusion from the screen
/// alone is that the app sorted them wrong. It had not — the day was simply
/// missing from the picture.
class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator({super.key, required this.at, this.now});

  final DateTime at;

  /// Injectable so a golden does not change meaning tomorrow.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs2.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardFieldFill,
            borderRadius: AppRadius.rFull,
          ),
          child: Text(
            TimeFormat.daySeparator(at, now: now),
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
