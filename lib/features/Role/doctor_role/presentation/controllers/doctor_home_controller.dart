import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/utils/app_navigator.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';
import 'doctor_shell_controller.dart';

/// Backs the practitioner dashboard: balance, statistics, quick actions, the
/// appointments chart and today's list.
class DoctorHomeController extends GetxController {
  DoctorHomeController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  /// Shown until the first load lands, so the masthead does not flash a name
  /// and a balance the practitioner does not have.
  final Rx<Practitioner> practitioner = const Practitioner(
    name: '',
    initials: '',
    availableBalance: 0,
  ).obs;

  final RxList<DayLoad> chartLoad = <DayLoad>[].obs;
  final RxList<PatientVisit> visits = <PatientVisit>[].obs;

  final RxBool isLoading = true.obs;

  /// Set when a load fails, so the screen can say what went wrong rather than
  /// showing zeroes that read as a quiet week.
  final RxnString error = RxnString();

  final Rx<ChartRange> range = ChartRange.weekly.obs;

  /// The four cards, in the order the design lays them out.
  ///
  /// Always four, even before the first load lands — the grid is a fixed 2×2
  /// and a shorter list would leave it indexing past the end.
  final RxList<PracticeStat> stats = <PracticeStat>[].obs;

  /// `—` rather than `0`: the practitioner has not been told they have no
  /// pending requests, only that the number is not in yet.
  List<PracticeStat> _statsFrom(DoctorDashboard? dashboard) => [
    PracticeStat(
      value: dashboard?.pendingRequests ?? '—',
      label: AppStrings.pendingApptRequests.tr,
    ),
    PracticeStat(
      value: dashboard?.todaysPatients ?? '—',
      label: AppStrings.todaysPatients.tr,
    ),
    PracticeStat(
      value: dashboard?.totalEarned ?? '—',
      label: AppStrings.totalEarned.tr,
    ),
    PracticeStat(
      value: dashboard?.totalPatients ?? '—',
      label: AppStrings.totalPatients.tr,
    ),
  ];

  /// The chart's y-axis top, which follows the busiest day rather than a
  /// number picked to suit the sample data.
  final RxInt chartMax = DoctorDashboard.chartDivisions.obs;

  int get chartDivisions => DoctorDashboard.chartDivisions;

  // ─── Fees sheet ──────────────────────────────────────────────────────────

  final RxString currency = DoctorPracticeData.currencies.first.obs;
  final RxString consultationFee = ''.obs;

  /// Bumped when the fee lands, so the sheet's field is rebuilt against it —
  /// it owns its text controller and seeds it once.
  final RxInt feeGeneration = 0.obs;

  @override
  void onInit() {
    super.onInit();
    stats.value = _statsFrom(null);
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final dashboard = await _repository.dashboard();
      practitioner.value = dashboard.practitioner;
      chartLoad.value = dashboard.load;
      visits.value = dashboard.visits;
      chartMax.value = dashboard.chartMax;
      stats.value = _statsFrom(dashboard);
      // Set Fees opens on what the practice charges now, not on the design's
      // placeholder — a sheet that shows $440 to a doctor charging $50 invites
      // them to save a figure they never chose.
      consultationFee.value = dashboard.consultationFee == 0
          ? ''
          : dashboard.consultationFee.toStringAsFixed(0);
      currency.value =
          DoctorPracticeData.currencies.contains(dashboard.currency)
          ? dashboard.currency
          : DoctorPracticeData.currencies.first;
      feeGeneration.value++;
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

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

  /// "See all" on the Upcoming Appointments card.
  ///
  /// The row it sits in used to be a bare `Text`/`Icon` pair with nothing
  /// wrapping them, so the tap had nowhere to go. The full list is a shell tab
  /// (`DoctorAppointmentsScreen`), not a pushed route, so this switches tabs
  /// the same way the patient Home's "See all" switches to Doctors.
  void openAppointments() =>
      Get.find<DoctorShellController>().select(DoctorTab.appointments);

  void selectCurrency(String value) => currency.value = value;

  /// Refuses an unparseable fee rather than posting a zero, which would make
  /// the practitioner free to consult until they noticed.
  Future<void> saveConsultationFee() async {
    final amount = double.tryParse(consultationFee.value.trim());
    if (amount == null || amount <= 0) {
      AppSnackbar.info(AppStrings.enterAValidAmount.tr);
      return;
    }
    try {
      await _repository.saveConsultationFee(
        amount: amount,
        currency: currency.value,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }
    Get.back<void>();
    AppSnackbar.success(AppStrings.consultationFeeSaved.tr);
  }

  /// Leaving the practitioner role returns to the patient app. Not currently
  /// wired to anything — the bell used to call this by mistake, which reset
  /// the whole app to patient Home on every tap instead of opening the feed.
  void exitDoctorRole() => AppNavigator.resetTo(AppRoutes.home);

  /// Opens the practitioner's notification feed.
  void openNotifications() =>
      Get.toNamed<void>(AppRoutes.doctorNotifications);
}
