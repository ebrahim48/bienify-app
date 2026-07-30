import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Navigation helpers that survive tearing down the whole route stack.
class AppNavigator {
  AppNavigator._();

  /// Replaces the entire stack with [route].
  ///
  /// Use this instead of `Get.offAllNamed` directly. Clearing the stack
  /// disposes every route at once, and if any of them still holds focus — a
  /// chat composer, a search field — the `Overlay`'s inherited element is
  /// unmounted while those descendants are still registered against it, and
  /// the framework asserts `'_dependents.isEmpty': is not true`.
  ///
  /// Dropping focus first and deferring to the next frame gives Flutter one
  /// clean frame to unregister those dependents before the routes go.
  static void resetTo(String route, {dynamic arguments}) {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed<void>(route, arguments: arguments);
    });
  }
}
