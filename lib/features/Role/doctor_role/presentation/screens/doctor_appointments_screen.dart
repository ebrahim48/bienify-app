import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../patient/appointments/presentation/widgets/cancel_reason_dialog.dart';
import '../../../patient/doctors/presentation/widgets/doctor_search_field.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_appointments_controller.dart';

/// The practitioner's Appointments tab: search, stage chips, and the bookings.
class DoctorAppointmentsScreen extends GetView<DoctorAppointmentsController> {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Text(
            AppStrings.navAppointments.tr,
            style: AppTextStyles.headlineLarge.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.base),
          DoctorSearchField(
            initialText: controller.query.value,
            onChanged: (value) => controller.query.value = value,
          ),
          AppSpacing.gapV(AppSpacing.base),
          // The active chip is read here so the row repaints.
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in DoctorApptFilter.values)
                  controller.filterLabel(value),
              ],
              selectedIndex: DoctorApptFilter.values.indexOf(
                controller.filter.value,
              ),
              onSelected: (index) =>
                  controller.selectFilter(DoctorApptFilter.values[index]),
              isLarge: true,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(() {
            final appointments = controller.visible;
            if (appointments.isEmpty) {
              return AppEmptyState(
                icon: Icons.event_busy_outlined,
                title: AppStrings.noUpcomingAppointments.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final appointment in appointments) ...[
                  // A finished consultation has nothing left to join or
                  // cancel, so it shows what it was worth instead.
                  if (appointment.filter == DoctorApptFilter.fresh)
                    _AppointmentCard(
                      appointment: appointment,
                      onOpen: () => controller.openDetails(appointment),
                      onJoin: () => controller.join(appointment),
                      onCancel: () => _cancel(context, appointment),
                    )
                  else
                    _CompletedCard(
                      appointment: appointment,
                      statusLabel: controller.cardStatusLabel(
                        appointment.filter,
                      ),
                      onOpen: () => controller.openDetails(appointment),
                    ),
                  AppSpacing.gapV(AppSpacing.sm),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  /// The reason sheet is the appointments feature's own dialog, so both roles
  /// cancel through one blurred popup.
  Future<void> _cancel(
    BuildContext context,
    DoctorAppointment appointment,
  ) async {
    final reason = await CancelReasonDialog.show(context);
    if (reason != null) controller.cancel(appointment, reason);
  }
}

/// Patient photo, name, complaint and schedule, with Join and Cancel stacked
/// on the right. Join is muted until the room opens.
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onOpen,
    required this.onJoin,
    required this.onCancel,
  });

  final DoctorAppointment appointment;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final VoidCallback onCancel;

  static const double _avatar = 56;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      onTap: onOpen,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            name: appointment.patientName,
            size: _avatar,
            imageUrl: appointment.photoUrl,
            fallbackAsset: appointment.photoAsset,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appointment.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                Text(
                  appointment.complaint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray600,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Expanded(
                      child: Text(
                        appointment.scheduleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // A size down from the name: the full date has to fit
                        // beside the Join / Cancel column, and at `bodyLarge`
                        // it clipped to "…at 11:00 …".
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _JoinPill(isEnabled: appointment.isJoinable, onTap: onJoin),
              AppSpacing.gapV(AppSpacing.sm),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCancel,
                child: Text(
                  AppStrings.cancel.tr,
                  style: AppTextStyles.bodyLarge
                      .rc(AppColors.logoutFill)
                      .copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.logoutFill,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grey "Join" until the room opens, then green "Join Visit".
///
/// Follows the design that distinguishes the two states, and matches the
/// patient side's `AppointmentHistoryCard`, so an open room reads the same
/// way to both parties.
class _JoinPill extends StatelessWidget {
  const _JoinPill({required this.isEnabled, required this.onTap});

  final bool isEnabled;
  final VoidCallback onTap;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isEnabled ? AppColors.success400 : AppColors.gray400,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          alignment: Alignment.center,
          child: Text(
            (isEnabled ? AppStrings.joinVisit : AppStrings.join).tr,
            style: AppTextStyles.titleSmall.rc(AppColors.white),
          ),
        ),
      ),
    );
  }
}

/// A finished consultation: initials disc, patient, complaint and age, the
/// presenting summary, then the date, time and fee.
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({
    required this.appointment,
    required this.statusLabel,
    required this.onOpen,
  });

  final DoctorAppointment appointment;
  final String statusLabel;
  final VoidCallback onOpen;

  static const double _disc = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      onTap: onOpen,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _disc.w,
            height: _disc.w,
            decoration: BoxDecoration(
              color: AppColors.patientInitialsSurface,
              borderRadius: AppRadius.rXl,
            ),
            alignment: Alignment.center,
            child: Text(
              appointment.initials ?? '',
              style: AppTextStyles.labelLarge.rc(AppColors.patientInitialsInk),
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.patientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    _StatusPill(label: statusLabel, state: appointment.filter),
                  ],
                ),
                Text(
                  appointment.complaintLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.menuLabel),
                ),
                if (appointment.summary != null)
                  Text(
                    appointment.summary!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                  ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray500,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Text(
                      appointment.shortDateLabel,
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                    ),
                    AppSpacing.gapH(AppSpacing.sm),
                    Icon(
                      Icons.schedule_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray500,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Expanded(
                      child: Text(
                        appointment.timeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs),
                    Text(
                      appointment.feeLabel,
                      style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined green pill, unlike the filled status tags elsewhere — which is
/// how the design distinguishes a settled consultation.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.state});

  final String label;
  final DoctorApptFilter state;

  /// Green reads as "went well", so only a completed consultation wears it —
  /// a cancelled one used to, which said the opposite of what happened.
  (Color, Color) get _tint => switch (state) {
    DoctorApptFilter.completed => (
      AppColors.completedSurface,
      AppColors.completedInk,
    ),
    DoctorApptFilter.cancelled => (
      AppColors.cancelledSurface,
      AppColors.cancelledInk,
    ),
    DoctorApptFilter.fresh => (AppColors.freshSurface, AppColors.freshInk),
  };

  @override
  Widget build(BuildContext context) {
    final (surface, ink) = _tint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.rFull,
        border: Border.all(color: ink, width: AppSizes.borderWidth),
      ),
      child: Text(label, style: AppTextStyles.bodyMedium.rc(ink)),
    );
  }
}
