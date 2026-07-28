import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/doctor_details_controller.dart';
import '../widgets/availability_picker.dart';
import '../widgets/doctor_hero.dart';
import '../widgets/doctor_info_grid.dart';
import '../widgets/doctor_summary.dart';

/// Doctor profile with the booking picker and the Book Appointment action.
class DoctorDetailsScreen extends GetView<DoctorDetailsController> {
  const DoctorDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.doctorDetails.tr),
      child: Obx(() {
        final details = controller.details.value;
        final availability = controller.availability.value;

        if (controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl5.h),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (details == null || availability == null) {
          return _Failure(controller: controller);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.xs),
            DoctorHero(onMessage: controller.openChat),
            AppSpacing.gapV(AppSpacing.base),
            DoctorSummary(doctor: details.doctor),
            AppSpacing.gapV(AppSpacing.base),
            DoctorInfoGrid(details: details),
            AppSpacing.gapV(AppSpacing.lg),
            Text(
              AppStrings.biography.tr,
              style: AppTextStyles.titleLarge.rc(AppColors.black),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Text(
              details.biography,
              style: AppTextStyles.bodyLarge.rc(AppColors.textSecondary),
            ),
            AppSpacing.gapV(AppSpacing.lg),
            // Selections are read here, inside the `Obx`, so a tap actually
            // repaints the chips.
            AvailabilityPicker(
              availability: availability,
              selectedMonth: controller.selectedMonth.value,
              onMonthSelected: controller.selectMonth,
              selectedDay: controller.selectedDay.value,
              onDaySelected: controller.selectDay,
              slots: controller.selectedDay.value?.slots ?? const [],
              selectedSlot: controller.selectedSlot.value,
              onSlotSelected: controller.selectSlot,
            ),
            AppSpacing.gapV(AppSpacing.xl2),
            AppButton(
              label: AppStrings.bookAppointment.tr,
              onPressed: controller.bookAppointment,
            ),
            AppSpacing.gapV(AppSpacing.lg),
          ],
        );
      }),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.controller});

  final DoctorDetailsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xl5.h),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48.w, color: AppColors.gray300),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            controller.errorMessage.value ?? AppStrings.somethingWentWrong.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.base),
          AppButton(
            label: AppStrings.retry.tr,
            expanded: false,
            onPressed: controller.load,
          ),
        ],
      ),
    );
  }
}
