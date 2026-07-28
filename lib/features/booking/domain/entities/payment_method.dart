import '../../../../core/constants/app_strings.dart';

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
}

/// A stored-value balance that can offset part of the total.
class Wallet {
  const Wallet({required this.balance, this.currencySymbol = '\$'});

  final double balance;
  final String currencySymbol;

  String get balanceLabel =>
      '$currencySymbol${balance.toStringAsFixed(2)}';
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

  /// What the chosen payment method is actually charged.
  double get payable => (total - walletDeduction).clamp(0, double.infinity);

  String format(double amount) =>
      '$currencySymbol${amount.toStringAsFixed(0)}';

  String get consultationFeeLabel => format(consultationFee);

  /// VAT reads as a bare `0` in the design when there is none.
  String get vatLabel => vat == 0 ? '0' : format(vat);

  String get totalLabel => format(total);

  String get payableLabel => format(payable);
}
