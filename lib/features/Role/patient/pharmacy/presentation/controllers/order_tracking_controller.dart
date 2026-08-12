import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
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
  OrderTrackingController({PharmacyRepository? repository})
    : _repository = repository ?? Get.find<PharmacyRepository>();

  final PharmacyRepository _repository;

  /// The timeline, with the placed step naming the real order.
  ///
  /// The design's `#RX8841` is a sample; the patient's own reference is what
  /// they would quote to the pharmacy.
  List<OrderStep> get steps {
    final placed = order.value;
    if (placed == null) return PharmacyMockData.orderSteps;

    return [
      for (final step in PharmacyMockData.orderSteps)
        if (step.stage == OrderStage.placed)
          OrderStep(
            stage: step.stage,
            title: step.title,
            subtitle: AppStrings.orderConfirmedRef.trParams({
              'ref': orderReference(placed.id),
            }),
          )
        else
          step,
    ];
  }

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

  /// The rider, as a chat peer — the thread reuses the existing chat screen
  /// rather than a second messaging UI.
  ConversationPeer get rider => const ConversationPeer(
    id: 'rider-arif',
    name: PharmacyMockData.riderName,
    specialty: PharmacyMockData.riderCountry,
    photoAsset: AppAssets.rider,
    isOnline: true,
  );

  void trackNow() => Get.toNamed<void>(AppRoutes.liveTracking);

  void backToHome() => AppNavigator.resetTo(AppRoutes.home);

  void openRiderChat() => Get.toNamed<void>(AppRoutes.chat, arguments: rider);

  /// Closing live tracking stands in for the delivery completing.
  void finishDelivery() => Get.offNamed<void>(AppRoutes.deliveryFeedback);
}
