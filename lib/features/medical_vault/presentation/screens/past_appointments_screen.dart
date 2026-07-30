import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/presentation/controllers/appointments_controller.dart';
import '../../../appointments/presentation/widgets/appointment_history_card.dart';
import '../../../appointments/presentation/widgets/need_care_banner.dart';
import '../../../appointments/presentation/widgets/review_dialog.dart';

/// Completed consultations, reached from My Health profile.
///
/// Deliberately thin: the banner, the row card and the review popup are the
/// Appointments tab's own widgets, and the roster comes from its controller.
/// This screen only chooses which slice to show and gives it a title.
class PastAppointmentsScreen extends GetView<AppointmentsController> {
  const PastAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.pastAppointmentsTitle.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          NeedCareBanner(onBook: controller.bookAppointment),
          AppSpacing.gapV(AppSpacing.base),
          // The roster is read here so the list repaints after a review or a
          // cancellation; the cards receive plain values.
          Obx(() {
            final past = controller.appointments
                .where((a) => a.status == AppointmentStatus.completed)
                .toList();

            if (past.isEmpty) {
              return AppEmptyState(
                icon: Icons.event_available_outlined,
                title: AppStrings.noTestsYet.tr,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final appointment in past) ...[
                  AppointmentHistoryCard(
                    appointment: appointment,
                    isJoinable: false,
                    onBookAgain: () => controller.bookAgain(appointment),
                    onReview: () => _review(context),
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

  Future<void> _review(BuildContext context) => ReviewDialog.show(context);
}
