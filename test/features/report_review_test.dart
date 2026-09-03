import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/controllers/test_results_controller.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/report_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What a patient is shown once their doctor has reviewed a result.
///
/// The screen used to draw the doctor's outcome as an empty box for the
/// patient to write back into. Nothing read what they typed — there is no
/// patient-reply endpoint on a lab order — and the message the doctor had
/// actually sent was not on the screen at all. So a reviewed result reached
/// the patient as a reply box addressed to nobody, above no message.
void main() {
  setUp(() async {
    // The controller reaches for several services through `Get.find`, so the
    // whole mock graph is stood up rather than guessing at which ones.
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(useMocks: true);
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  TestOrder order({String? reviewMessage}) => TestOrder(
    id: 'order-1',
    discipline: ResultDiscipline.laboratory,
    category: 'Diagnostics',
    priority: 'routine',
    title: 'Complete Blood Count',
    orderedBy: 'Dr Dana Okafor',
    stage: TestStage.reviewed,
    reviewMessage: reviewMessage,
  );

  Future<TestResultsController> pump(
    WidgetTester tester, {
    required ReviewOutcome outcome,
    String? reviewMessage,
  }) async {
    // The screen sizes itself against the design canvas; the default 800x600
    // surface overflows it, which is the viewport's fault and not the widget's.
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = Get.put(TestResultsController());
    controller
      ..selected.value = order(reviewMessage: reviewMessage)
      ..hasDocument.value = true
      ..outcome.value = outcome;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (context, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const ReportReviewScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('shows what the doctor wrote', (tester) async {
    await pump(
      tester,
      outcome: ReviewOutcome.messaged,
      reviewMessage: 'Bloods are normal. No action needed.',
    );

    // The server sends this and the app already parsed it into
    // `reviewMessage`; no screen read it, so the patient saw an empty box
    // where their doctor's answer should have been.
    expect(find.text('Bloods are normal. No action needed.'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('offers nothing to type into', (tester) async {
    await pump(
      tester,
      outcome: ReviewOutcome.messaged,
      reviewMessage: 'Bloods are normal. No action needed.',
    );

    // A lab order has no patient-reply endpoint and carries no consultation to
    // send into, so a box here collects a reply the doctor can never receive.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('carries a referral in the doctor\'s own words', (tester) async {
    await pump(
      tester,
      outcome: ReviewOutcome.referred,
      reviewMessage: 'Referring you to cardiology.',
    );

    expect(find.text('Referring you to cardiology.'), findsOneWidget);
    expect(find.text('Refer & Escalation'), findsOneWidget);
  });

  testWidgets('only an offer to talk says the doctor wants to talk', (
    tester,
  ) async {
    await pump(
      tester,
      outcome: ReviewOutcome.messaged,
      reviewMessage: 'Bloods are normal.',
    );

    // The panel used to be drawn for every reviewed order, so a doctor who had
    // written a note appeared to be asking for a call they never asked for.
    expect(find.text('Accept follow-up'), findsNothing);
    expect(find.textContaining('Talk to you'), findsNothing);

    await pump(tester, outcome: ReviewOutcome.followUpOffered);
    expect(find.text('Accept follow-up'), findsOneWidget);
  });

  testWidgets('does not print the honorific twice', (tester) async {
    await pump(tester, outcome: ReviewOutcome.followUpOffered);

    // The copy already says "Doctor", and the old strip matched `Dr. ` only —
    // with the dot — while every name the server sends is `Dr Dana Okafor`.
    expect(find.textContaining('Doctor Dr'), findsNothing);
    expect(find.textContaining('Dana Okafor'), findsOneWidget);
  });

  test('takes the honorific off a name however it is written', () {
    expect(withoutHonorific('Dr Dana Okafor'), 'Dana Okafor');
    expect(withoutHonorific('Dr. Dana Okafor'), 'Dana Okafor');
    expect(withoutHonorific('Doctor Dana Okafor'), 'Dana Okafor');
    expect(withoutHonorific('Dana Okafor'), 'Dana Okafor');
  });
}
