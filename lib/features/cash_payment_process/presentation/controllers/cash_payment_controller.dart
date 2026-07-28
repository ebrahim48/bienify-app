import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/static/cash_payment_data.dart';
import '../../domain/entities/cash_payment.dart';

/// Shared state for the whole cash-payment journey.
///
/// One controller spans "How it works" → "Nearby points" → "Pending" because
/// all three read the same code and countdown; keeping them in sync through
/// three separate controllers would mean three timers.
///
/// **UI-only.** Nothing here calls an API — the code and countdown come from
/// [CashPaymentData]. Swapping in a repository later touches this file alone.
class CashPaymentController extends GetxController {
  CashPaymentController({String amountLabel = '\$74.89'})
    : code = CashPaymentData.code(amountLabel: amountLabel);

  final PaymentCode code;

  /// How often the pending screen says it re-checks.
  static const int autoCheckSeconds = 30;

  /// Seconds left before the code expires.
  final RxInt secondsRemaining = 0.obs;

  /// True for a few seconds after "Copy Code", which drives the success
  /// banner and the check-mark swap on the copy button.
  final RxBool justCopied = false.obs;

  Timer? _countdown;
  Timer? _copyReset;

  /// `23:55:48`.
  String get countdownLabel {
    final total = secondsRemaining.value;
    final hours = (total ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    secondsRemaining.value = code.expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 24 * 3600);
    _startCountdown();
  }

  @override
  void onClose() {
    _countdown?.cancel();
    _copyReset?.cancel();
    super.onClose();
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value <= 1) {
        secondsRemaining.value = 0;
        timer.cancel();
      } else {
        secondsRemaining.value--;
      }
    });
  }

  Future<void> copyCode() async {
    await Clipboard.setData(ClipboardData(text: code.code));
    justCopied.value = true;
    _copyReset?.cancel();
    _copyReset = Timer(const Duration(seconds: 3), () {
      justCopied.value = false;
    });
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void findPaymentLocation() => Get.toNamed<void>(AppRoutes.paymentPoints);

  void viewNearbyLocations() => Get.toNamed<void>(AppRoutes.paymentPoints);

  /// Leaving the points screen lands on the pending state.
  void confirmLocationChosen() =>
      Get.offNamed<void>(AppRoutes.paymentPending);

  /// Manual re-check.
  ///
  /// UI-only for now — it goes straight to the confirmed receipt. When the
  /// status endpoint exists, call it here and only navigate on success.
  /// `offNamed` so Back cannot return to a pending state that is over.
  void checkStatus() => Get.offNamed<void>(AppRoutes.paymentConfirmed);
}
