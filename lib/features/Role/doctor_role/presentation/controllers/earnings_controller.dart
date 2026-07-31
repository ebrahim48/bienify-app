import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';

/// Backs Earning Withdraw and the payout request over it.
///
/// UI-only — the balances are static and nothing is transferred.
class EarningsController extends GetxController {
  final RxList<ConsultationEarning> earnings = <ConsultationEarning>[].obs;

  /// Which payout method the request dialog has selected.
  final RxInt selectedMethodIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    earnings.value = DoctorPracticeData.earnings();
  }

  String get availableBalance => DoctorPracticeData.availableBalanceLabel;

  String get totalEarned => DoctorPracticeData.totalEarnedLabel;

  String get paidOut => DoctorPracticeData.paidOutLabel;

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

  /// UI-only: the transfer is a marked seam, so this acknowledges the request
  /// and closes the dialog.
  void requestPayout() {
    AppSnackbar.success(AppStrings.payoutRequested.tr);
    Get.back<void>();
  }
}
