import '../../domain/entities/cash_payment.dart';
import '../../domain/repositories/cash_payment_repository.dart';
import '../static/cash_payment_data.dart';

/// Cash payment, served from the design's sample data.
class MockCashPaymentRepository implements CashPaymentRepository {
  const MockCashPaymentRepository();

  @override
  Future<List<PaymentPoint>> points() async => CashPaymentData.points;

  @override
  Future<PaymentCode> issueCode({
    required String paymentPointId,
    required double amount,
  }) async =>
      CashPaymentData.code(amountLabel: '\$${amount.toStringAsFixed(2)}');

  /// Confirmed, so the goldens can reach the receipt without an agent taking
  /// cash in the middle of a test run.
  @override
  Future<CashIntentState> refresh(String reference) async =>
      CashIntentState.confirmed;
}
