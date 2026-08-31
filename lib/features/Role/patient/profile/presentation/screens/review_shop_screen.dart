import '../../domain/entities/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../../appointments/presentation/widgets/review_dialog.dart';
import '../../../pharmacy/presentation/widgets/medicine_card.dart';
import '../controllers/account_controller.dart';

/// The shop an order came from, and the place a review is written.
///
/// Reuses the Pharmacy `MedicineCard` for the catalogue grid and the
/// appointments `ReviewDialog` for the rating, so neither is rebuilt here.
class ReviewShopScreen extends GetView<AccountController> {
  const ReviewShopScreen({super.key});

  /// Three tiles per row with 8pt gutters, as on the Pharmacy tab.
  static const int _columns = 3;
  static const double _gutter = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    // The order the patient tapped, which names the shop that filled it. The
    // screen drew the first demo store for everybody before, under a rating
    // and review count belonging to a *rider*.
    final order = Get.arguments is OrderHistoryEntry
        ? Get.arguments as OrderHistoryEntry
        : null;

    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.reviewShop.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          _Masthead(storeName: order?.storeName ?? ''),
          AppSpacing.gapV(AppSpacing.xs),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            order?.storeAddress ?? '',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
          Text(
            order?.storeCity ?? '',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
          ),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            AppStrings.allMedicines.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          _Grid(onAdd: controller.openPromo),
          AppSpacing.gapV(AppSpacing.md),
          AppButton(
            label: AppStrings.writeReviews.tr,
            onPressed: () => _review(context, order),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, OrderHistoryEntry? order) async {
    final stars = await ReviewDialog.show(context);
    if (stars == null) return;

    // No order means the screen was opened without one, and there is nothing
    // to attach a rating to — the server derives the shop from the order.
    if (order == null) {
      Get.back<void>();
      return;
    }

    if (await controller.submitShopReview(order, stars)) Get.back<void>();
  }
}

/// The promo banner with the store's disc overlapping its lower edge, and the
/// store name underneath.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.storeName});

  final String storeName;

  static const double _avatar = 44;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // `clipBehavior: none` so the disc can hang below the banner the way
        // the design draws it.
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: AppRadius.rLg,
              child: Image.asset(AppAssets.promoBanner, fit: BoxFit.fitWidth),
            ),
            Positioned(
              bottom: -_avatar.w / 2,
              child: Container(
                width: _avatar.w,
                height: _avatar.w,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: AppSpacing.xs2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(AppAssets.storesNear, fit: BoxFit.cover),
              ),
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.lg),
        Text(storeName, style: AppTextStyles.titleSmall.rc(AppColors.authInk)),
      ],
    );
  }
}

class _Grid extends GetView<AccountController> {
  const _Grid({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // The Obx belongs here, around the read, not around this widget from the
    // caller: GetX only tracks observables touched inside the closure's own
    // build, so wrapping the widget watched nothing.
    return Obx(() {
      // What this shop actually stocks. A fixed grid of demo medicines was
      // drawn for every shop before, so a patient could tap "add" on something
      // the pharmacy they were reviewing had never carried.
      final medicines = controller.shopMedicines;
      if (medicines.isEmpty) return const SizedBox.shrink();

      return LayoutBuilder(
        builder: (context, constraints) {
          final gutter = ReviewShopScreen._gutter.w;
          final itemWidth =
              (constraints.maxWidth -
                  gutter * (ReviewShopScreen._columns - 1)) /
              ReviewShopScreen._columns;

          return Wrap(
            spacing: gutter,
            runSpacing: gutter,
            children: [
              for (final medicine in medicines)
                SizedBox(
                  width: itemWidth,
                  child: MedicineCard(medicine: medicine, onAdd: onAdd),
                ),
            ],
          );
        },
      );
    });
  }
}
