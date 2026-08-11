import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/appointment.dart';

/// A booked consultation: tinted heart badge, doctor, specialty, schedule and
/// an optional Join pill.
///
/// Shared by the Home feed, the Appointments tab and the payment summary —
/// the summary hides the action with `showJoin: false`.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onJoin,
    this.showJoin = true,
  });

  final Appointment appointment;
  final VoidCallback? onJoin;
  final bool showJoin;

  static const double _badgeSize = 56;

  /// `Apr 1, 2026 at 10:00 AM` — formatted by hand so the app carries no
  /// `intl` dependency for one string.
  String get _schedule {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final at = appointment.scheduledAt;
    final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    final period = at.hour < 12 ? 'AM' : 'PM';
    return '${months[at.month - 1]} ${at.day}, ${at.year} '
        'at $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _badgeSize.w,
            height: _badgeSize.w,
            decoration: const BoxDecoration(
              color: AppColors.accentSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: AppSvgIcon(
              AppIcons.heart,
              size: AppSizes.xl3,
              color: AppColors.primary500,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.black,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  appointment.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.textSecondary),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2 + 2),
                    Flexible(
                      child: Text(
                        _schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.rc(
                          AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showJoin && onJoin != null) ...[
            AppSpacing.gapH(AppSpacing.xs),
            _JoinButton(onTap: onJoin!),
          ],
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mutedFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: AppSpacing.sm.h,
          ),
          child: Text(
            AppStrings.join.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.authInk),
          ),
        ),
      ),
    );
  }
}
