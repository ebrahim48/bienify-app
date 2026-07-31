import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_svg_icon.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/doctor_list_controller.dart';
import '../widgets/doctor_filter_sheet.dart';
import '../widgets/doctor_list_card.dart';
import '../widgets/doctor_result_list.dart';

/// "«Category» Doctor lists" — the roster behind a category, with the filter
/// sheet on the trailing app-bar action.
///
/// Tapping a row continues into the existing Doctor Details → Payment
/// Summary → cash-payment journey; none of that is rebuilt here.
class DoctorListScreen extends GetView<DoctorListController> {
  const DoctorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      topBar: AppTopBar(
        title: AppStrings.categoryDoctorLists.trParams({
          'category': controller.category.name,
        }),
        trailing: _FilterAction(controller: controller),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          Expanded(
            child: Obx(
              () => DoctorResultList(
                doctors: controller.doctors.toList(),
                isLoading: false,
                itemBuilder: (doctor) => DoctorListCard(
                  doctor: doctor,
                  onTap: () => controller.openDoctor(doctor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterAction extends StatelessWidget {
  const _FilterAction({required this.controller});

  final DoctorListController controller;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      radius: AppSizes.xl2.r,
      onTap: () async {
        final applied = await DoctorFilterSheet.show(
          context,
          current: controller.filter.value,
        );
        if (applied != null) controller.applyFilter(applied);
      },
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xs.w),
        child: AppSvgIcon(AppIcons.filter, color: AppColors.authInk),
      ),
    );
  }
}
