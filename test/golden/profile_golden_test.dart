import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/bindings/medical_vault_bindings.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/controllers/test_results_controller.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/all_prescriptions_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/all_test_reports_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/health_profile_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/past_appointments_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/prescription_details_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/report_review_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/results_submitted_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/test_order_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/test_results_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/testing_centres_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/upload_report_screen.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/data/static/medical_mock_data.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/bindings/profile_bindings.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/account_controller.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/add_card_controller.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/add_card_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/become_partner_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/payment_options_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/review_shop_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/change_password_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/legal_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/order_history_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/profile_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/settings_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/wallet_accounts_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the account section and the medical vault.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init();
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

  // ─── Profile ─────────────────────────────────────────────────────────────

  testWidgets('Profile', (tester) async {
    await pump(tester, const ProfileScreen(), binding: ProfileBinding());
    await settleImages(tester);
    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('profile.png'),
    );
  });

  testWidgets('Profile fits a narrow device with enlarged text', (
    tester,
  ) async {
    // The log-out card is pinned with a `Spacer`, which needs the page to
    // fit — this is the configuration where it would not.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(
      tester,
      const ProfileScreen(),
      binding: ProfileBinding(),
      size: const Size(320, 640),
    );
    await settleImages(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Log out confirmation blurs the page', (tester) async {
    await pump(tester, const ProfileScreen(), binding: ProfileBinding());
    await settleImages(tester);

    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Ready to log out?'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('logout_dialog.png'),
    );
  });

  testWidgets('Settings', (tester) async {
    await pump(tester, const SettingsScreen(), binding: SettingsBinding());
    await settleImages(tester);
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('settings.png'),
    );
  });

  testWidgets('Change password', (tester) async {
    await pump(
      tester,
      const ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(ChangePasswordScreen),
      matchesGoldenFile('change_password.png'),
    );
  });

  testWidgets('About Us', (tester) async {
    await pump(
      tester,
      const LegalScreen(),
      arguments: LegalDocument.aboutUs,
      size: const Size(390, 900),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(LegalScreen),
      matchesGoldenFile('about_us.png'),
    );
  });

  testWidgets('Terms & Conditions', (tester) async {
    await pump(
      tester,
      const LegalScreen(),
      arguments: LegalDocument.terms,
      size: const Size(390, 1800),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(LegalScreen),
      matchesGoldenFile('terms.png'),
    );
  });

  testWidgets('Privacy Policy', (tester) async {
    await pump(
      tester,
      const LegalScreen(),
      arguments: LegalDocument.privacy,
      size: const Size(390, 1800),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(LegalScreen),
      matchesGoldenFile('privacy.png'),
    );
  });

  testWidgets('Become a Partner', (tester) async {
    await pump(
      tester,
      const BecomePartnerScreen(),
      binding: PartnerBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(BecomePartnerScreen),
      matchesGoldenFile('become_partner.png'),
    );
  });

  testWidgets('Order history', (tester) async {
    await pump(
      tester,
      const OrderHistoryScreen(),
      binding: AccountBinding(),
      size: const Size(390, 950),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(OrderHistoryScreen),
      matchesGoldenFile('order_history.png'),
    );
  });

  testWidgets('My Wallet', (tester) async {
    await pump(
      tester,
      const WalletScreen(),
      binding: AccountBinding(),
      size: const Size(390, 1000),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(WalletScreen),
      matchesGoldenFile('wallet.png'),
    );
  });

  testWidgets('Hiding the balance masks it', (tester) async {
    await pump(
      tester,
      const WalletScreen(),
      binding: AccountBinding(),
      size: const Size(390, 1000),
    );
    final account = Get.find<AccountController>();
    expect(account.balanceLabel, r'$0.00');

    account.toggleBalanceVisibility();
    await tester.pump();
    expect(account.balanceLabel, '••••');
    expect(find.text('••••'), findsOneWidget);
  });

  testWidgets('Wallet accounts list', (tester) async {
    await pump(
      tester,
      const WalletAccountsScreen(),
      binding: AccountBinding(),
    );
    final account = Get.find<AccountController>();

    // Empty until an account is added, then one removable row.
    expect(find.text('Add Account'), findsOneWidget);
    account.saveCard(
      const WalletCard(
        id: 'card-1',
        brand: 'Debit card',
        maskedNumber: '•••• 4242',
        expiry: '8/27',
      ),
    );
    await tester.pumpAndSettle();

    await settleImages(tester);
    await expectLater(
      find.byType(WalletAccountsScreen),
      matchesGoldenFile('wallet_accounts.png'),
    );
  });

  // ─── Medical vault ───────────────────────────────────────────────────────

  testWidgets('My Health profile', (tester) async {
    await pump(tester, const HealthProfileScreen(), binding: DocumentsBinding());
    await settleImages(tester);
    await expectLater(
      find.byType(HealthProfileScreen),
      matchesGoldenFile('health_profile.png'),
    );
  });

  testWidgets('All Prescriptions — uploads, then the vault', (tester) async {
    await pump(
      tester,
      const AllPrescriptionsScreen(),
      binding: DocumentsBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(AllPrescriptionsScreen),
      matchesGoldenFile('all_prescriptions_uploads.png'),
    );

    await tester.tap(find.text('Your Medical vault'));
    // Settled, not a single pump: the ink ripple would otherwise still be
    // washing over the pill and the golden would show a lighter fill.
    await tester.pumpAndSettle();
    expect(find.text('Digital Prescription 05'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(AllPrescriptionsScreen),
      matchesGoldenFile('all_prescriptions_vault.png'),
    );
  });

  testWidgets('All Test Reports', (tester) async {
    await pump(
      tester,
      const AllTestReportsScreen(),
      binding: DocumentsBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(AllTestReportsScreen),
      matchesGoldenFile('all_test_reports.png'),
    );
  });

  testWidgets('Review shop', (tester) async {
    await pump(
      tester,
      const ReviewShopScreen(),
      binding: AccountBinding(),
      size: const Size(390, 1000),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(ReviewShopScreen),
      matchesGoldenFile('review_shop.png'),
    );
  });

  testWidgets('Payment Options picks a method', (tester) async {
    await pump(
      tester,
      const PaymentOptionsScreen(),
      binding: AccountBinding(),
    );
    final account = Get.find<AccountController>();

    // Debit/Credit is selected on open, as the design shows.
    expect(account.selectedMethodIndex.value, 0);
    await settleImages(tester);
    await expectLater(
      find.byType(PaymentOptionsScreen),
      matchesGoldenFile('payment_options.png'),
    );

    await tester.tap(find.text('Paypal'));
    await tester.pumpAndSettle();
    expect(account.selectedMethodIndex.value, 4);
  });

  testWidgets('Saving a card masks it to the last four', (tester) async {
    await pump(tester, const AddCardScreen(), binding: AddCardBinding());
    final controller = Get.find<AddCardController>()
      ..number.value = '4242 4242 4242 4242'
      ..holder.value = 'Mohammod Jakuan'
      ..expiry.value = '11/29'
      ..cvv.value = '123';

    // Not awaited: `submit` waits on a delay that only advances when the
    // tester pumps, so awaiting here would deadlock.
    controller.save();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    final card = Get.find<AccountController>().cards.single;
    expect(card.maskedNumber, '•••• 4242');
    expect(card.expiry, '11/29');
    expect(card.isDefault, isTrue);
  });

  testWidgets('Add Debit Card rejects a short number', (tester) async {
    await pump(tester, const AddCardScreen(), binding: AddCardBinding());
    final controller = Get.find<AddCardController>()
      ..number.value = '4242 42'
      ..holder.value = 'Mohammod Jakuan'
      ..expiry.value = '13/29'
      ..cvv.value = '12';

    // Validation fails before `submit`, so this resolves without a pump.
    await controller.save();
    await tester.pump();

    expect(controller.errorOf(AddCardController.numberField), isNotNull);
    // A month of 13 is the one expiry rule worth checking client-side.
    expect(controller.errorOf(AddCardController.expiryField), isNotNull);
    expect(controller.errorOf(AddCardController.cvvField), isNotNull);
    expect(controller.errorOf(AddCardController.holderField), isNull);
    expect(Get.find<AccountController>().cards, isEmpty);

    await settleImages(tester);
    await expectLater(
      find.byType(AddCardScreen),
      matchesGoldenFile('add_card.png'),
    );
  });

  testWidgets('Prescription details', (tester) async {
    await pump(
      tester,
      const PrescriptionDetailsScreen(),
      binding: DocumentsBinding(),
      size: const Size(390, 1020),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(PrescriptionDetailsScreen),
      matchesGoldenFile('prescription_details.png'),
    );
  });

  testWidgets('Past appointments', (tester) async {
    await pump(
      tester,
      const PastAppointmentsScreen(),
      binding: PastAppointmentsBinding(),
      size: const Size(390, 900),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(PastAppointmentsScreen),
      matchesGoldenFile('past_appointments.png'),
    );
  });

  testWidgets('My tests and results', (tester) async {
    await pump(
      tester,
      const TestResultsScreen(),
      binding: TestResultsBinding(),
      size: const Size(390, 1160),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(TestResultsScreen),
      matchesGoldenFile('test_results.png'),
    );
  });

  testWidgets('Filter chips narrow the list', (tester) async {
    await pump(
      tester,
      const TestResultsScreen(),
      binding: TestResultsBinding(),
      size: const Size(390, 1160),
    );
    final controller = Get.find<TestResultsController>();

    // "all" shows three laboratory orders; "Reviewed" only the read one.
    expect(controller.orders.length, 3);
    controller.selectFilter(ResultFilter.reviewed);
    await tester.pump();
    expect(controller.orders.single.stage, TestStage.reviewed);

    // The chip really repainted, which is what the golden would catch.
    controller.selectDiscipline(ResultDiscipline.radiology);
    controller.selectFilter(ResultFilter.all);
    await tester.pump();
    expect(controller.orders.length, 2);
  });

  testWidgets('Result cards never truncate their tags', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(
      tester,
      const TestResultsScreen(),
      binding: TestResultsBinding(),
      size: const Size(320, 1400),
    );
    await settleImages(tester);

    // "Laboratory" used to ellipsize to "Laborat…" on the card whose status
    // pill is the widest; the tag row wraps instead.
    expect(find.text('Laboratory'), findsNWidgets(3));
    expect(find.text('Awaiting review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Test order sheet', (tester) async {
    await pump(
      tester,
      const TestOrderScreen(),
      binding: TestResultsBinding(),
      size: const Size(390, 1800),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(TestOrderScreen),
      matchesGoldenFile('test_order.png'),
    );
  });

  testWidgets('Test order sheet after a centre is chosen', (tester) async {
    await pump(
      tester,
      const TestOrderScreen(),
      binding: TestResultsBinding(),
      size: const Size(390, 2100),
    );
    Get.find<TestResultsController>().centre.value =
        MedicalMockData.centres.first;
    await tester.pump();
    expect(find.text('I Completed My Test'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(TestOrderScreen),
      matchesGoldenFile('test_order_booked.png'),
    );
  });

  testWidgets('Testing centres', (tester) async {
    await pump(
      tester,
      const TestingCentresScreen(),
      binding: TestResultsBinding(),
      size: const Size(390, 900),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(TestingCentresScreen),
      matchesGoldenFile('testing_centres.png'),
    );
  });

  testWidgets('Upload report, empty then attached', (tester) async {
    await pump(
      tester,
      const UploadReportScreen(),
      binding: TestResultsBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(UploadReportScreen),
      matchesGoldenFile('upload_report.png'),
    );

    await tester.tap(find.text('Add report document'));
    await tester.pump();
    await settleImages(tester);
    await expectLater(
      find.byType(UploadReportScreen),
      matchesGoldenFile('upload_report_attached.png'),
    );
  });

  testWidgets('Results submitted', (tester) async {
    await pump(
      tester,
      const ResultsSubmittedScreen(),
      binding: TestResultsBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(ResultsSubmittedScreen),
      matchesGoldenFile('results_submitted.png'),
    );
  });

  testWidgets('Report review, waiting then follow-up offered', (tester) async {
    await pump(
      tester,
      const ReportReviewScreen(),
      binding: TestResultsBinding(),
    );
    final controller = Get.find<TestResultsController>()
      ..selected.value = MedicalMockData.testOrders.first
      ..note.value = MedicalMockData.patientNote
      ..hasDocument.value = true;
    await tester.pump();

    await settleImages(tester);
    await expectLater(
      find.byType(ReportReviewScreen),
      matchesGoldenFile('report_review.png'),
    );

    controller.outcome.value = ReviewOutcome.followUpOffered;
    await tester.pump();
    expect(find.text('Accept follow-up'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ReportReviewScreen),
      matchesGoldenFile('report_review_followup.png'),
    );

    // The three later outcomes replace the call button with their own
    // section, so the panel becomes a heading.
    controller.outcome.value = ReviewOutcome.messaged;
    await tester.pumpAndSettle();
    expect(find.text('Accept follow-up'), findsNothing);
    expect(find.text('Message'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(ReportReviewScreen),
      matchesGoldenFile('report_review_message.png'),
    );

    controller.outcome.value = ReviewOutcome.referred;
    await tester.pumpAndSettle();
    expect(find.text('Refer & Escalation'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(ReportReviewScreen),
      matchesGoldenFile('report_review_refer.png'),
    );

    controller.outcome.value = ReviewOutcome.furtherTestRequested;
    await tester.pumpAndSettle();
    expect(find.text('Cardiac Markers'), findsOneWidget);
    expect(find.text('Request sent'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(ReportReviewScreen),
      matchesGoldenFile('report_review_request.png'),
    );
  });
}
