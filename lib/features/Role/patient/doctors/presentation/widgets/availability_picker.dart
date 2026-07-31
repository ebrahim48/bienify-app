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
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../domain/entities/doctor_details.dart';

/// Month strip, day strip and slot grid — the booking picker on Doctor
/// Details.
class AvailabilityPicker extends StatelessWidget {
  const AvailabilityPicker({
    super.key,
    required this.availability,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.selectedDay,
    required this.onDaySelected,
    required this.slots,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  final DoctorAvailability availability;
  final String? selectedMonth;
  final ValueChanged<String> onMonthSelected;

  /// Current selections as **values**, not predicates.
  ///
  /// A predicate would be invoked during this widget's build — outside the
  /// caller's `Obx` — so the observable would never be registered and the
  /// chips would not repaint when the selection changed.
  final AvailableDay? selectedDay;
  final TimeSlot? selectedSlot;

  final ValueChanged<AvailableDay> onDaySelected;
  final List<TimeSlot> slots;
  final ValueChanged<TimeSlot> onSlotSelected;

  static const double _dayWidth = 56;
  static const double _dayHeight = 64;
  static const double _monthHeight = 34;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.selectYearAndDate.tr,
              style: AppTextStyles.titleMedium.rc(AppColors.authInk),
            ),
            Row(
              children: [
                Text(
                  '${availability.year}',
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.gray900,
                ),
              ],
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.sm),
        _MonthStrip(
          months: availability.months,
          selected: selectedMonth,
          onSelected: onMonthSelected,
        ),
        AppSpacing.gapV(AppSpacing.base),
        _DayStrip(
          days: availability.days,
          selectedDay: selectedDay,
          onSelected: onDaySelected,
        ),
        AppSpacing.gapV(AppSpacing.lg),
        Text(
          AppStrings.availableTime.tr,
          style: AppTextStyles.titleMedium.rc(AppColors.authInk),
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs.w,
          runSpacing: AppSpacing.xs.h,
          children: [
            for (final slot in slots)
              _SlotChip(
                slot: slot,
                isSelected: slot.label == selectedSlot?.label,
                onTap: () => onSlotSelected(slot),
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({
    required this.months,
    required this.selected,
    required this.onSelected,
  });

  final List<String> months;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AvailabilityPicker._monthHeight.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: months.length,
        separatorBuilder: (_, _) => AppSpacing.gapH(AppSpacing.xs),
        itemBuilder: (context, index) {
          final month = months[index];
          final isSelected = month == selected;
          return Material(
            color: isSelected ? AppColors.actionFill : AppColors.surface,
            borderRadius: AppRadius.rFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(month),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.base.w,
                  ),
                  child: Center(
                    child: Text(
                      month,
                      style: AppTextStyles.bodyMedium.rc(
                        isSelected ? AppColors.white : AppColors.gray900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.days,
    required this.selectedDay,
    required this.onSelected,
  });

  final List<AvailableDay> days;
  final AvailableDay? selectedDay;
  final ValueChanged<AvailableDay> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Room for the selection ring and the dot beneath the active day.
      height: (AvailabilityPicker._dayHeight + 18).h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: days.length,
        separatorBuilder: (_, _) => AppSpacing.gapH(AppSpacing.xs),
        itemBuilder: (context, index) => _DayChip(
          day: days[index],
          isSelected: days[index].date == selectedDay?.date,
          onTap: () => onSelected(days[index]),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final AvailableDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isSelected ? AppColors.white : AppColors.gray900;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AvailabilityPicker._dayWidth.w,
            height: AvailabilityPicker._dayHeight.h,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.actionFill : AppColors.denyFill,
              borderRadius: AppRadius.rXl,
              // The active day carries a thin outset ring in the design.
              border: isSelected
                  ? Border.all(color: AppColors.white, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.actionFill,
                        spreadRadius: 1.5,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.dayLabel,
                  style: AppTextStyles.titleMedium.rc(ink),
                ),
                Text(
                  day.weekdayLabel,
                  style: AppTextStyles.bodySmall.rc(ink),
                ),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          SizedBox(
            height: AppSizes.sm.h,
            child: isSelected
                ? Container(
                    width: AppSizes.sm.w,
                    height: AppSizes.sm.w,
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = switch ((isSelected, slot.isBooked)) {
      (true, _) => AppColors.white,
      (_, true) => AppColors.gray500,
      _ => AppColors.gray900,
    };

    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.transparent,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: slot.isBooked ? null : onTap,
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
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm.w,
              vertical: AppSpacing.xs.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(AppIcons.clock, size: AppSizes.lg, color: ink),
                AppSpacing.gapH(AppSpacing.xs2 + 2),
                Text(
                  slot.label,
                  style: AppTextStyles.bodyMedium.rc(ink).copyWith(
                    decoration: slot.isBooked
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
