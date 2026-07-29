import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';

/// Backs the Pharmacy tab: the catalogue, its filter chips, and the cart
/// badge in the header.
///
/// UI-only — the catalogue is static and the cart is an in-memory count.
class PharmacyController extends GetxController {
  final TextEditingController searchController = TextEditingController();

  final RxList<String> chips = <String>[].obs;
  final RxString selectedChip = ''.obs;

  final RxList<Medicine> commonMedicines = <Medicine>[].obs;
  final RxList<Medicine> dermatologyMedicines = <Medicine>[].obs;
  final RxList<PharmacyStore> stores = <PharmacyStore>[].obs;

  /// Badge on the cart icon.
  final RxInt cartCount = 1.obs;

  @override
  void onInit() {
    super.onInit();
    chips.value = PharmacyMockData.searchChips;
    selectedChip.value = chips.first;
    commonMedicines.value = PharmacyMockData.commonMedicines;
    dermatologyMedicines.value = PharmacyMockData.dermatologyMedicines;
    stores.value = PharmacyMockData.nearbyStores;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void selectChip(String chip) => selectedChip.value = chip;

  void addToCart(Medicine medicine) {
    cartCount.value++;
    AppSnackbar.success(AppStrings.addedToCart.tr);
  }

  void openUpload() => Get.toNamed<void>(AppRoutes.uploadPrescription);

  void openCart() => Get.toNamed<void>(AppRoutes.pharmacyCart);

  /// "See all" on either catalogue section, and the store row, all land on
  /// the same directory for now.
  void seeAll() => Get.toNamed<void>(AppRoutes.uploadPrescription);

  void openStore(PharmacyStore store) => openUpload();
}
