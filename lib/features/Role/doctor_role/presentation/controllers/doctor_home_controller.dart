import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';

/// Backs the practitioner dashboard: balance, statistics, quick actions, the
/// appointments chart and today's list.
///
/// UI-only — everything comes from [DoctorPracticeData] and nothing calls an
/// API.
class DoctorHomeController extends GetxController {
  final Rx<Practitioner> practitioner = DoctorPracticeData.practitioner.obs;

  final RxList<DayLoad> load = <DayLoad>[].obs;
  final RxList<PatientVisit> visits = <PatientVisit>[].obs;

  final Rx<ChartRange> range = ChartRange.weekly.obs;

  // ─── Fees sheet ──────────────────────────────────────────────────────────

  final RxString currency = DoctorPracticeData.currencies.first.obs;
  final RxString consultationFee = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load.value = List.of(DoctorPracticeData.weeklyLoad);
    visits.value = List.of(DoctorPracticeData.upcomingVisits);
  }

  List<PracticeStat> get stats => [
    PracticeStat(
      value: DoctorPracticeData.pendingRequests,
      label: AppStrings.pendingApptRequests.tr,
    ),
    PracticeStat(
      value: DoctorPracticeData.todaysPatients,
      label: AppStrings.todaysPatients.tr,
    ),
    PracticeStat(
      value: DoctorPracticeData.totalEarned,
      label: AppStrings.totalEarned.tr,
    ),
    PracticeStat(
      value: DoctorPracticeData.totalPatients,
      label: AppStrings.totalPatients.tr,
    ),
  ];

  String rangeLabel(ChartRange value) => switch (value) {
    ChartRange.weekly => AppStrings.weekly.tr,
    ChartRange.monthly => AppStrings.monthly.tr,
  };

  void selectRange(ChartRange value) => range.value = value;

  String statusLabel(VisitStatus status) => switch (status) {
    VisitStatus.pending => AppStrings.filterPending.tr,
    VisitStatus.confirmed => AppStrings.confirmed.tr,
  };

  // ─── Actions ─────────────────────────────────────────────────────────────

  void openSchedule() => Get.toNamed<void>(AppRoutes.doctorSetSchedule);

  void openResultsToReview() =>
      Get.toNamed<void>(AppRoutes.doctorResultsToReview);

  void withdraw() => Get.toNamed<void>(AppRoutes.doctorEarnings);

  void selectCurrency(String value) => currency.value = value;

  void saveConsultationFee() {
    AppSnackbar.success(AppStrings.consultationFeeSaved.tr);
    Get.back<void>();
  }

  /// Leaving the practitioner role returns to the patient app.
  void exitDoctorRole() => AppNavigator.resetTo(AppRoutes.home);
}
