import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/repositories/cash_payment_repository.dart';
import 'cash_payment_controller.dart';

/// Which pane the Nearby Payment Points screen is showing.
enum PaymentPointsView { map, list }

/// Backs the Nearby Payment Points screen.
///
/// "Directions" / "Go" stay local selections rather than external launches.
class PaymentPointsController extends GetxController {
  PaymentPointsController({CashPaymentRepository? repository})
    : _repository = repository ?? Get.find<CashPaymentRepository>();

  final CashPaymentRepository _repository;

  final Rx<PaymentPointsView> view = PaymentPointsView.map.obs;
  final RxList<PaymentPoint> points = <PaymentPoint>[].obs;
  final RxnString selectedId = RxnString();

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  bool get isMap => view.value == PaymentPointsView.map;

  /// The highlighted point shown above "ALL NEARBY".
  PaymentPoint? get featured =>
      points.firstWhereOrNull((point) => point.id == selectedId.value);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      points.value = await _repository.points();
      // The nearest point starts selected, as in the design.
      selectedId.value = points.isEmpty ? null : points.first.id;
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void showMap() => view.value = PaymentPointsView.map;

  void showList() => view.value = PaymentPointsView.list;

  /// Choosing a counter re-issues the code against it: a code is bound to the
  /// point it was issued for, so the one in the patient's hand has to be the
  /// one the agent they walk to can take.
  void select(PaymentPoint point) {
    if (selectedId.value == point.id) return;
    selectedId.value = point.id;
    if (Get.isRegistered<CashPaymentController>()) {
      Get.find<CashPaymentController>().load(paymentPointId: point.id);
    }
  }

  bool isSelected(PaymentPoint point) => selectedId.value == point.id;
}
