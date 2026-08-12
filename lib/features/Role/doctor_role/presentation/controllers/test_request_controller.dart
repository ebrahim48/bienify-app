import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_orders_data.dart';
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

  /// The catalogue, narrowed by the search box. The free-text row at the foot
  /// is drawn by the screen, not stored here — it is an affordance, not a test.
  List<String> get visibleTests {
    final catalogue = isRadiology
        ? DoctorOrdersData.radiologyTests
        : DoctorOrdersData.labTests;
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return catalogue;
    return catalogue
        .where((test) => test.toLowerCase().contains(search))
        .toList();
  }

  /// The imaging flow draws the same catalogue again as its subtests, which is
  /// what the design shows.
  List<String> get subtests => DoctorOrdersData.radiologyTests;

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
    final test = selectedSubtest.value ?? selectedTest.value;
    if (test == null) {
      AppSnackbar.info(AppStrings.pickATestFirst.tr);
      return;
    }

    // Priority and the signature have nowhere to go on a lab order, so they
    // ride along in the note rather than being dropped without trace.
    final note = [
      priorityLabel(priority.value),
      if (clinicalNotes.value.trim().isNotEmpty) clinicalNotes.value.trim(),
      if (instructions.value.trim().isNotEmpty) instructions.value.trim(),
    ].join(' — ');

    isSubmitting.value = true;
    try {
      await _repository.orderTest(
        patientId: patient.id,
        tests: [test],
        notes: note,
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
