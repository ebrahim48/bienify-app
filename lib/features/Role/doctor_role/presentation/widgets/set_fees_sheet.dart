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
import '../../data/static/doctor_practice_data.dart';
import '../controllers/doctor_home_controller.dart';
import 'app_dropdown_field.dart';

/// "Set Fees" — a bottom sheet over the dashboard, as the design shows it.
class SetFeesSheet extends GetView<DoctorHomeController> {
  const SetFeesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.rXl2.topLeft),
      ),
      builder: (_) => const SetFeesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet clear of the keyboard while the fee is typed.
      padding: EdgeInsets.only(
        left: AppSpacing.base.w,
        right: AppSpacing.base.w,
        top: AppSpacing.base.h,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkResponse(
              onTap: () => Navigator.of(context).pop(),
              radius: AppSizes.xl2.r,
              child: Icon(
                Icons.close_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.gray900,
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            AppStrings.selectCurrency.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => AppDropdownField(
              value: controller.currency.value,
              options: DoctorPracticeData.currencies,
              onChanged: controller.selectCurrency,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.consultationFeeLabel.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          // Keyed on the load so the field seeds from the fee that arrived;
          // it owns its text controller and reads [initialText] once.
          Obx(
            () => _FeeField(
              key: ValueKey(controller.feeGeneration.value),
              initialText: controller.consultationFee.value,
              onChanged: (value) => controller.consultationFee.value = value,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          AppButton(
            label: AppStrings.saveConsultationFee.tr,
            onPressed: controller.saveConsultationFee,
          ),
        ],
      ),
    );
  }
}

class _FeeField extends StatefulWidget {
  const _FeeField({super.key, required this.onChanged, this.initialText});

  final ValueChanged<String> onChanged;

  /// Seeds the field with the fee the practice charges now.
  final String? initialText;

  @override
  State<_FeeField> createState() => _FeeFieldState();
}

class _FeeFieldState extends State<_FeeField> {
  /// Owned here so nothing is disposed out from under the sheet.
  late final TextEditingController _text = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.controlHeight.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.fieldBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _text,
        onChanged: widget.onChanged,
        keyboardType: TextInputType.number,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: DoctorPracticeData.defaultFeeHint,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ),
    );
  }
}
