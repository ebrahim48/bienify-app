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
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/blurred_dialog.dart';
import '../../domain/entities/test_request.dart';

/// "Choose Order" — the sheet between a patient and the request wizard.
///
/// Returns the kind chosen, or null if it was dismissed.
class ChooseOrderSheet extends StatefulWidget {
  const ChooseOrderSheet({super.key});

  /// Over the blurred page, as the design draws it — not the plain scrim
  /// `showModalBottomSheet` gives on its own.
  static Future<OrderKind?> show(BuildContext context) {
    return showBlurredSheet<OrderKind>(
      context: context,
      builder: (_) => const ChooseOrderSheet(),
    );
  }

  @override
  State<ChooseOrderSheet> createState() => _ChooseOrderSheetState();
}

class _ChooseOrderSheetState extends State<ChooseOrderSheet> {
  /// Local, not in a controller: the choice does not outlive the sheet, and
  /// the wizard is built from it only once Next is pressed.
  OrderKind _kind = OrderKind.lab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base.w,
        AppSpacing.md.h,
        AppSpacing.base.w,
        AppSpacing.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.chooseOrder.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.md),
          // No `stretch` here: the Column above sizes itself to its children,
          // so stretching a Row inside it asks for an infinite height. The
          // cards set their own.
          Row(
            children: [
              Expanded(
                child: _KindCard(
                  icon: Icons.science_outlined,
                  // The sheet is labelled "Lab Order / Radiology Order" while
                  // laboratory is chosen and "Lab Test / Radiology" once
                  // imaging is, which is how the two designs differ.
                  label: _kind == OrderKind.lab
                      ? AppStrings.labOrder.tr
                      : AppStrings.labTest.tr,
                  isSelected: _kind == OrderKind.lab,
                  onTap: () => setState(() => _kind = OrderKind.lab),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: _KindCard(
                  icon: Icons.monitor_heart_outlined,
                  label: _kind == OrderKind.lab
                      ? AppStrings.radiologyOrder.tr
                      : AppStrings.radiology.tr,
                  isSelected: _kind == OrderKind.radiology,
                  onTap: () => setState(() => _kind = OrderKind.radiology),
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.md),
          AppButton(
            label: AppStrings.next.tr,
            radius: AppRadius.xl,
            onPressed: () => Navigator.of(context).pop(_kind),
          ),
        ],
      ),
    );
  }
}

/// Glyph over a label, selected in the palest blue with a navy outline.
class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _height = 116;

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
              color: isSelected
                  ? AppColors.actionFill
                  : AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.xl3.w, color: AppColors.gray900),
              AppSpacing.gapV(AppSpacing.sm),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
