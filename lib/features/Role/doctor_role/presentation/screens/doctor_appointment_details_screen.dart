import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../patient/medical_vault/presentation/widgets/uploaded_document_card.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_appointments_controller.dart';

/// One booking, with whatever the patient attached to it.
///
/// The attachment card is the medical vault's `UploadedDocumentCard` — the
/// patient's All Prescriptions draws the identical row.
class DoctorAppointmentDetailsScreen
    extends GetView<DoctorAppointmentsController> {
  const DoctorAppointmentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.appointmentDetails.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Obx(() {
            final appointment = controller.selected.value;
            if (appointment == null) return const SizedBox.shrink();
            return _PatientCard(appointment: appointment);
          }),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.patientsPrescription.tr,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(() {
            final documents = controller.patientDocuments.toList();
            if (documents.isEmpty) {
              return AppEmptyState(
                icon: Icons.folder_open_outlined,
                title: AppStrings.noUploadsYet.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final document in documents) ...[
                  UploadedDocumentCard(
                    document: document,
                    dateLabel: controller.shortDateLabel(document.uploadedOn),
                    onView: () => controller.viewDocument(document),
                    onRemove: () => controller.removeDocument(document),
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
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.appointment});

  final DoctorAppointment appointment;

  static const double _avatar = 56;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
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
                        style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                      ),
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
