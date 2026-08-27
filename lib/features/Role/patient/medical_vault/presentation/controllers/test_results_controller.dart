import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../chat/presentation/widgets/attachment_sheet.dart';
import '../../domain/entities/medical_record.dart';
import '../../domain/repositories/vault_repository.dart';

/// Backs My tests and results: the discipline toggle, the filter chips and
/// the card list, plus the order → book → upload → review journey.
///
/// One controller across those screens because the chosen order and the
/// chosen testing centre follow the patient through all of them.
class TestResultsController extends GetxController {
  TestResultsController({
    VaultRepository? repository,
    AttachmentPickerService? picker,
  }) : _repository = repository ?? Get.find<VaultRepository>(),
       _picker = picker ?? Get.find<AttachmentPickerService>();

  final VaultRepository _repository;
  final AttachmentPickerService _picker;

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
    orderDocument.value = order.document;
    switch (order.stage) {
      case TestStage.requestSent:
        Get.toNamed<void>(AppRoutes.testOrder);
      case TestStage.awaitingUpload:
        Get.toNamed<void>(AppRoutes.uploadTestReport);
      case TestStage.awaitingReview:
        hasDocument.value = true;
        outcome.value = ReviewOutcome.pending;
        Get.toNamed<void>(AppRoutes.reportReview);
      case TestStage.reviewed:
        hasDocument.value = true;
        // What the doctor actually said, rather than a fixture that assumed
        // every review offered a follow-up.
        outcome.value = order.reviewMessage == null
            ? ReviewOutcome.pending
            : ReviewOutcome.messaged;
        Get.toNamed<void>(AppRoutes.reportReview);
    }
  }

  void openTestingCentres() => Get.toNamed<void>(AppRoutes.testingCentres);

  /// True while the facility choice is being saved.
  final RxBool isSavingCentre = false.obs;

  /// Records where the patient chose to be tested.
  ///
  /// This used to set a local field and pop the sheet — the choice lived in
  /// memory until the app was closed, and the order never knew about it. The
  /// server needs it: nothing may reach the lab states until a facility is on
  /// the order, because a sample cannot be collected somewhere nobody named.
  Future<void> selectCentre(TestingCentre value) async {
    final order = selected.value;
    centre.value = value;

    // The picker is also reachable from the vault's own testing-centre list,
    // with no order in hand. That is a browse, not a choice to record.
    if (order == null || order.stage != TestStage.requestSent) {
      Get.back<void>();
      return;
    }

    isSavingCentre.value = true;
    try {
      await _repository.selectTestingCentre(
        labOrderId: order.id,
        testingCentreId: value.id,
      );
      await load();
      selected.value = allOrders.firstWhereOrNull((o) => o.id == order.id);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSavingCentre.value = false;
    }
    Get.back<void>();
  }

  /// True while an accept/decline is in flight.
  final RxBool isResponding = false.obs;

  /// Whether the patient still owes the doctor an answer.
  ///
  /// Only a brand-new order can be answered — once accepted it moves on, and a
  /// declined one is cancelled. The server enforces the same rule; this keeps
  /// the buttons off a screen where pressing them would only produce an error.
  bool get canRespond =>
      selected.value != null &&
      selected.value!.stage == TestStage.requestSent &&
      !hasFacility;

  /// Accepting or declining a test the doctor raised.
  ///
  /// The endpoint has existed since the platform routes were written and no
  /// screen ever called it, so a patient had no way to refuse a test — the
  /// order simply sat in `requested` for ever.
  Future<void> respond({required bool accept}) async {
    final order = selected.value;
    if (order == null || isResponding.value) return;

    isResponding.value = true;
    try {
      await _repository.respondToLabOrder(
        labOrderId: order.id,
        accept: accept,
      );
      await load();
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isResponding.value = false;
    }

    if (accept) {
      // Accepting is only half the step; the order cannot move until a centre
      // is chosen, so send them straight there.
      selected.value = allOrders.firstWhereOrNull((o) => o.id == order.id);
      openTestingCentres();
    } else {
      AppSnackbar.success(AppStrings.testDeclined.tr);
      Get.back<void>();
    }
  }

  /// The facility shown on the order sheet and the upload banner: whichever
  /// centre was picked, otherwise the one already on the order.
  ///
  /// Falls back to a prompt rather than a fixture. Naming a real clinic the
  /// patient never chose is worse than an empty state — they would turn up
  /// somewhere the order does not point at.
  String get facilityName =>
      centre.value?.name ??
      selected.value?.facility ??
      AppStrings.noFacilityChosen.tr;

  /// True once a centre is actually on the order, so a screen can tell
  /// "not chosen yet" from a real name.
  bool get hasFacility =>
      centre.value != null || selected.value?.facility != null;

  String get doctorName =>
      selected.value?.orderedBy ?? AppStrings.yourDoctor.tr;

  /// The signed order sheet for whichever order is open.
  ///
  /// Built from the order row and the signed-in account. It used to be a
  /// `const` fixture on every screen that showed it, so a patient opening
  /// their own order read another person's name, date of birth, insurer and
  /// member id, under a doctor and a DEA registration that existed nowhere.
  final Rxn<TestOrderDocument> orderDocument = Rxn<TestOrderDocument>();

  void completedTest() => Get.toNamed<void>(AppRoutes.uploadTestReport);

  // ─── Upload ──────────────────────────────────────────────────────────────

  /// The report the patient picked, held until they press Upload.
  ///
  /// This used to be `hasDocument.value = true` and nothing else: the screen
  /// said a report was attached, the success screen said it was submitted, and
  /// no file was ever chosen or stored. The boolean is kept only because the
  /// review screen renders a thumbnail for orders that are already past this
  /// step and have no local file to show.
  final Rxn<PickedAttachment> document = Rxn<PickedAttachment>();

  /// 0–1 while the upload runs, null when idle.
  final RxnDouble uploadProgress = RxnDouble();

  /// Asks what to attach, then holds it. A camera shot and a PDF are both
  /// normal here — a lab hands over paper as often as a file.
  Future<void> attachDocument(BuildContext context) async {
    final source = await AttachmentSheet.show(context);
    if (source == null) return;

    try {
      final picked = await _picker.pick(source);
      if (picked == null) return;
      document.value = picked;
      hasDocument.value = true;
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    }
  }

  void removeDocument() {
    document.value = null;
    hasDocument.value = false;
  }

  bool get canUpload => hasDocument.value && uploadProgress.value == null;

  /// Stores the report in the vault, then moves on.
  ///
  /// The navigation happens only after the record exists. Announcing success
  /// first and uploading afterwards is what made the old version look like it
  /// worked.
  Future<void> upload() async {
    final picked = document.value;
    if (picked == null) {
      AppSnackbar.info(AppStrings.addReportDocument.tr);
      return;
    }

    final order = selected.value;

    uploadProgress.value = 0;
    try {
      if (order == null) {
        // Reached from the vault rather than from an order: this is a document
        // the patient is filing for themselves, with nothing to attach it to.
        await _repository.uploadDocument(
          path: picked.file.path,
          fileName: picked.name,
          mimeType: picked.mime,
          // Radiology films and lab printouts are filed differently, and the
          // screen already knows which list the patient came from.
          type: discipline.value == ResultDiscipline.radiology
              ? VaultRecordType.imaging
              : VaultRecordType.labReport,
          notes: note.value,
          onProgress: (value) => uploadProgress.value = value,
        );
      } else {
        // Against an order, filing the result is what completes it and sends
        // it to the doctor. The generic vault upload used to be called here
        // instead: the document landed in the patient's vault, the order stayed
        // where it was, and the doctor was never told anything had arrived.
        await _repository.uploadLabResult(
          labOrderId: order.id,
          path: picked.file.path,
          fileName: picked.name,
          mimeType: picked.mime,
          notes: note.value,
          onProgress: (value) => uploadProgress.value = value,
        );
        await load();
      }
      outcome.value = ReviewOutcome.pending;
      Get.toNamed<void>(AppRoutes.resultsSubmitted);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      uploadProgress.value = null;
    }
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

  /// Whether the doctor's review asked for another test.
  ///
  /// Always false today: `PATCH /lab-orders/:id/review` carries a message and
  /// nothing else, so there is no follow-up request on the wire to render. The
  /// card used to draw `MedicalMockData.followUpRequest` — a fixture the
  /// patient could act on, describing a test no doctor had ordered. Hiding it
  /// is the honest state until the endpoint carries one.
  bool get hasRequest => false;

  /// What the doctor wrote when they reviewed the result.
  String get reviewMessage => selected.value?.reviewMessage ?? '';

  /// Accepting the follow-up starts a consultation, which the booking flow
  /// already owns — the doctor directory is its entry point.
  void acceptFollowUp() => Get.toNamed<void>(AppRoutes.search);

  /// UI-only: PDF export is a marked seam.
  void downloadDocument() => AppSnackbar.info(AppStrings.downloadPdf.tr);
}
