import '../../../../../core/constants/app_assets.dart';
import '../../domain/entities/test_request.dart';

/// Sample data behind Results to Review.
///
/// Static by design — the doctor section is UI-first, so there is no
/// repository or API here; these shapes are what an endpoint will fill in.
class DoctorOrdersData {
  DoctorOrdersData._();

  /// The designs date every row the same day, so one constant serves.
  static final DateTime _seenOn = DateTime(2026, 7, 12);

  static final List<ReviewPatient> patients = [
    ReviewPatient(
      id: 'p-1',
      name: 'Amelia Hart',
      code: 'CXR-2',
      age: 34,
      gender: 'Female',
      complaint: 'Persistent chest pain',
      seenOn: _seenOn,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    ReviewPatient(
      id: 'p-2',
      name: 'Amelia Hart',
      code: 'CXR-2',
      age: 34,
      gender: 'Female',
      complaint: 'Persistent chest pain',
      seenOn: _seenOn,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
    ReviewPatient(
      id: 'p-3',
      name: 'Amelia Hart',
      code: 'CXR-2',
      age: 34,
      gender: 'Female',
      complaint: 'Persistent chest pain',
      seenOn: _seenOn,
      photoAsset: AppAssets.doctorPlaceholder,
    ),
  ];

  /// What "Select lab Test" offers. The design repeats the thyroid panel by
  /// accident and lists the pregnancy test in its place on the previous
  /// screen, so it appears once here.
  static const List<String> labTests = [
    'Complete Blood Count (CBC)',
    'Blood Glucose Test',
    'Lipid Profile',
    'Liver Function Test (LFT)',
    'Kidney Function Test (KFT)',
    'Urine Routine Test',
    'Thyroid Function Test (TFT)',
    'Pregnancy Test (hCG)',
  ];

  /// "Select Radiology Test", and the subtests on the step after it — the
  /// design draws the same catalogue in both places.
  static const List<String> radiologyTests = [
    'X-Ray',
    'Ultrasound (USG)',
    'CT Scan (Computed Tomography)',
    'MRI (Magnetic Resonance Imaging)',
    'Mammography',
    'ECG (Electrocardiogram)',
    'Echocardiogram (Echo)',
  ];

  /// The signature the electric-sign box is pre-filled with.
  static const String signatureHint = 'dr.deep';

  static final DateTime _orderedOn = DateTime(2026, 7, 20);

  /// Three lab requests, one in each state the design shows.
  static final List<TestRequest> requests = [
    TestRequest(
      id: 'r-1',
      kind: OrderKind.lab,
      title: 'Cardiac Markers',
      subtitle: 'Troponin I',
      priority: OrderPriority.urgent,
      status: RequestStatus.awaitingReview,
      stage: OrderStage.ordered,
      patient: patients.first,
      orderedOn: _orderedOn,
      isCritical: true,
      hospitalName: 'St. Mary’s Hospital',
      hospitalAddress: '100 Grand Avenue, Downtown',
      clinicalNotes: 'Persistent chest pain; assess for myocardial injury.',
      documentAsset: AppAssets.reportDocument,
    ),
    TestRequest(
      id: 'r-2',
      kind: OrderKind.lab,
      title: 'Cardiac Markers',
      subtitle: 'Troponin I',
      priority: OrderPriority.urgent,
      // Nothing has come back yet, which is what leaves the detail screen on
      // "Awaiting patient upload".
      status: RequestStatus.requestSent,
      stage: OrderStage.ordered,
      patient: patients.first,
      orderedOn: _orderedOn,
    ),
    TestRequest(
      id: 'r-3',
      kind: OrderKind.lab,
      title: 'Cardiac Markers',
      subtitle: 'Troponin I',
      priority: OrderPriority.urgent,
      status: RequestStatus.reviewed,
      stage: OrderStage.reviewed,
      patient: patients.first,
      orderedOn: _orderedOn,
      hospitalName: 'St. Mary’s Hospital',
      hospitalAddress: '100 Grand Avenue, Downtown',
      clinicalNotes: 'Persistent chest pain; assess for myocardial injury.',
      documentAsset: AppAssets.reportDocument,
    ),
  ];

  /// The Radiology Requests segment shows the same three orders against the
  /// imaging department.
  static final List<TestRequest> radiologyRequests = [
    for (final request in requests)
      TestRequest(
        id: 'rad-${request.id}',
        kind: OrderKind.radiology,
        title: 'Chest Imaging',
        subtitle: 'CT Scan (Computed Tomography)',
        priority: request.priority,
        status: request.status,
        stage: request.stage,
        patient: request.patient,
        orderedOn: request.orderedOn,
        isCritical: request.isCritical,
        hospitalName: request.hospitalName,
        hospitalAddress: request.hospitalAddress,
        clinicalNotes: request.clinicalNotes,
        documentAsset: request.documentAsset,
      ),
  ];
}
