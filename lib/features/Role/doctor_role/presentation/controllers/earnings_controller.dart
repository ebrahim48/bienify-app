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

  /// Files a withdrawal against the selected payout account.
  ///
  /// Both halves are checked here rather than left to the server: an amount
  /// that will not parse and a missing account both come back as the same
  /// validation error, which would tell the doctor nothing about which to fix.
  Future<void> requestPayout() async {
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

    try {
      await _repository.requestWithdrawal(
        amount: value,
        payoutAccountId: account.id,
      );
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    }

    AppSnackbar.success(AppStrings.payoutRequested.tr);
    amount.value = '';
    Get.back<void>();
    // The balance moves into `pendingWithdrawal` the moment the request lands,
    // so the totals above the list are re-read rather than left stale.
    await load();
  }
}
