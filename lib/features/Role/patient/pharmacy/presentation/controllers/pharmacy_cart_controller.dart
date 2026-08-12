import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../data/static/pharmacy_mock_data.dart';
import '../../domain/entities/pharmacy.dart';

/// Spans medicine selection, the cart, payment and the placed order.
///
/// One controller because the basket, the wallet toggle and the delivery
/// address all follow the patient across those screens. UI-only: totals are
/// computed locally and no payment is taken.
class PharmacyCartController extends GetxController {
  PharmacyCartController({WalletRepository? wallet})
    : _wallet = wallet ?? Get.find<WalletRepository>();

  final WalletRepository _wallet;

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

  final Rx<DeliveryAddress> address = PharmacyMockData.address.obs;

  /// False until the patient saves an address for the first time, which is
  /// what switches the payment screen's link between "Add" and "Change".
  final RxBool hasSavedAddress = false.obs;

  final RxInt selectedMethodIndex = 0.obs;

  // ─── Availability ────────────────────────────────────────────────────────

  /// The prescription, with lines beyond the store's stock marked
  /// unavailable — that is what greys the last row when a pharmacy cannot
  /// fill the whole script.
  List<Medicine> get prescribed {
    final available = store.value?.availableCount ?? 6;
    return [
      for (var index = 0; index < PharmacyMockData.prescribed.length; index++)
        _withAvailability(
          PharmacyMockData.prescribed[index],
          isAvailable: index < available,
        ),
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
    );
  }

  int get availableCount =>
      prescribed.where((medicine) => medicine.isAvailable).length;

  int get totalCount => PharmacyMockData.prescribed.length;

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

  void placeOrder() => Get.offNamed<void>(AppRoutes.pharmacyOrder);
}
