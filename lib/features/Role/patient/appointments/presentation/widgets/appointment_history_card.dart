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
import '../../domain/entities/appointment.dart';

/// A row in Appointment History.
///
/// One card covers all three tabs; the trailing action is what changes:
/// * upcoming today → green **Join Visit**
/// * upcoming later → muted **Join**, not yet enabled
/// * past → **Book Again** and a **Review** link
/// * cancelled → **Book Again**
class AppointmentHistoryCard extends StatelessWidget {
  const AppointmentHistoryCard({
    super.key,
    required this.appointment,
    required this.isJoinable,
    this.onJoin,
    this.onBookAgain,
    this.onReview,
    this.onReschedule,
    this.onCancel,
  });

  final Appointment appointment;

  /// True only for a visit whose room is open now.
  final bool isJoinable;

  final VoidCallback? onJoin;
  final VoidCallback? onBookAgain;
  final VoidCallback? onReview;
  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  static const double _avatar = 56;
  /// Sized to the "Book Again" label and no wider, so the doctor's name keeps
  /// the ~160pt it needs at `titleMedium`.
  static const double _actionsWidth = 88;

  bool get _isUpcoming => appointment.status == AppointmentStatus.upcoming;

  /// `Apr 1, 2026 at 10:00 AM`.
  String get _schedule {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final at = appointment.scheduledAt;
    final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '${months[at.month - 1]} ${at.day}, ${at.year} '
        'at $hour12:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: appointment.doctorPhotoUrl,
            name: appointment.doctorName,
            size: _avatar,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appointment.doctorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rc(AppColors.authInk),
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  appointment.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray400,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2 + 2),
                    Flexible(
                      child: Text(
                        _schedule,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                      ),
                    ),
                  ],
                ),
                if (_isUpcoming) ...[
                  AppSpacing.gapV(AppSpacing.sm),
                  _JoinButton(isEnabled: isJoinable, onTap: onJoin),
                ],
              ],
            ),
          ),
          if (_isUpcoming)
            _OverflowMenu(onReschedule: onReschedule, onCancel: onCancel)
          else
            // Fixed so the doctor's name and the schedule keep the width the
            // design gives them instead of being squeezed by the button.
            SizedBox(
              width: _actionsWidth.w,
              child: _HistoryActions(
                onBookAgain: onBookAgain,
                onReview: onReview,
              ),
            ),
        ],
      ),
    );
  }
}

/// Green when the room is open, muted grey until then.
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.isEnabled, required this.onTap});

  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEnabled ? AppColors.success400 : AppColors.mutedFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: AppSpacing.xs.h + 2,
          ),
          child: Text(
            (isEnabled ? AppStrings.joinVisit : AppStrings.join).tr,
            style: AppTextStyles.titleSmall.rc(
              isEnabled ? AppColors.white : AppColors.gray600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({this.onReschedule, this.onCancel});

  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback?>(
      onSelected: (action) => action?.call(),
      padding: EdgeInsets.zero,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
      ),
      icon: Icon(
        Icons.more_vert_rounded,
        size: AppSizes.xl2.w,
        color: AppColors.authInk,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: onReschedule,
          child: Text(
            AppStrings.reschedule.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
        ),
        PopupMenuItem(
          value: onCancel,
          child: Text(
            AppStrings.cancelAppointment.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.error600),
          ),
        ),
      ],
    );
  }
}

/// "Book Again" over an optional "Review" link, right-aligned.
class _HistoryActions extends StatelessWidget {
  const _HistoryActions({this.onBookAgain, this.onReview});

  final VoidCallback? onBookAgain;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.transparent,
          borderRadius: AppRadius.rFull,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onBookAgain,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: AppRadius.rFull,
                border: Border.all(
                  color: AppColors.primary600,
                  width: AppSizes.borderWidth,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs.w,
                  vertical: AppSpacing.xs.h,
                ),
                child: Center(
                  child: Text(
                    AppStrings.bookAgain.tr,
                    maxLines: 1,
                    style: AppTextStyles.bodySmall.rc(AppColors.primary600),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onReview != null) ...[
          AppSpacing.gapV(AppSpacing.md),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onReview,
            child: Text(
              AppStrings.review.tr,
              style: AppTextStyles.bodySmall
                  .rc(AppColors.primary600)
                  .copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
