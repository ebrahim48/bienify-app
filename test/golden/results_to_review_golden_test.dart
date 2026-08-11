import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/test_request.dart';
import 'package:bienify_app/features/Role/doctor_role/data/static/doctor_orders_data.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/bindings/doctor_bindings.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/results_to_review_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/test_request_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/choose_review_option_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/order_detail_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/request_follow_up_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/request_test_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/results_to_review_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/review_message_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/review_patient_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/widgets/choose_order_sheet.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/widgets/signature_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the practitioner's Results to Review flow.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(useMocks: true);
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Bindings? binding,
    Object? arguments,
    Size size = const Size(390, 876),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: '/target',
              page: () => screen,
              binding: binding,
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    Get.toNamed<void>('/target', arguments: arguments);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('Patients segment', (tester) async {
    await pump(
      tester,
      const ResultsToReviewScreen(),
      binding: ResultsToReviewBinding(),
    );

    final controller = Get.find<ResultsToReviewController>();
    expect(controller.visiblePatients.length, 3);
    // The segments are captioned "Orders" while the roster is showing.
    expect(find.text('Lab Orders'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ResultsToReviewScreen),
      matchesGoldenFile('results_to_review_patients.png'),
    );

    // The search box is what the field is for.
    controller.query.value = 'nobody';
    await tester.pump();
    expect(controller.visiblePatients, isEmpty);
  });

  testWidgets('Lab Requests segment, then its filters', (tester) async {
    await pump(
      tester,
      const ResultsToReviewScreen(),
      binding: ResultsToReviewBinding(),
    );

    final controller = Get.find<ResultsToReviewController>()
      ..selectTab(ResultsTab.labRequests);
    await tester.pumpAndSettle();

    // Selecting the segment re-captions it, which is how the designs differ.
    expect(find.text('Lab Requests'), findsOneWidget);
    expect(controller.visibleRequests.length, 3);
    expect(find.text('Critical'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ResultsToReviewScreen),
      matchesGoldenFile('results_to_review_lab.png'),
    );

    controller.selectFilter(RequestFilter.toReview);
    await tester.pump();
    expect(
      controller.visibleRequests.single.status,
      RequestStatus.awaitingReview,
    );

    controller.selectFilter(RequestFilter.inProgress);
    await tester.pump();
    expect(controller.visibleRequests.single.status, RequestStatus.requestSent);
  });

  testWidgets('Patient, then the Choose Order sheet', (tester) async {
    await pump(
      tester,
      const ReviewPatientScreen(),
      binding: ResultsToReviewBinding(),
    );
    Get.find<ResultsToReviewController>().patient.value =
        DoctorOrdersData.patients.first;
    await tester.pumpAndSettle();

    expect(find.text('34 • Female'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(ReviewPatientScreen),
      matchesGoldenFile('review_patient.png'),
    );

    await tester.tap(find.text('Request Test'));
    await tester.pumpAndSettle();
    expect(find.byType(ChooseOrderSheet), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('choose_order_sheet.png'),
    );
  });

  testWidgets('Request lab Test, all three steps', (tester) async {
    Get.put(ResultsToReviewController()).patient.value =
        DoctorOrdersData.patients.first;
    await pump(
      tester,
      const RequestTestScreen(),
      binding: TestRequestBinding(),
      arguments: OrderKind.lab,
    );

    final controller = Get.find<TestRequestController>();
    // Nothing is chosen yet, so Next is dead.
    expect(controller.canContinue, isFalse);

    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_lab_test_select.png'),
    );

    controller.selectTest('Lipid Profile');
    await tester.pump();
    expect(controller.canContinue, isTrue);

    controller.next();
    await tester.pumpAndSettle();
    expect(controller.step.value, 1);
    expect(find.text('Clinical notes'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_lab_test_notes.png'),
    );

    controller.next();
    await tester.pumpAndSettle();
    expect(controller.step.value, 2);
    expect(find.text('Submit imaging Order'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_lab_test_priority.png'),
    );

    // The chevron walks back through the wizard rather than leaving it.
    expect(controller.stepBack(), isTrue);
    expect(controller.step.value, 1);
  });

  testWidgets('The signature pad takes a real signature', (tester) async {
    Get.put(ResultsToReviewController()).patient.value =
        DoctorOrdersData.patients.first;
    await pump(
      tester,
      const RequestTestScreen(),
      binding: TestRequestBinding(),
      arguments: OrderKind.lab,
    );

    final controller = Get.find<TestRequestController>()
      ..selectTest('Lipid Profile')
      ..next();
    await tester.pumpAndSettle();
    expect(controller.hasSignature.value, isFalse);

    // Drag across the pad the way a finger would.
    final pad = find.byType(SignaturePad);
    final origin = tester.getCenter(pad);
    final gesture = await tester.startGesture(origin - const Offset(60, 6));
    await gesture.moveBy(const Offset(30, 12));
    await gesture.moveBy(const Offset(30, -18));
    await gesture.moveBy(const Offset(30, 10));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.hasSignature.value, isTrue);
    expect(tester.state<SignaturePadState>(pad).isEmpty, isFalse);
    // The hint gives way to the ink.
    expect(find.text('dr.deep'), findsNothing);

    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_lab_test_signed.png'),
    );

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(controller.hasSignature.value, isFalse);
    expect(find.text('dr.deep'), findsOneWidget);

    // Saving an empty pad says so rather than filing a blank signature.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('Request Radiology Test picks a study, then a subtest', (
    tester,
  ) async {
    Get.put(ResultsToReviewController()).patient.value =
        DoctorOrdersData.patients.first;
    await pump(
      tester,
      const RequestTestScreen(),
      binding: TestRequestBinding(),
      arguments: OrderKind.radiology,
    );

    final controller = Get.find<TestRequestController>();
    expect(controller.isRadiology, isTrue);
    expect(find.text('Study'), findsOneWidget);

    controller.selectTest('CT Scan (Computed Tomography)');
    await tester.pump();
    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_radiology_study.png'),
    );

    controller.next();
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    // Imaging will not move on without a subtest.
    expect(controller.canContinue, isFalse);

    controller.selectSubtest('CT Scan (Computed Tomography)');
    await tester.pump();
    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_radiology_subtest.png'),
    );

    controller.next();
    await tester.pumpAndSettle();
    expect(find.text('Review and Submit'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RequestTestScreen),
      matchesGoldenFile('request_radiology_review.png'),
    );
  });

  testWidgets('Order detail before and after results', (tester) async {
    await pump(
      tester,
      const OrderDetailScreen(),
      binding: ResultsToReviewBinding(),
    );

    final controller = Get.find<ResultsToReviewController>();

    // The order nobody has been to yet: the tracker sits on step one and the
    // page says it is waiting.
    controller.request.value = DoctorOrdersData.requests[1];
    await tester.pumpAndSettle();
    expect(find.text('Awaiting patient upload'), findsOneWidget);
    expect(find.text('Choose Your Review'), findsNothing);

    await settleImages(tester);
    await expectLater(
      find.byType(OrderDetailScreen),
      matchesGoldenFile('order_detail_awaiting.png'),
    );

    // With results in, the hospital, notes and report appear.
    controller.request.value = DoctorOrdersData.requests.first;
    await tester.pumpAndSettle();
    expect(find.text('Uploaded documents'), findsOneWidget);
    expect(find.text('Choose Your Review'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(OrderDetailScreen),
      matchesGoldenFile('order_detail_results.png'),
    );
  });

  testWidgets('Choose review Option', (tester) async {
    await pump(
      tester,
      const ChooseReviewOptionScreen(),
      binding: ResultsToReviewBinding(),
    );

    final controller = Get.find<ResultsToReviewController>();
    expect(controller.reviewOption.value, ReviewOption.messagePatient);

    await settleImages(tester);
    await expectLater(
      find.byType(ChooseReviewOptionScreen),
      matchesGoldenFile('choose_review_option.png'),
    );

    controller.selectReviewOption(ReviewOption.refer);
    await tester.pump();
    expect(controller.reviewOption.value, ReviewOption.refer);
  });

  testWidgets('Write Message and Refer/Escalation are one screen', (
    tester,
  ) async {
    await pump(
      tester,
      const ReviewMessageScreen(),
      binding: ResultsToReviewBinding(),
      arguments: ReviewOption.messagePatient,
    );
    expect(find.text('Write your Message'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ReviewMessageScreen),
      matchesGoldenFile('review_write_message.png'),
    );
  });

  testWidgets('Refer/Escalation', (tester) async {
    await pump(
      tester,
      const ReviewMessageScreen(),
      binding: ResultsToReviewBinding(),
      arguments: ReviewOption.refer,
    );
    expect(find.text('Write your option'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ReviewMessageScreen),
      matchesGoldenFile('review_refer_escalation.png'),
    );
  });

  testWidgets('Request Follow UP', (tester) async {
    await pump(tester, const RequestFollowUpScreen());

    await settleImages(tester);
    await expectLater(
      find.byType(RequestFollowUpScreen),
      matchesGoldenFile('review_request_follow_up.png'),
    );
  });

  testWidgets('Order Additional Test reuses the patient screen', (
    tester,
  ) async {
    await pump(
      tester,
      const ReviewPatientScreen(),
      binding: ResultsToReviewBinding(),
      arguments: ReviewOption.additionalTest,
    );
    Get.find<ResultsToReviewController>().patient.value =
        DoctorOrdersData.patients.first;
    await tester.pumpAndSettle();

    // Titled by the action rather than the patient, and no age line.
    expect(find.text('Order Additional Test'), findsOneWidget);
    expect(find.text('34 • Female'), findsNothing);

    await settleImages(tester);
    await expectLater(
      find.byType(ReviewPatientScreen),
      matchesGoldenFile('order_additional_test.png'),
    );
  });
}
