import 'package:get/get.dart';

import '../constants/app_strings.dart';
import '../models/country.dart';

/// Form validation shared by every auth screen.
///
/// Each method returns `null` when the value is acceptable and a *translated*
/// message otherwise, so it can be dropped straight into a `TextFormField`'s
/// `validator` or read by a controller before submitting.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  /// Minimum characters accepted for a password.
  static const int minPasswordLength = 8;

  /// Digits in a one-time passcode.
  static const int otpLength = 6;

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.errorNameRequired.tr;
    }
    return null;
  }

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return AppStrings.errorEmailRequired.tr;
    if (!_emailPattern.hasMatch(input)) return AppStrings.errorEmailInvalid.tr;
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return AppStrings.errorPasswordRequired.tr;
    if (input.length < minPasswordLength) {
      return AppStrings.errorPasswordTooShort.tr;
    }
    return null;
  }

  /// Validates [value] as a password *and* checks it matches [original].
  static String? confirmPassword(String? value, String original) {
    final error = password(value);
    if (error != null) return error;
    if (value != original) return AppStrings.errorPasswordMismatch.tr;
    return null;
  }

  /// Validates the national part of a phone number against [country]'s
  /// expected length (±1 digit, so trunk-prefix habits still pass).
  static String? phone(String? value, Country country) {
    final input = (value ?? '').replaceAll(RegExp(r'\s+'), '');
    if (input.isEmpty) return AppStrings.errorPhoneRequired.tr;
    if (!_digitsOnly.hasMatch(input)) return AppStrings.errorPhoneInvalid.tr;
    final expected = country.nationalNumberLength;
    if (input.length < expected - 1 || input.length > expected + 1) {
      return AppStrings.errorPhoneInvalid.tr;
    }
    return null;
  }

  static String? otp(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) return AppStrings.errorOtpRequired.tr;
    if (input.length != otpLength || !_digitsOnly.hasMatch(input)) {
      return AppStrings.errorOtpInvalid.tr;
    }
    return null;
  }
}
