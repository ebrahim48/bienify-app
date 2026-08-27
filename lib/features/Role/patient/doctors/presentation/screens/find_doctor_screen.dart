import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../controllers/find_doctor_controller.dart';
import '../widgets/doctor_category_card.dart';
import '../widgets/doctor_search_field.dart';

/// The Doctors tab: search, specialty grid, and the button that opens the
/// list for whichever category is selected.
class FindDoctorScreen extends GetView<FindDoctorController> {
  const FindDoctorScreen({super.key});

  /// Two columns, matching the design's 8pt gutters.
  static const int _columns = 2;
  static const double _gutter = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          Text(
            AppStrings.findADoctorTitle.tr,
            style: AppTextStyles.headlineMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.base),
          DoctorSearchField(
            initialText: controller.query.value,
            onChanged: (value) => controller.query.value = value,
            onSubmitted: controller.onQuerySubmitted,
          ),
          AppSpacing.gapV(AppSpacing.lg),
          Text(
            AppStrings.exploreCategories.tr,
            style: AppTextStyles.titleMedium.rc(AppColors.authInk),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DoctorCategoryCard.wide(
                  category: controller.general,
                  isSelected: controller.isSelected(controller.general),
                  onTap: () => controller.select(controller.general),
                ),
                AppSpacing.gapV(_gutter),
                _CategoryGrid(controller: controller),
              ],
            ),
          ),
          AppSpacing.gapV(AppSpacing.lg),
          Obx(
            () => AppButton(
              label: AppStrings.findCategoryDoctors.trParams({
                'category': controller.selected.value.name,
              }),
              onPressed: controller.openList,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// Fixed two-column grid so rows stay aligned regardless of label length.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.controller});

  final FindDoctorController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = FindDoctorScreen._gutter.w;
        final itemWidth =
            (constraints.maxWidth - gutter * (FindDoctorScreen._columns - 1)) /
            FindDoctorScreen._columns;

        // The specialties are read from the doctors on the platform, so they
        // arrive after the first frame. Without the `Obx` the grid drew once,
        // empty, and never again — it was a compile-time list before, which is
        // why it needed no watcher.
        return Obx(
          () => Wrap(
            spacing: gutter,
            runSpacing: gutter,
            children: [
              for (final category in controller.categories)
                SizedBox(
                  width: itemWidth,
                  child: DoctorCategoryCard(
                    category: category,
                    isSelected: controller.isSelected(category),
                    onTap: () => controller.select(category),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
