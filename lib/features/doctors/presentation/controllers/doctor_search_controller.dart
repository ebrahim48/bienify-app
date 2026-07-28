import 'dart:async';

import 'package:flutter/widgets.dart';
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

  final TextEditingController queryController = TextEditingController();

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
    queryController.dispose();
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

  void onQueryChanged(String _) {
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
    isLoading.value = true;
    errorMessage.value = null;
    try {
      results.value = await _searchDoctors(
        query: queryController.text,
        specialty: selectedSpecialty.value == allSpecialties
            ? null
            : selectedSpecialty.value,
      );
    } on AppException catch (error) {
      errorMessage.value = error.message;
      results.clear();
    } catch (_) {
      errorMessage.value = AppStrings.somethingWentWrong.tr;
      results.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void openDoctor(Doctor doctor) =>
      Get.toNamed<void>(AppRoutes.doctorDetails, arguments: doctor);
}
