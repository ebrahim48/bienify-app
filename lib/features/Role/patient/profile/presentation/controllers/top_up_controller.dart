import 'dart:math';

import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/profile.dart';
import 'account_controller.dart';

/// Backs Add Money.
///
/// The wallet is how consultations and medicine are paid for, and until this
/// screen existed the only ways into it were the seed script, a refund and a
/// cash payment an admin confirmed.
class TopUpController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  TopUpController({WalletRepository? repository, AccountController? account})
    : _repository = repository ?? Get.find<WalletRepository>(),
      _account = account ?? Get.find<AccountController>();

  final WalletRepository _repository;
  final AccountController _account;

  static const String amountField = 'top_up_amount';

  /// The amounts the chips offer, in major units.
  static const List<int> quickAmounts = [10, 25, 50, 100];

  /// A floor rather than the server's 1 minor unit: a one-cent top-up costs
  /// more in gateway fees than it moves.
  static const int minimumMinor = 100;

  /// What `topupSchema` accepts at the top end.
  static const int maximumMinor = 100000000;

  final RxString amount = ''.obs;

  /// Which saved card will be charged.
  final RxnString selectedCardId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _selectDefaultCard();
    // The card list belongs to the account, which may not have been read yet
    // if Add Money was opened directly.
    ever<List<WalletCard>>(_account.cards, (_) => _selectDefaultCard());
  }

  void _selectDefaultCard() {
    if (selectedCardId.value != null) return;
    final cards = _account.cards;
    if (cards.isEmpty) return;
    // The server marks one card default; honour it rather than picking the
    // first row, which is only the newest.
    final preferred = cards.firstWhereOrNull((card) => card.isDefault);
    selectedCardId.value = (preferred ?? cards.first).id;
  }

  List<WalletCard> get cards => _account.cards;

  /// Always the real figure, never the Wallet's eye-toggle mask: a top-up
  /// screen that hides the balance cannot show what the balance becomes.
  String get balanceLabel =>
      '\$${_account.balance.value.toStringAsFixed(2)}';

  bool get hasCard => cards.isNotEmpty;

  void selectCard(String cardId) => selectedCardId.value = cardId;

  void selectQuickAmount(int major) {
    amount.value = major.toStringAsFixed(2);
    clearError(amountField);
    // A new amount is a new attempt; reusing the key would make the server
    // treat a deliberate second top-up as a retry of the first.
    _idempotencyKey = null;
  }

  void setAmount(String value) {
    amount.value = value;
    clearError(amountField);
    _idempotencyKey = null;
  }

  /// Whether a quick chip matches what is typed, so the chip and the field
  /// cannot disagree — the amount is the single source of truth.
  bool isQuickAmountSelected(int major) => _parsed == major.toDouble();

  double? get _parsed {
    final text = amount.value.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  /// Minor units for the wire.
  ///
  /// `.round()`, never `.toInt()`: `(0.29 * 100).toInt()` is 28 in IEEE-754,
  /// which is a silent one-cent shortfall on a real payment.
  int? get amountMinor {
    final value = _parsed;
    if (value == null) return null;
    return (value * 100).round();
  }

  bool get isAmountValid {
    final minor = amountMinor;
    return minor != null && minor >= minimumMinor && minor <= maximumMinor;
  }

  bool get canSubmit => isAmountValid && selectedCardId.value != null;

  /// The balance the wallet will hold if this lands. Hidden while the amount
  /// is unusable rather than showing the balance unchanged, which would read
  /// as a preview of nothing happening.
  String? get newBalanceLabel {
    if (!isAmountValid) return null;
    final after = _account.balance.value + (amountMinor! / 100);
    return '\$${after.toStringAsFixed(2)}';
  }

  String get amountLabel =>
      isAmountValid ? '\$${(amountMinor! / 100).toStringAsFixed(2)}' : '';

  /// Held across retries of one attempt.
  ///
  /// A patient who taps Add, loses the network on the response and taps again
  /// must reuse this: the server's duplicate handling is what stops the second
  /// tap becoming a second charge.
  String? _idempotencyKey;

  String get _key => _idempotencyKey ??=
      'topup-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';

  String? _validateAmount() {
    final minor = amountMinor;
    if (minor == null) return AppStrings.errorAmountInvalid.tr;
    if (minor < minimumMinor) return AppStrings.errorAmountTooSmall.tr;
    if (minor > maximumMinor) return AppStrings.errorAmountTooLarge.tr;
    return null;
  }

  Future<void> addMoney() async {
    if (!validate({amountField: _validateAmount()})) return;

    final cardId = selectedCardId.value;
    if (cardId == null) {
      AppSnackbar.info(AppStrings.topUpNeedsCard.tr);
      return;
    }

    final minor = amountMinor!;
    // A 409 means the ledger already holds this movement — the money moved and
    // the response was lost. Reporting it as a failure invites a second, real
    // charge, so it is treated as the success it is.
    var alreadyProcessed = false;

    final ok = await submit(() async {
      try {
        final result = await _repository.topUp(
          amountMinor: minor,
          savedCardId: cardId,
          idempotencyKey: _key,
        );
        _account.applyTopUp(result);
      } on ConflictException {
        alreadyProcessed = true;
        rethrow;
      }
    });

    if (!ok && !alreadyProcessed) return;

    if (alreadyProcessed) {
      // The local figures are unknown after a lost response, so they are
      // re-read rather than guessed.
      await _account.load();
    }

    // Spent, so the next visit starts clean rather than re-offering an amount
    // that has already been charged.
    _idempotencyKey = null;
    amount.value = '';

    Get.until((route) => route.settings.name != AppRoutes.walletTopUp);
    AppSnackbar.success(AppStrings.topUpAdded.tr);
  }

  void openAddCard() => Get.toNamed<void>(AppRoutes.paymentOptions);
}
