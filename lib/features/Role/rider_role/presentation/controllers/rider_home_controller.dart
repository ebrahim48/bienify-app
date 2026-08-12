import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';
import 'rider_orders_controller.dart';
import 'rider_shell_controller.dart';

/// Backs the courier's dashboard.
class RiderHomeController extends GetxController {
  RiderHomeController({RiderRepository? repository})
    : _repository = repository ?? Get.find<RiderRepository>();

  final RiderRepository _repository;

  /// Empty until the first load lands, so the masthead does not flash a name
  /// and a set of figures the courier has not earned.
  final Rx<Rider> rider = const Rider(
    name: '',
    location: '',
    todaysEarnings: 0,
    deliveriesToday: 0,
    rating: 0,
    isOnline: false,
    email: '',
    country: '',
    city: '',
    address: '',
  ).obs;

  final RxList<DeliveryRecord> recent = <DeliveryRecord>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// How many finished deliveries the dashboard lists.
  static const int _recentCount = 3;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      rider.value = await _repository.rider();
      recent.value = (await _repository.earnings()).history
          .take(_recentCount)
          .toList();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Jobs the courier could take, counted off the shared board rather than
  /// fetched again — it is the same list the Orders tab shows.
  ///
  /// Reading `requests` rather than calling `openCount` is what makes the
  /// count reactive: an `Obx` around this only subscribes to observables it
  /// touches during its build, and a plain method call touches none.
  int get openRequests {
    if (!Get.isRegistered<RiderOrdersController>()) return 0;
    return Get.find<RiderOrdersController>()
        .requests
        .where((r) => r.tab == RequestTab.fresh)
        .length;
  }

  /// Going offline stops new work arriving.
  ///
  /// The card only flips once the server has taken the change: a courier who
  /// believes they are offline while the board still sends them jobs is worse
  /// off than one whose switch did not move.
  Future<void> toggleOnline() async {
    final next = !rider.value.isOnline;
    try {
      await _repository.setOnline(isOnline: next);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }
    rider.value = rider.value.copyWith(isOnline: next);
  }

  void openNotifications() => Get.toNamed<void>(AppRoutes.shopNotifications);

  /// Both quick actions are tabs of this shell, not separate pages.
  void openOrders() => Get.find<RiderShellController>().select(RiderTab.orders);

  void openEarnings() =>
      Get.find<RiderShellController>().select(RiderTab.earnings);
}
