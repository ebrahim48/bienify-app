import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/appointment.dart';
import '../controllers/appointments_controller.dart';
import '../widgets/appointment_card.dart';

/// Appointments tab: upcoming and past bookings behind a segmented switch.
class AppointmentsScreen extends GetView<AppointmentsController> {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xl),
          Text(
            AppStrings.myAppointments.tr,
            style: AppTextStyles.titleLarge.rc(AppColors.black),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => _SegmentedSwitch(
              selectedIndex: controller.selectedTab.value,
              labels: [AppStrings.upcoming.tr, AppStrings.past.tr],
              onSelected: controller.selectTab,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = controller.visible.toList();
              if (items.isEmpty) return _EmptyState(controller: controller);

              return ListView.separated(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
                itemCount: items.length,
                separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.sm),
                itemBuilder: (context, index) => AppointmentCard(
                  appointment: items[index],
                  showJoin: items[index].status == AppointmentStatus.upcoming,
                  onJoin: () => controller.join(items[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Two-option pill switch shared by this screen's Upcoming / Past filter.
class _SegmentedSwitch extends StatelessWidget {
  const _SegmentedSwitch({
    required this.selectedIndex,
    required this.labels,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.xl5.h,
      padding: EdgeInsets.all(AppSpacing.xs2.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rFull,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == selectedIndex
                        ? AppColors.actionFill
                        : AppColors.transparent,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: Text(
                    labels[index],
                    style: AppTextStyles.labelLarge.rc(
                      index == selectedIndex
                          ? AppColors.white
                          : AppColors.authInk,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final AppointmentsController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48.w,
            color: AppColors.gray300,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            AppStrings.noAppointmentsYet.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.base),
          AppButton(
            label: AppStrings.findADoctor.tr,
            expanded: false,
            onPressed: controller.findDoctor,
          ),
        ],
      ),
    );
  }
}
