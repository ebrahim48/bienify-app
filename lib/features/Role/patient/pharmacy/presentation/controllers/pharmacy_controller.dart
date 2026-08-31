import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/pharmacy.dart';
import 'pharmacy_cart_controller.dart';
import '../../domain/repositories/pharmacy_repository.dart';
import '../../../profile/domain/repositories/account_repository.dart';

/// Backs the Pharmacy tab: the catalogue, its filter chips, and the cart
/// badge in the header.
class PharmacyController extends GetxController {
  PharmacyController({PharmacyRepository? repository, AccountRepository? account})
    : _repository = repository ?? Get.find<PharmacyRepository>(),
      _account = account ?? Get.find<AccountRepository>();

  final PharmacyRepository _repository;

  /// The saved address, which is the only city the app knows the patient is
  /// in. The shop list is headed "near you" and was the whole national list.
  final AccountRepository _account;

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

  /// The shop whose shelf is being shown, when the patient tapped one.
  ///
  /// Null means the whole catalogue. Tapping a shop card used to open the
  /// prescription upload — so the one thing it could not do was show the shop.
  final Rxn<PharmacyStore> viewingStore = Rxn<PharmacyStore>();

  /// Badge on the cart icon: what is actually in the basket.
  ///
  /// This was its own counter that started at 1 and only ever went up, so an
  /// empty basket wore a "1" and adding a medicine moved the badge without
  /// moving the cart.
  int get cartCount => _cart.itemCount;

  /// The basket is shared with the prescription flow, and either entry point
  /// can be the first one used, so it is created on demand rather than
  /// assumed present.
  PharmacyCartController get _cart {
    if (!Get.isRegistered<PharmacyCartController>()) {
      Get.lazyPut(PharmacyCartController.new, fenix: true);
    }
    return Get.find<PharmacyCartController>();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final medicines = await _repository.searchMedicines(
        query: query.value,
        // Null for the whole catalogue; a shop id narrows the shelf to what
        // that shop actually stocks.
        pharmacyId: viewingStore.value?.id,
      );
      commonMedicines.value = medicines;
      // The catalogue carries no department, so the design's second shelf
      // shows the same stock rather than a section invented client-side.
      dermatologyMedicines.value = medicines;
      // The server has filtered pharmacies by city since the endpoint was
      // written; nothing ever sent one. An account with no saved address sends
      // nothing and still sees every shop, which is the honest fallback.
      stores.value = await _repository.stores(city: await _city());
      _rebuildChips(medicines);
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// The patient's city, or empty when they have not saved an address.
  Future<String> _city() async {
    try {
      return (await _account.savedAddress())?.city ?? '';
    } on AppException {
      // A shop list narrowed to nowhere is worse than one that is too wide.
      return '';
    }
  }

  /// The chip row, drawn from what is actually on the shelf.
  ///
  /// These were six fixed strings out of the design ("ex 50", "emojil") over
  /// a live catalogue, and tapping one only tinted it — the shelf never
  /// changed. Now each chip is a real medicine to search for, so the row both
  /// says something true and does something.
  ///
  /// Only rebuilt while the query is empty: narrowing the shelf must not
  /// narrow the chips that got you there, or a search leaves one chip and no
  /// way back.
  void _rebuildChips(List<Medicine> medicines) {
    if (query.value.isNotEmpty && chips.isNotEmpty) return;

    final names = <String>{
      for (final medicine in medicines) medicine.name.split(' ').first,
    }.take(_maxChips).toList();

    chips.value = [AppStrings.filterAll.tr, ...names];
    selectedChip.value = chips.first;
  }

  static const int _maxChips = 5;

  /// Re-runs the catalogue search for the current [query].
  Future<void> search(String term) async {
    query.value = term;
    await load();
  }

  /// Searching the catalogue for the chip, rather than only tinting it.
  Future<void> selectChip(String chip) async {
    selectedChip.value = chip;
    query.value = chip == AppStrings.filterAll.tr ? '' : chip;
    await load();
  }

  void addToCart(Medicine medicine) {
    _cart.addMedicine(medicine);
    AppSnackbar.success(AppStrings.addedToCart.tr);
  }

  void openUpload() => Get.toNamed<void>(AppRoutes.uploadPrescription);

  void openCart() => Get.toNamed<void>(AppRoutes.pharmacyCart);

  /// "See all" on either catalogue section, and the store row, all land on
  /// the same directory for now.
  void seeAll() => Get.toNamed<void>(AppRoutes.uploadPrescription);

  /// Shows what this shop stocks.
  ///
  /// It opened the prescription upload instead, for every shop — so the store
  /// row was decorative and the one screen that could have answered "what does
  /// this pharmacy have?" was never reachable.
  Future<void> openStore(PharmacyStore store) async {
    viewingStore.value = store;
    // A query typed against the whole catalogue does not carry meaningfully
    // into one shop's shelf, and leaving it makes an empty result look like an
    // empty shop.
    query.value = '';
    selectedChip.value = '';
    await load();
  }

  /// Back to the whole catalogue.
  Future<void> clearStore() async {
    if (viewingStore.value == null) return;
    viewingStore.value = null;
    query.value = '';
    selectedChip.value = '';
    await load();
  }
}
