import 'dart:async';

import '../../../patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/models/chat_thread.dart';
import '../../../../../core/network/mappers.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../patient/chat/domain/entities/conversation.dart';
import '../../data/services/rider_location_reporter.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';

/// Backs Order Requests and the live job behind it.
class RiderOrdersController extends GetxController {
  RiderOrdersController({
    RiderRepository? repository,
    RiderLocationReporter? reporter,
  }) : _repository = repository ?? Get.find<RiderRepository>(),
       _reporter =
           reporter ??
           RiderLocationReporter(repository ?? Get.find<RiderRepository>());

  final RiderRepository _repository;

  /// Sends the courier's position while a parcel is in motion.
  final RiderLocationReporter _reporter;

  final RxList<DeliveryRequest> requests = <DeliveryRequest>[].obs;

  final Rx<RequestTab> tab = RequestTab.fresh.obs;

  final RxBool isLoading = true.obs;
  final RxBool isSettling = false.obs;
  final RxnString error = RxnString();

  /// The job being tracked.
  final Rxn<ActiveDelivery> active = Rxn<ActiveDelivery>();

  /// Whether the customer's note is showing over the sheet.
  final RxBool isNoteVisible = false.obs;

  /// The receipt for the job just handed over, built when it is delivered so
  /// the confirmation names the customer the courier actually delivered to.
  final Rxn<DeliveryReceipt> receipt = Rxn<DeliveryReceipt>();

  @override
  void onInit() {
    super.onInit();
    _followOwnPosition();
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

  /// The jobs under the active chip, with anything still to do above anything
  /// already finished — a courier opens this tab to find what they are
  /// carrying, and a season of completed drops would otherwise bury it.
  /// Partitioned rather than sorted: `List.sort` is not stable, and within
  /// each group the server's newest-first order is the one to keep.
  List<DeliveryRequest> get visible {
    final rows = requests.where((request) => request.tab == tab.value);
    return [
      ...rows.where((request) => !request.isDelivered),
      ...rows.where((request) => request.isDelivered),
    ];
  }

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
    // `assigned` as well as the chip. The card kept the board's `unassigned`
    // after a successful claim, and everything downstream reads that status:
    // the tracking sheet showed nought of four steps done, and its button —
    // which looks up the next state from the current one — found no transition
    // out of `unassigned` and answered "this delivery is already finished".
    // A courier could accept a job and then not move it, which is why holding
    // several at once looked broken: only a job that survived a reload worked.
    _move(
      request,
      RequestTab.accepted,
      AppStrings.requestAccepted,
      status: 'assigned',
    );
  }

  /// Declining a job the courier has not claimed is theirs alone to know —
  /// the board has no "refused by" list — so the card is simply set aside.
  void decline(DeliveryRequest request) =>
      _move(request, RequestTab.cancelled, AppStrings.requestDeclined);

  void _move(
    DeliveryRequest request,
    RequestTab to,
    String message, {
    String? status,
  }) {
    final index = requests.indexWhere((r) => r.id == request.id);
    if (index == -1) return;
    requests[index] = request.copyWith(tab: to, status: status);
    AppSnackbar.success(message.tr);
  }

  /// "Track LIVE" opens the map on that job.
  ///
  /// Built here rather than through the fixture factory: a live controller
  /// reaching into `RiderData` was how the road name, arrival window and step
  /// count came to be constants wrapped around a real job.
  /// The job's route, for the map. Null until the read lands, and null on a
  /// delivery whose ends nobody has coordinates for.
  final Rxn<DeliveryRoute> route = Rxn<DeliveryRoute>();

  void track(DeliveryRequest request) {
    active.value = ActiveDelivery(request: request, status: request.status);
    _loadRoute(request.id);
    _reportPosition(request);
    isNoteVisible.value = false;
    Get.toNamed<void>(AppRoutes.riderTracking);
  }

  /// The statuses a parcel is actually moving in. The server refuses a
  /// position on anything else, so reporting outside them is a guaranteed
  /// rejection rather than a stale pin.
  static const Set<String> _inMotion = {'assigned', 'picked_up', 'in_transit'};

  /// Starts or stops position reporting to match the job's state.
  ///
  /// Tied to the parcel rather than to the tracking screen: a courier who
  /// backs out to check the next address is still carrying it, and the
  /// customer's map should not freeze because they changed tabs.
  Future<void> _reportPosition(DeliveryRequest request) async {
    if (!_inMotion.contains(request.status)) {
      await _reporter.stop();
      return;
    }
    final refused = await _reporter.start(request.id);
    if (refused != null) AppSnackbar.info(refused);
  }

  /// The courier's own pin, moved by their own pings rather than by re-reading
  /// the delivery. Without this their map only caught up with them when the
  /// screen was reopened.
  void _followOwnPosition() {
    _ownPosition = _reporter.reported.listen((position) {
      final current = route.value;
      if (current == null) return;
      // Through `movedTo`, which carries every other field. Rebuilding the
      // route by hand here dropped the road and the arrival time on every
      // ping — the courier's own map lost its route seconds after drawing it.
      route.value = current.movedTo(
        MapPoint(lat: position.latitude, lng: position.longitude),
      );
    });
  }

  StreamSubscription<Position>? _ownPosition;

  @override
  void onClose() {
    _ownPosition?.cancel();
    _reporter.dispose();
    super.onClose();
  }

  /// Where the parcel is coming from and going to.
  ///
  /// The courier's map drew two compile-time constants, so every job showed
  /// the same road between the same two pins whatever they were carrying.
  Future<void> _loadRoute(String deliveryId) async {
    route.value = null;
    try {
      route.value = await _repository.route(deliveryId);
    } on AppException {
      // The sheet below the map still names both ends from the job itself, so
      // a failed read costs the pins rather than the screen.
    }
  }

  void toggleNote() => isNoteVisible.value = !isNoteVisible.value;

  /// The courier's thread with the customer on this job.
  ///
  /// The delivery *is* the thread — the same machinery a consultation uses,
  /// with the two people on the parcel instead of a doctor and a patient. It
  /// navigated with no peer at all before, which fell through to the chat
  /// binding's fallback: a sample conversation with a doctor the courier had
  /// never spoken to.
  void openChat() {
    final job = active.value;
    if (job == null) {
      AppSnackbar.info(AppStrings.noActiveDelivery.tr);
      return;
    }

    Get.toNamed<void>(
      AppRoutes.chat,
      arguments: ConversationPeer(
        // The customer, not the delivery: presence is per person, and the
        // header asks about whoever is on the other end.
        id: job.request.customerId,
        thread: ChatThread.delivery(job.request.id),
        name: job.request.customerName,
        // The customer's own picture in the thread header. Without it the
        // courier's side of the conversation showed initials while the
        // customer's side has shown the courier's photo all along.
        photoUrl: job.request.customerPhotoUrl,
        // Where the parcel is going, which is what a courier needs under the
        // name. `specialty` is the field's name from the doctor thread this
        // screen shares a widget with.
        specialty: job.request.customerAddress,
      ),
    );
  }

  /// A parcel moves one step at a time, and the server refuses a jump: a job
  /// goes from claimed, to collected, to on the road, to handed over.
  static const Map<String, String> _nextStatus = {
    'assigned': 'picked_up',
    'picked_up': 'in_transit',
    'in_transit': 'delivered',
  };

  /// What the tracking screen's single button does next.
  ///
  /// The design draws one button and the server keeps four states, so the
  /// button names the step it is about to take rather than always claiming
  /// the courier has arrived.
  String get advanceLabel => switch (active.value?.request.status) {
    'assigned' => AppStrings.confirmPickedUp,
    'picked_up' => AppStrings.confirmOnTheWay,
    _ => AppStrings.arrived,
  };

  /// Moves the live job on by one state, and finishes it on the last.
  ///
  /// The intermediate states are not busywork: the customer's order only
  /// becomes "out for delivery" when the parcel reaches `in_transit`, so
  /// skipping them would leave the patient's tracking stuck at "ready".
  Future<void> arrived() async {
    final job = active.value?.request;
    if (job == null) {
      await Get.toNamed<void>(AppRoutes.riderDelivered);
      return;
    }

    final next = _nextStatus[job.status];
    if (next == null) {
      AppSnackbar.error(AppStrings.deliveryAlreadyFinished.tr);
      return;
    }

    if (isSettling.value) return;
    isSettling.value = true;
    try {
      await _repository.setStatus(job.id, next);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSettling.value = false;
    }

    final moved = job.copyWith(status: next);
    active.value = ActiveDelivery(request: moved, status: next);

    // Follows the parcel into its new state: reporting starts at `assigned` if
    // the courier reached the map before granting location, and stops the
    // moment the parcel is handed over — a delivered job is not moving, and
    // the server rejects positions on one.
    await _reportPosition(moved);

    final index = requests.indexWhere((r) => r.id == job.id);
    if (index != -1) requests[index] = requests[index].copyWith(status: next);

    if (next != 'delivered') return;

    receipt.value = DeliveryReceipt(
      orderId: job.code,
      customerName: job.customerName,
      location: job.customerAddress,
      timeLabel: clockLabel(DateTime.now()),
    );
    await Get.toNamed<void>(AppRoutes.riderDelivered);
  }
}
