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
/// * pending payment → **Pay Now**, plus Cancel — never Join, no matter the day
/// * past → **Book Again** and a **Review** link
/// * cancelled → **Book Again**
class AppointmentHistoryCard extends StatelessWidget {
  const AppointmentHistoryCard({
    super.key,
    required this.appointment,
    required this.isJoinable,
    this.onJoin,
    this.onPayNow,
    this.onBookAgain,
    this.onReview,
    this.onReschedule,
    this.onRequestRefund,
    this.onCancel,
    this.isResolving = false,
  });

  final Appointment appointment;

  /// True only for a visit whose room is open now.
  final bool isJoinable;

  final VoidCallback? onJoin;
  final VoidCallback? onPayNow;
  final VoidCallback? onBookAgain;
  final VoidCallback? onReview;
  final VoidCallback? onReschedule;
  final VoidCallback? onRequestRefund;
  final VoidCallback? onCancel;

  /// True while one of the two lapse remedies is in flight.
  final bool isResolving;

  static const double _avatar = 56;

  /// Sized to the "Book Again" label and no wider, so the doctor's name keeps
  /// the ~160pt it needs at `titleMedium`.
  static const double _actionsWidth = 88;

  bool get _isUpcoming => appointment.status == AppointmentStatus.upcoming;

  bool get _needsPayment =>
      appointment.status == AppointmentStatus.pendingPayment;

  /// `Apr 1, 2026 at 10:00 AM`.
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
                if (_needsPayment) ...[
                  AppSpacing.gapV(AppSpacing.sm),
                  _PayNowButton(onTap: onPayNow),
                ],
                // A lapsed consultation the patient has not resolved: they
                // choose which remedy they want, and the two are exclusive.
                if (appointment.needsLapseChoice) ...[
                  AppSpacing.gapV(AppSpacing.xs),
                  Text(
                    AppStrings.chooseRescheduleOrRefund.tr,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                  ),
                  AppSpacing.gapV(AppSpacing.sm),
                  _LapseChoices(
                    isBusy: isResolving,
                    onReschedule: onReschedule,
                    onRequestRefund: onRequestRefund,
                  ),
                ]
                // Asked for, not yet paid — the doctor still has to settle it,
                // so this says who it is waiting on rather than implying the
                // money has moved.
                else if (appointment.isRefundPending) ...[
                  AppSpacing.gapV(AppSpacing.xs),
                  Text(
                    AppStrings.refundAwaitingDoctor.tr,
                    style: AppTextStyles.bodyMedium.rc(AppColors.warning500),
                  ),
                ],
              ],
            ),
          ),
          if (_isUpcoming)
            _OverflowMenu(onReschedule: onReschedule, onCancel: onCancel)
          // A lapsed consultation shows its two remedies and nothing else.
          //
          // The 88pt Book Again / Review column stole the width the remedy
          // buttons needed, so "Request refund" ellipsised down to a few
          // characters — the option was on screen but unreadable. Re-booking
          // is also the wrong offer here: this consultation is already paid
          // for and needs settling, not replacing.
          else if (appointment.needsLapseChoice)
            const SizedBox.shrink()
          else if (_needsPayment)
            // No reschedule here — there is nothing confirmed yet to move to
            // a different time, only an unpaid slot to keep or give up.
            SizedBox(
              width: _actionsWidth.w,
              child: _CancelLink(onCancel: onCancel),
            )
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

/// Stands in for Join on a booking still awaiting payment. Amber rather than
/// the Join pill's green/grey pair — it is neither "ready" nor "not yet",
/// it is blocked on the patient.
class _PayNowButton extends StatelessWidget {
  const _PayNowButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning500,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.base.w,
            vertical: AppSpacing.xs.h + 2,
          ),
          child: Text(
            AppStrings.payNow.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.white),
          ),
        ),
      ),
    );
  }
}

/// The two remedies for a lapsed consultation.
///
/// Reschedule leads, blue, because it is the better outcome for both sides —
/// the patient still gets their consultation and the doctor keeps the fee.
/// Refund is pink rather than hidden behind a link: it is the patient's money,
/// and making it the harder of the two to find would be the wrong nudge. Pink
/// rather than red, too — asking for your own money back is not destructive.
///
/// Laid out with [Wrap], not [Row]. Two fixed-width buttons and a translated
/// label are not guaranteed to fit a narrow phone, and a `Row` answers that by
/// overflowing — the yellow-and-black stripe, with "Request refund" clipped
/// mid-word. Wrapping puts the second button on its own line instead, so both
/// labels stay whole at any width and in any language.
class _LapseChoices extends StatelessWidget {
  const _LapseChoices({
    required this.isBusy,
    required this.onReschedule,
    required this.onRequestRefund,
  });

  final bool isBusy;
  final VoidCallback? onReschedule;
  final VoidCallback? onRequestRefund;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs.w,
      runSpacing: AppSpacing.xs.h,
      children: [
        _ChoiceButton(
          label: AppStrings.reschedule.tr,
          fill: AppColors.actionFill,
          ink: AppColors.actionLabel,
          isBusy: false,
          onTap: isBusy ? null : onReschedule,
        ),
        _ChoiceButton(
          label: AppStrings.requestRefund.tr,
          fill: AppColors.secondaryActionFill,
          ink: AppColors.secondaryActionInk,
          // Only this one spins: it is the only one that waits on the server.
          // Reschedule opens a calendar, which is instant.
          isBusy: isBusy,
          onTap: isBusy ? null : onRequestRefund,
        ),
      ],
    );
  }
}

/// One pill in [_LapseChoices].
///
/// Both share a shape so neither reads as the lesser option; only the colours
/// differ. A minimum tap target keeps the shorter label from becoming a
/// button too small to hit comfortably.
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.fill,
    required this.ink,
    required this.isBusy,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final Color ink;
  final bool isBusy;
  final VoidCallback? onTap;

  /// Comfortably above the 44pt accessibility floor once padding is added.
  static const double _minHeight = 38;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _minHeight.h),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Center(
              widthFactor: 1,
              child: isBusy
                  ? SizedBox(
                      width: AppSizes.xl.w,
                      height: AppSizes.xl.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ink,
                      ),
                    )
                  : Text(
                      label,
                      // No ellipsis and no `maxLines`: wrapping is what stops
                      // the overflow, so the text never needs truncating.
                      style: AppTextStyles.titleSmall.rc(ink),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lone action available on an unpaid booking besides paying for it.
class _CancelLink extends StatelessWidget {
  const _CancelLink({this.onCancel});

  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onCancel,
        child: Text(
          AppStrings.cancelAppointment.tr,
          style: AppTextStyles.bodySmall
              .rc(AppColors.error600)
              .copyWith(
                decoration: TextDecoration.underline,
                decorationColor: AppColors.error600,
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
