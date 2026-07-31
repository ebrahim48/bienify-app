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
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../doctor_role/presentation/widgets/app_dropdown_field.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../controllers/shop_medicines_controller.dart';

/// Add Medicine and Edit Medicine are one screen.
///
/// The designs are identical apart from the title and the button — whether
/// [ShopMedicinesController.editing] holds a row decides both.
class MedicineFormScreen extends GetView<ShopMedicinesController> {
  const MedicineFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: Obx(
        () => AppTopBar(
          title: controller.editing.value == null
              ? AppStrings.addMedicine.tr
              : AppStrings.editMedicine.tr,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          AppCard(
            hasShadow: false,
            padding: EdgeInsets.all(AppSpacing.base.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Label(AppStrings.medicineNameLabel.tr),
                _Field(
                  initialText: controller.name.value,
                  hint: AppStrings.medicineNameHint.tr,
                  onChanged: (value) => controller.name.value = value,
                ),
                AppSpacing.gapV(AppSpacing.sm),
                _Label(AppStrings.categoryLabel.tr),
                Obx(
                  () => AppDropdownField(
                    value: controller.category.value,
                    options: PharmacyShopData.categories,
                    onChanged: controller.selectCategory,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.sm),
                _Label(AppStrings.medicineImageLabel.tr),
                _Field(
                  hint: AppStrings.medicineImageHint.tr,
                  onChanged: (value) => controller.imageName.value = value,
                  trailing: Icon(
                    Icons.cloud_upload_outlined,
                    size: AppSizes.xl.w,
                    color: AppColors.gray600,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.sm),
                _Label(AppStrings.priceUsdLabel.tr),
                _Field(
                  initialText: controller.price.value,
                  hint: '0.00',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => controller.price.value = value,
                ),
                AppSpacing.gapV(AppSpacing.sm),
                _Label(AppStrings.stockQuantityLabel.tr),
                _Field(
                  initialText: controller.stock.value,
                  hint: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => controller.stock.value = value,
                ),
                AppSpacing.gapV(AppSpacing.sm),
                _Label(AppStrings.expiryDateLabel.tr),
                _Field(
                  initialText: controller.expiry.value,
                  hint: '',
                  onChanged: (value) => controller.expiry.value = value,
                ),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => AppButton(
              label: controller.editing.value == null
                  ? AppStrings.addMedicine.tr
                  : AppStrings.updateMedicine.tr,
              onPressed: controller.submit,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Small capitalised caption above a field.
class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
    child: Text(
      label,
      style: AppTextStyles.labelMedium.rw(AppColors.gray500, FontWeight.w500),
    ),
  );
}

/// The form's own input: a paler fill than [AppTextField], which is what the
/// design draws inside this card.
class _Field extends StatefulWidget {
  const _Field({
    required this.hint,
    required this.onChanged,
    this.initialText,
    this.keyboardType,
    this.trailing,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String? initialText;
  final TextInputType? keyboardType;
  final Widget? trailing;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  /// Owned here: a `TextField` cannot be seeded any other way, and a GetX
  /// controller holding it would be disposed out from under the route.
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.shopFieldFill,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.fieldBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              cursorColor: AppColors.primary800,
              style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
              ),
            ),
          ),
          ?widget.trailing,
        ],
      ),
    );
  }
}
