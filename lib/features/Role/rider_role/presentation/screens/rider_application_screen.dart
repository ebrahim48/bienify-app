import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../../../core/widgets/photo_upload_box.dart';
import '../../../doctor_role/presentation/widgets/app_dropdown_field.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_application_controller.dart';
import '../widgets/rider_widgets.dart';

/// The five-step rider application.
///
/// The designs draw five screens; they are one page with the same progress
/// bar and Next, so the step decides what sits between them.
class RiderApplicationScreen extends GetView<RiderApplicationController> {
  const RiderApplicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: Obx(
        () => AppTopBar(
          title: controller.title,
          // Walks back through the application before leaving it.
          onBack: () {
            if (!controller.stepBack()) Get.back<void>();
          },
        ),
      ),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RiderProgressBar(
              step: controller.step.value,
              stepCount: RiderApplicationController.stepCount,
            ),
            AppSpacing.gapV(AppSpacing.md),
            _step(controller.step.value),
            AppSpacing.gapV(AppSpacing.md),
            AppButton(label: AppStrings.next.tr, onPressed: controller.next),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _step(int step) => switch (step) {
    0 => const _SelfiePane(),
    1 => const _IdentityPane(),
    2 => const _VehiclePane(),
    3 => const _LocationPane(),
    _ => const _PaymentPane(),
  };
}

/// The greeting and the selfie tile.
class _SelfiePane extends GetView<RiderApplicationController> {
  const _SelfiePane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSpacing.gapV(AppSpacing.md),
        Text(
          AppStrings.heyName.trParams({'name': RiderData.firstName}),
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.rc(AppColors.gray900),
        ),
        AppSpacing.gapV(AppSpacing.xs2),
        Text(
          AppStrings.applyingForRider.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
        ),
        AppSpacing.gapV(AppSpacing.base),
        Obx(
          () => PhotoUploadBox(
            label: AppStrings.takeSelfie.tr,
            icon: Icons.photo_camera_outlined,
            height: 150,
            file: controller.selfie.value,
            onPicked: (file) => controller.selfie.value = file,
          ),
        ),
      ],
    );
  }
}

/// Both sides of the ID card.
class _IdentityPane extends GetView<RiderApplicationController> {
  const _IdentityPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => PhotoRequirementRow(
            title: AppStrings.frontOfIdCard.tr,
            box: PhotoUploadBox(
              label: AppStrings.uploadPhoto.tr,
              height: 116,
              file: controller.idFront.value,
              onPicked: (file) => controller.idFront.value = file,
            ),
          ),
        ),
        AppSpacing.gapV(AppSpacing.base),
        Obx(
          () => PhotoRequirementRow(
            title: AppStrings.backOfIdCard.tr,
            box: PhotoUploadBox(
              label: AppStrings.uploadPhoto.tr,
              height: 116,
              file: controller.idBack.value,
              onPicked: (file) => controller.idBack.value = file,
            ),
          ),
        ),
      ],
    );
  }
}

/// Vehicle type, then its two photos.
class _VehiclePane extends GetView<RiderApplicationController> {
  const _VehiclePane();

  static const Map<VehicleType, IconData> _icons = {
    VehicleType.bicycle: Icons.pedal_bike_rounded,
    VehicleType.bike: Icons.two_wheeler_rounded,
    VehicleType.car: Icons.directions_car_rounded,
  };

  String _label(VehicleType type) => switch (type) {
    VehicleType.bicycle => AppStrings.vehicleBicycle.tr,
    VehicleType.bike => AppStrings.vehicleBike.tr,
    VehicleType.car => AppStrings.vehicleCar.tr,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        RiderFieldLabel(AppStrings.vehiclesType.tr),
        // Wraps rather than a 3-wide row: the design puts Car alone on the
        // second line, which is what a wrap does at these widths.
        Obx(
          () => Wrap(
            spacing: AppSpacing.sm.w,
            runSpacing: AppSpacing.sm.h,
            children: [
              for (final type in VehicleType.values)
                SizedBox(
                  width: 171.w,
                  child: _VehicleCard(
                    label: _label(type),
                    icon: _icons[type]!,
                    isSelected: type == controller.vehicle.value,
                    onTap: () => controller.selectVehicle(type),
                  ),
                ),
            ],
          ),
        ),
        AppSpacing.gapV(AppSpacing.base),
        Obx(
          () => PhotoRequirementRow(
            title: AppStrings.drivingLicense.tr,
            box: PhotoUploadBox(
              label: AppStrings.uploadPhoto.tr,
              height: 116,
              file: controller.licence.value,
              onPicked: (file) => controller.licence.value = file,
            ),
          ),
        ),
        AppSpacing.gapV(AppSpacing.base),
        // The number the licence is issued under, beside the photo of it. The
        // server stores it and will not take a profile without one, so the
        // application cannot be filed until it is here.
        RiderFieldLabel(AppStrings.licenseNumber.tr),
        AppTextField(
          initialText: controller.licenceNumber.value,
          hint: AppStrings.licenseNumberHint.tr,
          textInputAction: TextInputAction.done,
          onChanged: (value) => controller.licenceNumber.value = value,
        ),
        AppSpacing.gapV(AppSpacing.base),
        Obx(
          () => PhotoRequirementRow(
            title: AppStrings.vehiclesPhoto.tr,
            box: PhotoUploadBox(
              label: AppStrings.uploadPhoto.tr,
              height: 116,
              file: controller.vehiclePhoto.value,
              onPicked: (file) => controller.vehiclePhoto.value = file,
            ),
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final ink = isSelected ? AppColors.white : AppColors.gray900;

    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: _height.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: isSelected
                  ? AppColors.actionFill
                  : AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
          child: Row(
            children: [
              Icon(icon, size: AppSizes.xl2.w, color: ink),
              AppSpacing.gapH(AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the courier works, and whether the app may follow them.
class _LocationPane extends GetView<RiderApplicationController> {
  const _LocationPane();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        RiderFieldLabel(AppStrings.country.tr),
        Obx(
          () => AppDropdownField(
            value: controller.country.value,
            options: RiderData.countries,
            onChanged: controller.selectCountry,
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),
        RiderFieldLabel(AppStrings.city.tr),
        Obx(
          () => AppDropdownField(
            value: controller.city.value,
            options: RiderData.cities,
            onChanged: controller.selectCity,
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),
        RiderFieldLabel(AppStrings.locationLabel.tr),
        _AddressBox(
          initialText: controller.address.value,
          onChanged: (value) => controller.address.value = value,
        ),
        AppSpacing.gapV(AppSpacing.sm),
        RiderFieldLabel(AppStrings.preferredDeliveryZone.tr),
        Obx(
          () => AppDropdownField(
            value: controller.zone.value,
            options: RiderData.zones,
            onChanged: controller.selectZone,
          ),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Obx(
          () => ZoneChips(
            zones: controller.zones.toList(),
            onRemove: controller.removeZone,
          ),
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Obx(
          () => RiderToggleRow(
            label: AppStrings.liveLocationPermission.tr,
            value: controller.gpsEnabled.value,
            onChanged: controller.toggleGps,
          ),
        ),
      ],
    );
  }
}

/// Where the money lands. Adding one opens the patient app's own payment
/// screens rather than a courier copy of them.
class _PaymentPane extends GetView<RiderApplicationController> {
  const _PaymentPane();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl2.h),
      child: AppEmptyState(
        illustration: AppAssets.noPaymentMethod,
        title: AppStrings.noPaymentMethod.tr,
        body: AppStrings.noPaymentMethodBody.tr,
        actionLabel: AppStrings.addAccount.tr,
        onAction: controller.addPaymentMethod,
      ),
    );
  }
}

/// Three-line box; `AppTextField` is the app's fixed single-line control.
class _AddressBox extends StatefulWidget {
  const _AddressBox({required this.initialText, required this.onChanged});

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_AddressBox> createState() => _AddressBoxState();
}

class _AddressBoxState extends State<_AddressBox> {
  /// Owned here so nothing is disposed out from under the route.
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
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: AppColors.fieldBorder,
          width: AppSizes.borderWidth,
        ),
      ),
      child: TextField(
        controller: _text,
        onChanged: widget.onChanged,
        maxLines: 3,
        minLines: 3,
        cursorColor: AppColors.primary800,
        style: AppTextStyles.bodyLarge.rc(AppColors.authInk),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: AppStrings.locationLabel.tr,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ),
    );
  }
}
