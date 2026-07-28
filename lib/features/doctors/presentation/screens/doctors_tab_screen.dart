import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import 'doctor_search_screen.dart';

/// Doctors tab.
///
/// Presents the same directory as the Search screen — search field, specialty
/// chips and results — under a tab heading instead of a back bar, so the two
/// entry points behave identically.
class DoctorsTabScreen extends StatelessWidget {
  const DoctorsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xl),
          Text(
            AppStrings.navDoctors.tr,
            style: AppTextStyles.titleLarge.rc(AppColors.black),
          ),
          const Expanded(child: DoctorDirectoryView()),
        ],
      ),
    );
  }
}
