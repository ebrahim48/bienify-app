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
import '../../../../../core/utils/time_format.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../../../core/widgets/photo_upload_box.dart';
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
                const _ImageTile(),
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
                const _ExpiryField(),
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

/// The product photo: tap to take or choose one, which uploads at once.
///
/// Shows, in order of preference, the photo just picked, the one the server
/// already holds for this medicine, or an empty tile asking for one.
class _ImageTile extends GetView<ShopMedicinesController> {
  const _ImageTile();

  static const double _height = 140;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (controller.isUploadingImage.value) return;
        final file = await pickPhoto(context);
        if (file != null) await controller.attachImage(file);
      },
      child: Container(
        height: _height.h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.shopFieldFill,
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: AppColors.fieldBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        // The reads sit inside the `Obx`, not in a child's build.
        child: Obx(() {
          final picked = controller.pickedImage.value;
          final stored = controller.editing.value?.imageUrl;
          final bundled = controller.editing.value?.imageAsset;
          final uploading = controller.isUploadingImage.value;

          final Widget? photo = picked != null
              ? Image.file(picked, fit: BoxFit.cover)
              : stored != null
              ? Image.network(
                  stored,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _EmptyImage(),
                )
              // The sample shelf's picture, so the form matches the row.
              : bundled != null
              ? Image.asset(bundled, fit: BoxFit.cover)
              : null;
          if (photo == null) return const _EmptyImage();

          return Stack(
            fit: StackFit.expand,
            children: [
              photo,
              if (uploading)
                ColoredBox(
                  color: AppColors.gray900.withValues(alpha: 0.45),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.white),
                  ),
                )
              else
                Positioned(
                  right: AppSpacing.xs.w,
                  bottom: AppSpacing.xs.h,
                  child: const _ReplacePill(),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _EmptyImage extends StatelessWidget {
  const _EmptyImage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: AppSizes.xl2.w,
          color: AppColors.gray600,
        ),
        AppSpacing.gapV(AppSpacing.xs2),
        Text(
          AppStrings.medicineImageHint.tr,
          style: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ],
    );
  }
}

class _ReplacePill extends StatelessWidget {
  const _ReplacePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs.w,
        vertical: AppSpacing.xxs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray900.withValues(alpha: 0.6),
        borderRadius: AppRadius.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh_rounded,
            size: AppSizes.base.w,
            color: AppColors.white,
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          Text(
            AppStrings.replacePhoto.tr,
            style: AppTextStyles.labelMedium.rc(AppColors.white),
          ),
        ],
      ),
    );
  }
}

/// The expiry, chosen on a calendar rather than typed — a typed date is a
/// format to get wrong, and the server needs a real day.
class _ExpiryField extends GetView<ShopMedicinesController> {
  const _ExpiryField();

  Future<void> _open(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.calendarInitial,
      firstDate: controller.calendarFirst,
      lastDate: controller.calendarLast,
      helpText: AppStrings.selectExpiryDate.tr,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.actionFill,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.selectExpiry(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: AppRadius.rLg,
      child: Container(
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
              child: Obx(() {
                final day = controller.expiresOn.value;
                return Text(
                  day == null
                      ? AppStrings.selectExpiryDate.tr
                      : TimeFormat.date(day),
                  style: AppTextStyles.bodyLarge.rc(
                    day == null ? AppColors.fieldHint : AppColors.authInk,
                  ),
                );
              }),
            ),
            Icon(
              Icons.calendar_month_outlined,
              size: AppSizes.xl.w,
              color: AppColors.gray600,
            ),
          ],
        ),
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
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final String? initialText;
  final TextInputType? keyboardType;

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
        ],
      ),
    );
  }
}
