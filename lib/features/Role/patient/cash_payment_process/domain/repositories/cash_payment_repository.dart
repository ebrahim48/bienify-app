import '../entities/cash_payment.dart';

/// Paying at a counter rather than with a card.
abstract class CashPaymentRepository {
  /// Places that accept the code.
  Future<List<PaymentPoint>> points();

  /// Issues a code for [amount] at [paymentPointId], and returns it with the
  /// reference and expiry the server set.
  ///
  /// The expiry is the server's to decide — a client that chose its own would
  /// let a patient hold a booking for as long as they liked.
  Future<PaymentCode> issueCode({
    required String paymentPointId,
    required double amount,
  });

  /// The code as it stands now, which is how the pending screen learns that an
  /// agent has taken the cash.
  Future<CashIntentState> refresh(String reference);
}

/// Where an issued code has got to.
enum CashIntentState { pending, confirmed, expired, cancelled }
