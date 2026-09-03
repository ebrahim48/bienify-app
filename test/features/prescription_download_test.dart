import 'dart:async';
import 'dart:io';

import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/repositories/auth_repository.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/usecases/email_auth_usecases.dart';
import 'package:bienify_app/features/Role/patient/profile/data/repositories/mock_account_repository.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/repositories/account_repository.dart';
import 'package:bienify_app/core/services/file_download_service.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/repositories/vault_repository.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/controllers/documents_controller.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/screens/prescription_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// Download prescription.
///
/// The card was pulled once because it printed a snackbar and saved nothing.
/// What these assert is not that a button is on screen but that tapping it
/// puts real bytes — a PDF carrying this prescription's own medications — in
/// front of the device.
void main() {
  setUpAll(loadAppFonts);
  tearDown(Get.reset);

  final prescription = DigitalPrescription(
    id: '6a7d814bed769fc824194bc2',
    reference: '194BC2',
    doctorName: 'Dr Dana Okafor',
    specialty: 'General Practice',
    issuedOn: DateTime(2026, 8, 13),
    diagnosis: 'Bacterial throat infection',
    medications: const [
      Medication(
        name: 'Amoxicillin',
        dosage: '500 mg',
        frequency: '3 times daily, after meal',
        instructions: '',
        durationLabel: '7 days',
      ),
    ],
  );

  Future<_RecordingDownloads> pumpDetails(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Support and account deletion are resolved in the controller's defaults;
    // the detail screen touches neither, so they are only satisfied, not
    // exercised.
    Get.put(ApiClient(tokens: MemoryTokenStore()));
    Get.put<AuthRepository>(_UnusedAuth());
    Get.put(Logout(Get.find<AuthRepository>()));
    Get.put<AccountRepository>(MockAccountRepository());

    final downloads = _RecordingDownloads();
    Get.put(
      DocumentsController(repository: _EmptyVault(), downloads: downloads),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(),
        ),
      ),
    );
    await tester.pump();

    // The screen reads the script off the route arguments, as the list does
    // when a patient taps a row.
    Get.to<void>(
      () => const PrescriptionDetailsScreen(),
      arguments: prescription,
    );
    await tester.pumpAndSettle();
    return downloads;
  }

  testWidgets('the detail screen offers the download', (tester) async {
    await pumpDetails(tester);
    expect(find.text('Download prescription'), findsOneWidget);
  });

  testWidgets('tapping it hands a PDF of this prescription to the device', (
    tester,
  ) async {
    final downloads = await pumpDetails(tester);

    await tester.tap(find.text('Download prescription'));
    await tester.pumpAndSettle();

    expect(downloads.calls, hasLength(1));
    final call = downloads.calls.single;
    expect(call.fileName, 'prescription-194BC2.pdf');

    // A real PDF, not an empty buffer standing in for one.
    expect(String.fromCharCodes(call.bytes.take(5)), '%PDF-');

    // And this prescription's own contents. A document that rendered a
    // different script, or an empty one, would still be a file of the right
    // shape — what is drawn on the page is the only thing that says it is
    // this patient's.
    final drawn = _pageGlyphs(call.bytes);
    expect(drawn, contains('Amoxicillin'));
    expect(drawn, contains('DrDanaOkafor'));
    expect(drawn, contains('August13,2026'));
    expect(drawn, contains('194BC2'));
    expect(drawn, contains('3timesdaily,aftermeal'));
  });

  testWidgets('a second tap cannot start a parallel render', (tester) async {
    final downloads = await pumpDetails(tester)
      ..calls.clear();
    downloads.gate = true;

    await tester.tap(find.text('Download prescription'));
    await tester.pump();
    await tester.tap(find.text('Download prescription'));
    await tester.pump();

    expect(downloads.calls, hasLength(1));

    downloads.release();
    await tester.pumpAndSettle();
  });
}

/// Never called: the detail screen has no sign-out. Present so the account
/// deletion service the controller builds has something to resolve.
class _UnusedAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Every character the PDF actually draws on its page, in order.
///
/// The page text lives in deflated content streams, so the words are not in
/// the bytes as they stand: each stream is inflated, then the parenthesised
/// string literals the text operators take are concatenated. Inter-word gaps
/// are drawn as positioning rather than spaces, so this comes back without
/// them — assertions here spell their expectations the same way.
String _pageGlyphs(List<int> bytes) {
  final raw = String.fromCharCodes(bytes);
  final streams = StringBuffer();
  var cursor = 0;
  while (true) {
    final start = raw.indexOf('stream', cursor);
    if (start < 0) break;
    final end = raw.indexOf('endstream', start);
    if (end < 0) break;
    var from = start + 'stream'.length;
    // The keyword is followed by CRLF or LF.
    while (from < end &&
        (raw.codeUnitAt(from) == 13 || raw.codeUnitAt(from) == 10)) {
      from++;
    }
    try {
      streams.write(String.fromCharCodes(zlib.decode(bytes.sublist(from, end))));
    } catch (_) {
      // Not a deflated stream — the fonts and the cross-reference table.
      streams.write(raw.substring(from, end));
    }
    cursor = end + 1;
  }

  final glyphs = StringBuffer();
  final literal = RegExp(r'\((?:\\.|[^\\()])*\)', dotAll: true);
  for (final match in literal.allMatches(streams.toString())) {
    final quoted = match.group(0)!;
    glyphs.write(
      quoted
          .substring(1, quoted.length - 1)
          .replaceAll(RegExp(r'\\(.)'), r'$1'),
    );
  }
  return glyphs.toString();
}

/// Records what the screen asked to be written to the device, and can hold the
/// write open so the busy state is observable.
class _RecordingDownloads extends FileDownloadService {
  final List<({List<int> bytes, String fileName})> calls = [];

  bool gate = false;
  final _held = <void Function()>[];

  void release() {
    for (final complete in _held) {
      complete();
    }
    _held.clear();
  }

  @override
  Future<bool> openBytes({
    required List<int> bytes,
    required String fileName,
  }) async {
    calls.add((bytes: bytes, fileName: fileName));
    if (gate) {
      final completer = Completer<void>();
      _held.add(completer.complete);
      await completer.future;
    }
    return true;
  }
}

/// The detail screen reads nothing off the repository; it is here because the
/// controller requires one.
class _EmptyVault implements VaultRepository {
  @override
  Future<List<DigitalPrescription>> prescriptions() async => const [];
  @override
  Future<List<UploadedDocument>> documents() async => const [];
  @override
  Future<List<TestOrder>> testOrders() async => const [];
  @override
  Future<List<TestingCentre>> testingCentres() async => const [];
  @override
  Future<HealthProfile> healthProfile() async => const HealthProfile();
  @override
  Future<void> saveHealthProfile(HealthProfile profile) async {}
  @override
  Future<({String url, String fileName})> recordDownloadUrl(
    String recordId,
  ) async => (url: '', fileName: '');
  @override
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  }) async {}
  @override
  Future<void> revokeShare({
    required String recordId,
    required String doctorUserId,
  }) async {}
  @override
  Future<void> uploadLabResult({
    required String labOrderId,
    required String path,
    required String fileName,
    required String mimeType,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {}
  @override
  Future<void> selectTestingCentre({
    required String labOrderId,
    required String testingCentreId,
  }) async {}
  @override
  Future<void> respondToLabOrder({
    required String labOrderId,
    required bool accept,
  }) async {}
  @override
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  }) async => UploadedDocument(
    id: 'rec-1',
    fileName: fileName,
    kindLabel: type.name,
    uploadedOn: DateTime(2026, 2, 20),
  );
}
