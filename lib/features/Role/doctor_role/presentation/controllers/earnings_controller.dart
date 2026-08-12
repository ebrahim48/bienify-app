import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs Earning Withdraw and the payout request over it.
class EarningsController extends GetxController {
  EarningsController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  final RxList<ConsultationEarning> earnings = <ConsultationEarning>[].obs;
  final RxList<PayoutAccount> accounts = <PayoutAccount>[].obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Which payout method the request dialog has selected.
  final RxInt selectedMethodIndex = 0.obs;

  /// Guards the request button: a withdrawal that has been sent must not be
  /// sent twice while the server is still answering.
  final RxBool isRequestingPayout = false.obs;

  /// How much to withdraw, as typed. Plain string so the input owns its text
  /// controller.
  final RxString amount = ''.obs;

  final RxString availableBalance = ''.obs;
  final RxString totalEarned = ''.obs;
  final RxString paidOut = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      final summary = await _repository.earnings();
      availableBalance.value = summary.availableLabel;
      totalEarned.value = summary.totalEarnedLabel;
      paidOut.value = summary.paidOutLabel;
      earnings.value = summary.consultations;
      accounts.value = await _repository.payoutAccounts();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  String stateLabel(PayoutState state) => switch (state) {
    PayoutState.pending => AppStrings.filterPending.tr,
    PayoutState.completed => AppStrings.completed.tr,
  };

  /// `Apr 3, 2026`.
  String dateLabel(DateTime at) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[at.month - 1]} ${at.day}, ${at.year}';
  }

  void selectMethod(int index) => selectedMethodIndex.value = index;

  void setAmount(String value) => amount.value = value;

  // ─── New payout account ──────────────────────────────────────────────────
  //
  // Held as plain strings so the inputs own their text controllers, the same
  // way every other form in the app is built.

  /// `bank` or `mobile_money`, as the server names them.
  final RxString accountKind = 'bank'.obs;
  final RxString accountName = ''.obs;
  final RxString accountNumber = ''.obs;
  final RxString accountBank = ''.obs;
  final RxBool isSavingAccount = false.obs;

  void selectAccountKind(String value) => accountKind.value = value;

  void setAccountName(String value) => accountName.value = value;

  void setAccountNumber(String value) => accountNumber.value = value;

  void setAccountBank(String value) => accountBank.value = value;

  /// Files an account a payout can be paid into, then reloads the list so the
  /// request dialog can select it straight away.
  ///
  /// Returns whether it landed, so the caller knows whether to close its form.
  Future<bool> addPayoutAccount() async {
    if (isSavingAccount.value) return false;

    final name = accountName.value.trim();
    final number = accountNumber.value.trim();
    // The server takes four digits at minimum; checking here names the field
    // rather than returning a validation error about the whole body.
    if (name.isEmpty || number.length < 4) {
      AppSnackbar.info(AppStrings.payoutAccountNeedsDetails.tr);
      return false;
    }

    isSavingAccount.value = true;
    try {
      await _repository.addPayoutAccount(
        kind: accountKind.value,
        displayName: name,
        accountNumber: number,
        bankName: accountBank.value.trim(),
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return false;
    } finally {
      isSavingAccount.value = false;
    }

    accountName.value = '';
    accountNumber.value = '';
    accountBank.value = '';
    accounts.value = await _repository.payoutAccounts();
    // The new account is the one the doctor just chose to be paid into.
    selectedMethodIndex.value = accounts.length - 1;
    AppSnackbar.success(AppStrings.payoutAccountAdded.tr);
    return true;
  }

  /// Files a withdrawal against the selected payout account.
  ///
  /// Both halves are checked here rather than left to the server: an amount
  /// that will not parse and a missing account both come back as the same
  /// validation error, which would tell the doctor nothing about which to fix.
  Future<void> requestPayout() async {
    if (isRequestingPayout.value) return;

    final value = double.tryParse(amount.value.trim());
    if (value == null || value <= 0) {
      AppSnackbar.info(AppStrings.enterAValidAmount.tr);
      return;
    }
    if (accounts.isEmpty) {
      AppSnackbar.info(AppStrings.noPayoutAccount.tr);
      return;
    }

    final account =
        accounts[selectedMethodIndex.value.clamp(0, accounts.length - 1)];

    isRequestingPayout.value = true;
    try {
      await _repository.requestWithdrawal(
        amount: value,
        payoutAccountId: account.id,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isRequestingPayout.value = false;
    }

    amount.value = '';
    // Closed before the snackbar, not after: GetX shows a snackbar as a route,
    // so `Get.back()` after one pops the snackbar and leaves the dialog up —
    // which read as "nothing happened" over a withdrawal the server had taken,
    // and invited a second tap that would file it twice.
    Get.back<void>();
    AppSnackbar.success(AppStrings.payoutRequested.tr);
    // The balance moves into `pendingWithdrawal` the moment the request lands,
    // so the totals above the list are re-read rather than left stale.
    await load();
  }
}
