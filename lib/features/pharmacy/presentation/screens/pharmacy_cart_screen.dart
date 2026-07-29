import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_icons.dart';
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
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';
import '../controllers/pharmacy_cart_controller.dart';
import '../widgets/quantity_stepper.dart';

/// The basket: lines with steppers, the wallet and pickup switches, and the
/// order summary.
class PharmacyCartScreen extends GetView<PharmacyCartController> {
  const PharmacyCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.yourCard.tr),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            _DeliveryHeader(store: controller.store.value),
            AppSpacing.gapV(AppSpacing.sm),
            _Lines(controller: controller),
            AppSpacing.gapV(AppSpacing.sm),
            _EditLink(onTap: controller.editMedicines),
            AppSpacing.gapV(AppSpacing.sm),
            _SwitchCard(
              icon: AppIcons.wallet,
              title: AppStrings.rxWallet.tr,
              subtitle: AppStrings.walletBalance.trParams({
                'amount': controller.format(PharmacyMockData.walletBalance),
              }),
              value: controller.useWallet.value,
              onChanged: controller.toggleWallet,
              note: controller.useWallet.value
                  ? AppStrings.walletDeduction.trParams({
                      'amount': controller.format(
                        PharmacyMockData.walletBalance,
                      ),
                    })
                  : null,
            ),
            if (controller.useWallet.value) ...[
              AppSpacing.gapV(AppSpacing.sm),
              _SwitchCard(
                iconData: Icons.directions_walk_rounded,
                title: AppStrings.pickupYourself.tr,
                value: controller.pickupYourself.value,
                onChanged: controller.togglePickup,
              ),
            ],
            AppSpacing.gapV(AppSpacing.sm),
            _Summary(controller: controller),
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.proceedToPayment.trParams({
                'amount': controller.checkoutLabel,
              }),
              icon: Icon(
                Icons.credit_card_rounded,
                size: AppSizes.xl.w,
                color: AppColors.actionLabel,
              ),
              onPressed: controller.proceedToPayment,
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _DeliveryHeader extends StatelessWidget {
  const _DeliveryHeader({required this.store});

  final PharmacyStore? store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm.w,
        vertical: AppSpacing.xs.h + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: AppSizes.xl.w,
            color: AppColors.primary600,
          ),
          AppSpacing.gapH(AppSpacing.xs),
          // Scaled rather than ellipsized: a clipped store name ("MediQuick
          // Pharm…") is the one part of this row the patient needs whole,
          // and store names vary in length far more than the ETA does.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.deliveryFrom.trParams({
                  'store': store?.name ?? '',
                }),
                maxLines: 1,
                style: AppTextStyles.labelLarge.rc(AppColors.gray900),
              ),
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(
            store?.etaLabel ?? '',
            style: AppTextStyles.bodySmall.rc(AppColors.gray400),
          ),
        ],
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.controller});

  final PharmacyCartController controller;

  static const double _thumb = 40;

  @override
  Widget build(BuildContext context) {
    final lines = controller.lines.toList();

    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < lines.length; index++) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm.w,
                vertical: AppSpacing.xs.h + 2,
              ),
              child: Row(
                children: [
                  Container(
                    width: _thumb.w,
                    height: _thumb.w,
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: AppRadius.rLg,
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: EdgeInsets.all(AppSpacing.xxs.w),
                    child: Image.asset(
                      AppAssets.medicine,
                      fit: BoxFit.contain,
                    ),
                  ),
                  AppSpacing.gapH(AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lines[index].medicine.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.rc(
                            AppColors.authInk,
                          ),
                        ),
                        Text(
                          lines[index].medicine.detailLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.rc(
                            AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH(AppSpacing.xs),
                  QuantityStepper(
                    quantity: lines[index].quantity,
                    decrementIcon: Icons.close_rounded,
                    onIncrement: () => controller.increment(lines[index]),
                    onDecrement: () => controller.decrement(lines[index]),
                  ),
                  AppSpacing.gapH(AppSpacing.xs),
                  Text(
                    lines[index].medicine.priceLabel,
                    style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                  ),
                ],
              ),
            ),
            if (index != lines.length - 1)
              Divider(
                height: AppSizes.borderWidth,
                thickness: AppSizes.borderWidth,
                color: AppColors.surfaceBorder,
                indent: AppSpacing.sm.w,
                endIndent: AppSpacing.sm.w,
              ),
          ],
        ],
      ),
    );
  }
}

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chatFieldFill,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.xl5.h,
          alignment: Alignment.center,
          child: Text(
            AppStrings.addOrRemoveMedicines.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
        ),
      ),
    );
  }
}

/// Wallet / pickup row with an optional note under a rule.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
    this.iconData,
    this.subtitle,
    this.note,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? icon;
  final IconData? iconData;
  final String? subtitle;
  final String? note;

  static const double _badge = 44;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: _badge.w,
                height: _badge.w,
                decoration: const BoxDecoration(
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? AppSvgIcon(
                        icon!,
                        size: AppSizes.xl,
                        color: AppColors.primary600,
                      )
                    : Icon(
                        iconData,
                        size: AppSizes.xl.w,
                        color: AppColors.primary600,
                      ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleSmall.rc(AppColors.black),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.actionFill,
                inactiveThumbColor: AppColors.white,
                inactiveTrackColor: AppColors.gray200,
                trackOutlineColor: WidgetStateProperty.all(
                  AppColors.transparent,
                ),
              ),
            ],
          ),
          if (note != null) ...[
            AppSpacing.gapV(AppSpacing.xs),
            Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: AppColors.surfaceBorder,
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                note!,
                style: AppTextStyles.labelLarge.rc(AppColors.gray800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.controller});

  final PharmacyCartController controller;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.orderSummary.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.black),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          _Row(
            label: AppStrings.subtotalItems.trParams({
              'count': '${controller.itemCount}',
            }),
            value: controller.subtotalLabel,
          ),
          if (!controller.pickupYourself.value) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            _Row(
              label: AppStrings.deliveryFee.tr,
              value: controller.deliveryFeeLabel,
            ),
          ],
          if (controller.useWallet.value) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            _Row(
              label: AppStrings.walletCredit.tr,
              value: controller.walletCreditLabel,
              valueColor: AppColors.openInk,
            ),
          ],
          AppSpacing.gapV(AppSpacing.sm),
          _Row(
            label: AppStrings.total.tr,
            value: controller.totalLabel,
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isTotal
                ? AppTextStyles.titleSmall.rc(AppColors.black)
                : AppTextStyles.bodyLarge.rc(AppColors.gray500),
          ),
        ),
        Text(
          value,
          style: isTotal
              ? AppTextStyles.headlineSmall.rc(AppColors.black)
              : AppTextStyles.bodyLarge.rc(valueColor ?? AppColors.gray900),
        ),
      ],
    );
  }
}
