import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';

/// Backs the shop's feed, reached from the dashboard's bell.
class ShopNotificationsController extends GetxController {
  ShopNotificationsController({PharmacyShopRepository? repository})
    : _repository = repository ?? Get.find<PharmacyShopRepository>();

  final PharmacyShopRepository _repository;

  final RxList<ShopNotification> notifications = <ShopNotification>[].obs;

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
      notifications.value = await _repository.notifications();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }
}
