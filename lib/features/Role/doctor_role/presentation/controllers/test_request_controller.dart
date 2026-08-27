import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/test_request.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the three-step request wizard.
///
/// One controller and one screen for both kinds of order: the designs draw
/// the same three steps, and only what each step *holds* differs — a lab
/// request takes its notes on step two, an imaging request picks a subtest
/// there and reviews everything on step three.
class TestRequestController extends GetxController {
  TestRequestController({
    required this.kind,
    required this.patient,
    DoctorPracticeRepository? repository,
  }) : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final OrderKind kind;
  final ReviewPatient patient;

  final DoctorPracticeRepository _repository;

  static const int stepCount = 3;

  final RxInt step = 0.obs;

  final RxBool isSubmitting = false.obs;

  /// Live query from the search field above the catalogue.
  final RxString query = ''.obs;

  final RxnString selectedTest = RxnString();
  final RxnString selectedSubtest = RxnString();

  final RxString clinicalNotes = ''.obs;
  final RxString instructions = ''.obs;

  /// Whether the doctor has signed. The strokes themselves live in the pad —
  /// a drawing is widget state, and holding sampled points here would rebuild
  /// the canvas on every one of them.
  final RxBool hasSignature = false.obs;

  final Rx<OrderPriority> priority = OrderPriority.routine.obs;

  bool get isRadiology => kind == OrderKind.radiology;

  /// The orderable tests for this discipline, from `GET /diagnostic-tests`.
  ///
  /// Hardcoded before this, so a test the admin added never appeared in the
  /// wizard and one they retired never left it.
  final RxList<DiagnosticTest> catalogue = <DiagnosticTest>[].obs;

  final RxBool isLoadingCatalogue = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    isLoadingCatalogue.value = true;
    try {
      catalogue.value = await _repository.testCatalogue(radiology: isRadiology);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isLoadingCatalogue.value = false;
    }
  }

  /// The catalogue, narrowed by the search box. The free-text row at the foot
  /// is drawn by the screen, not stored here — it is an affordance, not a test.
  List<String> get visibleTests {
    final names = catalogue.map((t) => t.name).toList();
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return names;
    return names.where((test) => test.toLowerCase().contains(search)).toList();
  }

  /// The body regions an imaging study can cover, taken from the categories the
  /// catalogue actually groups its radiology tests under.
  ///
  /// This used to redraw the modality list a second time, so step two offered
  /// "MRI" as a sub-study of "MRI".
  List<String> get subtests =>
      catalogue.map((t) => t.category).toSet().toList()..sort();

  /// The catalogue row behind the current selection, which is what carries the
  /// modality the order has to be filed with.
  DiagnosticTest? get selectedCatalogueTest {
    final name = selectedTest.value;
    if (name == null) return null;
    for (final test in catalogue) {
      if (test.name == name) return test;
    }
    return null;
  }

  String get title => isRadiology
      ? AppStrings.requestRadiologyTest.tr
      : AppStrings.requestLabTest.tr;

  /// Only the imaging flow captions its steps.
  String? get sectionHeading {
    if (!isRadiology) return null;
    return switch (step.value) {
      0 => AppStrings.study.tr,
      1 => AppStrings.details.tr,
      _ => AppStrings.reviewAndSubmit.tr,
    };
  }

  /// Whether the primary button is live. Both flows refuse to leave step one
  /// without a test, and imaging also wants its subtest.
  bool get canContinue => switch (step.value) {
    0 => selectedTest.value != null,
    1 => !isRadiology || selectedSubtest.value != null,
    _ => true,
  };

  bool get isLastStep => step.value == stepCount - 1;

  void selectTest(String value) => selectedTest.value = value;

  void selectSubtest(String value) => selectedSubtest.value = value;

  void selectPriority(OrderPriority value) => priority.value = value;

  String priorityLabel(OrderPriority value) => switch (value) {
    OrderPriority.routine => AppStrings.priorityRoutine.tr,
    OrderPriority.urgent => AppStrings.priorityUrgent.tr,
    OrderPriority.stat => AppStrings.priorityStat.tr,
  };

  void signed(bool value) => hasSignature.value = value;

  /// Refuses an empty pad rather than filing a blank signature.
  void saveSignature() {
    if (!hasSignature.value) {
      AppSnackbar.info(AppStrings.signFirst.tr);
      return;
    }
    AppSnackbar.success(AppStrings.signatureSaved.tr);
  }

  void next() {
    if (!canContinue) {
      AppSnackbar.info(AppStrings.pickATestFirst.tr);
      return;
    }
    if (isLastStep) {
      submit();
      return;
    }
    step.value++;
  }

  /// Steps back through the wizard before leaving it, so the chevron walks
  /// the flow rather than dropping out of it.
  bool stepBack() {
    if (step.value == 0) return false;
    step.value--;
    return true;
  }

  /// Files the order against the patient the wizard was opened for.
  ///
  /// The imaging flow's subtest is the more specific of the two selections, so
  /// it is what goes on the order; the study it sits under is the heading, not
  /// the test being run.
  Future<void> submit() async {
    if (isSubmitting.value) return;

    if (patient.id.isEmpty) {
      AppSnackbar.info(AppStrings.testNeedsPatient.tr);
      return;
    }
    // The study is the test; the second step narrows *where* on the body, which
    // is the order's body region rather than a different test. It used to be
    // sent as the test name, so an MRI brain was filed as an order for
    // "Head and neck".
    final test = selectedTest.value;
    if (test == null) {
      AppSnackbar.info(AppStrings.pickATestFirst.tr);
      return;
    }

    // Priority is a field on the order now, so the note stays clinical. It used
    // to be prepended as text because the order had nowhere to carry it, which
    // is why every seeded indication began "Routine — ".
    final note = [
      if (clinicalNotes.value.trim().isNotEmpty) clinicalNotes.value.trim(),
      if (instructions.value.trim().isNotEmpty) instructions.value.trim(),
    ].join(' — ');

    isSubmitting.value = true;
    try {
      await _repository.orderTest(
        patientId: patient.id,
        tests: [test],
        notes: note,
        imaging: isRadiology,
        modality: selectedCatalogueTest?.modality,
        bodyRegion: isRadiology ? selectedSubtest.value : null,
        priority: priority.value.name,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }

    AppSnackbar.success(AppStrings.orderSubmitted.tr);
    // Back to Results to Review, where the new order now sits, rather than
    // unwinding one screen at a time through the wizard. `isFirst` is the
    // safety net: a predicate that never matches empties the whole stack.
    Get.until(
      (route) =>
          route.settings.name == AppRoutes.doctorResultsToReview ||
          route.isFirst,
    );
  }
}
