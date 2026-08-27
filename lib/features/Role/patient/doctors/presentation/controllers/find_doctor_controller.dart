import '../../domain/repositories/doctor_repository.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../domain/entities/doctor_category.dart';

/// Backs the Doctors tab: search box, specialty grid, and the call to action
/// that opens the matching list.
///
/// The specialty grid is read from what the doctors on the platform actually
/// practise. It was a fixed list of six, so a specialty with real
/// practitioners never appeared and one with none showed an empty result.
class FindDoctorController extends GetxController {
  FindDoctorController({DoctorRepository? repository})
    : _repository = repository ?? Get.find<DoctorRepository>();

  final DoctorRepository _repository;

  /// The live query. `DoctorSearchField` owns the text controller, so this
  /// one lives as long as the tab without any disposal to coordinate.
  final RxString query = ''.obs;

  /// The catch-all shown full-width above the grid. Not a specialty — it is
  /// "show me everyone", which is why it is not read from the server.
  static const DoctorCategory generalCategory = DoctorCategory(
    id: 'general',
    name: 'General',
  );

  final DoctorCategory general = generalCategory;

  final RxList<DoctorCategory> categories = <DoctorCategory>[].obs;

  /// Starts on `General`, which is why that card is filled in the design.
  late final Rx<DoctorCategory> selected = general.obs;

  final RxBool isLoadingCategories = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
  }

  /// The specialties patients can actually book.
  ///
  /// A fixed grid of six before, so a specialty with real practitioners never
  /// appeared and one with none showed an empty list. `getSpecialties` reads
  /// what the doctors on the platform actually practise.
  Future<void> _loadCategories() async {
    isLoadingCategories.value = true;
    try {
      final specialties = await _repository.getSpecialties();
      categories.value = [
        for (final specialty in specialties)
          DoctorCategory(id: specialty, name: _titleCase(specialty)),
      ];
    } on AppException {
      // An empty grid rather than six specialties that may not be offered —
      // the search field above it still works.
      categories.clear();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// `internal-medicine` -> `Internal Medicine`. The server stores the slug.
  static String _titleCase(String slug) => slug
      .split(RegExp(r'[-_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  bool isSelected(DoctorCategory category) => selected.value.id == category.id;

  void select(DoctorCategory category) => selected.value = category;

  /// Typing a specialty is a shortcut into the same list.
  void onQuerySubmitted(String _) => openList();

  void openList() =>
      Get.toNamed<void>(AppRoutes.doctorList, arguments: selected.value);
}
