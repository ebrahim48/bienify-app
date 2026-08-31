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

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/models/delivery_address.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../../../../core/services/device_location_service.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../chat/presentation/widgets/attachment_sheet.dart';
import '../../../profile/domain/repositories/account_repository.dart';

/// What the dialog resolves to: an address, and whether it should replace the
/// one on the patient's profile.
///
/// The two are separate because a checkout change is normally for *that*
/// delivery — sending one parcel to the office should not move the patient's
/// home address, and every later order with it.
class LocationEdit {
  const LocationEdit({required this.address, required this.saveToProfile});

  final DeliveryAddress address;
  final bool saveToProfile;
}


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

  String? _doorImageKey;
  bool _uploading = false;

  /// The pin, carried through the edit so saving does not drop one the patient
  /// took on a previous visit.
  double? _lat;
  double? _lng;
  bool _locating = false;

  /// Off by default: a change made at checkout is for that delivery.
  bool _saveToProfile = false;


  static const _allowedExtensions = {'jpg', 'jpeg', 'png'};

  @override
  void initState() {
    super.initState();

    _doorImage = widget.address.doorImageName;

    _doorImageKey = widget.address.doorImageKey;
    _lat = widget.address.lat;
    _lng = widget.address.lng;

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

  /// Pins where the patient actually is.
  ///
  /// The server geocodes the typed line when no pin is sent, but geocoding
  /// free text is a guess — and with no Maps key configured it returns nothing
  /// at all, which is why most orders have had no destination and the courier
  /// map no road to draw.
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final fix = await Get.find<DeviceLocationService>().currentPosition(
        onRefused: (reason) => AppSnackbar.info(
          switch (reason) {
            DeviceLocationRefusal.serviceOff =>
              AppStrings.locationServiceOff.tr,
            DeviceLocationRefusal.denied => AppStrings.locationDenied.tr,
            DeviceLocationRefusal.blocked => AppStrings.locationBlocked.tr,
            DeviceLocationRefusal.noFix => AppStrings.locationNoFix.tr,
          },
        ),
      );
      if (fix == null || !mounted) return;
      setState(() {
        _lat = fix.lat;
        _lng = fix.lng;
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _save() {
    Navigator.of(context).pop(

      DeliveryAddress(
        line1: widget.address.line1,
        line2: widget.address.line2,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        doorImageName: _doorImage,

      LocationEdit(
        address: DeliveryAddress(
          line1: line1,
          line2: _line2.text.trim(),
          city: _city.text.trim(),
          lat: _lat,
          lng: _lng,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          doorImageKey: _doorImageKey,
        ),
        // Not offered means this dialog *is* the profile editor, so the edit
        // always lands on the profile.
        saveToProfile: widget.offerSaveToProfile ? _saveToProfile : true,

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
          // The pin, above the door photo: both help the courier find the
          // door, and this is the one the map needs.
          _Field(
            onTap: _useCurrentLocation,
            child: Row(
              children: [
                Icon(
                  _lat == null
                      ? Icons.my_location_outlined
                      : Icons.location_on,
                  size: AppSizes.lg.w,
                  color: _lat == null
                      ? AppColors.gray400
                      : AppColors.primary600,
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Expanded(
                  child: Text(
                    _locating
                        ? AppStrings.locating.tr
                        : _lat == null
                        ? AppStrings.useCurrentLocation.tr
                        : AppStrings.locationPinned.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(
                      _lat == null ? AppColors.gray400 : AppColors.gray900,
                    ),
                  ),
                ),
                if (_locating)
                  SizedBox(
                    width: AppSizes.lg.w,
                    height: AppSizes.lg.w,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.borderWidth * 2,
                      color: AppColors.primary600,
                    ),
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
