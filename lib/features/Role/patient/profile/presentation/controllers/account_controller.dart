import '../../../pharmacy/domain/entities/pharmacy.dart';
import '../../../pharmacy/domain/repositories/pharmacy_repository.dart';
import '../../../pharmacy/presentation/controllers/pharmacy_cart_controller.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import '../../../booking/domain/entities/payment_method.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/profile.dart';

/// Backs My Order History and My Wallet.
///
/// One controller because both are views of the same account and neither has
/// enough state to justify its own.
class AccountController extends GetxController {
  AccountController({WalletRepository? repository, PharmacyRepository? pharmacy})
    : _repository = repository ?? Get.find<WalletRepository>(),
      _pharmacy = pharmacy ?? Get.find<PharmacyRepository>();

  final WalletRepository _repository;
  final PharmacyRepository _pharmacy;

  /// What the shop being reviewed actually stocks.
  ///
  /// The review screen drew a fixed grid of demo medicines for every shop.
  final RxList<Medicine> shopMedicines = <Medicine>[].obs;

  final RxList<OrderHistoryEntry> orders = <OrderHistoryEntry>[].obs;
  final RxList<WalletCard> cards = <WalletCard>[].obs;

  /// Where money is paid *out* to. Listed alongside the cards because the
  /// Wallet is where both are added, and a courier who filed a bank account
  /// here had no way to see that it had been stored.
  final RxList<PayoutAccount> payoutAccounts = <PayoutAccount>[].obs;

  final RxDouble balance = 0.0.obs;

  final RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  final RxDouble _totalSpent = 0.0.obs;
  final RxDouble _addedThisMonth = 0.0.obs;
  final RxInt _spentOrderCount = 0.obs;

  /// The eye toggle on the balance card.
  final RxBool isBalanceHidden = false.obs;

  /// Which method the Payment Options step has selected.
  final RxInt selectedMethodIndex = 0.obs;

  /// Which chip is active above the order list.
  final Rx<OrderFilter> filter = OrderFilter.all.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final summary = await _repository.summary();
      balance.value = summary.balance;
      // `List.of`: a repository may hand back a const list, and saving a card
      // then throws "Cannot add to an unmodifiable list".
      cards.value = List.of(summary.cards);
      // `List.of` for the same reason as the cards above: a repository may hand
      // back a const list, and a top-up inserting its new row into one throws
      // "Cannot add to an unmodifiable list".
      transactions.value = List.of(summary.transactions);
      _totalSpent.value = summary.totalSpent;
      _addedThisMonth.value = summary.addedThisMonth;
      _spentOrderCount.value = summary.spentOrderCount;
      orders.value = await _repository.orders();
      payoutAccounts.value = await _repository.payoutAccounts();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasCard => cards.isNotEmpty;

  // ─── Wallet ──────────────────────────────────────────────────────────────

  String get balanceLabel =>
      isBalanceHidden.value ? '••••' : '\$${balance.value.toStringAsFixed(2)}';

  String get totalSpentLabel => '\$${_totalSpent.value.toStringAsFixed(2)}';

  String get addedThisMonthLabel =>
      '\$${_addedThisMonth.value.toStringAsFixed(2)}';

  int get spentOrderCount => _spentOrderCount.value;

  void toggleBalanceVisibility() =>
      isBalanceHidden.value = !isBalanceHidden.value;

  /// `Jul 10, 2026` — the transaction rows carry the year.
  String transactionDateLabel(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[at.month - 1]} ${at.day}, ${at.year}';
  }

  void selectMethod(int index) => selectedMethodIndex.value = index;

  /// The methods Payment Options offers, which are the ones that store
  /// something. See [PaymentMethod.isStorable].
  List<PaymentMethod> get methodOptions => PaymentMethod.storable;

  /// The method currently picked, guarded against an index left over from a
  /// previous visit.
  PaymentMethod get selectedMethod {
    final options = methodOptions;
    final index = selectedMethodIndex.value;
    return index >= 0 && index < options.length ? options[index] : options.first;
  }

  /// Payment Options continues to the form the chosen method actually needs.
  ///
  /// It used to open the debit-card form whichever of the six methods was
  /// selected, so the choice was decorative: picking Bank Transfer collected a
  /// card number, expiry and CVV and filed the result to `/wallet/cards`. A
  /// courier who added their bank here was then told by the payout sheet to
  /// add a payout account, because none had been created — the money-in list
  /// and the money-out list are separate, and only the first was ever written.
  void continueToAccountForm() {
    final kind = selectedMethod.payoutKind;
    if (kind == null) {
      Get.toNamed<void>(AppRoutes.addDebitCard);
      return;
    }
    Get.toNamed<void>(AppRoutes.addPayoutAccount, arguments: kind);
  }

  void openAccounts() => Get.toNamed<void>(AppRoutes.walletAccounts);

  // ─── Order history ───────────────────────────────────────────────────────

  List<OrderHistoryEntry> get visibleOrders => orders
      .where(
        (order) => switch (filter.value) {
          OrderFilter.all => true,
          OrderFilter.delivered => order.state == OrderState.delivered,
          OrderFilter.pending => order.state == OrderState.inProgress,
          OrderFilter.cancelled => order.state == OrderState.cancelled,
        },
      )
      .toList();

  void selectFilter(OrderFilter value) => filter.value = value;

  String filterLabel(OrderFilter value) => switch (value) {
    OrderFilter.all => AppStrings.filterAll.tr,
    OrderFilter.delivered => AppStrings.filterDelivered.tr,
    OrderFilter.pending => AppStrings.filterPending.tr,
    OrderFilter.cancelled => AppStrings.filterCancelled.tr,
  };

  /// `Jun 28` — the order rows carry no year, as the design shows.
  String shortDateLabel(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[at.month - 1]} ${at.day}';
  }

  /// Rates the shop that filled [order].
  ///
  /// The dialog used to collect the stars and navigate away without sending
  /// them anywhere, so every shop rating a patient gave was discarded at the
  /// moment they gave it. Returns whether it landed, so the screen only
  /// closes on a review that exists.
  Future<bool> submitShopReview(OrderHistoryEntry order, int rating) async {
    try {
      await _pharmacy.reviewPharmacy(orderId: order.id, rating: rating);
    } on AppException catch (e) {
      // The server refuses a second review of the same order, and an order
      // that is not delivered yet. Both are worth saying out loud rather than
      // silently pretending the rating was taken.
      AppSnackbar.error(e.message);
      return false;
    }
    AppSnackbar.success(AppStrings.reviewSubmitted.tr);
    return true;
  }

  /// Opening an order shows the shop it came from, which is where a review is
  /// written.
  void openOrder(OrderHistoryEntry order) {
    _loadShopMedicines(order.pharmacyId);
    Get.toNamed<void>(AppRoutes.reviewShop, arguments: order);
  }

  Future<void> _loadShopMedicines(String pharmacyId) async {
    shopMedicines.clear();
    if (pharmacyId.isEmpty) return;
    try {
      shopMedicines.value = await _pharmacy.searchMedicines(
        pharmacyId: pharmacyId,
      );
    } on AppException {
      // The grid simply stays empty; the review itself is the point of the
      // screen, and a shelf of somebody else's stock is not a fallback.
    }
  }

  /// The pill and the filter chip use the same words in the design, so they
  /// share one set of labels — an order the chip calls "Pending" must not read
  /// "In progress" on its own row.
  String stateLabel(OrderState state) => switch (state) {
    OrderState.delivered => AppStrings.filterDelivered.tr,
    OrderState.cancelled => AppStrings.filterCancelled.tr,
    OrderState.inProgress => AppStrings.filterPending.tr,
  };

  /// `31 Mar 2026` — formatted by hand so the app carries no `intl`
  /// dependency, matching the other date labels.
  String dateLabel(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${at.day} ${months[at.month - 1]} ${at.year}';
  }

  /// Puts the previous order's lines back in the basket, then opens it.
  ///
  /// It opened an empty cart, so "Reorder" ordered nothing — the patient had
  /// to remember what they had bought and find each medicine again.
  ///
  /// The medicines are re-read rather than trusted from the old row: a price
  /// or a stock level from weeks ago is not what the patient would be
  /// charged, and anything the shop no longer carries is dropped rather than
  /// added as a line the checkout would refuse.
  Future<void> reorder(OrderHistoryEntry order) async {
    if (order.quantitiesByMedicineId.isEmpty) {
      AppSnackbar.info(AppStrings.reorderNothingToAdd.tr);
      return;
    }

    final List<Medicine> stock;
    try {
      stock = await _pharmacy.searchMedicines(pharmacyId: order.pharmacyId);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    final cart = Get.isRegistered<PharmacyCartController>()
        ? Get.find<PharmacyCartController>()
        : Get.put(PharmacyCartController());

    var added = 0;
    for (final entry in order.quantitiesByMedicineId.entries) {
      final medicine = stock.firstWhereOrNull((m) => m.id == entry.key);
      if (medicine == null) continue;
      for (var i = 0; i < entry.value; i++) {
        cart.addMedicine(medicine);
      }
      added++;
    }

    if (added == 0) {
      // Every line has gone from the shop's shelf. Saying so beats opening an
      // empty basket that looks like the reorder simply failed.
      AppSnackbar.info(AppStrings.reorderNothingToAdd.tr);
      return;
    }
    if (added < order.quantitiesByMedicineId.length) {
      AppSnackbar.info(AppStrings.reorderPartial.tr);
    }

    Get.toNamed<void>(AppRoutes.pharmacyCart);
  }

  /// The promo strip opens the catalogue.
  void openPromo() => Get.toNamed<void>(AppRoutes.uploadPrescription);

  // ─── Wallet ──────────────────────────────────────────────────────────────

  void openPaymentOptions() => Get.toNamed<void>(AppRoutes.paymentOptions);

  void openAddCard() => Get.toNamed<void>(AppRoutes.addDebitCard);

  void openTopUp() => Get.toNamed<void>(AppRoutes.walletTopUp);

  /// Folds a completed top-up into what the Wallet is showing.
  ///
  /// The balance comes from the server's own `balanceAfterMinor` rather than
  /// being added up here, and the row is inserted rather than triggering a
  /// reload — a full `load()` blanks and repaints a screen the patient is
  /// looking at, to show something already known.
  void applyTopUp(WalletTopUp result) {
    balance.value = result.balanceAfter;
    transactions.insert(0, result.transaction);
    _addedThisMonth.value += result.transaction.amount;
  }

  final RxBool isSavingPayoutAccount = false.obs;

  /// Files somewhere the account holder can be paid, and adds it to the list
  /// the Wallet and the payout sheet both read.
  ///
  /// Returns whether it landed, so the form knows whether to close.
  Future<bool> savePayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    if (isSavingPayoutAccount.value) return false;

    final name = displayName.trim();
    final number = accountNumber.trim();
    // The server masks down to the last four digits, so fewer than four is a
    // number it cannot store. Checked here to name the field rather than
    // return a validation error about the whole body.
    if (name.isEmpty || number.length < 4) {
      AppSnackbar.info(AppStrings.payoutAccountNeedsDetails.tr);
      return false;
    }

    isSavingPayoutAccount.value = true;
    try {
      final saved = await _repository.addPayoutAccount(
        kind: kind,
        displayName: name,
        accountNumber: number,
        bankName: bankName?.trim(),
      );
      payoutAccounts.add(saved);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isSavingPayoutAccount.value = false;
    }

    AppSnackbar.success(AppStrings.payoutAccountAdded.tr);
    return true;
  }

  void addPaymentMethod() => openPaymentOptions();

  /// Saves a card and nothing else. Navigation is the caller's decision — a
  /// controller that popped its own route would break any screen that saved a
  /// card without one on the stack.
  ///
  /// [gatewayToken] comes from the payment SDK: a raw card number must never
  /// reach the API, and the form does not have one to give.
  Future<void> saveCard({
    required String gatewayToken,
    required String brand,
    required String last4,
    required int expiryMonth,
    required int expiryYear,
  }) async {
    final WalletCard saved;
    try {
      saved = await _repository.addCard(
        gatewayToken: gatewayToken,
        brand: brand,
        last4: last4,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    // The first card saved becomes the default; there is nothing to compare
    // it against.
    if (cards.isEmpty) {
      try {
        await _repository.makeCardDefault(saved.id);
      } on AppException {
        // The card is stored either way; the server picks a default on its
        // own if this does not land.
      }
      cards.add(_asDefault(saved));
    } else {
      cards.add(saved);
    }
    AppSnackbar.success(AppStrings.cardSaved.tr);
  }

  WalletCard _asDefault(WalletCard card) => WalletCard(
    id: card.id,
    brand: card.brand,
    maskedNumber: card.maskedNumber,
    expiry: card.expiry,
    isDefault: true,
  );

  Future<void> makeDefault(WalletCard card) async {
    try {
      await _repository.makeCardDefault(card.id);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }
    // The server clears the other defaults as part of the same write, so the
    // list is rebuilt rather than having one row flipped — two cards both
    // marked default is a state the wallet can never be in.
    cards.value = [
      for (final existing in cards)
        WalletCard(
          id: existing.id,
          brand: existing.brand,
          maskedNumber: existing.maskedNumber,
          expiry: existing.expiry,
          isDefault: existing.id == card.id,
        ),
    ];
  }

  Future<void> removeCard(WalletCard card) async {
    try {
      await _repository.removeCard(card.id);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }
    cards.removeWhere((existing) => existing.id == card.id);
  }
}
