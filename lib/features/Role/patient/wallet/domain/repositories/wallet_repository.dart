/// The patient's stored balance.
abstract class WalletRepository {
  /// The current balance in major units.
  ///
  /// Read fresh rather than cached: it changes whenever a consultation is paid
  /// for or an order settled, and a stale figure on the payment screen tells
  /// the patient a payment will succeed when it will not.
  Future<double> balance();
}
