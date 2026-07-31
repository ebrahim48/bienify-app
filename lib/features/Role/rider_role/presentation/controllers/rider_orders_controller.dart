import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';

/// Backs Order Requests and the live job behind it.
///
/// UI-only — the board comes from [RiderData], and accepting or declining
/// only moves a card between chips.
class RiderOrdersController extends GetxController {
  final RxList<DeliveryRequest> requests = <DeliveryRequest>[].obs;

  final Rx<RequestTab> tab = RequestTab.fresh.obs;

  /// The job being tracked.
  final Rxn<ActiveDelivery> active = Rxn<ActiveDelivery>();

  /// Whether the customer's note is showing over the sheet.
  final RxBool isNoteVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    requests.value = RiderData.requests();
  }

  List<DeliveryRequest> get visible =>
      requests.where((request) => request.tab == tab.value).toList();

  int get openCount => requests.where((r) => r.tab == RequestTab.fresh).length;

  void selectTab(RequestTab value) => tab.value = value;

  String tabLabel(RequestTab value) => switch (value) {
    RequestTab.fresh => AppStrings.newRequest.tr,
    RequestTab.accepted => AppStrings.acceptedRequest.tr,
    RequestTab.cancelled => AppStrings.cancelledRequest.tr,
  };

  void accept(DeliveryRequest request) =>
      _move(request, RequestTab.accepted, AppStrings.requestAccepted);

  void decline(DeliveryRequest request) =>
      _move(request, RequestTab.cancelled, AppStrings.requestDeclined);

  void _move(DeliveryRequest request, RequestTab to, String message) {
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return;
    requests[index] = request.copyWith(tab: to);
    AppSnackbar.success(message.tr);
  }

  /// "Track LIVE" opens the map on that job.
  void track(DeliveryRequest request) {
    active.value = RiderData.activeDelivery();
    isNoteVisible.value = false;
    Get.toNamed<void>(AppRoutes.riderTracking);
  }

  void toggleNote() => isNoteVisible.value = !isNoteVisible.value;

  /// The courier's own thread with the customer.
  void openChat() => Get.toNamed<void>(AppRoutes.chat);

  void arrived() => Get.toNamed<void>(AppRoutes.riderDelivered);
}
