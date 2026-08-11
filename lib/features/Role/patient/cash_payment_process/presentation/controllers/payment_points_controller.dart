import 'package:get/get.dart';

import '../../data/static/cash_payment_data.dart';
import '../../domain/entities/cash_payment.dart';

/// Which pane the Nearby Payment Points screen is showing.
enum PaymentPointsView { map, list }

/// Backs the Nearby Payment Points screen.
///
/// UI-only: the list is static and "Directions" / "Go" are local selections
/// rather than external launches.
class PaymentPointsController extends GetxController {
  final Rx<PaymentPointsView> view = PaymentPointsView.map.obs;
  final RxList<PaymentPoint> points = <PaymentPoint>[].obs;
  final RxnString selectedId = RxnString();

  bool get isMap => view.value == PaymentPointsView.map;

  /// The highlighted point shown above "ALL NEARBY".
  PaymentPoint? get featured =>
      points.firstWhereOrNull((point) => point.id == selectedId.value);

  @override
  void onInit() {
    super.onInit();
    points.value = CashPaymentData.points;
    // The nearest point starts selected, as in the design.
    selectedId.value = points.isEmpty ? null : points.first.id;
  }

  void showMap() => view.value = PaymentPointsView.map;

  void showList() => view.value = PaymentPointsView.list;

  void select(PaymentPoint point) => selectedId.value = point.id;

  bool isSelected(PaymentPoint point) => selectedId.value == point.id;
}
