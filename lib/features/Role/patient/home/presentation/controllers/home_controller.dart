import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../main/presentation/controllers/main_nav_controller.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../doctors/domain/entities/doctor.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/lab_request.dart';
import '../../domain/usecases/home_usecases.dart';

/// Loading lifecycle of the Home feed.
enum HomeStatus { initial, loading, success, failure }

/// Backs the Home tab.
///
/// Holds one [HomeFeed] plus a [HomeStatus], so the screen has a single
/// source of truth for skeleton / content / error rather than a flag per
/// section.
class HomeController extends GetxController {
  HomeController({required GetHomeFeed getHomeFeed})
    : _getHomeFeed = getHomeFeed;

  final GetHomeFeed _getHomeFeed;

  final Rx<HomeStatus> status = HomeStatus.initial.obs;
  final Rx<HomeFeed> feed = const HomeFeed.empty().obs;
  final RxnString errorMessage = RxnString();

  // ─── Derived view state ──────────────────────────────────────────────────

  String get patientName => feed.value.patientName;

  String? get patientPhotoUrl => feed.value.patientPhotoUrl;
  String get location => feed.value.location;
  List<LabRequest> get labRequests => feed.value.labRequests;
  List<Appointment> get upcomingAppointments => feed.value.upcomingAppointments;
  List<Doctor> get nearbyDoctors => feed.value.nearbyDoctors;

  bool get isLoading =>
      status.value == HomeStatus.loading || status.value == HomeStatus.initial;
  bool get hasFailed => status.value == HomeStatus.failure;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    status.value = HomeStatus.loading;
    errorMessage.value = null;
    try {
      feed.value = await _getHomeFeed();
      status.value = HomeStatus.success;
      _syncNavBadges();
    } on AppException catch (error) {
      errorMessage.value = error.message;
      status.value = HomeStatus.failure;
    } catch (_) {
      errorMessage.value = AppStrings.somethingWentWrong.tr;
      status.value = HomeStatus.failure;
    }
  }

  /// Pull-to-refresh; keeps the current content on screen while reloading.
  Future<void> refreshFeed() async {
    try {
      feed.value = await _getHomeFeed();
      status.value = HomeStatus.success;
      _syncNavBadges();
    } on AppException catch (error) {
      AppSnackbar.error(error.message);
    }
  }

  /// Mirrors unread counts from the feed onto the bottom navigation.
  void _syncNavBadges() {
    if (!Get.isRegistered<MainNavController>()) return;
    Get.find<MainNavController>().setBadge(1, feed.value.unreadAppointments);
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  void openSearch() => Get.toNamed<void>(AppRoutes.search);

  void openDoctor(Doctor doctor) =>
      Get.toNamed<void>(AppRoutes.doctorDetails, arguments: doctor);

  /// Header message shortcut opens the most recent thread.
  /// Opens the thread list, not a thread.
  ///
  /// This went straight to `AppRoutes.chat`, which — with no peer argument —
  /// dropped the patient into the sample conversation with whichever doctor
  /// `ChatMockData.peer` names, no matter who they had actually messaged.
  void openMessages() => Get.toNamed<void>(AppRoutes.messages);

  void seeAllDoctors() => _nav.select(2);

  /// Opens the feed.
  ///
  /// This switched to the Appointments tab, so a notification about an order,
  /// a lab result or a payment took the patient somewhere unrelated to it —
  /// and looked deliberate rather than unfinished.
  void openNotifications() => Get.toNamed<void>(AppRoutes.notifications);

  void openCart() => _nav.select(3);

  /// The header avatar is the entry point into the account section.
  void openProfile() => Get.toNamed<void>(AppRoutes.profile);

  void changeLocation() => AppSnackbar.info(location);

  /// Reviewing an order is the first step of the booking flow, so it opens
  /// the ordering doctor's profile.
  void reviewLabRequest(LabRequest request) {
    final doctor = nearbyDoctors.firstWhereOrNull(
      (candidate) => candidate.name.contains(request.requestedBy),
    );
    if (doctor != null) {
      Get.toNamed<void>(AppRoutes.doctorDetails, arguments: doctor);
      return;
    }
    // The ordering clinician is not in the nearby list — send the patient to
    // the directory rather than nowhere.
    _nav.select(2);
  }

  /// A consultation room opens shortly before the slot.
  ///
  /// This used to open `/chat` unconditionally — joining a video consultation
  /// landed the patient in messaging, never the call. It also had no separate
  /// answer for a booking still awaiting payment, which `canJoin` already
  /// excludes, so it silently read as "come back later" instead of "you still
  /// need to pay for this".
  void joinAppointment(Appointment appointment) {
    if (appointment.status == AppointmentStatus.pendingPayment) {
      Get.toNamed<void>(AppRoutes.paymentSummary, arguments: appointment);
      return;
    }
    if (!appointment.canJoin) {
      AppSnackbar.info(AppStrings.joinOpensSoon.tr);
      return;
    }
    Get.toNamed<void>(AppRoutes.videoCall, arguments: appointment);
  }

  MainNavController get _nav => Get.find<MainNavController>();
}
