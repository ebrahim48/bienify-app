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
        // The amount arrives as a number, not as the previous screen's label:
        // a label has already been rounded to whole units, and parsing one back
        // depends on the locale's decimal separator.
        amount: Get.arguments is num ? (Get.arguments as num).toDouble() : 74.89,
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
        // Blank rather than the design's sample. A confirmation screen naming
        // a payment reference nobody was issued is worse than one that names
        // none — the patient would quote it at the counter.
        totalLabel: cash?.code?.amountLabel ?? '',
        code: cash?.code?.code ?? '',
      ),
    );
  }
}
