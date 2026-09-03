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
///
/// The street lines used to be `Text` widgets, so the dialog that offered to
/// add a location could not accept one — it round-tripped whatever it was
/// given, which for a patient with nothing saved was the empty string.
class LocationDialog extends StatefulWidget {
  const LocationDialog({
    super.key,
    required this.address,
    required this.isEditing,
    this.offerSaveToProfile = false,
  });

  final DeliveryAddress address;
  final bool isEditing;

  /// Whether to offer "Also save to my profile".
  ///
  /// True at checkout, where the edit applies to this delivery unless the
  /// patient says otherwise. False when the dialog *is* the profile editor,
  /// where saving is the whole point and a toggle would be nonsense.
  final bool offerSaveToProfile;

  /// Resolves to the edit, or `null` if dismissed.
  static Future<LocationEdit?> show(
    BuildContext context, {
    required DeliveryAddress address,
    required bool isEditing,
    bool offerSaveToProfile = false,
  }) {
    return showBlurredDialog<LocationEdit>(
      context: context,
      builder: (_) => LocationDialog(
        address: address,
        isEditing: isEditing,
        offerSaveToProfile: offerSaveToProfile,
      ),
    );
  }

  @override
  State<LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
  late final TextEditingController _line1 = TextEditingController(
    text: widget.address.line1,
  );
  late final TextEditingController _line2 = TextEditingController(
    text: widget.address.line2,
  );
  late final TextEditingController _city = TextEditingController(
    text: widget.address.city,
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.address.note ?? '',
  );

  String? _doorImageKey;
  bool _uploading = false;

  /// The pin, carried through the edit so saving does not drop one the patient
  /// took on a previous visit.
  double? _lat;
  double? _lng;
  bool _locating = false;

  /// Off by default: a change made at checkout is for that delivery.
  bool _saveToProfile = false;

  /// Set when the patient tries to save with no street, so the requirement is
  /// stated where it is broken rather than in a snackbar over the dialog.
  String? _line1Error;

  @override
  void initState() {
    super.initState();
    _doorImageKey = widget.address.doorImageKey;
    _lat = widget.address.lat;
    _lng = widget.address.lng;
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Uploads a photo of the door so the courier can recognise it.
  ///
  /// The same presign-then-PUT the avatar and credential flows use. It used
  /// to set the literal string 'door.jpg', so the field looked filled and no
  /// image existed anywhere.
  Future<void> _attachDoorImage() async {
    if (_uploading) return;

    final source = await AttachmentSheet.show(context);
    if (source == null) return;

    setState(() => _uploading = true);
    try {
      final picked = await Get.find<AttachmentPickerService>().pick(source);
      if (picked == null) return;

      final key = await Get.find<AccountRepository>().uploadDoorImage(
        path: picked.file.path,
        mimeType: picked.mime,
      );
      if (mounted) setState(() => _doorImageKey = key);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
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
    final line1 = _line1.text.trim();
    if (line1.isEmpty) {
      setState(() => _line1Error = AppStrings.streetRequired.tr);
      return;
    }

    Navigator.of(context).pop(
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

  /// The shared field decoration: `_Field` already draws the border, so the
  /// input inside it must not draw a second one.
  InputDecoration _plain(String hint) => InputDecoration(
    isDense: true,
    border: InputBorder.none,
    contentPadding: EdgeInsets.zero,
    hintText: hint,
    hintStyle: AppTextStyles.bodyLarge.rc(AppColors.gray400),
  );

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
            child: TextField(
              controller: _line1,
              autofocus: widget.address.line1.isEmpty,
              textCapitalization: TextCapitalization.words,
              cursorColor: AppColors.primary800,
              style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              onChanged: (_) {
                if (_line1Error != null) setState(() => _line1Error = null);
              },
              decoration: _plain(AppStrings.streetAndNumber.tr),
            ),
          ),
          if (_line1Error != null) ...[
            AppSpacing.gapV(AppSpacing.xxs),
            Text(
              _line1Error!,
              style: AppTextStyles.bodySmall.rc(AppColors.error),
            ),
          ],
          AppSpacing.gapV(AppSpacing.xs),
          _Field(
            child: TextField(
              controller: _line2,
              textCapitalization: TextCapitalization.words,
              cursorColor: AppColors.primary800,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              decoration: _plain(AppStrings.apartmentOrFloor.tr),
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
            child: TextField(
              controller: _city,
              textCapitalization: TextCapitalization.words,
              cursorColor: AppColors.primary800,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              decoration: _plain(AppStrings.cityLabel.tr),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Field(
            onTap: _attachDoorImage,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _uploading
                        ? AppStrings.uploading.tr
                        : _doorImageKey == null
                        ? AppStrings.uploadDoorImage.tr
                        : AppStrings.doorPhotoAttached.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(
                      _doorImageKey == null
                          ? AppColors.gray400
                          : AppColors.gray900,
                    ),
                  ),
                ),
                if (_uploading)
                  SizedBox(
                    width: AppSizes.lg.w,
                    height: AppSizes.lg.w,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.borderWidth * 2,
                      color: AppColors.primary600,
                    ),
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
              decoration: _plain(AppStrings.enterNote.tr),
            ),
          ),
          if (widget.offerSaveToProfile) ...[
            AppSpacing.gapV(AppSpacing.xs),
            InkWell(
              onTap: () => setState(() => _saveToProfile = !_saveToProfile),
              borderRadius: AppRadius.rLg,
              child: Row(
                children: [
                  Checkbox(
                    value: _saveToProfile,
                    onChanged: (v) => setState(() => _saveToProfile = v ?? false),
                    activeColor: AppColors.primary600,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  AppSpacing.gapH(AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      AppStrings.alsoSaveToProfile.tr,
                      style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
