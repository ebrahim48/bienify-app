import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/profile.dart';
import '../controllers/top_up_controller.dart';

/// Add Money: an amount, the card it comes from, and what the balance becomes.
///
/// A full route rather than a sheet — the amount, the quick picks, the card
/// list and a running preview do not fit above a keyboard on a 390pt screen.
class TopUpScreen extends GetView<TopUpController> {
  const TopUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.addMoney.tr),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BalancePreview(),
                  AppSpacing.gapV(AppSpacing.md),
                  _Label(AppStrings.topUpAmount.tr),
                  AppSpacing.gapV(AppSpacing.xs2),
                  const _AmountField(),
                  AppSpacing.gapV(AppSpacing.sm),
                  const _QuickAmounts(),
                  AppSpacing.gapV(AppSpacing.md),
                  _Label(AppStrings.topUpPayWith.tr),
                  AppSpacing.gapV(AppSpacing.xs2),
                  const _CardList(),
                ],
              ),
            ),
          ),
          // Disabled rather than hidden, so the target never moves under a
          // thumb that is already reaching for it.
          Obx(
            () => AppButton(
              label: controller.canSubmit
                  ? AppStrings.topUpAction.trParams({
                      'amount': controller.amountLabel,
                    })
                  : AppStrings.addMoney.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.canSubmit ? controller.addMoney : null,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.labelLarge
        .rc(AppColors.gray400)
        .copyWith(letterSpacing: 0.6),
  );
}

/// The balance now, and what it becomes.
///
/// The second figure is the only number on this screen the patient actually
/// cares about, and it is derived rather than invented — so a mistyped 500 is
/// obvious before the tap.
class _BalancePreview extends GetView<TopUpController> {
  const _BalancePreview();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Obx(() {
        final after = controller.newBalanceLabel;
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.availableBalanceCaps.tr,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                  ),
                  AppSpacing.gapV(AppSpacing.xxs),
                  Text(
                    controller.balanceLabel,
                    style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
                  ),
                ],
              ),
            ),
            // Nothing is drawn while the amount is unusable: repeating the
            // current balance would read as a preview of nothing happening.
            if (after != null) ...[
              Icon(
                Icons.arrow_forward_rounded,
                size: AppSizes.xl.w,
                color: AppColors.gray400,
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.topUpNewBalance.tr,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                  ),
                  AppSpacing.gapV(AppSpacing.xxs),
                  Text(
                    after,
                    style: AppTextStyles.headlineSmall.rc(AppColors.creditInk),
                  ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _AmountField extends GetView<TopUpController> {
  const _AmountField();

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final error = controller.errorOf(TopUpController.amountField);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: _height.h,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
            decoration: BoxDecoration(
              color: AppColors.cardFieldFill,
              borderRadius: AppRadius.rLg,
              border: Border.all(
                color: error == null ? AppColors.transparent : AppColors.error,
                width: AppSizes.borderWidth,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              children: [
                Text(
                  r'$',
                  style: AppTextStyles.headlineSmall.rc(AppColors.gray500),
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Expanded(
                  // No controller passed: the field owns its own, so nothing
                  // is disposed out from under it when the route pops.
                  child: TextField(
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: controller.setAmount,
                    onSubmitted: (_) {
                      if (controller.canSubmit) controller.addMoney();
                    },
                    cursorColor: AppColors.primary800,
                    style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: AppTextStyles.headlineSmall.rc(
                        AppColors.gray500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            AppSpacing.gapV(AppSpacing.xxs),
            Text(error, style: AppTextStyles.bodySmall.rc(AppColors.error)),
          ],
        ],
      );
    });
  }
}

/// Chips set the field and nothing else. Selection is read back off the
/// amount, so a chip and the field can never disagree.
class _QuickAmounts extends GetView<TopUpController> {
  const _QuickAmounts();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          for (final major in TopUpController.quickAmounts) ...[
            if (major != TopUpController.quickAmounts.first)
              AppSpacing.gapH(AppSpacing.xs),
            Expanded(
              child: _Chip(
                label: '\$$major',
                isSelected: controller.isQuickAmountSelected(major),
                onTap: () => controller.selectQuickAmount(major),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : AppColors.cardFieldFill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _height.h,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.rc(
                isSelected ? AppColors.actionLabel : AppColors.gray900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardList extends GetView<TopUpController> {
  const _CardList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cards = controller.cards.toList();
      if (cards.isEmpty) {
        // Not an error, and not a Pay button that can only fail: adding a card
        // becomes the action.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppEmptyState(
              icon: Icons.credit_card_outlined,
              title: AppStrings.topUpNeedsCard.tr,
            ),
            AppSpacing.gapV(AppSpacing.xs),
            AppButton(
              label: AppStrings.topUpAddCard.tr,
              variant: AppButtonVariant.outlined,
              onPressed: controller.openAddCard,
            ),
          ],
        );
      }

      return AppCard(
        hasShadow: false,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0)
                Container(
                  height: AppSizes.borderWidth,
                  color: AppColors.surfaceBorder,
                ),
              _CardRow(
                card: cards[index],
                isSelected: controller.selectedCardId.value == cards[index].id,
                onTap: () => controller.selectCard(cards[index].id),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  final WalletCard card;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.sm.w),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: AppSizes.xl.w,
              color: isSelected ? AppColors.primary600 : AppColors.gray400,
            ),
            AppSpacing.gapH(AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.brand,
                    style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                  ),
                  Text(
                    card.maskedNumber,
                    style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                  ),
                ],
              ),
            ),
            Text(
              card.expiry,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}
