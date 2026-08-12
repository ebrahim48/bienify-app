import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/profile.dart';

/// Backs My Order History and My Wallet.
///
/// One controller because both are views of the same account and neither has
/// enough state to justify its own.
class AccountController extends GetxController {
  AccountController({WalletRepository? repository})
    : _repository = repository ?? Get.find<WalletRepository>();

  final WalletRepository _repository;

  final RxList<OrderHistoryEntry> orders = <OrderHistoryEntry>[].obs;
  final RxList<WalletCard> cards = <WalletCard>[].obs;

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
      transactions.value = summary.transactions;
      _totalSpent.value = summary.totalSpent;
      _addedThisMonth.value = summary.addedThisMonth;
      _spentOrderCount.value = summary.spentOrderCount;
      orders.value = await _repository.orders();
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

  /// Payment Options continues to the card form. The design's Next leads
  /// there for every method; the non-card ones gain their own step when those
  /// are designed.
  void continueToCardForm() => Get.toNamed<void>(AppRoutes.addDebitCard);

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

  /// Opening an order shows the shop it came from, which is where a review is
  /// written.
  void openOrder(OrderHistoryEntry order) =>
      Get.toNamed<void>(AppRoutes.reviewShop, arguments: order);

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

  /// Re-ordering resumes the pharmacy flow at the basket.
  void reorder(OrderHistoryEntry order) =>
      Get.toNamed<void>(AppRoutes.pharmacyCart);

  /// The promo strip opens the catalogue.
  void openPromo() => Get.toNamed<void>(AppRoutes.uploadPrescription);

  // ─── Wallet ──────────────────────────────────────────────────────────────

  void openPaymentOptions() => Get.toNamed<void>(AppRoutes.paymentOptions);

  void openAddCard() => Get.toNamed<void>(AppRoutes.addDebitCard);

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
