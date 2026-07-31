import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../../domain/entities/pharmacy_shop.dart';

/// Backs the Orders tab, the dashboard's Recent Orders and the detail behind
/// both.
///
/// UI-only — the book comes from [PharmacyShopData], and accepting or
/// declining only moves a row between chips.
class ShopOrdersController extends GetxController {
  final RxList<ShopOrder> orders = <ShopOrder>[].obs;
  final RxList<ShopOrder> recent = <ShopOrder>[].obs;

  final Rx<ShopOrderStatus> filter = ShopOrderStatus.fresh.obs;

  /// The row tapped into.
  final Rxn<ShopOrder> selected = Rxn<ShopOrder>();

  @override
  void onInit() {
    super.onInit();
    orders.value = PharmacyShopData.orders();
    recent.value = PharmacyShopData.recentOrders();
  }

  /// The chip row narrows the book to one state at a time, which is what the
  /// design shows — there is no "all".
  List<ShopOrder> get visible =>
      orders.where((order) => order.status == filter.value).toList();

  void selectFilter(ShopOrderStatus value) => filter.value = value;

  String statusLabel(ShopOrderStatus value) => switch (value) {
    ShopOrderStatus.fresh => AppStrings.stateNew.tr,
    ShopOrderStatus.accepted => AppStrings.stateAccepted.tr,
    ShopOrderStatus.declined => AppStrings.stateDeclined.tr,
    ShopOrderStatus.preparing => AppStrings.statePreparing.tr,
    ShopOrderStatus.outForDelivery => AppStrings.stateOutForDelivery.tr,
    ShopOrderStatus.delivered => AppStrings.stateDelivered.tr,
  };

  void openDetails(ShopOrder order) {
    selected.value = order;
    Get.toNamed<void>(AppRoutes.shopOrderDetails);
  }

  /// Viewing the attached prescription opens the report screen, which is what
  /// renders a document image today.
  void viewPrescription() => Get.toNamed<void>(AppRoutes.reportReview);

  void accept() => _settle(ShopOrderStatus.accepted, AppStrings.orderAccepted);

  void decline() => _settle(ShopOrderStatus.declined, AppStrings.orderDeclined);

  void _settle(ShopOrderStatus status, String message) {
    final order = selected.value;
    if (order == null) return;
    final moved = order.copyWith(status: status);
    selected.value = moved;

    final index = orders.indexWhere((o) => o.id == order.id);
    if (index != -1) orders[index] = moved;
    final recentIndex = recent.indexWhere((o) => o.id == order.id);
    if (recentIndex != -1) recent[recentIndex] = moved;

    AppSnackbar.success(message.tr);
    Get.back<void>();
  }
}
