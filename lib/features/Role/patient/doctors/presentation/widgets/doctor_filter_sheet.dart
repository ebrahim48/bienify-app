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
import '../../domain/entities/doctor_category.dart';

/// Price and rating filters for a doctor list.
///
/// Local state, committed on Apply — dragging the slider should not refilter
/// the list underneath on every frame.
///
/// ```dart
/// final applied = await DoctorFilterSheet.show(context, current: filter);
/// if (applied != null) controller.applyFilter(applied);
/// ```
class DoctorFilterSheet extends StatefulWidget {
  const DoctorFilterSheet({super.key, required this.current});

  final DoctorFilter current;

  /// Resolves to the new filter, or `null` if dismissed.
  static Future<DoctorFilter?> show(
    BuildContext context, {
    required DoctorFilter current,
  }) {
    return showModalBottomSheet<DoctorFilter>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2.r),
        ),
      ),
      builder: (_) => DoctorFilterSheet(current: current),
    );
  }

  @override
  State<DoctorFilterSheet> createState() => _DoctorFilterSheetState();
}

class _DoctorFilterSheetState extends State<DoctorFilterSheet> {
  late RangeValues _price = RangeValues(
    widget.current.minPrice,
    widget.current.maxPrice,
  );
  late Set<int> _ratings = {...widget.current.ratings};

  /// Left column then right, as laid out in the design.
  static const List<int> _leftStars = [5, 4, 3];
  static const List<int> _rightStars = [2, 1];

  void _toggle(int stars) {
    setState(() {
      if (!_ratings.remove(stars)) _ratings.add(stars);
    });
  }

  void _reset() {
    setState(() {
      _price = const RangeValues(0, DoctorFilter.maxSupportedPrice);
      _ratings = {};
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      DoctorFilter(
        minPrice: _price.start,
        maxPrice: _price.end,
        ratings: _ratings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding.w,
        AppSpacing.sm.h,
        AppSpacing.screenPadding.w,
        AppSpacing.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(),
              radius: AppSizes.xl2.r,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xs2.w),
                child: Icon(
                  Icons.close_rounded,
                  size: AppSizes.xl2.w,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ),
          Text(
            AppStrings.priceRange.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_price.start.round()}',
                style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
              ),
              Text(
                '\$${_price.end.round()}',
                style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: AppColors.primary500,
              inactiveTrackColor: AppColors.gray100,
              thumbColor: AppColors.primary500,
              overlayColor: AppColors.primary500.withValues(alpha: 0.12),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 7,
              ),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: RangeSlider(
              values: _price,
              max: DoctorFilter.maxSupportedPrice,
              onChanged: (value) => setState(() => _price = value),
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            AppStrings.rating.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _StarColumn(stars: _leftStars, selected: _ratings, onToggle: _toggle)),
              Expanded(child: _StarColumn(stars: _rightStars, selected: _ratings, onToggle: _toggle)),
            ],
          ),
          AppSpacing.gapV(AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: AppStrings.reset.tr,
                  onTap: _reset,
                  background: AppColors.gray50,
                  ink: AppColors.gray900,
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: _SheetButton(
                  label: AppStrings.apply.tr,
                  onTap: _apply,
                  background: AppColors.actionFill,
                  ink: AppColors.actionLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarColumn extends StatelessWidget {
  const _StarColumn({
    required this.stars,
    required this.selected,
    required this.onToggle,
  });

  final List<int> stars;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final star in stars)
          _StarCheckbox(
            stars: star,
            isChecked: selected.contains(star),
            onTap: () => onToggle(star),
          ),
      ],
    );
  }
}

class _StarCheckbox extends StatelessWidget {
  const _StarCheckbox({
    required this.stars,
    required this.isChecked,
    required this.onTap,
  });

  final int stars;
  final bool isChecked;
  final VoidCallback onTap;

  static const double _box = 22;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _box.w,
              height: _box.w,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.actionFill : AppColors.surface,
                borderRadius: AppRadius.rMd,
                border: Border.all(
                  color: isChecked
                      ? AppColors.actionFill
                      : AppColors.gray200,
                  width: AppSizes.borderWidth,
                ),
              ),
              child: isChecked
                  ? Icon(
                      Icons.check_rounded,
                      size: AppSizes.lg.w,
                      color: AppColors.white,
                    )
                  : null,
            ),
            AppSpacing.gapH(AppSpacing.xs),
            Text(
              AppStrings.starCount.trParams({'count': '$stars'}),
              style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.ink,
  });

  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.xl5.h,
          alignment: Alignment.center,
          child: Text(label, style: AppTextStyles.titleSmall.rc(ink)),
        ),
      ),
    );
  }
}
