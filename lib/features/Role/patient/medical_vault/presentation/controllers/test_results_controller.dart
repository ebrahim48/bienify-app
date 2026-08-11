import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/medical_mock_data.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/vault_repository.dart';

/// Backs My tests and results: the discipline toggle, the filter chips and
/// the card list, plus the order → book → upload → review journey.
///
/// One controller across those screens because the chosen order and the
/// chosen testing centre follow the patient through all of them.
class TestResultsController extends GetxController {
  TestResultsController({VaultRepository? repository})
    : _repository = repository ?? Get.find<VaultRepository>();

  final VaultRepository _repository;

  final RxList<TestOrder> allOrders = <TestOrder>[].obs;

  /// Where the patient can have a test done.
  final RxList<TestingCentre> centres = <TestingCentre>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  final Rx<ResultDiscipline> discipline = ResultDiscipline.laboratory.obs;
  final Rx<ResultFilter> filter = ResultFilter.all.obs;

  /// The order the patient tapped into.
  final Rxn<TestOrder> selected = Rxn<TestOrder>();

  /// Where they chose to have it done, once picked.
  final Rxn<TestingCentre> centre = Rxn<TestingCentre>();

  /// The note typed on the upload screen, and whether a file is attached.
  final RxString note = ''.obs;
  final RxBool hasDocument = false.obs;

  /// What the doctor came back with, on the review screen.
  final Rx<ReviewOutcome> outcome = ReviewOutcome.pending.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      allOrders.value = await _repository.testOrders();
      centres.value = await _repository.testingCentres();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── List ────────────────────────────────────────────────────────────────

  /// The chips group stages rather than mapping one-to-one: "Active Orders"
  /// covers everything the patient still has to act on.
  bool _matchesFilter(TestOrder order) => switch (filter.value) {
    ResultFilter.all => true,
    ResultFilter.activeOrders =>
      order.stage == TestStage.requestSent ||
          order.stage == TestStage.awaitingUpload,
    ResultFilter.resultsReady => order.stage == TestStage.awaitingReview,
    ResultFilter.reviewed => order.stage == TestStage.reviewed,
  };

  List<TestOrder> get orders => allOrders
      .where((o) => o.discipline == discipline.value && _matchesFilter(o))
      .toList();

  void selectDiscipline(ResultDiscipline value) => discipline.value = value;

  void selectFilter(ResultFilter value) => filter.value = value;

  String disciplineLabel(ResultDiscipline value) => switch (value) {
    ResultDiscipline.laboratory => AppStrings.labResults.tr,
    ResultDiscipline.radiology => AppStrings.radiologyResults.tr,
  };

  String filterLabel(ResultFilter value) => switch (value) {
    // Its own key, not the directory's `filterAll`: this chip is lowercase
    // "all" in the design while the doctor filters are capitalised "All".
    ResultFilter.all => AppStrings.resultsFilterAll.tr,
    ResultFilter.activeOrders => AppStrings.activeOrders.tr,
    ResultFilter.resultsReady => AppStrings.resultsReady.tr,
    ResultFilter.reviewed => AppStrings.reviewed.tr,
  };

  String stageLabel(TestStage stage) => switch (stage) {
    TestStage.requestSent => AppStrings.requestSent.tr,
    TestStage.awaitingUpload => AppStrings.uploadReport.tr,
    TestStage.awaitingReview => AppStrings.awaitingReview.tr,
    TestStage.reviewed => AppStrings.reviewed.tr,
  };

  /// The link at the foot of each card, which is what the stage really
  /// determines: what the patient can do next.
  String actionLabel(TestStage stage) => switch (stage) {
    TestStage.requestSent => AppStrings.reviewRequest.tr,
    TestStage.awaitingUpload => AppStrings.uploadReport.tr,
    TestStage.awaitingReview => AppStrings.uploadReport.tr,
    TestStage.reviewed => AppStrings.viewReview.tr,
  };

  // ─── Journey ─────────────────────────────────────────────────────────────

  /// Every card's action opens something different, which is the whole point
  /// of the stage: a fresh request opens the order sheet, a booked test opens
  /// the upload form, a read one opens the doctor's review.
  void openAction(TestOrder order) {
    selected.value = order;
    switch (order.stage) {
      case TestStage.requestSent:
        Get.toNamed<void>(AppRoutes.testOrder);
      case TestStage.awaitingUpload:
        Get.toNamed<void>(AppRoutes.uploadTestReport);
      case TestStage.awaitingReview:
        _seedUploadedReport();
        Get.toNamed<void>(AppRoutes.reportReview);
      case TestStage.reviewed:
        _seedUploadedReport();
        outcome.value = ReviewOutcome.followUpOffered;
        Get.toNamed<void>(AppRoutes.reportReview);
    }
  }

  /// A card past the upload step already has a report and a note attached —
  /// the review screen renders both, so they have to be there.
  void _seedUploadedReport() {
    hasDocument.value = true;
    if (note.value.isEmpty) note.value = MedicalMockData.patientNote;
  }

  void openTestingCentres() => Get.toNamed<void>(AppRoutes.testingCentres);

  void selectCentre(TestingCentre value) {
    centre.value = value;
    Get.back<void>();
  }

  /// The facility shown on the order sheet and the upload banner: whichever
  /// centre was picked, otherwise the one already on the order.
  String get facilityName =>
      centre.value?.name ??
      selected.value?.facility ??
      MedicalMockData.defaultFacility;

  String get doctorName =>
      selected.value?.orderedBy ?? MedicalMockData.orderingDoctor;

  void completedTest() => Get.toNamed<void>(AppRoutes.uploadTestReport);

  // ─── Upload ──────────────────────────────────────────────────────────────

  /// UI-only: file capture is a marked seam, so this attaches the bundled
  /// report image and lets the rest of the flow proceed.
  void attachDocument() => hasDocument.value = true;

  void removeDocument() => hasDocument.value = false;

  bool get canUpload => hasDocument.value;

  void upload() {
    if (!canUpload) {
      AppSnackbar.info(AppStrings.addReportDocument.tr);
      return;
    }
    outcome.value = ReviewOutcome.pending;
    Get.toNamed<void>(AppRoutes.resultsSubmitted);
  }

  /// From the success screen into the review, which is where the patient
  /// waits for the doctor.
  void viewSubmittedReport() => Get.offNamed<void>(AppRoutes.reportReview);

  // ─── Review ──────────────────────────────────────────────────────────────

  /// The follow-up panel shows for every outcome past `pending` — the doctor
  /// has looked at it and said something, and what follows differs.
  bool get hasFollowUp => outcome.value != ReviewOutcome.pending;

  /// A free-text section the doctor's outcome adds under the panel, and its
  /// heading. `null` when the outcome has no note to write.
  String? get noteSectionLabel => switch (outcome.value) {
    ReviewOutcome.messaged => AppStrings.message.tr,
    ReviewOutcome.referred => AppStrings.referAndEscalation.tr,
    _ => null,
  };

  /// Whatever the patient types into that section.
  final RxString replyNote = ''.obs;

  bool get hasRequest => outcome.value == ReviewOutcome.furtherTestRequested;

  FollowUpRequest get request => MedicalMockData.followUpRequest;

  /// Accepting the follow-up starts a consultation, which the booking flow
  /// already owns — the doctor directory is its entry point.
  void acceptFollowUp() => Get.toNamed<void>(AppRoutes.search);

  /// UI-only: PDF export is a marked seam.
  void downloadDocument() => AppSnackbar.info(AppStrings.downloadPdf.tr);
}
