import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../data/static/medical_mock_data.dart';
import '../../domain/entities/medical_record.dart';
import '../controllers/test_results_controller.dart';

/// Pick where the test will be done. Choosing one pops back to the order
/// sheet, which then shows the confirmation footer.
class TestingCentresScreen extends GetView<TestResultsController> {
  const TestingCentresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.chooseLaboratoryCentre.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.base),
          for (final centre in MedicalMockData.centres) ...[
            _CentreCard(
              centre: centre,
              onTap: () => controller.selectCentre(centre),
            ),
            AppSpacing.gapV(AppSpacing.sm),
          ],
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

class _CentreCard extends StatelessWidget {
  const _CentreCard({required this.centre, required this.onTap});

  final TestingCentre centre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centre.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                Text(
                  centre.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: AppSizes.lg.w,
                      color: AppColors.link,
                    ),
                    AppSpacing.gapH(AppSpacing.xs2),
                    Expanded(
                      child: Text(
                        AppStrings.awayOpenBookingApp.trParams({
                          'distance': centre.distanceLabel,
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.rc(AppColors.link),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Icon(
            Icons.open_in_new_rounded,
            size: AppSizes.xl.w,
            color: AppColors.link,
          ),
        ],
      ),
    );
  }
}
