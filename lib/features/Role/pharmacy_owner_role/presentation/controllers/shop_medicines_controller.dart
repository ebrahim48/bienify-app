import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/pharmacy_shop_data.dart';
import '../../domain/entities/pharmacy_shop.dart';
import '../../domain/repositories/pharmacy_shop_repository.dart';

/// Backs the Medicines tab and the Add / Edit form behind it.
class ShopMedicinesController extends GetxController {
  ShopMedicinesController({PharmacyShopRepository? repository})
    : _repository = repository ?? Get.find<PharmacyShopRepository>();

  final PharmacyShopRepository _repository;

  final RxList<ShopMedicine> medicines = <ShopMedicine>[].obs;

  /// Live query from the search field.
  final RxString query = ''.obs;

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString error = RxnString();

  /// The row being edited; null while adding, which is the only difference
  /// between the two designs.
  final Rxn<ShopMedicine> editing = Rxn<ShopMedicine>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      medicines.value = await _repository.medicines();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
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

  /// Takes a medicine off sale, or puts it back.
  ///
  /// The shelf can only ever show listed stock — `GET /medicines` filters on
  /// `isActive` and there is no owner-scoped list that includes the rest — so
  /// switching a row off takes it out of the list rather than greying it. The
  /// owner is told so, because a row that silently disappears reads as a bug.
  Future<void> toggleListed(ShopMedicine medicine, bool value) async {
    final updated = medicine.copyWith(isListed: value);
    try {
      await _repository.updateMedicine(updated);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    if (!value) {
      medicines.removeWhere((m) => m.id == medicine.id);
      AppSnackbar.info(AppStrings.medicineDelisted.tr);
      return;
    }

    final index = medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) medicines[index] = updated;
  }

  /// Removing a medicine takes it off sale rather than deleting it: a product
  /// with orders against it cannot vanish, and the server has no delete.
  Future<void> remove(ShopMedicine medicine) async {
    try {
      await _repository.delistMedicine(medicine);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }
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

  /// Bumped when the form is seeded, so its prefilled fields are rebuilt.
  /// They own their text controllers and seed them once.
  final RxInt formGeneration = 0.obs;

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
    category.value = medicine == null || medicine.category.isEmpty
        ? PharmacyShopData.categories.first
        : medicine.category;
    imageName.value = '';
    price.value = medicine == null ? '' : medicine.price.toStringAsFixed(2);
    stock.value = medicine?.stock.toString() ?? '';
    expiry.value = medicine?.expiryLabel ?? '';
    formGeneration.value++;
  }

  void selectCategory(String value) => category.value = value;

  /// Saves the form, adding or editing depending on how it was opened.
  ///
  /// The price and the stock are checked here rather than left to the server:
  /// both come back as one validation error, which would not tell the owner
  /// which of the two fields to fix.
  Future<void> submit() async {
    if (isSubmitting.value) return;

    final trimmed = name.value.trim();
    final priceValue = double.tryParse(price.value.trim());
    final stockValue = int.tryParse(stock.value.trim());

    if (trimmed.isEmpty || priceValue == null || stockValue == null) {
      AppSnackbar.info(AppStrings.medicineNeedsFields.tr);
      return;
    }

    final existing = editing.value;
    isSubmitting.value = true;
    try {
      if (existing == null) {
        final added = await _repository.addMedicine(
          name: trimmed,
          price: priceValue,
          stock: stockValue,
          isListed: true,
          category: category.value,
        );
        medicines.insert(0, added);
      } else {
        final updated = ShopMedicine(
          id: existing.id,
          name: trimmed,
          category: category.value,
          expiryLabel: expiry.value.trim(),
          stock: stockValue,
          price: priceValue,
          isListed: existing.isListed,
          imageAsset: existing.imageAsset,
        );
        await _repository.updateMedicine(updated);
        final index = medicines.indexWhere((m) => m.id == existing.id);
        if (index != -1) medicines[index] = updated;
      }
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isSubmitting.value = false;
    }

    Get.back<void>();
    AppSnackbar.success(AppStrings.medicineSaved.tr);
  }
}
