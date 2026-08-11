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
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/appointment.dart';
import '../controllers/appointments_controller.dart';
import '../widgets/appointment_history_card.dart';
import '../widgets/cancel_reason_dialog.dart';
import '../widgets/need_care_banner.dart';
import '../widgets/review_dialog.dart';

/// Appointments tab: the booking prompt, then history across three tabs.
class AppointmentsScreen extends GetView<AppointmentsController> {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.navAppointments.tr,
            style: AppTextStyles.headlineMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.base),
          NeedCareBanner(onBook: controller.bookAppointment),
          AppSpacing.gapV(AppSpacing.lg),
          Text(
            AppStrings.appointmentHistory.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          // Observables are read inside the closures and handed down as
          // values; passing `controller` alone would leave the `Obx` with
          // nothing to track, so a tab change would never repaint.
          Obx(
            () => _TabChips(
              selected: controller.tab.value,
              onSelected: controller.selectTab,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => _History(
              controller: controller,
              groups: controller.groups,
              isLoading: controller.isLoading.value,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Horizontally scrolling filter pills; the third runs off the edge in the
/// design, so the row scrolls rather than compressing.
class _TabChips extends StatelessWidget {
  const _TabChips({required this.selected, required this.onSelected});

  final AppointmentTab selected;
  final ValueChanged<AppointmentTab> onSelected;

  static const Map<AppointmentTab, String> _labels = {
    AppointmentTab.upcoming: AppStrings.upcomingAppointmentsTab,
    AppointmentTab.past: AppStrings.pastAppointmentsTab,
    AppointmentTab.cancelled: AppStrings.cancelledAppointmentTab,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.xl4.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        children: [
          for (final entry in _labels.entries) ...[
            _Chip(
              label: entry.value.tr,
              isSelected: entry.key == selected,
              onTap: () => onSelected(entry.key),
            ),
            AppSpacing.gapH(AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.surface,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rFull,
            border: Border.all(
              color: isSelected
                  ? AppColors.actionFill
                  : AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.titleSmall.rc(
                  isSelected ? AppColors.white : AppColors.gray900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({
    required this.controller,
    required this.groups,
    required this.isLoading,
  });

  /// Used only for callbacks and the joinable rule, both of which read no
  /// observable — the reactive values arrive as [groups] and [isLoading].
  final AppointmentsController controller;

  final List<AppointmentGroup> groups;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl4.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final visible = groups.where((group) => group.items.isNotEmpty).toList();

    if (visible.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl4.h),
        child: Center(
          child: Text(
            AppStrings.noAppointmentsInTab.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in visible) ...[
          if (group.label.isNotEmpty) ...[
            Text(
              group.label,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
            ),
            AppSpacing.gapV(AppSpacing.xs),
          ],
          for (final appointment in group.items) ...[
            AppointmentHistoryCard(
              appointment: appointment,
              isJoinable: controller.isJoinable(appointment),
              onJoin: () => controller.join(appointment),
              onBookAgain: () => controller.bookAgain(appointment),
              onReview: appointment.status == AppointmentStatus.completed
                  ? () => _review(context, appointment)
                  : null,
              onReschedule: () => controller.reschedule(appointment),
              onCancel: () => _cancel(context, appointment),
            ),
            AppSpacing.gapV(AppSpacing.sm),
          ],
          AppSpacing.gapV(AppSpacing.xs),
        ],
      ],
    );
  }

  Future<void> _cancel(BuildContext context, Appointment appointment) async {
    final reason = await CancelReasonDialog.show(context);
    if (reason != null) controller.cancel(appointment, reason);
  }

  Future<void> _review(BuildContext context, Appointment appointment) async {
    final stars = await ReviewDialog.show(context);
    if (stars != null) controller.submitReview(appointment, stars);
  }
}
