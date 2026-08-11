import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../domain/entities/payment_method.dart';

/// Backs the Payment Summary screen.
///
/// Holds the draft appointment carried over from Doctor Details, the wallet
/// toggle, the chosen method and any attached documents.
class PaymentController extends GetxController with SubmissionMixin {
  PaymentController({required this.appointment});

  final Appointment appointment;

  /// Balance available to offset the total.
  static const Wallet wallet = Wallet(balance: 45);

  final Rx<PaymentMethod> selectedMethod = PaymentMethod.debitCredit.obs;
  final RxBool useWallet = true.obs;

  /// File names of documents the patient attached, shown under the tiles.
  final RxList<String> attachments = <String>[].obs;

  PaymentBreakdown get breakdown => PaymentBreakdown(
    consultationFee: _fee,
    walletDeduction: useWallet.value ? wallet.balance : 0,
  );

  /// The fee is fixed per doctor; the design shows $400.
  double get _fee => 400;

  bool isSelected(PaymentMethod method) => selectedMethod.value == method;

  /// Selects [method]; paying at a location is a journey of its own, so it
  /// opens the Cash Payment Process straight away rather than waiting for the
  /// Pay button.
  void selectMethod(PaymentMethod method) {
    selectedMethod.value = method;
    if (method == PaymentMethod.cashOnLocation) _openCashPayment();
  }

  void _openCashPayment() =>
      Get.toNamed<void>(AppRoutes.howToPay, arguments: breakdown.payableLabel);

  void toggleWallet(bool value) => useWallet.value = value;

  /// Document capture needs a platform picker; until one is wired the tiles
  /// record the intent so the flow stays walkable.
  void addAttachment() {
    attachments.add('document_${attachments.length + 1}.pdf');
    AppSnackbar.success(AppStrings.attachmentAdded.tr);
  }

  void captureFromCamera() {
    attachments.add('photo_${attachments.length + 1}.jpg');
    AppSnackbar.success(AppStrings.attachmentAdded.tr);
  }

  void removeAttachment(String name) => attachments.remove(name);

  Future<void> pay() async {
    // Cash is settled at an agent, not here.
    if (selectedMethod.value == PaymentMethod.cashOnLocation) {
      _openCashPayment();
      return;
    }

    final ok = await submit(() async {
      // Stands in for the payment-gateway round trip.
      await Future<void>.delayed(const Duration(milliseconds: 900));
    });

    if (ok) Get.offNamed<void>(AppRoutes.appointmentBooked);
  }
}
