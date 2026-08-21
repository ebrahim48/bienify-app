import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_orders_data.dart';
import '../../domain/entities/test_request.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs Results to Review and everything reached from it.
///
/// One controller for the whole flow because every screen in it is about the
/// same patient and the same order — the list picks them, and the detail,
/// review options and their four destinations all read them back.
///
/// The Patients and Lab segments are served by the API — `GET /lab-orders`
/// answers "the orders I requested" when asked with `role=doctor`, and
/// `PATCH /lab-orders/:id/review` is what actually sends the doctor's note and
/// moves the order to `reviewed`.
///
/// Radiology still shows [DoctorOrdersData]: the backend models every order as
/// a lab order and has no imaging equivalent, so there is nothing to read.
/// See the note in `docs/API-GAPS.md`.
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
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _repository.reviewPatients(),
        _repository.labRequests(),
      ]);
      patients.value = results[0] as List<ReviewPatient>;
      requests.value = results[1] as List<TestRequest>;
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

  /// True while a review is in flight, so the button can guard a double tap.
  final RxBool isSubmitting = false.obs;

  /// A real server id, as opposed to a placeholder from the static data.
  static final RegExp _objectId = RegExp(r'^[a-f0-9]{24}$');

  static bool _isServerId(String id) => _objectId.hasMatch(id);

  /// Sends the doctor's note to the patient and marks the order reviewed.
  ///
  /// This whole flow used to end at a snackbar: the text was captured into
  /// [messageBody] / [referralBody] and then dropped, nothing was sent, and
  /// the order kept whatever status it already had. Returns true when the
  /// server accepted it, so the screen only navigates away on success.
  Future<bool> submitReview({required bool isReferral}) async {
    if (isSubmitting.value) return false;

    final order = request.value;
    if (order == null) {
      AppSnackbar.error(AppStrings.somethingWentWrong.tr);
      return false;
    }

    // Radiology is still [DoctorOrdersData] — the backend models every order
    // as a lab order and has none of its own — so those rows carry ids like
    // `rad-r-1`. Sending one reached the server and came back "Validation
    // failed", which reads as a bug in the message rather than a feature that
    // does not exist yet. Refuse it here, and say which it is.
    if (order.kind == OrderKind.radiology || !_isServerId(order.id)) {
      AppSnackbar.info(AppStrings.radiologyReviewUnavailable.tr);
      return false;
    }

    // Only a finished result can be reviewed; the server enforces this too,
    // but its transition error names internal states the doctor never sees.
    if (order.status != RequestStatus.awaitingReview) {
      AppSnackbar.info(AppStrings.resultNotReadyToReview.tr);
      return false;
    }

    final message = (isReferral ? referralBody.value : messageBody.value).trim();
    if (message.isEmpty) {
      AppSnackbar.info(AppStrings.writeYourMessage.tr);
      return false;
    }

    isSubmitting.value = true;
    try {
      await _repository.reviewLabOrder(
        labOrderId: order.id,
        message: message,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isSubmitting.value = false;
    }

    // Clear the drafts so the next order does not open with this one's text.
    messageBody.value = '';
    referralBody.value = '';

    // The list holds the pre-review status, so without this the row still
    // reads "Awaiting review" after the server has moved it on.
    await load();
    AppSnackbar.success(AppStrings.sentToPatient.tr);
    return true;
  }

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
