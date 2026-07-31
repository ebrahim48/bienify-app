import 'package:get/get.dart';

import '../../../../../core/routes/app_routes.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../../domain/entities/pharmacy_shop.dart';
import 'shop_shell_controller.dart';

/// Backs the shop dashboard.
class ShopHomeController extends GetxController {
  final Rx<Shop> shop = PharmacyShopData.shop.obs;

  final RxList<StockAlert> alerts = <StockAlert>[].obs;

  @override
  void onInit() {
    super.onInit();
    alerts.value = List.of(PharmacyShopData.stockAlerts);
  }

  /// The same Earning Withdraw screen the practitioner uses — a payout is a
  /// payout, so it is navigated to rather than rebuilt.
  void withdraw() => Get.toNamed<void>(AppRoutes.doctorEarnings);

  void openNotifications() => Get.toNamed<void>(AppRoutes.shopNotifications);

  /// "See all" is the Orders tab, not another list.
  void openAllOrders() =>
      Get.find<ShopShellController>().select(ShopTab.orders);
}
