import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';
import 'shop_shell_controller.dart';

/// Backs the shop dashboard.
class ShopHomeController extends GetxController {
  ShopHomeController({PharmacyShopRepository? repository})
    : _repository = repository ?? Get.find<PharmacyShopRepository>();

  final PharmacyShopRepository _repository;

  /// Empty until the first load lands, so the masthead does not flash a shop
  /// name and a balance the owner does not have.
  final Rx<Shop> shop = const Shop(
    name: '',
    ownerName: '',
    phone: '',
    location: '',
    availableBalance: 0,
    email: '',
    country: '',
    address: '',
  ).obs;

  final RxList<StockAlert> alerts = <StockAlert>[].obs;

  /// The four dashboard tiles. Zeroed until the read lands, so the owner does
  /// not see a figure that belongs to nobody — they used to be hardcoded, and
  /// showed the same day's trade to every shop on the platform.
  final Rx<ShopStats> stats = const ShopStats().obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      // Three independent reads, run together so the dashboard costs one
      // round trip's latency rather than three.
      final results = await Future.wait([
        _repository.shop(),
        _repository.stockAlerts(),
        _repository.stats(),
      ]);
      shop.value = results[0] as Shop;
      alerts.value = results[1] as List<StockAlert>;
      stats.value = results[2] as ShopStats;
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// The same Earning Withdraw screen the practitioner uses — a payout is a
  /// payout, so it is navigated to rather than rebuilt.
  void withdraw() => Get.toNamed<void>(AppRoutes.doctorEarnings);

  void openNotifications() => Get.toNamed<void>(AppRoutes.shopNotifications);

  /// "See all" is the Orders tab, not another list.
  void openAllOrders() =>
      Get.find<ShopShellController>().select(ShopTab.orders);
}
