import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../data/static/cash_payment_data.dart';
import '../../domain/entities/cash_payment.dart';

/// Backs the Payment Confirmed receipt.
///
/// UI-only: the confirmation comes from [CashPaymentData]. When the status
/// endpoint exists it returns this same shape.
class PaymentConfirmedController extends GetxController {
  PaymentConfirmedController({
    String totalLabel = '\$74.89',
    String code = '#BIE12345',
  }) : confirmation = CashPaymentData.confirmation(
         totalLabel: totalLabel,
         code: code,
       );

  final PaymentConfirmation confirmation;

  /// Clears the booking flow off the stack — the journey is finished.
  void goHome() => AppNavigator.resetTo(AppRoutes.home);
}
