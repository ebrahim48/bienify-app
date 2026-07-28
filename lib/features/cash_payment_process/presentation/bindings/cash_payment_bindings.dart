import 'package:get/get.dart';

import '../controllers/cash_payment_controller.dart';
import '../controllers/payment_confirmed_controller.dart';
import '../controllers/payment_points_controller.dart';

/// Bindings for the Cash Payment Process journey.

/// Entry point of the flow.
///
/// [CashPaymentController] is created once here and kept alive with `fenix`
/// so the code and its countdown survive the hop through Nearby Points to
/// Payment Pending — recreating it per screen would restart the timer.
class HowToPayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CashPaymentController(
        amountLabel: Get.arguments is String
            ? Get.arguments as String
            : '\$74.89',
      ),
      fenix: true,
    );
  }
}

class PaymentPointsBinding extends Bindings {
  @override
  void dependencies() {
    // Deep-linking straight to this screen still needs the shared state.
    if (!Get.isRegistered<CashPaymentController>()) {
      Get.lazyPut(CashPaymentController.new, fenix: true);
    }
    Get.lazyPut(PaymentPointsController.new);
  }
}

class PaymentPendingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CashPaymentController>()) {
      Get.lazyPut(CashPaymentController.new, fenix: true);
    }
  }
}

class PaymentConfirmedBinding extends Bindings {
  @override
  void dependencies() {
    // The receipt is the end of the flow, so it reads the code and total off
    // the shared controller rather than keeping it alive any longer.
    final cash = Get.isRegistered<CashPaymentController>()
        ? Get.find<CashPaymentController>()
        : null;

    Get.put(
      PaymentConfirmedController(
        totalLabel: cash?.code.amountLabel ?? '\$74.89',
        code: cash?.code.code ?? '#BIE12345',
      ),
    );
  }
}
