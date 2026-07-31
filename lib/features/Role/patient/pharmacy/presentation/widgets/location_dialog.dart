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
import '../../../../../../core/widgets/blurred_dialog.dart';
import '../../domain/entities/pharmacy.dart';

/// Add or edit the delivery address, over a blurred page.
///
/// One dialog for both: the title and confirm label switch on [isEditing],
/// which is what distinguishes "Add Location" from "Change Location".
class LocationDialog extends StatefulWidget {
  const LocationDialog({
    super.key,
    required this.address,
    required this.isEditing,
  });

  final DeliveryAddress address;
  final bool isEditing;

  /// Resolves to the saved address, or `null` if dismissed.
  static Future<DeliveryAddress?> show(
    BuildContext context, {
    required DeliveryAddress address,
    required bool isEditing,
  }) {
    return showBlurredDialog<DeliveryAddress>(
      context: context,
      builder: (_) => LocationDialog(address: address, isEditing: isEditing),
    );
  }

  @override
  State<LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
  late final TextEditingController _note = TextEditingController(
    text: widget.address.note ?? '',
  );
  String? _doorImage;

  @override
  void initState() {
    super.initState();
    _doorImage = widget.address.doorImageName;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Image picking needs a platform plugin; until one is wired the field
  /// records the intent so the flow stays walkable.
  void _attachDoorImage() => setState(() => _doorImage = 'door.jpg');

  void _save() {
    Navigator.of(context).pop(
      DeliveryAddress(
        line1: widget.address.line1,
        line2: widget.address.line2,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        doorImageName: _doorImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (widget.isEditing
                        ? AppStrings.changeLocation
                        : AppStrings.addLocation)
                    .tr,
                style: AppTextStyles.titleSmall.rc(AppColors.authInk),
              ),
              InkResponse(
                onTap: () => Navigator.of(context).pop(),
                radius: AppSizes.xl2.r,
                child: Icon(
                  Icons.close_rounded,
                  size: AppSizes.xl2.w,
                  color: AppColors.gray900,
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Field(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.address.line1,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  widget.address.line2,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Field(
            onTap: _attachDoorImage,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _doorImage ?? AppStrings.uploadDoorImage.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(
                      _doorImage == null
                          ? AppColors.gray400
                          : AppColors.gray900,
                    ),
                  ),
                ),
                AppSvgIcon(
                  AppIcons.cloudUpload,
                  size: AppSizes.xl,
                  color: AppColors.gray500,
                ),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Field(
            child: TextField(
              controller: _note,
              cursorColor: AppColors.primary800,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: AppStrings.enterNote.tr,
                hintStyle: AppTextStyles.bodyLarge.rc(AppColors.gray400),
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Material(
            color: AppColors.actionFill,
            borderRadius: AppRadius.rLg,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _save,
              child: Container(
                height: AppSizes.controlHeight.h,
                alignment: Alignment.center,
                child: Text(
                  (widget.isEditing
                          ? AppStrings.updateLocation
                          : AppStrings.addLocation)
                      .tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rLg,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm.w,
          vertical: AppSpacing.sm.h,
        ),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rLg,
          border: Border.all(
            color: AppColors.surfaceBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
