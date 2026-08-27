import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/models/chat_thread.dart';
import '../../../../../../core/network/mappers.dart';
import '../../../../../../core/network/socket_service.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// Backs the placed-order screens: the progress timeline and live tracking.
///
/// The stage follows the patient's newest order. It used to be pinned to
/// "Being Prepared" whatever the server said, so an order still awaiting
/// payment showed a pharmacist packing it.
class OrderTrackingController extends GetxController {
  OrderTrackingController({PharmacyRepository? repository, SocketService? socket})
    : _repository = repository ?? Get.find<PharmacyRepository>(),
      _socket = socket ?? Get.find<SocketService>();

  final PharmacyRepository _repository;
  final SocketService _socket;

  /// The timeline, with the placed step naming the real order.
  ///
  /// The design's `#RX8841` is a sample; the patient's own reference is what
  /// they would quote to the pharmacy.
  List<OrderStep> get steps {
    final placed = order.value;
    if (placed == null) return PharmacyMockData.orderSteps;

    return [
      for (final step in PharmacyMockData.orderSteps)
        OrderStep(
          stage: step.stage,
          title: step.title,
          subtitle: _subtitleFor(step, placed),
        ),
    ];
  }

  /// The line under each timeline step.
  ///
  /// Three of the seven read "Estimated in ~20 min" from the fixture, and the
  /// pharmacy step named "MediQuick" — a shop that fills nobody's order. There
  /// is no arrival estimate behind this screen, so the steps that had one now
  /// carry nothing rather than a number that was never calculated.
  String _subtitleFor(OrderStep step, PharmacyOrder placed) => switch (step.stage) {
    OrderStage.placed => AppStrings.orderConfirmedRef.trParams({
      'ref': orderReference(placed.id),
    }),
    OrderStage.pharmacyConfirmed =>
      placed.pharmacyName.isEmpty
          ? ''
          : AppStrings.shopAccepted.trParams({'shop': placed.pharmacyName}),
    OrderStage.beingPrepared => step.subtitle,
    OrderStage.delivered => step.subtitle,
    _ => '',
  };

  /// `#7261` — the tail of the server's id, which is what fits on a row and
  /// is still enough to tell two of the patient's orders apart.
  static String orderReference(String id) =>
      id.length <= 4 ? '#$id' : '#${id.substring(id.length - 4).toUpperCase()}';

  final Rx<OrderStage> stage = OrderStage.placed.obs;

  /// The order the timeline is about, once it has been read back.
  final Rxn<PharmacyOrder> order = Rxn<PharmacyOrder>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      final orders = await _repository.orders();
      if (orders.isEmpty) return;
      order.value = orders.first;
      stage.value = stageFor(orders.first.status);
    } on AppException {
      // Leave the timeline at "Order Placed" — the order was accepted, and
      // guessing a later stage would be worse than showing the earliest one.
    }
  }

  /// The server's status as a step on the design's seven-stage timeline.
  ///
  /// `pending_payment` and `placed` are both "Order Placed" to a patient: the
  /// distinction is the platform's, not theirs. A rejected or cancelled order
  /// has no place on a progress line, so it stays at the start.
  static OrderStage stageFor(String status) => switch (status) {
    'accepted' => OrderStage.pharmacyConfirmed,
    'preparing' => OrderStage.beingPrepared,
    'ready' => OrderStage.readyForPickup,
    'out_for_delivery' => OrderStage.outForDelivery,
    'delivered' => OrderStage.delivered,
    _ => OrderStage.placed,
  };

  /// The step the order is at, for the heading above the timeline.
  OrderStep get currentStep =>
      steps.firstWhere((step) => step.stage == stage.value, orElse: () => steps.first);

  /// 1-based position of [stage] in [steps].
  int get currentIndex =>
      steps.indexWhere((step) => step.stage == stage.value) + 1;

  /// The design counts five stages of progress on the header bar.
  static const int progressSteps = 5;

  double get progress => (currentIndex / progressSteps).clamp(0, 1);

  bool isComplete(OrderStep step) => steps.indexOf(step) < currentIndex - 1;

  bool isCurrent(OrderStep step) => step.stage == stage.value;

  /// The courier carrying this order, once one has taken it.
  ///
  /// Null until then, and null on an order nobody has been assigned to — the
  /// sheet says so rather than naming somebody. It used to print one name,
  /// one country and one star rating for every order on the platform.
  final Rxn<Courier> courier = Rxn<Courier>();

  /// The courier as a chat peer — the thread reuses the existing chat screen
  /// rather than a second messaging UI.
  ConversationPeer? get rider {
    final person = courier.value;
    final deliveryId = watchedDeliveryId;
    if (person == null || deliveryId == null) return null;
    return ConversationPeer(
      id: person.id,
      // The delivery is the thread. Without it the screen opened the sample
      // conversation — a chat button that looked live and reached nobody.
      thread: ChatThread.delivery(deliveryId),
      name: person.name,
      // Their vehicle and city, which is what a patient wants to know about a
      // courier. `specialty` is the field's name from the doctor thread it
      // shares a widget with.
      specialty: [
        person.vehicleType,
        person.city,
      ].where((v) => v.isNotEmpty).join(' · '),
      photoAsset: AppAssets.rider,
      photoUrl: person.photoUrl,
      // Left false: the chat screen reads real presence for the peer, and
      // asserting "online" here would print it for a courier who is not.
    );
  }

  // ─── Live tracking ───────────────────────────────────────────────────────

  /// Where the courier is, and the two ends of their journey.
  ///
  /// Null until the first read lands. The map used to draw four compile-time
  /// constants, so every patient watched the same courier take the same route
  /// regardless of what their order was doing.
  final Rxn<DeliveryRoute> route = Rxn<DeliveryRoute>();

  final RxBool isRouteLoading = false.obs;

  Timer? _routeTimer;

  /// The socket subscription, when one is live.
  StreamSubscription<Map<String, dynamic>>? _locationSub;

  /// The delivery being watched, so a push for somebody else's is ignored.
  ///
  /// Public because it is also the courier thread's identity: the chat this
  /// screen opens is bound to this delivery, not to the courier.
  String? watchedDeliveryId;

  /// How often the position is re-read as a fallback.
  ///
  /// Positions arrive over the socket as the courier reports them; this is the
  /// safety net for a dropped or unavailable connection, which is why it is
  /// slower than the push. Polling alone was the whole mechanism before —
  /// a pin was up to an interval stale and jumped between fixes.
  static const Duration _pollInterval = Duration(seconds: 30);

  Future<void> loadRoute() async {
    final placed = order.value;
    if (placed == null) return;

    isRouteLoading.value = true;
    try {
      final deliveryId = await _repository.deliveryIdForOrder(placed.id);
      // No delivery yet means the pharmacy has not dispatched it. That is a
      // normal state, and the screen says so rather than showing an error.
      if (deliveryId == null) return;
      watchedDeliveryId = deliveryId;
      route.value = await _repository.deliveryRoute(deliveryId);
      // Identity does not change during a delivery, so it is read once rather
      // than on every poll.
      courier.value ??= await _repository.courierFor(deliveryId);
    } on AppException {
      // Keep whatever position was last known. A dropped poll is not a reason
      // to blank a map the patient is watching.
    } finally {
      isRouteLoading.value = false;
    }
  }

  /// The four segments on the tracking bar, from the delivery's own status.
  /// It was pinned to the first segment, so a courier at the door showed the
  /// same progress as one who had not left the shop.
  int get routeStepsReached => switch (route.value?.status) {
    'assigned' => 1,
    'picked_up' => 2,
    'in_transit' => 3,
    'delivered' => 4,
    _ => 0,
  };

  String get routeStatusLabel => switch (route.value?.status) {
    'assigned' => AppStrings.courierAssigned.tr,
    'picked_up' => AppStrings.orderPickedUp.tr,
    'in_transit' => AppStrings.onTheWay.tr,
    'delivered' => AppStrings.deliveredLabel.tr,
    _ => AppStrings.awaitingDispatch.tr,
  };

  /// When the courier last reported, or why there is nothing to show.
  String get routeSubtitle {
    final at = route.value?.reportedAt;
    if (at == null) return AppStrings.courierNotReporting.tr;
    return AppStrings.lastSeenAt.trParams({'time': clockLabel(at)});
  }

  void startTrackingUpdates() {
    loadRoute();
    _routeTimer?.cancel();
    _routeTimer = Timer.periodic(_pollInterval, (_) => loadRoute());

    _locationSub?.cancel();
    _locationSub = _socket.deliveryLocations.listen(_onCourierMoved);
  }

  /// A pushed position for the delivery being watched.
  ///
  /// Applied straight to the route rather than triggering a refetch: the
  /// payload already carries everything that changed, and re-reading would put
  /// the courier back a request behind the thing that just told us they moved.
  void _onCourierMoved(Map<String, dynamic> payload) {
    if (payload['deliveryId'] != watchedDeliveryId) return;

    final lat = payload['lat'];
    final lng = payload['lng'];
    final current = route.value;
    if (lat == null || lng == null || current == null) return;

    route.value = DeliveryRoute(
      status: '${payload['status'] ?? current.status}',
      courier: MapPoint(lat: Api.decimal(lat), lng: Api.decimal(lng)),
      pickup: current.pickup,
      dropoff: current.dropoff,
      reportedAt: payload['at'] == null ? DateTime.now() : Api.date(payload['at']),
    );
  }

  void stopTrackingUpdates() {
    _routeTimer?.cancel();
    _routeTimer = null;
    _locationSub?.cancel();
    _locationSub = null;
  }

  @override
  void onClose() {
    stopTrackingUpdates();
    super.onClose();
  }

  void trackNow() {
    Get.toNamed<void>(AppRoutes.liveTracking);
    startTrackingUpdates();
  }

  void backToHome() => AppNavigator.resetTo(AppRoutes.home);

  void openRiderChat() {
    final peer = rider;
    if (peer == null) {
      AppSnackbar.info(AppStrings.noCourierYet.tr);
      return;
    }
    Get.toNamed<void>(AppRoutes.chat, arguments: peer);
  }

  /// Closing live tracking stands in for the delivery completing.
  void finishDelivery() => Get.offNamed<void>(AppRoutes.deliveryFeedback);
}
