import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/usecases/doctor_usecases.dart';

/// Backs the Search screen and the Doctors tab.
///
/// Typing is debounced so a keystroke does not fire a request per character;
/// the specialty chips filter the same query.
class DoctorSearchController extends GetxController {
  DoctorSearchController({
    required SearchDoctors searchDoctors,
    required GetSpecialties getSpecialties,
  }) : _searchDoctors = searchDoctors,
       _getSpecialties = getSpecialties;

  final SearchDoctors _searchDoctors;
  final GetSpecialties _getSpecialties;

  /// Sentinel for the leading chip, which clears the specialty filter.
  static const String allSpecialties = '__all__';

  static const Duration _debounce = Duration(milliseconds: 300);

  /// The live query. Held as a plain string, not a `TextEditingController` —
  /// see `DoctorSearchField`, which owns the text controller so it is
  /// disposed with the widget rather than with the route.
  final RxString query = ''.obs;

  final RxList<Doctor> results = <Doctor>[].obs;
  final RxList<String> specialties = <String>[].obs;
  final RxString selectedSpecialty = allSpecialties.obs;
  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  Timer? _debounceTimer;

  bool get hasResults => results.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadSpecialties();
    search();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadSpecialties() async {
    try {
      specialties.value = await _getSpecialties();
    } on AppException {
      // Chips are an enhancement; search still works without them.
      specialties.clear();
    }
  }

  void onQueryChanged(String value) {
    query.value = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, search);
  }

  void selectSpecialty(String specialty) {
    if (selectedSpecialty.value == specialty) return;
    selectedSpecialty.value = specialty;
    search();
  }

  bool isSelected(String specialty) => selectedSpecialty.value == specialty;

  Future<void> search() async {
    if (isClosed) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final found = await _searchDoctors(
        query: query.value,
        specialty: selectedSpecialty.value == allSpecialties
            ? null
            : selectedSpecialty.value,
      );
      // The request outlives the route: a debounced search fired just before
      // the screen was popped still resolves afterwards, and assigning to a
      // closed controller's observables throws.
      if (isClosed) return;
      results.value = found;
    } on AppException catch (error) {
      if (isClosed) return;
      errorMessage.value = error.message;
      results.clear();
    } catch (_) {
      if (isClosed) return;
      errorMessage.value = AppStrings.somethingWentWrong.tr;
      results.clear();
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void openDoctor(Doctor doctor) =>
      Get.toNamed<void>(AppRoutes.doctorDetails, arguments: doctor);
}
