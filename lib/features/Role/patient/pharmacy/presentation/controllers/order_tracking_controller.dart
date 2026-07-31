import 'package:get/get.dart';

import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';

/// Backs the placed-order screens: the progress timeline and live tracking.
///
/// UI-only — the stage is fixed at "Being Prepared", which is what the
/// design shows; a backend will drive it later.
class OrderTrackingController extends GetxController {
  final List<OrderStep> steps = PharmacyMockData.orderSteps;

  final Rx<OrderStage> stage = OrderStage.beingPrepared.obs;

  /// 1-based position of [stage] in [steps].
  int get currentIndex =>
      steps.indexWhere((step) => step.stage == stage.value) + 1;

  /// The design counts five stages of progress on the header bar.
  static const int progressSteps = 5;

  double get progress => (currentIndex / progressSteps).clamp(0, 1);

  bool isComplete(OrderStep step) =>
      steps.indexOf(step) < currentIndex - 1;

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

  void openRiderChat() =>
      Get.toNamed<void>(AppRoutes.chat, arguments: rider);

  /// Closing live tracking stands in for the delivery completing.
  void finishDelivery() => Get.offNamed<void>(AppRoutes.deliveryFeedback);
}
