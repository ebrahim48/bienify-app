// What Change Password actually changes.
//
// The form used to `await Future.delayed(600ms)` and report success. Every
// piece around it existed — `POST /auth/password/change` is implemented and
// routed, the app had a path constant and an API wrapper — and nothing called
// any of it. A patient reacting to a suspected compromise was told their
// password had changed when it had not, which is why these tests assert on
// what reached the repository rather than on what the screen said.
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/repositories/auth_repository.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/usecases/email_auth_usecases.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/usecases/password_recovery_usecases.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/change_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Records what was asked of the account, and can refuse the way the server
/// refuses a wrong current password.
class _FakeAuthRepository implements AuthRepository {
  final List<Map<String, String>> changes = <Map<String, String>>[];
  int logouts = 0;

  /// Set to make `changePassword` answer the way the live server does when the
  /// current password does not match (401).
  bool rejectCurrent = false;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (rejectCurrent) {
      throw UnauthorizedException('Current password is incorrect');
    }
    changes.add({'current': currentPassword, 'new': newPassword});
  }

  @override
  Future<void> logout() async => logouts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeAuthRepository auth;
  late ChangePasswordController controller;

  setUp(() {
    auth = _FakeAuthRepository();
    controller = ChangePasswordController(
      changePassword: ChangePassword(auth),
      logout: Logout(auth),
    );
  });

  tearDown(Get.reset);

  /// The controller reports through `AppSnackbar` and finishes by resetting the
  /// stack, both of which need a navigator to attach to.
  Future<List<String>> mountApp(WidgetTester tester) async {
    final visited = <String>[];
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          GetPage(
            name: AppRoutes.login,
            page: () {
              visited.add(AppRoutes.login);
              return const Scaffold();
            },
            transition: Transition.noTransition,
          ),
        ],
      ),
    );
    await tester.pump();
    return visited;
  }

  void fillIn({
    String current = 'OldPassword1!',
    String replacement = 'NewPassword1!',
    String? confirmation,
  }) {
    controller.oldPassword.value = current;
    controller.newPassword.value = replacement;
    controller.confirmPassword.value = confirmation ?? replacement;
  }

  testWidgets('sends the typed passwords to the server', (tester) async {
    await mountApp(tester);
    fillIn();

    await controller.changePassword();
    await tester.pumpAndSettle();

    expect(auth.changes, hasLength(1));
    expect(auth.changes.single['current'], 'OldPassword1!');
    expect(auth.changes.single['new'], 'NewPassword1!');
  });

  testWidgets('signs out and returns to login once it lands', (tester) async {
    // The server revokes every refresh session on a password change, this
    // device's included, so staying signed in here means holding a session
    // that is already dead.
    final visited = await mountApp(tester);
    fillIn();

    await controller.changePassword();
    await tester.pumpAndSettle();

    expect(auth.logouts, 1);
    expect(visited, contains(AppRoutes.login));
  });

  testWidgets('a wrong current password is reported on that field', (
    tester,
  ) async {
    await mountApp(tester);
    auth.rejectCurrent = true;
    fillIn();

    await controller.changePassword();
    await tester.pumpAndSettle();

    expect(
      controller.errorOf(ChangePasswordController.oldPasswordField),
      isNotNull,
    );
    // And the patient stays where they are: nothing changed, so signing them
    // out would cost them their session for no reason.
    expect(auth.logouts, 0);
  });

  testWidgets('a form that does not validate sends nothing', (tester) async {
    await mountApp(tester);
    fillIn(confirmation: 'DifferentPassword1!');

    await controller.changePassword();
    await tester.pumpAndSettle();

    expect(auth.changes, isEmpty);
    expect(auth.logouts, 0);
  });
}
