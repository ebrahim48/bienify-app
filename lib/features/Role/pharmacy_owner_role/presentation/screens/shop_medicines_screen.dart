import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_svg_icon.dart';
import '../../../patient/doctors/presentation/widgets/doctor_search_field.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../controllers/shop_medicines_controller.dart';

/// What is on the shelf: search, then a row per product.
class ShopMedicinesScreen extends GetView<ShopMedicinesController> {
  const ShopMedicinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.medicinesTitle.tr,
                  style: AppTextStyles.headlineLarge.rc(AppColors.authInk),
                ),
              ),
              AppButton(
                label: AppStrings.addLabel.tr,
                expanded: false,
                height: 40,
                radius: AppRadius.lg,
                icon: Icon(
                  Icons.add_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.actionLabel,
                ),
                onPressed: controller.add,
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          // The field owns its controller; the screen only listens.
          DoctorSearchField(
            initialText: controller.query.value,
            hintKey: AppStrings.searchMedicines,
            onChanged: (value) => controller.query.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() {
            final rows = controller.visible;
            if (rows.isEmpty) {
              return AppEmptyState(title: AppStrings.noMedicinesYet.tr);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final medicine in rows) ...[
                  _MedicineRow(
                    medicine: medicine,
                    onToggle: (value) =>
                        controller.toggleListed(medicine, value),
                    onEdit: () => controller.edit(medicine),
                    onDelete: () => _confirmDelete(context, medicine),
                  ),
                  AppSpacing.gapV(AppSpacing.xs),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ShopMedicine medicine,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      question: AppStrings.deleteMedicineQuestion.tr,
      confirmLabel: AppStrings.delete.tr,
      denyLabel: AppStrings.cancel.tr,
      confirmColor: AppColors.logoutFill,
    );
    if (confirmed ?? false) controller.remove(medicine);
  }
}

/// Photo, name over its details, then the toggle and the two actions.
class _MedicineRow extends StatelessWidget {
  const _MedicineRow({
    required this.medicine,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopMedicine medicine;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const double _thumb = 48;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.all(AppSpacing.xs.w),
      child: Row(
        children: [
          Container(
            width: _thumb.w,
            height: _thumb.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.shopOrdersSurface,
              borderRadius: AppRadius.rLg,
            ),
            child: medicine.imageAsset == null
                ? Icon(
                    Icons.medication_outlined,
                    size: AppSizes.xl.w,
                    color: AppColors.shopOrdersInk,
                  )
                : Image.asset(medicine.imageAsset!, fit: BoxFit.cover),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(child: _Details(medicine: medicine)),
          AppSpacing.gapH(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: medicine.isListed,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.actionFill,
                onChanged: onToggle,
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAction(
                    onTap: onDelete,
                    // Untinted: the file ships stroked in `logoutFill`.
                    child: AppSvgIcon(AppIcons.delete, size: AppSizes.lg),
                  ),
                  AppSpacing.gapH(AppSpacing.xs2),
                  _IconAction(
                    fill: AppColors.chipSurface,
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.medicine});

  final ShopMedicine medicine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          medicine.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSmall.rc(AppColors.gray900),
        ),
        Text(
          medicine.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
        ),
        AppSpacing.gapV(AppSpacing.xs2),
        Row(
          children: [
            Text(
              medicine.stockLabel,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
            ),
            AppSpacing.gapH(AppSpacing.xs),
            Text(
              medicine.priceLabel,
              style: AppTextStyles.titleSmall.rc(AppColors.gray900),
            ),
          ],
        ),
      ],
    );
  }
}

/// A small square button; the bin has no fill in the design, the pencil does.
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.child,
    required this.onTap,
    this.fill = AppColors.transparent,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color fill;

  static const double _side = 28;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: AppRadius.rMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _side.w,
          height: _side.w,
          child: Center(child: child),
        ),
      ),
    );
  }
}
