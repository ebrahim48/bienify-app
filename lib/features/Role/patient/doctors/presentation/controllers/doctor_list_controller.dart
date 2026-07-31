import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../data/static/doctor_mock_data.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_category.dart';

/// Backs "«Category» Doctor lists" and its filter sheet.
///
/// UI-only: the roster is static and filtering happens in memory, which is
/// exactly what a server-side query will replace later.
class DoctorListController extends GetxController {
  DoctorListController({required this.category});

  final DoctorCategory category;

  final RxList<Doctor> doctors = <Doctor>[].obs;
  final Rx<DoctorFilter> filter = const DoctorFilter().obs;

  /// The roster the design shows: nine rows, so the list scrolls.
  List<Doctor> get _roster => [
    ...DoctorMockData.doctors,
    ...DoctorMockData.doctors.skip(4),
    ...DoctorMockData.doctors.skip(4),
    ...DoctorMockData.doctors.skip(4),
    ...DoctorMockData.doctors.skip(4),
  ];

  @override
  void onInit() {
    super.onInit();
    _applyFilter(const DoctorFilter());
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
