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
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/profile.dart';
import '../controllers/partner_controller.dart';

/// Two mutually exclusive partner programmes, then Continue.
class BecomePartnerScreen extends GetView<PartnerController> {
  const BecomePartnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.becomeAPartner.tr),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          // Read here so the cards repaint: the child reads no observable of
          // its own, it is handed plain values.
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final role in PartnerRole.values) ...[
                  if (role != PartnerRole.values.first)
                    AppSpacing.gapV(AppSpacing.sm),
                  _PartnerOption(
                    icon: switch (role) {
                      PartnerRole.pharmacyOwner => AppIcons.pharmacyOwner,
                      PartnerRole.rider => AppIcons.rider,
                    },
                    label: controller.labelFor(role),
                    isSelected: controller.selected.value == role,
                    onTap: () => controller.select(role),
                  ),
                ],
              ],
            ),
          ),
          const Spacer(),
          // A pending application is a fact worth printing: the server refuses
          // a second one, so a button that looks ready to file another is a
          // control that cannot do what it offers.
          Obx(
            () => controller.isPending
                ? Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
                    child: Text(
                      AppStrings.partnerApplicationPending.tr,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => AppButton(
              label: controller.actionLabel,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.isPending
                  ? null
                  : controller.submitApplication,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// A tall card with the programme's mark centred above its label. Selection
/// is a navy outline; the fill does not change.
class _PartnerOption extends StatelessWidget {
  const _PartnerOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: AppSizes.partnerCardHeight.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: isSelected ? AppColors.actionFill : AppColors.transparent,
              width: AppSizes.borderWidth,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Both marks ship in `authInk`, so they are drawn untinted.
              AppSvgIcon(icon, size: AppSizes.partnerIcon),
              AppSpacing.gapV(AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
