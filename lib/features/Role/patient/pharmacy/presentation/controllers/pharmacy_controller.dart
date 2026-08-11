import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// Backs the Pharmacy tab: the catalogue, its filter chips, and the cart
/// badge in the header.
class PharmacyController extends GetxController {
  PharmacyController({PharmacyRepository? repository})
    : _repository = repository ?? Get.find<PharmacyRepository>();

  final PharmacyRepository _repository;

  final RxBool isLoading = true.obs;

  /// Set when the catalogue cannot be loaded, so the tab can say why instead
  /// of showing an empty shelf that reads as "nothing in stock".
  final RxnString error = RxnString();

  /// The medicine query. `DoctorSearchField` owns the text controller.
  final RxString query = ''.obs;

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
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final medicines = await _repository.searchMedicines(query: query.value);
      commonMedicines.value = medicines;
      // The catalogue carries no department, so the design's second shelf
      // shows the same stock rather than a section invented client-side.
      dermatologyMedicines.value = medicines;
      stores.value = await _repository.stores();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-runs the catalogue search for the current [query].
  Future<void> search(String term) async {
    query.value = term;
    await load();
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
