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
import 'signature_pad.dart';

/// The pieces the ordering wizard is assembled from. Kept together because
/// the lab and imaging flows each use most of them, in a different order.

/// A three-segment bar showing how far through the wizard the doctor is.
class OrderProgressBar extends StatelessWidget {
  const OrderProgressBar({
    super.key,
    required this.step,
    required this.stepCount,
  });

  /// Zero-based; every segment up to and including it is filled.
  final int step;
  final int stepCount;

  static const double _height = 5;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < stepCount; index++) ...[
          if (index > 0) AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Container(
              height: _height.h,
              decoration: BoxDecoration(
                color: index <= step
                    ? AppColors.actionFill
                    : AppColors.progressTrack,
                borderRadius: AppRadius.rFull,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The pale-blue note explaining that the patient books the test themselves.
class OrderRequestBanner extends StatelessWidget {
  const OrderRequestBanner({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  static const double _tile = 56;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.authPanelSoft,
        borderRadius: AppRadius.rXl2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _tile.w,
            height: _tile.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.rXl,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: AppSizes.xl2.w,
              color: AppColors.actionFill,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  AppStrings.externalBookingNote.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.link),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of a test catalogue: white, or outlined navy once chosen.
class OrderChoiceRow extends StatelessWidget {
  const OrderChoiceRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.authPanelSoft : AppColors.surface,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: _height.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl,
            border: Border.all(
              color: isSelected ? AppColors.actionFill : AppColors.transparent,
              width: AppSizes.borderWidth,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
            ),
          ),
        ),
      ),
    );
  }
}

/// A label above a field, with an optional "(Optional)" qualifier drawn
/// smaller beside it the way the design sets it.
class OrderFieldLabel extends StatelessWidget {
  const OrderFieldLabel(this.label, {super.key, this.isOptional = false});

  final String label;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: AppTextStyles.titleLarge.rw(
                AppColors.gray900,
                FontWeight.w400,
              ),
            ),
            if (isOptional)
              TextSpan(
                text: ' ${AppStrings.optional.tr}',
                style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
              ),
          ],
        ),
      ),
    );
  }
}

/// Multi-line white box. Owns its text controller, so nothing is disposed out
/// from under it when the wizard moves on.
class OrderNoteField extends StatelessWidget {
  const OrderNoteField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.lines = 3,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.sm.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: TextField(
        onChanged: onChanged,
        maxLines: lines,
        minLines: lines,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ),
    );
  }
}

/// The signature box: a pad the doctor actually signs on, a red Clear above
/// it and a blue Save under it.
class ElectricSignField extends StatefulWidget {
  const ElectricSignField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.onSave,
  });

  final String hint;

  /// Whether the pad has ink on it.
  final ValueChanged<bool> onChanged;

  final VoidCallback onSave;

  @override
  State<ElectricSignField> createState() => _ElectricSignFieldState();
}

class _ElectricSignFieldState extends State<ElectricSignField> {
  /// Clear is drawn outside the pad, so the box reaches into it to wipe the
  /// ink — the strokes belong to the pad, not to this box.
  final GlobalKey<SignaturePadState> _pad = GlobalKey<SignaturePadState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkResponse(
              onTap: () => _pad.currentState?.clear(),
              radius: AppSizes.xl2.r,
              child: Text(
                AppStrings.clear.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.logoutFill),
              ),
            ),
          ),
          SignaturePad(
            key: _pad,
            hint: widget.hint,
            onChanged: widget.onChanged,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: _SavePill(onTap: widget.onSave),
          ),
        ],
      ),
    );
  }
}

class _SavePill extends StatelessWidget {
  const _SavePill({required this.onTap});

  final VoidCallback onTap;

  static const double _height = 36;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // No `alignment` on the container: with one it would take the whole
        // width Align offers instead of hugging its label.
        child: Container(
          height: _height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Center(
            widthFactor: 1,
            child: Text(
              AppStrings.save.tr,
              style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
            ),
          ),
        ),
      ),
    );
  }
}

/// Routine / Urgent / STAT, side by side.
class PriorityCard extends StatelessWidget {
  const PriorityCard({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _height = 76;

  @override
  Widget build(BuildContext context) {
    final ink = isSelected ? AppColors.actionFill : AppColors.stepInk;

    return Material(
      color: isSelected ? AppColors.authPanelSoft : AppColors.transparent,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: _height.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl,
            border: Border.all(
              color: isSelected ? AppColors.actionFill : AppColors.gray100,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.xl2.w, color: ink),
              AppSpacing.gapV(AppSpacing.xs2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(
                  isSelected ? AppColors.actionFill : AppColors.gray900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
