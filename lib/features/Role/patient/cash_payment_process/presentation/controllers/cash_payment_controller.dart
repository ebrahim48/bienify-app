import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/cash_payment_data.dart';
import '../../domain/entities/cash_payment.dart';
import '../../domain/repositories/cash_payment_repository.dart';

/// Shared state for the whole cash-payment journey.
///
/// One controller spans "How it works" → "Nearby points" → "Pending" because
/// all three read the same code and countdown; keeping them in sync through
/// three separate controllers would mean three timers.
///
/// A code belongs to a counter — `POST /cash-intents` will not issue one
/// without a `paymentPointId` — so the flow opens by issuing against the
/// nearest point. Choosing a different one on the Nearby screen re-issues.
class CashPaymentController extends GetxController {
  CashPaymentController({
    this.amount = 74.89,
    PaymentCode? code,
    CashPaymentRepository? repository,
  }) : _repository = repository ?? Get.find<CashPaymentRepository>(),
       _seeded = code;

  final CashPaymentRepository _repository;

  /// What the patient is paying, as a number.
  ///
  /// This used to arrive as the caller's formatted label and be parsed back
  /// into a number here, which lost money twice over: `payableLabel` rounds to
  /// whole units, so a $74.89 consultation issued a code for $75; and stripping
  /// non-digits reads a comma decimal separator as a thousands group, turning
  /// `74,89` into 7489. The amount now travels as the value it is, and the
  /// label is derived from it rather than the other way round.
  final double amount;

  /// The amount as the screens print it, to the cent.
  String get amountLabel => '\$${amount.toStringAsFixed(2)}';

  /// A code supplied by the caller instead of issued.
  ///
  /// Goldens pass one: the real expiry is 24h from `DateTime.now()`, so the
  /// rendered countdown differs run to run and no golden could ever match.
  final PaymentCode? _seeded;

  /// The issued code. Null until the server has given one out — the screens
  /// show the design's placeholder until then.
  final Rxn<PaymentCode> issued = Rxn<PaymentCode>();

  /// The placeholder the design draws, used until [issued] lands so no screen
  /// has to handle a null code.
  late final PaymentCode _placeholder = CashPaymentData.code(
    amountLabel: amountLabel,
  );

  PaymentCode get code => issued.value ?? _placeholder;

  final RxBool isLoading = true.obs;
  final RxBool isChecking = false.obs;
  final RxnString error = RxnString();

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
    if (_seeded != null) {
      issued.value = _seeded;
      isLoading.value = false;
      _resetCountdown();
      return;
    }
    _resetCountdown();
    load();
  }

  @override
  void onClose() {
    _countdown?.cancel();
    _copyReset?.cancel();
    super.onClose();
  }

  /// Issues a code at [paymentPointId], or at the nearest point when none is
  /// named — which is what opening the flow does.
  Future<void> load({String? paymentPointId}) async {
    isLoading.value = true;
    error.value = null;
    try {
      final id = paymentPointId ?? await _nearestPointId();
      if (id == null) {
        error.value = AppStrings.noPaymentPointsNearby.tr;
        return;
      }
      issued.value = await _repository.issueCode(
        paymentPointId: id,
        amount: amount,
      );
      _resetCountdown();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _nearestPointId() async {
    final points = await _repository.points();
    return points.isEmpty ? null : points.first.id;
  }

  void _resetCountdown() {
    secondsRemaining.value = code.expiresAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, 24 * 3600);
    _startCountdown();
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
  void confirmLocationChosen() => Get.offNamed<void>(AppRoutes.paymentPending);

  /// Asks the server whether an agent has taken the cash.
  ///
  /// Only a confirmed intent moves on. Navigating regardless would show the
  /// patient a receipt for money nobody has handed over — and `offNamed` means
  /// Back could not take them out of it again.
  Future<void> checkStatus() async {
    if (isChecking.value) return;
    isChecking.value = true;

    final CashIntentState state;
    try {
      state = await _repository.refresh(code.code);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
      return;
    } finally {
      isChecking.value = false;
    }

    switch (state) {
      case CashIntentState.confirmed:
        // `offNamed` so Back cannot return to a pending state that is over.
        Get.offNamed<void>(AppRoutes.paymentConfirmed);
      case CashIntentState.pending:
        AppSnackbar.info(AppStrings.paymentNotReceivedYet.tr);
      case CashIntentState.expired:
      case CashIntentState.cancelled:
        AppSnackbar.error(AppStrings.paymentCodeExpired.tr);
    }
  }
}
