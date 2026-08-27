import 'package:get/get.dart';

import '../controllers/order_tracking_controller.dart';
import '../controllers/pharmacy_cart_controller.dart';
import '../controllers/prescription_controller.dart';

/// Bindings for the Pharmacy journey.
///
/// `PharmacyController` (the tab) is created by `MainBinding`, because the
/// shell keeps all four tabs alive.

/// Upload → Best Matches → Select Medicines share one prescription and one
/// basket, so both controllers are created at the entry point and kept with
/// `fenix` for the length of the flow.
class PrescriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(PrescriptionController.new, fenix: true);
    Get.lazyPut(PharmacyCartController.new, fenix: true);
  }
}

/// Carries the chosen pharmacy from Best Matches into the basket.
class SelectMedicinesBinding extends Bindings {
  @override
  void dependencies() {
    _ensureFlowControllers();

    final prescription = Get.find<PrescriptionController>();
    final cart = Get.find<PharmacyCartController>();
    cart.store.value ??= prescription.selectedStore;
    // A prescription says what to take, not what it costs. The shop's own
    // catalogue is what prices the script — without it every line on this
    // screen read $0.00 and the basket totalled nothing.
    cart.loadStoreCatalogue();
  }
}

class PharmacyCartBinding extends Bindings {
  @override
  void dependencies() => _ensureFlowControllers();
}

class OrderTrackingBinding extends Bindings {
  @override
  void dependencies() {
    _ensureFlowControllers();
    Get.lazyPut(OrderTrackingController.new, fenix: true);
  }
}

/// Deep-linking straight to a later screen still needs the shared state.
void _ensureFlowControllers() {
  if (!Get.isRegistered<PrescriptionController>()) {
    Get.lazyPut(PrescriptionController.new, fenix: true);
  }
  if (!Get.isRegistered<PharmacyCartController>()) {
    Get.lazyPut(PharmacyCartController.new, fenix: true);
  }
}
