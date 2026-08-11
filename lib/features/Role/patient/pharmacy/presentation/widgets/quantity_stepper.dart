import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';

/// `−  1  +` control on medicine rows.
///
/// [decrementIcon] differs between screens: a minus while choosing
/// medicines, a × in the cart where it removes the line.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.decrementIcon = Icons.remove_rounded,
    this.isEnabled = true,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final IconData decrementIcon;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final ink = isEnabled ? AppColors.gray900 : AppColors.gray300;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.w),
      decoration: BoxDecoration(
        color: AppColors.chatFieldFill,
        borderRadius: AppRadius.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: decrementIcon,
            ink: ink,
            onTap: isEnabled ? onDecrement : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs.w),
            child: Text('$quantity', style: AppTextStyles.titleSmall.rc(ink)),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            ink: ink,
            onTap: isEnabled ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.ink, this.onTap});

  final IconData icon;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: AppSizes.xl.r,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xs2.w),
        child: Icon(icon, size: AppSizes.lg.w, color: ink),
      ),
    );
  }
}
