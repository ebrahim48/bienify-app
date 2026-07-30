import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/pharmacy.dart';

/// A catalogue tile: discount ribbon, product shot, name, dosage, price and
/// the Add action.
class MedicineCard extends StatelessWidget {
  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onAdd,
  });

  final Medicine medicine;
  final VoidCallback onAdd;

  static const double imageHeight = 66;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rXl,
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.xs.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: imageHeight.h,
                  child: Center(
                    child: Image.asset(
                      AppAssets.medicine,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  medicine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.authInk),
                ),
                Text(
                  medicine.dosage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                // Three items in a ~95pt row, so the prices are sized to fit
                // rather than left to ellipsize into "$…".
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              medicine.shortPriceLabel,
                              maxLines: 1,
                              style: AppTextStyles.labelLarge.rc(
                                AppColors.authInk,
                              ),
                            ),
                            if (medicine.oldPriceLabel != null) ...[
                              AppSpacing.gapH(AppSpacing.xs2),
                              Text(
                                medicine.oldPriceLabel!,
                                maxLines: 1,
                                style: AppTextStyles.bodySmall
                                    .rc(AppColors.gray400)
                                    .copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppColors.gray400,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    _AddButton(onTap: onAdd),
                  ],
                ),
              ],
            ),
          ),
          if (medicine.discountPercent > 0)
            Positioned(top: 0, left: AppSpacing.xs.w, child: _DiscountRibbon(
              percent: medicine.discountPercent,
            )),
        ],
      ),
    );
  }
}

/// The red flag in the corner. Its notched foot is drawn with a clip so it
/// reads as a ribbon rather than a plain badge.
class _DiscountRibbon extends StatelessWidget {
  const _DiscountRibbon({required this.percent});

  final int percent;

  static const double _width = 28;
  static const double _height = 24;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        width: _width.w,
        height: _height.h,
        color: AppColors.error600,
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: AppSpacing.xxs.h),
        child: FittedBox(
          child: Text(
            AppStrings.percentOff.trParams({'percent': '$percent'}),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.rc(AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final notch = size.height * 0.22;
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - notch)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.actionFill,
      borderRadius: AppRadius.rMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xs.w,
            vertical: AppSpacing.xs2.h,
          ),
          child: Text(
            AppStrings.add.tr,
            style: AppTextStyles.labelSmall.rc(AppColors.actionLabel),
          ),
        ),
      ),
    );
  }
}

/// Section heading with a trailing "See all".
class PharmacySectionHeader extends StatelessWidget {
  const PharmacySectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
  });

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSeeAll,
          child: Text(
            AppStrings.seeAll.tr,
            style: AppTextStyles.bodyMedium.rc(AppColors.primary600),
          ),
        ),
      ],
    );
  }
}

/// Circular storefront photo with the pharmacy's name underneath.
class StoreAvatar extends StatelessWidget {
  const StoreAvatar({super.key, required this.store, required this.onTap});

  final PharmacyStore store;
  final VoidCallback onTap;

  static const double size = 56;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size.w,
            height: size.w,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceBorder,
                width: AppSizes.borderWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: Image.asset(
              AppAssets.storesNear,
              fit: BoxFit.cover,
              // The initial stands in only if the shot fails to decode.
              errorBuilder: (context, _, _) => Text(
                store.initial,
                style: AppTextStyles.titleMedium.rc(AppColors.primary600),
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            store.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.rc(AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
