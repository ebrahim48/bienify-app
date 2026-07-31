import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../../domain/entities/pharmacy_shop.dart';

/// Backs the Medicines tab and the Add / Edit form behind it.
class ShopMedicinesController extends GetxController {
  final RxList<ShopMedicine> medicines = <ShopMedicine>[].obs;

  /// Live query from the search field.
  final RxString query = ''.obs;

  /// The row being edited; null while adding, which is the only difference
  /// between the two designs.
  final Rxn<ShopMedicine> editing = Rxn<ShopMedicine>();

  @override
  void onInit() {
    super.onInit();
    // `List.of`: a const list is unmodifiable, and toggling a row writes back.
    medicines.value = List.of(PharmacyShopData.medicines);
  }

  List<ShopMedicine> get visible {
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return medicines.toList();
    return medicines
        .where(
          (medicine) =>
              medicine.name.toLowerCase().contains(search) ||
              medicine.category.toLowerCase().contains(search),
        )
        .toList();
  }

  void toggleListed(ShopMedicine medicine, bool value) {
    final index = medicines.indexWhere((m) => m.id == medicine.id);
    if (index == -1) return;
    medicines[index] = medicine.copyWith(isListed: value);
  }

  void remove(ShopMedicine medicine) {
    medicines.removeWhere((m) => m.id == medicine.id);
    AppSnackbar.info(AppStrings.medicineRemoved.tr);
  }

  // ─── Form ────────────────────────────────────────────────────────────────
  //
  // Held as plain strings so the inputs own their text controllers.

  final RxString name = ''.obs;
  final RxString category = PharmacyShopData.categories.first.obs;
  final RxString imageName = ''.obs;
  final RxString price = ''.obs;
  final RxString stock = ''.obs;
  final RxString expiry = ''.obs;

  void add() {
    editing.value = null;
    _seed(null);
    Get.toNamed<void>(AppRoutes.shopMedicineForm);
  }

  void edit(ShopMedicine medicine) {
    editing.value = medicine;
    _seed(medicine);
    Get.toNamed<void>(AppRoutes.shopMedicineForm);
  }

  void _seed(ShopMedicine? medicine) {
    name.value = medicine?.name ?? '';
    category.value = medicine?.category ?? PharmacyShopData.categories.first;
    imageName.value = '';
    price.value = medicine == null ? '' : medicine.price.toStringAsFixed(2);
    stock.value = medicine?.stock.toString() ?? '';
    expiry.value = medicine?.expiryLabel ?? '';
  }

  void selectCategory(String value) => category.value = value;

  void submit() {
    AppSnackbar.success(AppStrings.medicineSaved.tr);
    Get.back<void>();
  }
}
