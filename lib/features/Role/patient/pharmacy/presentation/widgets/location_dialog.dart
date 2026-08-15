import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/services/photo_picker_service.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/mime_type.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/blurred_dialog.dart';
import '../../../medical_vault/domain/entities/medical_record.dart';
import '../../../medical_vault/domain/repositories/vault_repository.dart';
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
  bool _isUploadingDoorImage = false;

  final VaultRepository _vault = Get.find<VaultRepository>();
  final PhotoPickerService _photoPicker = PhotoPickerService();

  static const _allowedExtensions = {'jpg', 'jpeg', 'png'};

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

  Future<void> _attachDoorImage() async {
    if (_isUploadingDoorImage) return;
    final file = await _photoPicker.pick(PhotoSource.gallery);
    if (file == null) return;

    final fileName = file.path.split('/').last;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    if (!_allowedExtensions.contains(extension)) {
      AppSnackbar.error(AppStrings.onlyJpgPngAllowed.tr);
      return;
    }

    setState(() => _isUploadingDoorImage = true);
    try {
      final document = await _vault.uploadDocument(
        bytes: await file.readAsBytes(),
        fileName: fileName,
        contentType: contentTypeForPath(fileName),
        title: 'Delivery door photo — $fileName',
        type: VaultRecordType.other,
      );
      setState(() => _doorImage = document.fileName);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      setState(() => _isUploadingDoorImage = false);
    }
  }

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
            onTap: _isUploadingDoorImage ? null : _attachDoorImage,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isUploadingDoorImage
                        ? AppStrings.uploading.tr
                        : _doorImage ?? AppStrings.uploadDoorImage.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(
                      _doorImage == null
                          ? AppColors.gray400
                          : AppColors.gray900,
                    ),
                  ),
                ),
                if (_isUploadingDoorImage)
                  SizedBox(
                    width: AppSizes.xl.w,
                    height: AppSizes.xl.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
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
