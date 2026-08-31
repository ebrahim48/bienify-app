import '../../../../../../core/constants/app_strings.dart';

/// The ways a consultation can be paid for, in the order the design lists
/// them.
enum PaymentMethod {
  debitCredit(AppStrings.paymentDebitCredit),
  appleGooglePay(AppStrings.paymentApplePay),
  bankTransfer(AppStrings.paymentBankTransfer),
  tpago(AppStrings.paymentTpago),
  paypal(AppStrings.paymentPaypal),
  cashOnLocation(AppStrings.paymentCash);

  const PaymentMethod(this.labelKey);

  /// Translation key for the row label.
  final String labelKey;

  /// The server's own name for the payout destination this method files, or
  /// null when it files none.
  ///
  /// `bank | mobile_money` is the whole enum `/wallet/payout-accounts`
  /// accepts. tPago is a mobile-money wallet, so it belongs to the second.
  String? get payoutKind => switch (this) {
    PaymentMethod.bankTransfer => 'bank',
    PaymentMethod.tpago => 'mobile_money',
    _ => null,
  };

  /// Whether choosing this in the Wallet actually stores something.
  ///
  /// Apple/Google Pay, PayPal and cash are ways to settle a bill at the
  /// moment of paying; the API has nowhere to keep them and the app has no
  /// form for them. They used to be listed under "Add Account" anyway, and
  /// picking one silently opened the debit-card form — so a courier choosing
  /// Bank Transfer filed a card, which is not something they can be paid into.
  bool get isStorable => this == PaymentMethod.debitCredit || payoutKind != null;

  /// The methods the Wallet can genuinely add, in the design's order.
  static List<PaymentMethod> get storable =>
      values.where((method) => method.isStorable).toList(growable: false);
}

/// A stored-value balance that can offset part of the total.
class Wallet {
  const Wallet({required this.balance, this.currencySymbol = '\$'});

  final double balance;
  final String currencySymbol;

  String get balanceLabel => '$currencySymbol${balance.toStringAsFixed(2)}';
}

/// The money side of a booking.
class PaymentBreakdown {
  const PaymentBreakdown({
    required this.consultationFee,
    this.vat = 0,
    this.walletDeduction = 0,
    this.currencySymbol = '\$',
  });

  final double consultationFee;
  final double vat;

  /// Amount taken from the wallet when the toggle is on.
  final double walletDeduction;

  final String currencySymbol;

  double get total => consultationFee + vat;

  /// What the patient actually parts with, which is the whole bill.
  ///
  /// The wallet is where the money comes from, not a discount on it:
  /// `POST /payments/appointments/:id/pay` debits the full fee from the
  /// balance. Subtracting the wallet here made a $50 consultation read as
  /// "Pay $0" while $50 still left the patient's account.
  double get payable => total;

  String format(double amount) => '$currencySymbol${amount.toStringAsFixed(0)}';

  String get consultationFeeLabel => format(consultationFee);

  /// VAT reads as a bare `0` in the design when there is none.
  String get vatLabel => vat == 0 ? '0' : format(vat);

  String get totalLabel => format(total);

  String get payableLabel => format(payable);
}
