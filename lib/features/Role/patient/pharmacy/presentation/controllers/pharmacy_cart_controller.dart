import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// Spans medicine selection, the cart, payment and the placed order.
///
/// One controller because the basket, the wallet toggle and the delivery
/// address all follow the patient across those screens. UI-only: totals are
/// computed locally and no payment is taken.
class PharmacyCartController extends GetxController {
  PharmacyCartController({WalletRepository? wallet, PharmacyRepository? pharmacy})
    : _wallet = wallet ?? Get.find<WalletRepository>(),
      _pharmacy = pharmacy ?? Get.find<PharmacyRepository>();

  final WalletRepository _wallet;
  final PharmacyRepository _pharmacy;

  /// Which store is filling the script; drives which lines are available.
  final Rxn<PharmacyStore> store = Rxn<PharmacyStore>();

  /// The patient's own balance, not the design's $45. Read on open, because
  /// it moves whenever a consultation is paid for or an order settles, and a
  /// stale figure promises a deduction the server will refuse.
  final RxDouble walletBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadBalance();
    ever(store, (PharmacyStore? selected) {
      if (selected != null) _loadMedicines(selected);
    });
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

  Future<void> _loadMedicines(PharmacyStore selected) async {
    isLoadingMedicines.value = true;
    medicinesError.value = null;
    try {
      prescribed.value = await _pharmacy.searchMedicines(
        pharmacyId: selected.id,
      );
    } on AppException catch (e) {
      medicinesError.value = e.message;
    } finally {
      isLoadingMedicines.value = false;
    }
  }

  final RxList<CartLine> lines = <CartLine>[].obs;

  /// Ids ticked on the Select Medicines screen.
  final RxSet<String> selectedIds = <String>{}.obs;

  final RxBool useWallet = false.obs;
  final RxBool pickupYourself = false.obs;

  final Rx<DeliveryAddress> address = PharmacyMockData.address.obs;

  /// False until the patient saves an address for the first time, which is
  /// what switches the payment screen's link between "Add" and "Change".
  final RxBool hasSavedAddress = false.obs;

  final RxInt selectedMethodIndex = 0.obs;

  // ─── Availability ────────────────────────────────────────────────────────

  /// The selected pharmacy's catalogue, loaded once [store] is set. Each
  /// medicine carries its own real `isAvailable` (stock and listing status),
  /// so nothing here needs to fake unavailability past a cutoff index.
  final RxList<Medicine> prescribed = <Medicine>[].obs;

  final RxBool isLoadingMedicines = false.obs;
  final RxnString medicinesError = RxnString();

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
  double get selectionTotal => prescribed
      .where((medicine) => selectedIds.contains(medicine.id))
      .fold(0, (sum, medicine) => sum + medicine.price);

  // ─── Cart ────────────────────────────────────────────────────────────────

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  double get deliveryFee =>
      pickupYourself.value ? 0 : PharmacyMockData.deliveryFee;

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
        if (selectedIds.contains(medicine.id)) CartLine(medicine: medicine),
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

  void saveAddress(DeliveryAddress value) {
    address.value = value;
    hasSavedAddress.value = true;
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void editMedicines() => Get.toNamed<void>(AppRoutes.selectMedicines);

  void proceedToPayment() => Get.toNamed<void>(AppRoutes.pharmacyPayment);

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
    if (!hasSavedAddress.value) {
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

    isPlacingOrder.value = true;
    String orderId;
    try {
      orderId = await _pharmacy.placeOrder(
        pharmacyId: pharmacyId,
        quantitiesByMedicineId: {
          for (final line in lines) line.medicine.id: line.quantity,
        },
        deliveryAddress: '${address.value.line1}, ${address.value.line2}',
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
