import 'dart:io';

import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/document_picker_service.dart';
import '../../../../../../core/services/photo_picker_service.dart';
import '../../../../../../core/utils/mime_type.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../../medical_vault/domain/entities/medical_record.dart';
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
    PhotoPickerService? photoPicker,
    DocumentPickerService? documentPicker,
  }) : _appointments = appointments ?? Get.find<AppointmentRepository>(),
       _wallets = wallets ?? Get.find<WalletRepository>(),
       _vault = vault ?? Get.find<VaultRepository>(),
       _photoPicker = photoPicker ?? PhotoPickerService(),
       _documentPicker = documentPicker ?? DocumentPickerService();

  final Appointment appointment;
  final AppointmentRepository _appointments;
  final WalletRepository _wallets;
  final VaultRepository _vault;
  final PhotoPickerService _photoPicker;
  final DocumentPickerService _documentPicker;

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

  final RxBool isUploadingAttachment = false.obs;

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

  Future<void> addAttachment() async {
    final file = await _documentPicker.pick();
    if (file != null) await _upload(file);
  }

  Future<void> captureFromCamera() async {
    final file = await _photoPicker.pick(PhotoSource.camera);
    if (file != null) await _upload(file);
  }

  /// Stores the picked file in the patient's medical vault — the same
  /// upload every other document screen uses — and shows it under the
  /// tiles once it lands.
  Future<void> _upload(File file) async {
    if (isUploadingAttachment.value) return;

    isUploadingAttachment.value = true;
    try {
      final fileName = file.path.split('/').last;
      final document = await _vault.uploadDocument(
        bytes: await file.readAsBytes(),
        fileName: fileName,
        contentType: contentTypeForPath(fileName),
        title: 'Appointment document — $fileName',
        type: VaultRecordType.other,
      );
      attachments.add(document.fileName);
      AppSnackbar.success(AppStrings.attachmentAdded.tr);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    } finally {
      isUploadingAttachment.value = false;
    }
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
