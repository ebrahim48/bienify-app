// How It Works, the page read on the way *into* applying to ride.
//
// Its masthead used to be fed by the courier dashboard's controller, which
// asks the server for the signed-in courier. Nobody reading this page is one
// yet: the server guards the whole `/riders` namespace on the `rider` role,
// so opening it as a patient sent `GET /riders/me` and took back
// `403 FORBIDDEN — Insufficient permissions`, leaving the masthead blank
// above an invitation to apply.
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/repositories/account_repository.dart';
import 'package:bienify_app/features/Role/rider_role/domain/repositories/rider_repository.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/bindings/rider_bindings.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// The account behind whoever is reading the page.
class _FakeAccountRepository implements AccountRepository {
  @override
  Future<PatientProfile> me() async =>
      const PatientProfile(name: 'Amina Diallo', maskedPhone: '+880 189* ****');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not part of this');
}

/// Stands in for the server's role guard: every courier endpoint is a 403 to
/// someone who is not a courier. A screen that touches it fails here the way
/// it failed on the device.
class _ForbiddenRiderRepository implements RiderRepository {
  bool wasCalled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    wasCalled = true;
    throw ForbiddenException('Insufficient permissions');
  }
}

void main() {
  late _ForbiddenRiderRepository riders;

  setUp(() {
    Get.testMode = true;
    riders = _ForbiddenRiderRepository();
    Get
      ..put<AccountRepository>(_FakeAccountRepository())
      ..put<RiderRepository>(riders);
  });

  tearDown(Get.reset);

  Future<void> pumpGuide(WidgetTester tester) async {
    RiderGuideBinding().dependencies();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (context, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const RiderGuideScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names the signed-in account above the invitation to apply', (
    tester,
  ) async {
    await pumpGuide(tester);

    expect(find.text('Amina Diallo'), findsOneWidget);
    expect(find.text('Apply Rider?'), findsOneWidget);
  });

  testWidgets('asks the server for no courier the reader has not become', (
    tester,
  ) async {
    await pumpGuide(tester);

    expect(riders.wasCalled, isFalse);
  });
}
