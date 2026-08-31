import 'dart:io';

import 'package:get/get.dart';

import '../constants/api_constants.dart';
import '../exceptions/app_exceptions.dart';
import '../network/api_client.dart';

/// Where a push token comes from.
///
/// An interface rather than a direct FCM call so the registration flow below
/// is complete and testable now, and so the one part that needs Firebase
/// project files is a single named seam instead of being spread through the
/// session lifecycle.
abstract class PushTokenSource {
  /// The device's current token, or null when push is unavailable — no
  /// Firebase configuration, permission refused, or a platform without it.
  Future<String?> token();
}

/// The stand-in used until Firebase is configured.
///
/// It returns null, so registration is skipped entirely: nothing is sent, and
/// no device is recorded that could never be delivered to. Swap this for an
/// FCM-backed source once `google-services.json` and `GoogleService-Info.plist`
/// are in the project — nothing else here changes.
class UnavailablePushTokenSource implements PushTokenSource {
  @override
  Future<String?> token() async => null;
}

/// Tells the platform which device to push to, and stops telling it on
/// sign-out.
///
/// The notification list was pull-to-refresh only: nothing woke the app for an
/// appointment reminder, an order moving or a message. The server can now
/// address a device; this is the half that gives it the address.
class PushRegistrationService {
  PushRegistrationService({ApiClient? api, PushTokenSource? source})
    : _api = api ?? Get.find<ApiClient>(),
      _source = source ?? UnavailablePushTokenSource();

  final ApiClient _api;
  final PushTokenSource _source;

  /// The token this session registered, so sign-out can withdraw exactly it
  /// rather than guessing.
  String? _registered;

  /// Registers the device against the signed-in account.
  ///
  /// Failures are swallowed: a patient who cannot be pushed to must still be
  /// able to use the app, and the in-app list works regardless.
  Future<void> register() async {
    final token = await _source.token();
    if (token == null || token.isEmpty) return;

    try {
      await _api.post(
        ApiConstants.postNotificationsDevices,
        body: {'token': token, 'platform': _platform},
      );
      _registered = token;
    } on AppException {
      // Nothing to tell the patient: they did not ask for this, and the app
      // works without it.
    }
  }

  /// Withdraws the device on sign-out.
  ///
  /// Without it the next person to use the phone receives the previous
  /// account's reminders — which on a telemedicine platform means their
  /// appointments and their prescriptions.
  Future<void> unregister() async {
    final token = _registered;
    if (token == null) return;
    _registered = null;

    try {
      await _api.delete(ApiConstants.deleteNotificationsDevices(token));
    } on AppException {
      // The server drops a token it cannot deliver to anyway, and the session
      // is ending either way.
    }
  }

  /// What the server records the device as.
  String get _platform => Platform.isIOS ? 'ios' : 'android';
}
