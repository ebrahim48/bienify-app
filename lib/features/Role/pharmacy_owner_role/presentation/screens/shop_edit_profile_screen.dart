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
import '../../../doctor_role/presentation/widgets/dashed_drop_zone.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../controllers/shop_profile_controller.dart';

/// The shop's registration details and its three uploads.
class ShopEditProfileScreen extends GetView<ShopProfileController> {
  const ShopEditProfileScreen({super.key});

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

class _Form extends GetView<ShopProfileController> {
  const _Form({super.key});

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          _Label(AppStrings.fullName.tr),
          AppTextField(
            initialText: controller.fullName.value,
            hint: AppStrings.fullName.tr,
            textInputAction: TextInputAction.next,
            onChanged: (value) => controller.fullName.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.businessEmail.tr),
          AppTextField(
            initialText: controller.email.value,
            hint: AppStrings.emailHint.tr,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onChanged: (value) => controller.email.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.password.tr),
          AppTextField(
            hint: AppStrings.passwordHint.tr,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.next,
            onChanged: (value) => controller.password.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.countryOfPharmacy.tr),
          Obx(
            () => AppDropdownField(
              value: controller.country.value,
              options: PharmacyShopData.countries,
              onChanged: controller.selectCountry,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.pharmacyLocation.tr),
          _AddressBox(
            initialText: controller.address.value,
            onChanged: (value) => controller.address.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.businessLicenseNumber.tr),
          AppTextField(
            initialText: controller.licenceNumber.value,
            hint: AppStrings.businessLicenseHint.tr,
            textInputAction: TextInputAction.done,
            onChanged: (value) => controller.licenceNumber.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.uploadLicenseDocument.tr),
          Obx(
            () => DashedDropZone(
              hasFile: controller.hasLicence.value,
              onTap: controller.attachLicence,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.uploadShopLogo.tr),
          Obx(
            () => DashedDropZone(
              hasFile: controller.hasLogo.value,
              onTap: controller.attachLogo,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Label(AppStrings.uploadShopBanner.tr),
          Obx(
            () => DashedDropZone(
              hasFile: controller.hasBanner.value,
              onTap: controller.attachBanner,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Obx(
            () => AppButton(
              label: AppStrings.updateShopInformation.tr,
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

class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
    child: Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray600)),
  );
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
          hintText: AppStrings.pharmacyLocation.tr,
          hintStyle: AppTextStyles.bodyLarge.rc(AppColors.fieldHint),
        ),
      ),
    );
  }
}
