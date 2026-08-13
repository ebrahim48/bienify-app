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
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../doctor_role/presentation/widgets/app_dropdown_field.dart';
import '../../data/static/rider_data.dart';
import '../controllers/rider_profile_controller.dart';
import '../widgets/rider_widgets.dart';

/// The courier's details and where they are willing to ride.
class RiderEditProfileScreen extends GetView<RiderProfileController> {
  const RiderEditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.editProfile.tr),
      // Rebuilt when a load lands: the prefilled fields own their text
      // controllers and seed them from [initialText] once, so a value that
      // arrives after the first build only reaches them through a new key.
      child: Obx(() => _Form(key: ValueKey(controller.formGeneration.value))),
    );
  }
}

class _Form extends GetView<RiderProfileController> {
  const _Form({super.key});

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          RiderFieldLabel(AppStrings.fullName.tr),
          AppTextField(
            initialText: controller.fullName.value,
            hint: AppStrings.fullName.tr,
            textInputAction: TextInputAction.next,
            onChanged: (value) => controller.fullName.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          RiderFieldLabel(AppStrings.email.tr),
          AppTextField(
            initialText: controller.email.value,
            hint: AppStrings.emailHint.tr,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onChanged: (value) => controller.email.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          RiderFieldLabel(AppStrings.country.tr),
          Obx(
            () => AppDropdownField(
              value: controller.country.value,
              options: controller.countryOptions.toList(),
              onChanged: controller.selectCountry,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          RiderFieldLabel(AppStrings.city.tr),
          Obx(
            () => AppDropdownField(
              value: controller.city.value,
              options: controller.cityOptions.toList(),
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
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => AppButton(
              label: AppStrings.updateRiderInformation.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.submit,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
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
