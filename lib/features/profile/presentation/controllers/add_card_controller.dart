import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/base/base_controller.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../domain/entities/profile.dart';
import 'account_controller.dart';

/// Backs Add Debit Card.
///
/// UI-only — nothing is sent anywhere, and no card data is stored beyond the
/// masked tail. Values are held as plain strings so that `AppTextField` owns
/// the text controllers and disposes them with the widget.
class AddCardController extends GetxController
    with SubmissionMixin, FieldErrorMixin {
  static const String numberField = 'card_number';
  static const String holderField = 'card_holder';
  static const String expiryField = 'card_expiry';
  static const String cvvField = 'card_cvv';

  final RxString number = ''.obs;
  final RxString holder = ''.obs;
  final RxString expiry = ''.obs;
  final RxString cvv = ''.obs;

  /// Groups the digits in fours as they are typed, so the field reads like the
  /// card in the patient's hand.
  static final TextInputFormatter numberFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
        final capped = digits.length > 16 ? digits.substring(0, 16) : digits;
        final grouped = <String>[];
        for (var i = 0; i < capped.length; i += 4) {
          grouped.add(
            capped.substring(i, i + 4 > capped.length ? capped.length : i + 4),
          );
        }
        final text = grouped.join(' ');
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });

  /// Inserts the `/` after the month.
  static final TextInputFormatter expiryFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
        final capped = digits.length > 4 ? digits.substring(0, 4) : digits;
        final text = capped.length <= 2
            ? capped
            : '${capped.substring(0, 2)}/${capped.substring(2)}';
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      });

  String get _digits => number.value.replaceAll(RegExp(r'\D'), '');

  String? _validateNumber() =>
      _digits.length == 16 ? null : AppStrings.errorCardNumber.tr;

  String? _validateHolder() =>
      holder.value.trim().isEmpty ? AppStrings.errorCardHolder.tr : null;

  /// `MM/YY` with a month between 01 and 12 — the only check worth making
  /// client-side; the gateway decides whether the card is live.
  String? _validateExpiry() {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry.value);
    if (match == null) return AppStrings.errorCardExpiry.tr;
    final month = int.parse(match.group(1)!);
    if (month < 1 || month > 12) return AppStrings.errorCardExpiry.tr;
    return null;
  }

  String? _validateCvv() => RegExp(r'^\d{3}$').hasMatch(cvv.value)
      ? null
      : AppStrings.errorCardCvv.tr;

  Future<void> save() async {
    final isValid = validate({
      numberField: _validateNumber(),
      holderField: _validateHolder(),
      expiryField: _validateExpiry(),
      cvvField: _validateCvv(),
    });
    if (!isValid) return;

    final ok = await submit(() async {
      // The gateway call replaces this delay; see "Known seams".
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    if (!ok) return;

    Get.find<AccountController>().saveCard(
      WalletCard(
        id: 'card-${DateTime.now().microsecondsSinceEpoch}',
        brand: AppStrings.debitCard.tr,
        // Only the last four are kept — the full number never leaves the form.
        maskedNumber: '•••• ${_digits.substring(12)}',
        expiry: expiry.value,
      ),
    );

    // Unwinds the two steps of adding an account — the method picker and this
    // form — then shows the accounts list. `Get.until` stops at the first
    // route that is neither, so a short stack falls through to the root
    // rather than being cleared.
    Get.until(
      (route) =>
          route.settings.name != AppRoutes.addDebitCard &&
          route.settings.name != AppRoutes.paymentOptions,
    );
    Get.toNamed<void>(AppRoutes.walletAccounts);
  }
}
