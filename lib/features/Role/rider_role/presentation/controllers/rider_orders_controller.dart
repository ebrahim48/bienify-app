import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/rider_data.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';

/// Backs Order Requests and the live job behind it.
class RiderOrdersController extends GetxController {
  RiderOrdersController({RiderRepository? repository})
    : _repository = repository ?? Get.find<RiderRepository>();

  final RiderRepository _repository;

  final RxList<DeliveryRequest> requests = <DeliveryRequest>[].obs;

  final Rx<RequestTab> tab = RequestTab.fresh.obs;

  final RxBool isLoading = true.obs;
  final RxBool isSettling = false.obs;
  final RxnString error = RxnString();

  /// The job being tracked.
  final Rxn<ActiveDelivery> active = Rxn<ActiveDelivery>();

  /// Whether the customer's note is showing over the sheet.
  final RxBool isNoteVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      requests.value = await _repository.requests();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
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

  /// Takes a job off the board.
  ///
  /// A job can be claimed by someone else between the board being drawn and
  /// the courier tapping Accept, so the card only moves once the server has
  /// agreed this courier holds it.
  Future<void> accept(DeliveryRequest request) async {
    if (isSettling.value) return;
    isSettling.value = true;
    try {
      await _repository.claim(request.id);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      // Somebody else may have taken it; re-read rather than leaving a card
      // on the board that is no longer there.
      await load();
      return;
    } finally {
      isSettling.value = false;
    }
    _move(request, RequestTab.accepted, AppStrings.requestAccepted);
  }

  /// Declining a job the courier has not claimed is theirs alone to know —
  /// the board has no "refused by" list — so the card is simply set aside.
  void decline(DeliveryRequest request) =>
      _move(request, RequestTab.cancelled, AppStrings.requestDeclined);

  void _move(DeliveryRequest request, RequestTab to, String message) {
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return;
    requests[index] = request.copyWith(tab: to);
    AppSnackbar.success(message.tr);
  }

  /// "Track LIVE" opens the map on that job.
  ///
  /// The map's own figures — the road, the arrival window, how many turns are
  /// left — come from a routing service the app does not have, so they stay
  /// the design's. The job itself is the real one.
  void track(DeliveryRequest request) {
    active.value = RiderData.activeDeliveryFor(request);
    isNoteVisible.value = false;
    Get.toNamed<void>(AppRoutes.riderTracking);
  }

  void toggleNote() => isNoteVisible.value = !isNoteVisible.value;

  /// The courier's own thread with the customer.
  void openChat() => Get.toNamed<void>(AppRoutes.chat);

  /// Handing the package over ends the job.
  Future<void> arrived() async {
    final job = active.value?.request;
    if (job != null) {
      try {
        await _repository.setStatus(job.id, 'delivered');
      } on AppException catch (e) {
        AppSnackbar.error(e.message);
        return;
      }
    }
    await Get.toNamed<void>(AppRoutes.riderDelivered);
  }
}
