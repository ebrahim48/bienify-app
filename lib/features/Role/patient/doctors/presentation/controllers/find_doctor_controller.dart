import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../data/static/doctor_mock_data.dart';
import '../../domain/entities/doctor_category.dart';

/// Backs the Doctors tab: search box, specialty grid, and the call to action
/// that opens the matching list.
///
/// UI-only — categories come from [DoctorMockData]; nothing calls an API.
class FindDoctorController extends GetxController {
  /// The live query. `DoctorSearchField` owns the text controller, so this
  /// one lives as long as the tab without any disposal to coordinate.
  final RxString query = ''.obs;

  /// The catch-all shown full-width above the grid.
  final DoctorCategory general = DoctorMockData.generalCategory;

  final RxList<DoctorCategory> categories = <DoctorCategory>[].obs;

  /// Starts on `General`, which is why that card is filled in the design.
  late final Rx<DoctorCategory> selected = general.obs;

  @override
  void onInit() {
    super.onInit();
    categories.value = DoctorMockData.categories;
  }

  bool isSelected(DoctorCategory category) => selected.value.id == category.id;

  void select(DoctorCategory category) => selected.value = category;

  /// Typing a specialty is a shortcut into the same list.
  void onQuerySubmitted(String _) => openList();

  void openList() => Get.toNamed<void>(
    AppRoutes.doctorList,
    arguments: selected.value,
  );
}
