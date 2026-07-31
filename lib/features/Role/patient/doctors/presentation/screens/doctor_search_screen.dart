import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../controllers/doctor_search_controller.dart';
import '../widgets/doctor_list_card.dart';
import '../widgets/doctor_result_list.dart';
import '../widgets/doctor_search_field.dart';
import '../widgets/specialty_filter_chips.dart';

/// The Search screen: a live query field, specialty chips, and results.
///
/// The same controller and body serve the Doctors tab
/// ([DoctorDirectoryView]) — only the header differs.
class DoctorSearchScreen extends GetView<DoctorSearchController> {
  const DoctorSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.search.tr),
      scrollable: false,
      child: DoctorDirectoryView(autofocus: true),
    );
  }
}

/// Search field + chips + results, without a page shell.
///
/// Extracted so the Doctors tab can present the identical experience inside
/// the bottom-navigation shell.
class DoctorDirectoryView extends GetView<DoctorSearchController> {
  const DoctorDirectoryView({super.key, this.autofocus = false});

  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenTopGap(),
        DoctorSearchField(
          initialText: controller.query.value,
          onChanged: controller.onQueryChanged,
          onSubmitted: (_) => controller.search(),
          autofocus: autofocus,
        ),
        AppSpacing.gapV(AppSpacing.base),
        // Both observables are read inside the builder — handing over the
        // `RxList` or a predicate would not subscribe, and the chips would
        // never repaint.
        Obx(
          () => SpecialtyFilterChips(
            specialties: controller.specialties.toList(),
            selected: controller.selectedSpecialty.value,
            onSelected: controller.selectSpecialty,
          ),
        ),
        AppSpacing.gapV(AppSpacing.base),
        Expanded(
          child: Obx(
            () => DoctorResultList(
              doctors: controller.results.toList(),
              isLoading: controller.isLoading.value,
              errorMessage: controller.errorMessage.value,
              onRetry: controller.search,
              itemBuilder: (doctor) => DoctorListCard(
                doctor: doctor,
                onTap: () => controller.openDoctor(doctor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
