import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../data/static/doctor_orders_data.dart';
import '../../domain/entities/test_request.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs Results to Review and everything reached from it.
///
/// One controller for the whole flow because every screen in it is about the
/// same patient and the same order — the list picks them, and the detail,
/// review options and their four destinations all read them back.
///
/// The Patients segment is served by the API. The Lab and Radiology segments
/// are not: `GET /lab-orders` filters by `patientId`, so it answers "the
/// orders I am the subject of", and the backend has no route that answers
/// "the orders I requested". Until it does, those two segments show
/// [DoctorOrdersData] — see the note in `docs/API-GAPS.md`.
class ResultsToReviewController extends GetxController {
  ResultsToReviewController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  final RxList<ReviewPatient> patients = <ReviewPatient>[].obs;
  final RxList<TestRequest> requests = <TestRequest>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  final Rx<ResultsTab> tab = ResultsTab.patients.obs;
  final Rx<RequestFilter> filter = RequestFilter.all.obs;

  /// Live query from the patient search field.
  final RxString query = ''.obs;

  /// The row tapped into, and the order opened from it.
  final Rxn<ReviewPatient> patient = Rxn<ReviewPatient>();
  final Rxn<TestRequest> request = Rxn<TestRequest>();

  /// Which of the four review options is selected on `Choose review Option`.
  final Rx<ReviewOption> reviewOption = ReviewOption.messagePatient.obs;

  /// What the doctor typed into Write Message or Refer/Escalation. Plain
  /// strings, so those inputs own their text controllers.
  final RxString messageBody = ''.obs;
  final RxString referralBody = ''.obs;

  @override
  void onInit() {
    super.onInit();
    requests.value = List.of(DoctorOrdersData.requests);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      patients.value = await _repository.reviewPatients();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── List ────────────────────────────────────────────────────────────────

  /// Patients matching the search box; the whole roster when it is empty.
  List<ReviewPatient> get visiblePatients {
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return patients.toList();
    return patients
        .where((p) => p.name.toLowerCase().contains(search))
        .toList();
  }

  /// The lab or radiology segment's rows, narrowed by the chip above them.
  List<TestRequest> get visibleRequests {
    final kind = tab.value == ResultsTab.radiologyRequests
        ? OrderKind.radiology
        : OrderKind.lab;
    final source = kind == OrderKind.radiology
        ? DoctorOrdersData.radiologyRequests
        : requests;
    return source.where((r) => _matchesFilter(r.status)).toList();
  }

  bool _matchesFilter(RequestStatus status) => switch (filter.value) {
    RequestFilter.all => true,
    RequestFilter.inProgress => status == RequestStatus.requestSent,
    RequestFilter.toReview => status == RequestStatus.awaitingReview,
    // A reviewed order is one whose results have landed and been read.
    RequestFilter.resultsReady => status == RequestStatus.reviewed,
  };

  void selectTab(ResultsTab value) => tab.value = value;

  void selectFilter(RequestFilter value) => filter.value = value;

  String tabLabel(ResultsTab value) => switch (value) {
    ResultsTab.patients => AppStrings.patientsTab.tr,
    // The segment is called "Lab Orders" on the Patients tab and "Lab
    // Requests" once you are inside it, which is how the designs label them.
    ResultsTab.labRequests =>
      tab.value == ResultsTab.patients
          ? AppStrings.labOrders.tr
          : AppStrings.labRequests.tr,
    ResultsTab.radiologyRequests =>
      tab.value == ResultsTab.patients
          ? AppStrings.radiologyOrders.tr
          : AppStrings.radiologyRequests.tr,
  };

  String filterLabel(RequestFilter value) => switch (value) {
    RequestFilter.all => AppStrings.resultsFilterAll.tr,
    RequestFilter.inProgress => AppStrings.filterInProgress.tr,
    RequestFilter.toReview => AppStrings.filterToReview.tr,
    RequestFilter.resultsReady => AppStrings.resultsReady.tr,
  };

  // ─── Navigation ──────────────────────────────────────────────────────────

  void openPatient(ReviewPatient value) {
    patient.value = value;
    Get.toNamed<void>(AppRoutes.doctorReviewPatient);
  }

  void openRequest(TestRequest value) {
    request.value = value;
    patient.value = value.patient;
    Get.toNamed<void>(AppRoutes.doctorOrderDetail);
  }

  void chooseReview() => Get.toNamed<void>(AppRoutes.doctorChooseReview);

  void selectReviewOption(ReviewOption value) => reviewOption.value = value;

  /// The four options are four different screens; Order Additional Test
  /// re-enters the request flow at the patient screen it started from.
  void confirmReviewOption() => switch (reviewOption.value) {
    ReviewOption.messagePatient => Get.toNamed<void>(
      AppRoutes.doctorReviewMessage,
      arguments: ReviewOption.messagePatient,
    ),
    ReviewOption.followUpVisit => Get.toNamed<void>(
      AppRoutes.doctorRequestFollowUp,
    ),
    ReviewOption.additionalTest => Get.toNamed<void>(
      AppRoutes.doctorReviewPatient,
      arguments: ReviewOption.additionalTest,
    ),
    ReviewOption.refer => Get.toNamed<void>(
      AppRoutes.doctorReviewMessage,
      arguments: ReviewOption.refer,
    ),
  };
}
