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
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../doctors/presentation/widgets/doctor_search_field.dart';
import '../../domain/entities/pharmacy.dart';
import '../controllers/pharmacy_controller.dart';
import '../widgets/medicine_card.dart';

/// Pharmacy tab: prescription upload, medicine search, two catalogue
/// sections and the nearby stores strip.
class PharmacyScreen extends GetView<PharmacyController> {
  const PharmacyScreen({super.key});

  /// Three tiles per row, with 8pt gutters.
  static const int _columns = 3;
  static const double _gutter = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          _Header(controller: controller),
          AppSpacing.gapV(AppSpacing.base),
          _UploadButton(onTap: controller.openUpload),
          AppSpacing.gapV(AppSpacing.base),
          DoctorSearchField(
            initialText: controller.query.value,
            onChanged: (value) => controller.query.value = value,
            hintKey: AppStrings.searchMedicines,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => _Chips(
              chips: controller.chips.toList(),
              selected: controller.selectedChip.value,
              onSelected: controller.selectChip,
            ),
          ),
          // Says whose shelf this is, and how to get back to all of them.
          // Without it, a shop's stock is indistinguishable from a catalogue
          // that has mysteriously shrunk.
          Obx(() {
            final store = controller.viewingStore.value;
            if (store == null) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm.h),
              child: _ViewingStoreBar(
                name: store.name,
                onClear: controller.clearStore,
              ),
            );
          }),
          AppSpacing.gapV(AppSpacing.base),
          PharmacySectionHeader(
            title: AppStrings.commonMedicines.tr,
            onSeeAll: controller.seeAll,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => _Grid(
              medicines: controller.commonMedicines.toList(),
              onAdd: controller.addToCart,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
          PharmacySectionHeader(
            title: AppStrings.dermatologistCategories.tr,
            onSeeAll: controller.seeAll,
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => _Grid(
              medicines: controller.dermatologyMedicines.toList(),
              onAdd: controller.addToCart,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
          PharmacySectionHeader(
            title: AppStrings.storesNearYou.tr,
            onSeeAll: controller.seeAll,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => _Stores(
              stores: controller.stores.toList(),
              onTap: controller.openStore,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final PharmacyController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppStrings.pharmacyTitle.tr,
          style: AppTextStyles.headlineMedium.rc(AppColors.authInk),
        ),
        Obx(
          () => _CartAction(
            count: controller.cartCount,
            onTap: controller.openCart,
          ),
        ),
      ],
    );
  }
}

class _CartAction extends StatelessWidget {
  const _CartAction({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: AppSizes.xl2.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppSvgIcon(AppIcons.cart, color: AppColors.authInk),
          if (count > 0)
            Positioned(
              top: -6.h,
              right: -6.w,
              child: Container(
                constraints: BoxConstraints(minWidth: AppSizes.lg.w),
                height: AppSizes.lg.w,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs2.w),
                decoration: BoxDecoration(
                  color: AppColors.badge,
                  borderRadius: AppRadius.rFull,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: AppTextStyles.labelSmall.rw(
                      AppColors.white,
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base.w,
              vertical: AppSpacing.sm.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSvgIcon(
                  AppIcons.cloudUpload,
                  size: AppSizes.xl,
                  color: AppColors.actionLabel,
                ),
                AppSpacing.gapH(AppSpacing.xs),
                Text(
                  AppStrings.uploadPrescription.tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.chips,
    required this.selected,
    required this.onSelected,
  });

  final List<String> chips;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs.w,
      runSpacing: AppSpacing.xs.h,
      children: [
        for (final chip in chips)
          Material(
            color: chip == selected ? AppColors.actionFill : AppColors.surface,
            borderRadius: AppRadius.rFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onSelected(chip),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.base.w,
                  vertical: AppSpacing.xs.h,
                ),
                child: Text(
                  chip,
                  style: AppTextStyles.bodyLarge.rc(
                    chip == selected ? AppColors.white : AppColors.gray900,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Fixed three-column grid so tiles line up regardless of label length.
class _Grid extends StatelessWidget {
  const _Grid({required this.medicines, required this.onAdd});

  final List<Medicine> medicines;
  final ValueChanged<Medicine> onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = PharmacyScreen._gutter.w;
        final itemWidth =
            (constraints.maxWidth - gutter * (PharmacyScreen._columns - 1)) /
            PharmacyScreen._columns;

        return Wrap(
          spacing: gutter,
          runSpacing: gutter,
          children: [
            for (final medicine in medicines)
              SizedBox(
                width: itemWidth,
                child: MedicineCard(
                  medicine: medicine,
                  onAdd: () => onAdd(medicine),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Stores extends StatelessWidget {
  const _Stores({required this.stores, required this.onTap});

  final List<PharmacyStore> stores;
  final ValueChanged<PharmacyStore> onTap;

  @override
  Widget build(BuildContext context) {
    // A `Row` rather than a horizontal `ListView`: the list would need a
    // fixed height, and a height in `.h` around an avatar in `.w` plus two
    // lines of `.sp` text overflows as soon as those scales diverge. The row
    // sizes itself to its tallest child instead. The store count is small
    // and fully built either way, so nothing is lost by not being lazy.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < stores.length; index++) ...[
            if (index > 0) AppSpacing.gapH(AppSpacing.sm),
            SizedBox(
              width: 68.w,
              child: StoreAvatar(
                store: stores[index],
                onTap: () => onTap(stores[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "showing one shop" strip, with the way out of it.
class _ViewingStoreBar extends StatelessWidget {
  const _ViewingStoreBar({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.storefront_outlined,
          size: AppSizes.lg.w,
          color: AppColors.primary600,
        ),
        AppSpacing.gapH(AppSpacing.xs2),
        Expanded(
          child: Text(
            AppStrings.showingStore.trParams({'store': name}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClear,
          child: Text(
            AppStrings.showAllShops.tr,
            style: AppTextStyles.titleSmall.rc(AppColors.primary600),
          ),
        ),
      ],
    );
  }
}
