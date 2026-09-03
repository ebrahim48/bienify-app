import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../constants/app_strings.dart';

/// Raises an incoming consultation over whatever is on the phone.
///
/// The app already pushed a full-screen route the moment a call arrived, and
/// that is enough — as long as the app is the thing on screen. It is usually
/// not. A call arriving while the phone was in a pocket, or while its owner
/// was reading something else, pushed a screen behind the launcher: the
/// ringtone played into a UI nobody could see, and the callee learned about
/// the consultation by opening the app afterwards. Every other messaging app
/// people use rings over the lock screen, so this one has to.
///
/// A full-screen-intent notification is what asks Android for that. On a
/// locked or idle phone it takes over the screen; on an unlocked one it comes
/// down as a heads-up banner with the two buttons.
///
/// The limit worth being honest about: this needs the app's process to be
/// alive and its socket connected, because the call still arrives over the
/// socket. A phone that has killed the app hears nothing, and no amount of
/// local notification changes that — only a push does, which needs the
/// Firebase credentials this project does not have yet.
abstract class IncomingCallNotifier {
  /// Announces a call from [callerName].
  Future<void> show({required String callerName});

  /// Takes the notification down: answered, declined, or given up on.
  Future<void> dismiss();
}

/// The one that talks to Android.
class SystemIncomingCallNotifier implements IncomingCallNotifier {
  SystemIncomingCallNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// One id, reused: there is only ever one call to announce, and a second
  /// notification for the same one would be two rings to dismiss.
  static const int _notificationId = 8801;

  /// `max` importance is what earns the heads-up banner; the channel has to
  /// declare it at creation, because Android will not raise it later.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'bienify_incoming_calls',
    'Incoming consultations',
    description: 'Rings when a doctor or patient starts a video consultation.',
    importance: Importance.max,
  );

  bool _ready = false;

  /// Whether the app is the thing on screen right now.
  ///
  /// Read from the lifecycle rather than from the navigator: a route pushed
  /// while the app is backgrounded is invisible, and "is a call screen on the
  /// stack" cannot tell the difference.
  bool get _isForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _ensureReady() async {
    if (_ready) return;
    _ready = true;

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    // Asked for rather than assumed. Android 13 and later will drop every
    // notification silently if it was never granted, which would put this
    // straight back to where it started.
    await android?.requestNotificationsPermission();
  }

  @override
  Future<void> show({required String callerName}) async {
    // Nothing to raise when the app is already in front — the call screen is
    // there and visible, and a banner over it would only be in the way.
    if (_isForeground) return;

    await _ensureReady();
    await _plugin.show(
      _notificationId,
      callerName,
      AppStrings.incomingCallTitle.tr,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          // The three that make Android treat this as a call rather than a
          // message: a full-screen intent to take over the screen, the call
          // category for the ringer policy, and ongoing so it cannot be
          // swiped away while the phone is still ringing.
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          ongoing: true,
          autoCancel: false,
          // The app plays its own ringtone; a second one from the channel
          // would be two sounds at once.
          playSound: false,
          enableVibration: false,
        ),
      ),
    );
  }

  @override
  Future<void> dismiss() async {
    if (!_ready) return;
    await _plugin.cancel(_notificationId);
  }
}

/// Used in tests and anywhere without a platform behind it.
class SilentIncomingCallNotifier implements IncomingCallNotifier {
  @override
  Future<void> show({required String callerName}) async {}

  @override
  Future<void> dismiss() async {}
}
