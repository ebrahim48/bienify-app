import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../appointments/presentation/controllers/appointments_controller.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../medical_vault/domain/repositories/vault_repository.dart';
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
    VaultRepository? vault,
    AttachmentPickerService? picker,
  }) : _appointments = appointments ?? Get.find<AppointmentRepository>(),
       _wallets = wallets ?? Get.find<WalletRepository>(),
       _vault = vault ?? Get.find<VaultRepository>(),
       _picker = picker ?? Get.find<AttachmentPickerService>();

  final Appointment appointment;
  final AppointmentRepository _appointments;
  final WalletRepository _wallets;
  final VaultRepository _vault;
  final AttachmentPickerService _picker;

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

  /// Hands the cash flow the amount itself, not `payableLabel` — that label is
  /// rounded to whole units for display, so passing it charged $75 for a $74.89
  /// consultation.
  void _openCashPayment() =>
      Get.toNamed<void>(AppRoutes.howToPay, arguments: breakdown.payable);

  void toggleWallet(bool value) => useWallet.value = value;

  /// True while a document is being stored.
  final RxBool isAttaching = false.obs;

  /// Vault record ids for what has been attached, so a removal can revoke the
  /// doctor's access rather than only hiding the row.
  final Map<String, String> _recordIds = {};

  Future<void> addAttachment() => _attach(AttachmentSource.document);

  Future<void> captureFromCamera() => _attach(AttachmentSource.camera);

  /// Picks a document, files it in the patient's vault and shares it with the
  /// consulting doctor.
  ///
  /// Both tiles used to append a made-up filename — `document_1.pdf`,
  /// `photo_1.jpg` — and show a success message. Nothing was picked, nothing
  /// was stored, and the doctor received nothing. Sharing is the point of
  /// attaching a document at booking, so the upload is only half the job.
  Future<void> _attach(AttachmentSource source) async {
    if (isAttaching.value) return;

    isAttaching.value = true;
    try {
      final picked = await _picker.pick(source);
      if (picked == null) return;

      final record = await _vault.uploadDocument(
        path: picked.file.path,
        fileName: picked.name,
        mimeType: picked.mime,
        type: VaultRecordType.other,
      );

      // Sharing is per-record and per-doctor. An appointment whose payload
      // carried only the doctor's profile has no user to share with; the
      // document is still stored, and saying so is better than failing the
      // whole attachment.
      if (appointment.doctorUserId.isNotEmpty) {
        await _vault.shareRecord(
          recordId: record.id,
          doctorUserId: appointment.doctorUserId,
        );
      }

      _recordIds[picked.name] = record.id;
      attachments.add(picked.name);
      AppSnackbar.success(AppStrings.attachmentAdded.tr);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isAttaching.value = false;
    }
  }

  /// Removes a document from the list and takes the doctor's access back.
  Future<void> removeAttachment(String name) async {
    final recordId = _recordIds.remove(name);
    attachments.remove(name);

    if (recordId == null || appointment.doctorUserId.isEmpty) return;
    try {
      await _vault.revokeShare(
        recordId: recordId,
        doctorUserId: appointment.doctorUserId,
      );
    } on AppException {
      // The row is already gone from the patient's view. A failed revoke is
      // worth retrying on the vault screen, not worth blocking a payment for.
    }
  }

  Future<void> pay() async {
    // Cash is settled at an agent, not here.
    if (selectedMethod.value == PaymentMethod.cashOnLocation) {
      _openCashPayment();
      return;
    }

    final ok = await submit(() => _appointments.pay(appointment.id));

    if (!ok) return;

    // The Appointments tab keeps one `AppointmentsController` alive for the
    // whole signed-in session (`Get.put`, not `fenix`), so its list is
    // whatever `load()` fetched once at startup. Without this, a booking
    // paid for here — via "Pay Now" on an appointment that started out
    // pending — kept showing "Pay Now" after paying, because the row in
    // memory never learned the server had moved it to `confirmed`. Tapping
    // it again resent the same payment, which the server correctly refused
    // with a transition error: `confirmed` cannot become `confirmed`.
    if (Get.isRegistered<AppointmentsController>()) {
      unawaited(Get.find<AppointmentsController>().load());
    }

    Get.offNamed<void>(AppRoutes.appointmentBooked);
  }
}
