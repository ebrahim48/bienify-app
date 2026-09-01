import 'dart:async';
import 'dart:io';

import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/services/attachment_picker_service.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/repositories/appointment_repository.dart';
import 'package:bienify_app/features/Role/patient/booking/presentation/controllers/payment_controller.dart';
import 'package:bienify_app/features/Role/patient/booking/presentation/widgets/medical_document_picker.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/repositories/vault_repository.dart';
import 'package:bienify_app/features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// Covers the Medical Document tiles on Payment Summary.
///
/// Both symptoms this pins down were reported from the booking screen: the
/// card turned into a spinner that never cleared, and the Camera tile was a
/// dead end on any device without a camera.
void main() {
  setUpAll(loadAppFonts);
  tearDown(Get.reset);

  Appointment appointment() => Appointment(
    id: 'apt-1',
    doctorName: 'Dr Dana Okafor',
    specialty: 'Cardiology',
    scheduledAt: DateTime(2026, 9, 3, 10),
    consultationFee: 50,
    doctorUserId: 'doc-user-1',
  );

  PaymentController put({
    required AttachmentPickerService picker,
    VaultRepository? vault,
  }) {
    final controller = PaymentController(
      appointment: appointment(),
      appointments: _StubAppointments(),
      wallets: _StubWallet(),
      vault: vault ?? _RecordingVault(),
      picker: picker,
    );
    Get.put(controller);
    return controller;
  }

  Future<void> pumpPicker(WidgetTester tester, PaymentController c) async {
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Obx(
                () => MedicalDocumentPicker(
                  onAttach: c.addAttachment,
                  onCamera: () => c.captureFromCamera(context),
                  attachments: c.attachments.toList(),
                  isBusy: c.isAttaching.value,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the card does not go busy while the picker is still open', (
    tester,
  ) async {
    // Nothing has been chosen yet — this is the whole time the OS file
    // browser is on screen. The card used to show a spinner in place of both
    // tiles for exactly this stretch, which is what read as "stuck loading".
    final picker = _HangingPicker();
    final controller = put(picker: picker);
    await pumpPicker(tester, controller);

    unawaited(controller.addAttachment());
    await tester.pump();

    expect(controller.isAttaching.value, isFalse);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Attachment'), findsOneWidget);

    picker.complete(null);
    await tester.pump();
  });

  testWidgets('a stalled upload is the only thing that shows progress', (
    tester,
  ) async {
    // Once a file is chosen the screen really is working, so the tiles fade
    // and the bar appears — and the tiles stay on screen rather than being
    // swapped out.
    final vault = _HangingVault();
    final controller = put(
      picker: _StubPicker(name: 'report.pdf', mime: 'application/pdf'),
      vault: vault,
    );
    await pumpPicker(tester, controller);

    unawaited(controller.addAttachment());
    // Twice: the first frame runs the pick, the second paints what the Obx
    // was marked dirty for.
    await tester.pump();
    await tester.pump();

    expect(controller.isAttaching.value, isTrue);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Attachment'), findsOneWidget);

    vault.finish();
    await tester.pump();
    await settleSnackbar(tester);
  });

  testWidgets('the camera tile offers the gallery as well', (tester) async {
    // A tile wired straight to the camera is a dead end wherever there is
    // not one: image_picker shows its own "Camera not available." alert and
    // returns nothing, so the tap looked broken on a simulator.
    final picker = _StubPicker(name: 'photo.jpg', mime: 'image/jpeg');
    final vault = _RecordingVault();
    final controller = put(picker: picker, vault: vault);
    await pumpPicker(tester, controller);

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(find.text('Photo'), findsOneWidget);

    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();

    expect(picker.sources, [AttachmentSource.gallery]);
    expect(vault.uploads.single.fileName, 'photo.jpg');
    await settleSnackbar(tester);
  });

  testWidgets('a long file name is clipped rather than overflowing the row', (
    tester,
  ) async {
    // The chip took whatever the picker called the file, unwrapped, and a
    // scan straight off a hospital portal overflowed the row by 239px.
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: MedicalDocumentPicker(
              onAttach: () {},
              onCamera: () {},
              attachments: const [
                'discharge-summary-cardiology-outpatient-clinic-2026-08-31-'
                    'reviewed-and-countersigned-final-version.pdf',
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('the camera tile does not offer a video or a document', (
    tester,
  ) async {
    // Those belong on the Attachment tile; the sheet is shared with chat,
    // where all four are offered.
    final controller = put(picker: _StubPicker());
    await pumpPicker(tester, controller);

    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(find.text('Video'), findsNothing);
    expect(find.text('Document'), findsNothing);
  });
}

/// A picker whose future stays unresolved, standing in for a native sheet the
/// patient has not answered yet.
class _HangingPicker implements AttachmentPickerService {
  final _pending = Completer<PickedAttachment?>();

  void complete(PickedAttachment? value) => _pending.complete(value);

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) => _pending.future;
}

class _StubPicker implements AttachmentPickerService {
  _StubPicker({this.mime = 'image/png', this.name = 'file.png'});

  final String mime;
  final String name;

  /// What the controller asked for, so a test can tell the camera from the
  /// gallery.
  final List<AttachmentSource> sources = [];

  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async {
    sources.add(source);
    return PickedAttachment(
      file: File(name),
      name: name,
      mime: mime,
      size: 1024,
    );
  }
}

/// Records what it was asked to store.
class _RecordingVault extends Fake implements VaultRepository {
  final List<({String fileName, VaultRecordType type})> uploads = [];

  @override
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    uploads.add((fileName: fileName, type: type));
    return UploadedDocument(
      id: 'rec-${uploads.length}',
      fileName: fileName,
      kindLabel: type.name,
      uploadedOn: DateTime(2026, 8, 31),
    );
  }

  @override
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  }) async {}
}

/// An upload that never finishes on its own — a bucket that accepted the
/// connection and then went quiet.
class _HangingVault extends Fake implements VaultRepository {
  final _pending = Completer<UploadedDocument>();

  void finish() => _pending.complete(
    UploadedDocument(
      id: 'rec-1',
      fileName: 'report.pdf',
      kindLabel: 'other',
      uploadedOn: DateTime(2026, 8, 31),
    ),
  );

  @override
  Future<UploadedDocument> uploadDocument({
    required String path,
    required String fileName,
    required String mimeType,
    required VaultRecordType type,
    String? notes,
    void Function(double progress)? onProgress,
  }) => _pending.future;

  @override
  Future<void> shareRecord({
    required String recordId,
    required String doctorUserId,
  }) async {}
}

class _StubWallet extends Fake implements WalletRepository {
  @override
  Future<double> balance() async => 1268.01;
}

class _StubAppointments extends Fake implements AppointmentRepository {}
