import 'package:get/get.dart';

import '../../../../../core/routes/app_routes.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import 'rider_shell_controller.dart';

/// Backs the courier's dashboard.
class RiderHomeController extends GetxController {
  final Rx<Rider> rider = RiderData.rider.obs;

  final RxList<DeliveryRecord> recent = <DeliveryRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    recent.value = List.of(RiderData.recentDeliveries);
  }

  int get openRequests => RiderData.openRequests;

  /// Going offline stops new work arriving; the card says which it is.
  void toggleOnline() =>
      rider.value = rider.value.copyWith(isOnline: !rider.value.isOnline);

  void openNotifications() => Get.toNamed<void>(AppRoutes.shopNotifications);

  /// Both quick actions are tabs of this shell, not separate pages.
  void openOrders() => Get.find<RiderShellController>().select(RiderTab.orders);

  void openEarnings() =>
      Get.find<RiderShellController>().select(RiderTab.earnings);
}
