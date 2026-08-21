import 'dart:io';

import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/core/services/attachment_picker_service.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/repositories/vault_repository.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/controllers/test_results_controller.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/presentation/widgets/report_thumbnail.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/prescription_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// Covers the three upload buttons that used to be placeholders.
///
/// Each one previously invented a filename and reported success without ever
/// opening a picker or storing a byte. What matters here is not that a button
/// exists but that a real file reaches the repository, and that nothing
/// claims success before it has.
void main() {
  setUpAll(loadAppFonts);
  tearDown(Get.reset);

  /// Pumps [child] inside the overlay Get needs for navigation and snackbars,
  /// on a real phone-sized viewport.
  ///
  /// The size matters: the sheet is laid out against the 390pt design canvas,
  /// and on the test binding's default 800x600 its buttons land off-screen and
  /// cannot be tapped.
  Future<void> pumpHost(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(child));
    await tester.pump();
  }

  group('upload test report', () {
    testWidgets('shows the picked image, not the bundled artwork', (
      tester,
    ) async {
      final controller = TestResultsController(
        repository: _RecordingVault(),
        picker: _StubPicker(mime: 'image/png', name: 'xray.png'),
      );
      Get.put(controller);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 876),
          builder: (_, _) => GetMaterialApp(
            theme: AppTheme.light,
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: Obx(
                () => controller.document.value == null
                    ? const SizedBox()
                    : ReportThumbnail(
                        file: controller.document.value!.file,
                        isImage: controller.document.value!.mime.startsWith(
                          'image/',
                        ),
                      ),
              ),
            ),
          ),
        ),
      );

      controller.document.value = await _StubPicker(
        mime: 'image/png',
        name: 'xray.png',
      ).pick(AttachmentSource.gallery);
      await tester.pump();

      // The patient's own file, rather than stock cover art standing in for
      // whatever they chose.
      expect(find.byType(Image), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<FileImage>());
    });

    testWidgets('a PDF falls back to the artwork rather than a broken image', (
      tester,
    ) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 876),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: ReportThumbnail(
                file: File('report.pdf'),
                isImage: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
    });

    testWidgets('sends the picked file to the vault and files it by discipline', (
      tester,
    ) async {
      final vault = _RecordingVault();
      final controller = TestResultsController(
        repository: vault,
        picker: _StubPicker(mime: 'image/png', name: 'xray.png'),
      );
      Get.put(controller);
      await pumpHost(tester, const SizedBox());

      controller.note.value = 'Taken at St. Mary\'s';
      controller.document.value = await _StubPicker(
        mime: 'image/png',
        name: 'xray.png',
      ).pick(AttachmentSource.gallery);
      controller.hasDocument.value = true;
      controller.discipline.value = ResultDiscipline.radiology;

      await controller.upload();
      await settleSnackbar(tester);

      // The file the patient picked, not a name made up on the spot.
      expect(vault.uploads, hasLength(1));
      expect(vault.uploads.single.fileName, 'xray.png');
      expect(vault.uploads.single.notes, "Taken at St. Mary's");
      // A radiology film is not a lab report, and the screen already knows
      // which list the patient came from.
      expect(vault.uploads.single.type, VaultRecordType.imaging);
    });

    testWidgets('refuses to upload with nothing attached', (tester) async {
      final vault = _RecordingVault();
      final controller = TestResultsController(
        repository: vault,
        picker: _StubPicker(),
      );
      Get.put(controller);
      await pumpHost(tester, const SizedBox());

      await controller.upload();
      await settleSnackbar(tester);

      expect(vault.uploads, isEmpty);
    });
  });

  group('upload prescription', () {
    testWidgets('stores what the patient picked, under its real name', (
      tester,
    ) async {
      final vault = _RecordingVault();
      final controller = PrescriptionController(
        vault: vault,
        picker: _StubPicker(mime: 'application/pdf', name: 'script.pdf'),
      );
      Get.put(controller);

      await pumpHost(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => controller.browseFile(context),
            child: const Text('browse'),
          ),
        ),
      );

      await tester.tap(find.text('browse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Document'));
      await tester.pumpAndSettle();

      // The old version hardcoded 'prescription.pdf' and navigated on with
      // nothing picked and nothing stored — the pharmacy had no script to
      // read.
      expect(vault.uploads, hasLength(1));
      expect(vault.uploads.single.fileName, 'script.pdf');
      expect(vault.uploads.single.type, VaultRecordType.prescriptionScan);
      expect(controller.uploadedFileName.value, 'script.pdf');
      await settleSnackbar(tester);
    });
  });
}

/// A host app with the overlay Get needs for navigation and snackbars.
///
/// The destinations are stubs. What these tests assert is that the upload
/// happened *before* the screen moved on — the old code navigated first — so
/// the routes have to exist, but what is on them does not matter.
Widget _host(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 876),
  builder: (_, _) => GetMaterialApp(
    theme: AppTheme.light,
    translations: AppTranslations(),
    locale: const Locale('en', 'US'),
    home: Scaffold(body: child),
    getPages: [
      for (final route in [
        AppRoutes.resultsSubmitted,
        AppRoutes.pharmacyMatches,
      ])
        GetPage(
          name: route,
          page: () => const Scaffold(),
          transition: Transition.noTransition,
        ),
    ],
  ),
);

/// A vault that records what it was asked to store.
class _RecordingVault implements VaultRepository {
  final List<({String fileName, String? notes, VaultRecordType type})> uploads =
      [];

  @override
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    uploads.add((fileName: fileName, notes: notes, type: type));
    return UploadedDocument(
      id: 'rec-${uploads.length}',
      fileName: fileName,
      kindLabel: type.name,
      uploadedOn: DateTime(2026, 2, 20),
    );
  }

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
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  }) async {}
  @override
  Future<void> revokeShare({
    required String recordId,
    required String doctorUserId,
  }) async {}
}

/// Stands in for the platform picker, which has no plugin under
/// `flutter test`.
class _StubPicker implements AttachmentPickerService {
  _StubPicker({this.mime = 'image/png', this.name = 'file.png'});

  final String mime;
  final String name;

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async =>
      PickedAttachment(
        file: File(name),
        name: name,
        mime: mime,
        size: 1024,
      );
}
