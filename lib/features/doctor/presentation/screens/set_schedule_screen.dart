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
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_schedule_controller.dart';
import '../widgets/app_dropdown_field.dart';

/// Set Schedule: pick a week, then set each day's hours.
class SetScheduleScreen extends GetView<DoctorScheduleController> {
  const SetScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.setSchedule.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          _PickerLabel(AppStrings.selectYear.tr),
          Obx(
            () => AppDropdownField(
              value: controller.year.value,
              options: DoctorPracticeData.years,
              onChanged: controller.selectYear,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _PickerLabel(AppStrings.selectMonth.tr),
          Obx(
            () => AppDropdownField(
              value: controller.month.value,
              options: DoctorPracticeData.months,
              onChanged: controller.selectMonth,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _PickerLabel(AppStrings.selectWeek.tr),
          Obx(
            () => AppDropdownField(
              value: controller.week.value,
              options: DoctorPracticeData.weeks,
              onChanged: controller.selectWeek,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          // The days are read here so both the strip and the cards repaint
          // when a toggle flips or a slot is added.
          Obx(() {
            final days = controller.days.toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayStrip(days: days),
                AppSpacing.gapV(AppSpacing.base),
                for (var index = 0; index < days.length; index++)
                  if (days[index].isOpen) ...[
                    _DayCard(
                      day: days[index],
                      start: controller.startOf(index),
                      end: controller.endOf(index),
                      onToggle: (value) => controller.toggleDay(index, value),
                      onStartChanged: (value) =>
                          controller.setStart(index, value),
                      onEndChanged: (value) => controller.setEnd(index, value),
                      onAdd: () => controller.addSlot(index),
                      onRemoveSlot: (slot) =>
                          controller.removeSlot(index, slot),
                    ),
                    AppSpacing.gapV(AppSpacing.sm),
                  ],
                _WeeklySummary(
                  activeDays: controller.activeDays,
                  totalHours: controller.totalHoursLabel,
                  maxPatients: controller.maxPatients,
                ),
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.base),
          AppButton(
            label: AppStrings.saveSchedule.tr,
            onPressed: controller.save,
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
    child: Text(label, style: AppTextStyles.bodyLarge.rc(AppColors.gray500)),
  );
}

/// The seven day circles. Open days are filled navy; closed ones are muted.
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.days});

  final List<ScheduleDay> days;

  static const double _circle = 40;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days)
          Container(
            width: _circle.w,
            height: _circle.w,
            decoration: BoxDecoration(
              color: day.isOpen ? AppColors.actionFill : AppColors.mutedFill,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.name.substring(0, 1),
                  style: AppTextStyles.labelLarge.rc(
                    day.isOpen ? AppColors.white : AppColors.gray600,
                  ),
                ),
                Text(
                  '${day.dayOfMonth}',
                  style: AppTextStyles.bodySmall.rc(
                    day.isOpen
                        ? AppColors.white.withValues(alpha: 0.8)
                        : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One day: its toggle, a start/end pair with Add, and the slots already set.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.start,
    required this.end,
    required this.onToggle,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onAdd,
    required this.onRemoveSlot,
  });

  final ScheduleDay day;
  final String start;
  final String end;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveSlot;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.name,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
              ),
              Switch.adaptive(
                value: day.isOpen,
                onChanged: onToggle,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.actionFill,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _TimeField(
                  label: AppStrings.start.tr,
                  hint: '2:00 PM',
                  onChanged: onStartChanged,
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              Expanded(
                child: _TimeField(
                  label: AppStrings.end.tr,
                  hint: '3:00 PM',
                  onChanged: onEndChanged,
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              _AddButton(onTap: onAdd),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            AppStrings.currentSlots.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs.w,
            runSpacing: AppSpacing.xs.h,
            children: [
              for (var index = 0; index < day.slots.length; index++)
                _SlotChip(
                  label: day.slots[index].label,
                  onRemove: () => onRemoveSlot(index),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray500)),
        AppSpacing.gapV(AppSpacing.xxs),
        Container(
          height: _height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          decoration: BoxDecoration(
            color: AppColors.mutedFill,
            borderRadius: AppRadius.rFull,
          ),
          alignment: Alignment.center,
          // No controller passed: the field owns its own.
          child: TextField(
            onChanged: onChanged,
            cursorColor: AppColors.primary800,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _TimeField._height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          alignment: Alignment.center,
          child: Text(
            AppStrings.addSlot.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
          ),
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xs2.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.slotSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.bodyLarge.rc(AppColors.slotInk)),
          AppSpacing.gapH(AppSpacing.xs2),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onRemove,
            child: Icon(
              Icons.delete_outline_rounded,
              size: AppSizes.lg.w,
              color: AppColors.slotInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({
    required this.activeDays,
    required this.totalHours,
    required this.maxPatients,
  });

  final int activeDays;
  final String totalHours;
  final int maxPatients;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.tagInfoSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.weeklySummary.tr,
            style: AppTextStyles.labelLarge
                .rc(AppColors.authInk)
                .copyWith(letterSpacing: 0.6),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  value: '$activeDays',
                  label: AppStrings.activeDays.tr,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  value: totalHours,
                  label: AppStrings.totalHours.tr,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  value: '$maxPatients',
                  label: AppStrings.maxPatients.tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.rc(AppColors.actionFill),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
        ),
      ],
    );
  }
}
