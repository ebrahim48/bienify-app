import '../../domain/entities/medical_record.dart';

/// Sample prescriptions, test orders and the signed order document.
///
/// Static by design — this feature is UI-first, so there is no repository or
/// API here; the shapes are what a future endpoint will fill in.
class MedicalMockData {
  MedicalMockData._();

  // ─── Prescriptions ───────────────────────────────────────────────────────

  static DigitalPrescription prescription() => DigitalPrescription(
    id: 'rx-784875',
    reference: 'RX-784875',
    doctorName: 'Dr. Kwame Mensah',
    specialty: 'Pediatrician',
    issuedOn: DateTime(2026, 3, 31),
    diagnosis: 'Upper Respiratory Tract Infection',
    medications: const [
      Medication(
        name: 'Amoxicillin 500mg',
        dosage: '1 capsule',
        frequency: '3 times daily',
        instructions: 'Take with food',
        durationLabel: '7 days',
      ),
      Medication(
        name: 'Ibuprofen 400mg',
        dosage: '1 tablet',
        frequency: 'As needed (max 3 times daily)',
        instructions: 'Take with food or milk',
        durationLabel: '5 days',
      ),
    ],
  );

  /// Five scripts, numbered as the design lists them: `Digital Prescription
  /// 01` … `05` with consecutive references from `RX-784875`.
  static List<DigitalPrescription> prescriptions() => [
    for (var index = 0; index < 5; index++)
      DigitalPrescription(
        id: 'rx-${784875 + index}',
        reference: 'RX-${784875 + index}',
        doctorName: 'Dr. Kwame Mensah',
        specialty: 'Pediatrician',
        issuedOn: DateTime(2026, 3, 31 - index),
        diagnosis: 'Upper Respiratory Tract Infection',
        medications: prescription().medications,
      ),
  ];

  /// What the patient has uploaded themselves.
  static List<UploadedDocument> uploads() => [
    UploadedDocument(
      id: 'upload-1',
      fileName: 'image (7).png',
      kindLabel: 'Lab Result',
      uploadedOn: DateTime(2026, 4, 3),
    ),
  ];

  // ─── Tests and results ───────────────────────────────────────────────────

  static const String testTitle =
      'Complete Blood Count • CBC with Differential';
  static const String orderingDoctor = 'Dr. Reed';
  static const String defaultFacility = "St. Mary's Hospital";

  /// One order per stage, which is what the design shows: the same test in
  /// three states so every status pill and action link is visible at once.
  static const List<TestOrder> testOrders = [
    TestOrder(
      id: 'test-1',
      discipline: ResultDiscipline.laboratory,
      category: 'Laboratory',
      priority: 'Routine',
      title: testTitle,
      orderedBy: orderingDoctor,
      stage: TestStage.reviewed,
      facility: defaultFacility,
    ),
    TestOrder(
      id: 'test-2',
      discipline: ResultDiscipline.laboratory,
      category: 'Laboratory',
      priority: 'Routine',
      title: testTitle,
      orderedBy: orderingDoctor,
      stage: TestStage.awaitingReview,
      facility: defaultFacility,
    ),
    TestOrder(
      id: 'test-3',
      discipline: ResultDiscipline.laboratory,
      category: 'Laboratory',
      priority: 'Routine',
      title: testTitle,
      orderedBy: orderingDoctor,
      stage: TestStage.requestSent,
    ),
    TestOrder(
      id: 'test-4',
      discipline: ResultDiscipline.radiology,
      category: 'Radiology',
      priority: 'Urgent',
      title: 'MRI • Brain without contrast',
      orderedBy: 'Dr. Elena Reyes',
      stage: TestStage.requestSent,
    ),
    TestOrder(
      id: 'test-5',
      discipline: ResultDiscipline.radiology,
      category: 'Radiology',
      priority: 'Routine',
      title: 'Chest X-ray • PA and lateral',
      orderedBy: 'Dr. Elena Reyes',
      stage: TestStage.awaitingUpload,
      facility: defaultFacility,
    ),
  ];

  /// Six identical entries, as the design's list shows.
  static const List<TestingCentre> centres = [
    TestingCentre(
      id: 'centre-1',
      name: defaultFacility,
      address: '100 Grand Avenue, Downtown',
      distanceLabel: '1.2 km',
    ),
    TestingCentre(
      id: 'centre-2',
      name: defaultFacility,
      address: '100 Grand Avenue, Downtown',
      distanceLabel: '1.2 km',
    ),
    TestingCentre(
      id: 'centre-3',
      name: defaultFacility,
      address: '100 Grand Avenue, Downtown',
      distanceLabel: '1.2 km',
    ),
    TestingCentre(
      id: 'centre-4',
      name: defaultFacility,
      address: '100 Grand Avenue, Downtown',
      distanceLabel: '1.2 km',
    ),
    TestingCentre(
      id: 'centre-5',
      name: defaultFacility,
      address: '100 Grand Avenue, Downtown',
      distanceLabel: '1.2 km',
    ),
    TestingCentre(
      id: 'centre-6',
      name: defaultFacility,
      address: '100 Grand Avenue, Downtown',
      distanceLabel: '1.2 km',
    ),
  ];

  // ─── The signed order sheet ──────────────────────────────────────────────

  static const TestOrderDocument document = TestOrderDocument(
    practiceName: 'Harmony Health Medical Group',
    practiceLine: 'Dr. Elena Reyes, MD, FACP · Internal Medicine',
    practiceAddress:
        '1200 Medical Plaza Drive, Suite 400 · San Francisco, CA 94102',
    practiceContact: 'Tel: (415) 555-0100 · Fax: (415) 555-0199',
    kindLabel: 'RADIOLOGY ORDER',
    priorityLabel: 'Priority: Urgent',
    reference: 'RAD-2024-001',
    orderedOn: '2024-07-22 09:15',
    validForLabel: '30 days',
    patientName: 'Margaret Sullivan',
    dateOfBirth: 'March 15, 1978',
    medicalRecordNumber: 'PT-10042',
    insurance: 'BlueCross BlueShield PPO',
    memberId: 'BCB-0042-XY',
    modality: 'MRI',
    bodyRegion: 'Brain',
    clinicalIndication: 'Persistent headaches, rule out intracranial lesion',
    specialInstructions:
        'Patient is claustrophobic — open MRI preferred if available',
    physicianName: 'Dr. Elena Reyes, MD, FACP',
    physicianSpecialty: 'Internal Medicine',
    boardCertification: 'Board Certified — American Board of Internal Medicine',
    npi: '1234567890',
    dea: 'FR1234563',
    licence: 'CA-G-12345',
    signedOn: '2024-07-22 09:15',
  );

  /// The question the patient attached when uploading the report.
  static const String patientNote =
      'What is my problem with this report? is it critical or normal ?';

  /// The further test the doctor ordered after reading it.
  static const FollowUpRequest followUpRequest = FollowUpRequest(
    name: 'Cardiac Markers',
    detail: 'Troponin I',
    priorityLabel: 'Urgent',
    statusLabel: 'Request sent',
  );
}
