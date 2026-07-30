import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/add_card_controller.dart';

/// Debit/Credit Card — the card details, grouped in one panel.
///
/// The fields are grey-filled and borderless, and the labels sit above them
/// inside the panel, which is what the design draws rather than the app's
/// standard outlined `AppTextField`.
class AddCardScreen extends GetView<AddCardController> {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.debitCreditCard.tr),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Expanded(
            child: SingleChildScrollView(
              child: AutofillGroup(
                child: AppCard(
                  hasShadow: false,
                  padding: EdgeInsets.all(AppSpacing.base.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(
                        () => _Field(
                          label: AppStrings.cardNumber.tr,
                          hint: AppStrings.cardNumberHint.tr,
                          keyboardType: TextInputType.number,
                          formatters: [AddCardController.numberFormatter],
                          autofillHints: const [AutofillHints.creditCardNumber],
                          errorText: controller.errorOf(
                            AddCardController.numberField,
                          ),
                          onChanged: (value) {
                            controller.number.value = value;
                            controller.clearError(
                              AddCardController.numberField,
                            );
                          },
                        ),
                      ),
                      AppSpacing.gapV(AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Obx(
                              () => _Field(
                                label: AppStrings.cardExpiry.tr,
                                hint: AppStrings.cardExpiryHint.tr,
                                keyboardType: TextInputType.number,
                                formatters: [AddCardController.expiryFormatter],
                                errorText: controller.errorOf(
                                  AddCardController.expiryField,
                                ),
                                onChanged: (value) {
                                  controller.expiry.value = value;
                                  controller.clearError(
                                    AddCardController.expiryField,
                                  );
                                },
                              ),
                            ),
                          ),
                          AppSpacing.gapH(AppSpacing.sm),
                          Expanded(
                            child: Obx(
                              () => _Field(
                                label: AppStrings.cardCvv.tr,
                                hint: AppStrings.cardCvvHint.tr,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                errorText: controller.errorOf(
                                  AddCardController.cvvField,
                                ),
                                onChanged: (value) {
                                  controller.cvv.value = value;
                                  controller.clearError(
                                    AddCardController.cvvField,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapV(AppSpacing.sm),
                      Obx(
                        () => _Field(
                          label: AppStrings.nameOnCard.tr,
                          hint: AppStrings.cardHolderHint.tr,
                          autofillHints: const [AutofillHints.creditCardName],
                          textInputAction: TextInputAction.done,
                          errorText: controller.errorOf(
                            AddCardController.holderField,
                          ),
                          onChanged: (value) {
                            controller.holder.value = value;
                            controller.clearError(
                              AddCardController.holderField,
                            );
                          },
                          onSubmitted: (_) => controller.save(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Obx(
            () => AppButton(
              label: AppStrings.addDebitCard.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.save,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Label over a grey, borderless input. Errors render underneath so the
/// field's height never changes.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.onChanged,
    this.errorText,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.formatters,
    this.autofillHints,
    this.maxLength,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? formatters;
  final List<String>? autofillHints;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.bodyLarge.rc(AppColors.gray500)),
        AppSpacing.gapV(AppSpacing.xs2),
        Container(
          height: _height.h,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
          decoration: BoxDecoration(
            color: AppColors.cardFieldFill,
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: errorText == null
                  ? AppColors.transparent
                  : AppColors.error,
              width: AppSizes.borderWidth,
            ),
          ),
          alignment: Alignment.center,
          // No controller passed: the field owns its own, so nothing is
          // disposed out from under it when the route pops.
          child: TextField(
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: formatters,
            autofillHints: autofillHints,
            maxLength: maxLength,
            cursorColor: AppColors.primary800,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
          ),
        ),
        if (errorText != null) ...[
          AppSpacing.gapV(AppSpacing.xxs),
          Text(errorText!, style: AppTextStyles.bodySmall.rc(AppColors.error)),
        ],
      ],
    );
  }
}
