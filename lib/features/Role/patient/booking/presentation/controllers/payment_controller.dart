import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../domain/entities/payment_method.dart';

/// Backs the Payment Summary screen.
///
/// Holds the draft appointment carried over from Doctor Details, the wallet
/// toggle, the chosen method and any attached documents.
class PaymentController extends GetxController with SubmissionMixin {
  PaymentController({
    required this.appointment,
    AppointmentRepository? appointments,
    WalletRepository? wallets,
  }) : _appointments = appointments ?? Get.find<AppointmentRepository>(),
       _wallets = wallets ?? Get.find<WalletRepository>();

  final Appointment appointment;
  final AppointmentRepository _appointments;
  final WalletRepository _wallets;

  /// Balance available to offset the total.
  ///
  /// Loaded rather than assumed: paying draws on the real wallet, so a figure
  /// that is not the patient's actual balance promises a deduction the server
  /// will refuse.
  final Rx<Wallet> wallet = const Wallet(balance: 0).obs;

  @override
  void onInit() {
    super.onInit();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      wallet.value = Wallet(balance: await _wallets.balance());
    } on AppException {
      // A wallet that will not load should not block the screen — the other
      // methods still work and the offset simply shows nothing.
      wallet.value = const Wallet(balance: 0);
    }
  }

  final Rx<PaymentMethod> selectedMethod = PaymentMethod.debitCredit.obs;
  final RxBool useWallet = true.obs;

  /// File names of documents the patient attached, shown under the tiles.
  final RxList<String> attachments = <String>[].obs;

  PaymentBreakdown get breakdown => PaymentBreakdown(
    consultationFee: _fee,
    // Never offset more than the consultation costs — a wallet richer than the
    // fee would otherwise show a negative amount payable.
    walletDeduction: useWallet.value
        ? (wallet.value.balance <= _fee ? wallet.value.balance : _fee)
        : 0,
  );

  /// What the server quoted for this appointment, rather than a figure the
  /// client worked out for itself.
  double get _fee => appointment.consultationFee;

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

    final ok = await submit(() => _appointments.pay(appointment.id));

    if (ok) Get.offNamed<void>(AppRoutes.appointmentBooked);
  }
}
