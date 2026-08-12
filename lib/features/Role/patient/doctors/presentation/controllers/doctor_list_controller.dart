import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_category.dart';
import '../../domain/usecases/doctor_usecases.dart';

/// Backs "«Category» Doctor lists" and its filter sheet.
///
/// The roster comes from the API, narrowed to this category. The price and
/// rating filters are applied in memory: the server takes a specialty and a
/// search term, and neither of the other two.
class DoctorListController extends GetxController {
  DoctorListController({required this.category, SearchDoctors? search})
    : _search = search ?? Get.find<SearchDoctors>();

  final DoctorCategory category;

  final SearchDoctors _search;

  /// The catch-all category, which is every doctor rather than a specialty.
  static const String generalCategoryId = 'general';

  final RxList<Doctor> doctors = <Doctor>[].obs;
  final Rx<DoctorFilter> filter = const DoctorFilter().obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Everything the category holds, before the sheet narrows it.
  List<Doctor> _roster = const [];

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      // The category's id is its server token (`cardiology`), not its label
      // (`Cardiology`) — searching by the label matches nothing.
      //
      // `general` is the catch-all the design shows full-width above the
      // specialty grid, so it narrows to nothing rather than to doctors whose
      // specialty happens to be spelled that way.
      _roster = await _search(
        specialty: category.id == generalCategoryId ? null : category.id,
      );
      _applyFilter(filter.value);
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilter(DoctorFilter value) {
    filter.value = value;
    _applyFilter(value);
  }

  void resetFilter() => applyFilter(const DoctorFilter());

  void _applyFilter(DoctorFilter value) {
    doctors.value = _roster.where((doctor) {
      final withinPrice =
          doctor.consultationFee >= value.minPrice &&
          doctor.consultationFee <= value.maxPrice;
      // Star buckets are inclusive downwards: "4 Star" keeps 4.0–4.9.
      final matchesRating =
          value.ratings.isEmpty ||
          value.ratings.contains(doctor.rating.floor());
      return withinPrice && matchesRating;
    }).toList();
  }

  void openDoctor(Doctor doctor) =>
      Get.toNamed<void>(AppRoutes.doctorDetails, arguments: doctor);
}
