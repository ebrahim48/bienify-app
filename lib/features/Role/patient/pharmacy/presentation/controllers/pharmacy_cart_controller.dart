import 'prescription_controller.dart';
import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../profile/domain/repositories/account_repository.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// Spans medicine selection, the cart, payment and the placed order.
///
/// One controller because the basket, the wallet toggle and the delivery
/// address all follow the patient across those screens.
class PharmacyCartController extends GetxController {
  PharmacyCartController({
    WalletRepository? wallet,
    PharmacyRepository? pharmacy,
    AccountRepository? account,
  }) : _wallet = wallet ?? Get.find<WalletRepository>(),
       _pharmacy = pharmacy ?? Get.find<PharmacyRepository>(),
       _account = account ?? Get.find<AccountRepository>();

  final WalletRepository _wallet;
  final PharmacyRepository _pharmacy;
  final AccountRepository _account;

  /// Which store is filling the script; drives which lines are available.
  final Rxn<PharmacyStore> store = Rxn<PharmacyStore>();

  /// The chosen shop's catalogue, used to price the script.
  ///
  /// A prescription says what to take, not what it costs — the price depends
  /// on the shop filling it. Without this every line read $0.00 and the basket
  /// totalled nothing.
  final RxList<Medicine> _catalogue = <Medicine>[].obs;

  /// True while the catalogue is being read, so the list can say it is
  /// waiting. Without it an unloaded script and an empty one look the same.
  final RxBool isLoadingMedicines = false.obs;

  /// Reads the catalogue for whichever shop the patient picked.
  Future<void> loadStoreCatalogue() async {
    final chosen = store.value;
    _catalogue.clear();
    if (chosen == null) return;
    isLoadingMedicines.value = true;
    try {
      _catalogue.value = await _pharmacy.searchMedicines(
        pharmacyId: chosen.id,
      );
    } on AppException {
      // Lines then price at zero, which the Add to Cart total makes obvious —
      // better than pricing them from somebody else's shelf.
    } finally {
      isLoadingMedicines.value = false;
    }
  }

  /// The catalogue row matching a prescribed medicine, by name.
  ///
  /// Names are matched loosely because a script says "Amoxicillin 500mg" and a
  /// shelf may say "Amoxicillin 500 mg Capsules" — the strength is the part
  /// that has to agree.
  Medicine? _catalogueMatch(String prescribedName) {
    final needle = prescribedName.toLowerCase().replaceAll(' ', '');
    for (final item in _catalogue) {
      final hay = item.name.toLowerCase().replaceAll(' ', '');
      if (hay.contains(needle) || needle.contains(hay)) return item;
    }
    return null;
  }

  /// The patient's own balance, not the design's $45. Read on open, because
  /// it moves whenever a consultation is paid for or an order settles, and a
  /// stale figure promises a deduction the server will refuse.
  final RxDouble walletBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadBalance();
    _loadDeliveryCharge();
    _loadAddress();
  }

  /// Fills the delivery address from the patient's profile.
  ///
  /// Nothing stored an address before — not the profile, not anywhere — so
  /// the checkout had nothing to read and asked afresh every time.
  Future<void> _loadAddress() async {
    try {
      final saved = await _account.savedAddress();
      if (saved == null) return;
      profileAddress.value = saved;
      address.value = saved;
      hasSavedAddress.value = true;
    } on AppException {
      // The patient can still type one; failing to prefill is not a reason to
      // block the checkout.
    }
  }

  /// Sends this order back to the profile address after an override.
  void useProfileAddress() {
    final saved = profileAddress.value;
    if (saved == null) return;
    address.value = saved;
  }

  Future<void> _loadDeliveryCharge() async {
    try {
      deliveryCharge.value = await _pharmacy.deliveryCharge();
    } on AppException {
      // Showing nothing beats showing a number the server will not honour —
      // the total then matches the items, which is what gets charged if the
      // fee genuinely could not be read.
      deliveryCharge.value = 0;
    }
  }

  Future<void> _loadBalance() async {
    try {
      walletBalance.value = await _wallet.balance();
    } on AppException {
      // A wallet that cannot be read is a wallet with nothing to spend; the
      // toggle then credits nothing rather than a number nobody has.
      walletBalance.value = 0;
    }
  }

  final RxList<CartLine> lines = <CartLine>[].obs;

  /// Ids ticked on the Select Medicines screen.
  final RxSet<String> selectedIds = <String>{}.obs;

  final RxBool useWallet = false.obs;
  final RxBool pickupYourself = false.obs;

  /// Where *this* order is going.
  ///
  /// Starts as the address on the patient's profile and can be pointed
  /// somewhere else for one delivery. Empty only until [_loadAddress] lands:
  /// it held a fabricated street once, so a checkout that had never been
  /// given an address still displayed one.
  final Rx<DeliveryAddress> address = const DeliveryAddress(line1: '').obs;

  /// The address on the patient's profile, which is the default for every
  /// order. Null until they have saved one.
  ///
  /// Kept apart from [address] so "send this one to the office" can be undone
  /// — without it there would be nothing to go back to.
  final Rxn<DeliveryAddress> profileAddress = Rxn<DeliveryAddress>();

  /// True when this order is going somewhere other than the profile address,
  /// which is what shows the "Use my profile address" link.
  bool get isOverridingAddress =>
      profileAddress.value != null &&
      profileAddress.value!.singleLine != address.value.singleLine;

  /// False until the patient has an address, which is what switches the
  /// payment screen's link between "Add" and "Change".
  final RxBool hasSavedAddress = false.obs;

  final RxInt selectedMethodIndex = 0.obs;

  // ─── Availability ────────────────────────────────────────────────────────

  /// The prescription, with lines beyond the store's stock marked
  /// unavailable — that is what greys the last row when a pharmacy cannot
  /// fill the whole script.
  /// What the doctor actually prescribed, marked against the store's stock.
  ///
  /// Read from the patient's own prescription rather than a fixed list of six
  /// demo medicines — the basket used to be the same script for everybody, so
  /// a patient could order drugs no doctor had written for them.
  List<Medicine> get prescribed {
    final script = _prescriptionLines();
    final available = store.value?.availableCount ?? script.length;
    return [
      for (var index = 0; index < script.length; index++)
        _withAvailability(script[index], isAvailable: index < available),
    ];
  }

  /// The prescription's medicines, as cart lines.
  ///
  /// The prescription carries a name, dose and duration; it does not carry a
  /// price, because what a script costs depends on the shop filling it. The
  /// price lands when the store's catalogue is matched on the next screen.
  List<Medicine> _prescriptionLines() {
    final script = Get.isRegistered<PrescriptionController>()
        ? Get.find<PrescriptionController>().prescription.value
        : null;
    if (script == null) return const [];

    return [
      for (final medication in script.medications)
        () {
          final stocked = _catalogueMatch(medication.name);
          return Medicine(
            // The shop's own id when it stocks the line, so adding to the cart
            // sends a medicine the server can price and reserve.
            id: stocked?.id ?? '${script.id}-${medication.name}',
            name: medication.name,
            dosage: medication.dosage,
            packSize: medication.durationLabel,
            price: stocked?.price ?? 0,
            oldPrice: stocked?.oldPrice,
            discountPercent: stocked?.discountPercent ?? 0,
            isAvailable: stocked != null,
            pharmacyId: stocked?.pharmacyId ?? '',
          );
        }(),
    ];
  }

  Medicine _withAvailability(Medicine medicine, {required bool isAvailable}) {
    return Medicine(
      id: medicine.id,
      name: medicine.name,
      dosage: medicine.dosage,
      packSize: medicine.packSize,
      price: medicine.price,
      oldPrice: medicine.oldPrice,
      discountPercent: medicine.discountPercent,
      isAvailable: isAvailable,
      pharmacyId: medicine.pharmacyId,
    );
  }

  int get availableCount =>
      prescribed.where((medicine) => medicine.isAvailable).length;

  int get totalCount => prescribed.length;

  // ─── Selection ───────────────────────────────────────────────────────────

  bool isSelected(Medicine medicine) => selectedIds.contains(medicine.id);

  void toggle(Medicine medicine) {
    if (!medicine.isAvailable) return;
    if (!selectedIds.remove(medicine.id)) selectedIds.add(medicine.id);
  }

  bool get allSelected => selectedIds.length == availableCount;

  /// How many packs of each medicine the patient wants, before the basket
  /// exists. Absent means one — the quantity a prescription line implies.
  ///
  /// Kept apart from [lines] because Select Medicines runs before there is a
  /// basket to hold quantities: the stepper on that screen was wired to two
  /// empty callbacks and a literal `1`, so it read as working and did nothing.
  final RxMap<String, int> _quantities = <String, int>{}.obs;

  int quantityOf(Medicine medicine) => _quantities[medicine.id] ?? 1;

  void incrementSelection(Medicine medicine) =>
      _setSelectionQuantity(medicine, quantityOf(medicine) + 1);

  void decrementSelection(Medicine medicine) =>
      _setSelectionQuantity(medicine, quantityOf(medicine) - 1);

  /// One is the floor. The tick box is what removes a line here, and a row
  /// showing 0 that is still ticked would be counted by the total below.
  void _setSelectionQuantity(Medicine medicine, int quantity) {
    if (!medicine.isAvailable || quantity < 1) return;
    _quantities[medicine.id] = quantity;
  }

  void toggleSelectAll() {
    if (allSelected) {
      selectedIds.clear();
    } else {
      selectedIds
        ..clear()
        ..addAll(prescribed.where((m) => m.isAvailable).map((m) => m.id));
    }
  }

  /// Sum of the ticked lines, before delivery.
  ///
  /// Multiplied by the quantity chosen on each row, so the bar under the list
  /// agrees with what the basket will cost.
  double get selectionTotal => prescribed
      .where((medicine) => selectedIds.contains(medicine.id))
      .fold(0, (sum, medicine) => sum + medicine.price * quantityOf(medicine));

  // ─── Cart ────────────────────────────────────────────────────────────────

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  /// What the shop charges to bring it, as the server will bill it.
  ///
  /// A constant before, and one the server did not charge: the checkout added
  /// a fee to the total the patient agreed to and the order came back priced
  /// on items alone. The quote and the bill disagreed on every delivered
  /// order. Now both read the same platform setting.
  final RxDouble deliveryCharge = 0.0.obs;

  double get deliveryFee => pickupYourself.value ? 0 : deliveryCharge.value;

  /// Never more than the bill: crediting the whole balance against a smaller
  /// order printed a negative deduction on the summary.
  double get walletCredit => useWallet.value
      ? walletBalance.value.clamp(0, subtotal + deliveryFee)
      : 0;

  double get total =>
      (subtotal + deliveryFee - walletCredit).clamp(0, double.infinity);

  String format(double amount) => '\$${amount.toStringAsFixed(2)}';

  String get subtotalLabel => format(subtotal);
  String get deliveryFeeLabel => format(deliveryFee);
  String get walletCreditLabel => '-${format(walletCredit)}';
  String get totalLabel => format(total);

  /// The design keeps the button showing the pre-credit amount while the
  /// summary shows the payable one. It still follows the pickup toggle —
  /// quoting a delivery fee on a pickup order would be wrong either way.
  String get checkoutLabel => format(subtotal + deliveryFee);

  void addSelectionToCart() {
    lines.value = [
      for (final medicine in prescribed)
        if (selectedIds.contains(medicine.id))
          CartLine(medicine: medicine, quantity: quantityOf(medicine)),
    ];
    Get.toNamed<void>(AppRoutes.pharmacyCart);
  }

  /// Puts one medicine in the basket, from the catalogue rather than from a
  /// prescription.
  ///
  /// The Pharmacy tab's Add button used to increment a counter and nothing
  /// else, so the badge climbed while the basket stayed empty. Adding the same
  /// medicine twice raises its quantity rather than listing it twice.
  void addMedicine(Medicine medicine) {
    final index = lines.indexWhere((l) => l.medicine.id == medicine.id);
    if (index == -1) {
      lines.add(CartLine(medicine: medicine));
      selectedIds.add(medicine.id);
      return;
    }
    lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
  }

  void increment(CartLine line) => _setQuantity(line, line.quantity + 1);

  void decrement(CartLine line) => _setQuantity(line, line.quantity - 1);

  void _setQuantity(CartLine line, int quantity) {
    final index = lines.indexWhere((l) => l.medicine.id == line.medicine.id);
    if (index == -1) return;
    if (quantity <= 0) {
      lines.removeAt(index);
      selectedIds.remove(line.medicine.id);
      return;
    }
    lines[index] = line.copyWith(quantity: quantity);
  }

  void toggleWallet(bool value) => useWallet.value = value;

  void togglePickup(bool value) => pickupYourself.value = value;

  void selectMethod(int index) => selectedMethodIndex.value = index;

  /// Points this order at an address.
  ///
  /// [saveToProfile] is what separates "deliver this one elsewhere" from
  /// "I have moved". Without the distinction, sending a single parcel to the
  /// office would quietly relocate every order after it.
  Future<void> saveAddress(
    DeliveryAddress value, {
    bool saveToProfile = false,
  }) async {
    address.value = value;
    hasSavedAddress.value = true;
    if (!saveToProfile) return;

    profileAddress.value = value;
    try {
      await _account.saveAddress(value);
    } on AppException catch (e) {
      // The order can still go to it — only the remembering failed, and
      // saying so beats silently asking again next time.
      AppSnackbar.error(e.message);
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void editMedicines() => Get.toNamed<void>(AppRoutes.selectMedicines);

  void proceedToPayment() => Get.toNamed<void>(AppRoutes.pharmacyPayment);

  /// A real catalogue id, as the server assigns them. The prescription flow
  /// (`PharmacyMockData.prescribed`) hands out placeholder ids like `rx-1`
  /// that this pattern rejects, which is the signal to resolve them below.
  static final RegExp _objectId = RegExp(r'^[a-f0-9]{24}$');

  /// Maps this basket's lines to real, orderable medicine ids.
  ///
  /// A line added from the catalogue already carries the server's id. A line
  /// that came from the prescription screen carries a placeholder id instead
  /// — that screen is UI-only and was never wired to the pharmacy's actual
  /// stock — so its medicine is looked up by name at [pharmacyId] here. A
  /// name with no match at that pharmacy is dropped rather than sent, since
  /// the server would otherwise reject the whole order for one bad id.
  Future<Map<String, int>> _resolveQuantities(String pharmacyId) async {
    final quantities = <String, int>{};
    for (final line in lines) {
      if (_objectId.hasMatch(line.medicine.id)) {
        quantities[line.medicine.id] = line.quantity;
        continue;
      }
      final matches = await _pharmacy.searchMedicines(
        query: line.medicine.name,
        pharmacyId: pharmacyId,
      );
      final match = matches.isEmpty ? null : matches.first;
      if (match == null) continue;
      quantities[match.id] = (quantities[match.id] ?? 0) + line.quantity;
    }
    return quantities;
  }

  /// Files the order with the server, then shows its tracking screen.
  ///
  /// This used to navigate and nothing else: the patient saw "order placed"
  /// over a server that had never heard of it, and the Orders list stayed
  /// empty. `POST /medicine-orders` existed the whole time.
  Future<void> placeOrder() async {
    if (isPlacingOrder.value) return;

    if (lines.isEmpty) {
      AppSnackbar.info(AppStrings.cartIsEmpty.tr);
      return;
    }
    // Guarded on the address itself rather than the "has one saved" flag: the
    // flag is about which link the screen shows, and an order needs somewhere
    // to go regardless of how it got there.
    if (!address.value.isComplete) {
      AppSnackbar.info(AppStrings.addDeliveryAddressFirst.tr);
      return;
    }

    // An order names one pharmacy. The chosen store wins when the basket came
    // through Best Matches; otherwise it is the one stocking what is in it.
    final pharmacyId =
        store.value?.id ??
        lines
            .map((line) => line.medicine.pharmacyId)
            .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    if (pharmacyId.isEmpty) {
      AppSnackbar.error(AppStrings.somethingWentWrong.tr);
      return;
    }

    // The server takes a real pharmacy, and says so twice: `pharmacyId` is an
    // ObjectId on both `GET /medicines` and `POST /medicine-orders`. A basket
    // that came through Best Matches carries an id from that screen's static
    // list instead, which is not one — the lookup below then 400s, and it did
    // so as an *unhandled* exception because it sat outside the try.
    //
    // Checked before anything is sent: an order that cannot succeed should
    // say why here, not fail two requests later with "Validation failed".
    if (!_objectId.hasMatch(pharmacyId)) {
      AppSnackbar.error(AppStrings.pharmacyNotOrderable.tr);
      return;
    }

    isPlacingOrder.value = true;

    String orderId;
    try {
      final quantitiesByMedicineId = await _resolveQuantities(pharmacyId);
      if (quantitiesByMedicineId.isEmpty) {
        AppSnackbar.error(AppStrings.somethingWentWrong.tr);
        isPlacingOrder.value = false;
        return;
      }

      orderId = await _pharmacy.placeOrder(
        pharmacyId: pharmacyId,
        quantitiesByMedicineId: quantitiesByMedicineId,
        deliveryAddress: address.value.singleLine,
        // Null unless the patient pinned it, in which case the server keeps
        // the pin instead of geocoding the address line — a guess that
        // returns nothing at all without a Maps key configured.
        deliveryLat: address.value.lat,
        deliveryLng: address.value.lng,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      isPlacingOrder.value = false;
      return;
    }

    // Paid straight away, out of the wallet — unpaid, the order is a dead
    // end: the pharmacy sees it as new but the server refuses to let them
    // accept it. A wallet that cannot cover it leaves the order pending and
    // says why, rather than pretending the purchase completed.
    try {
      await _pharmacy.payOrder(orderId);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isPlacingOrder.value = false;
    }

    Get.offNamed<void>(AppRoutes.pharmacyOrder);
  }

  /// Guards the button: an order that has been sent must not be sent twice.
  final RxBool isPlacingOrder = false.obs;
}
