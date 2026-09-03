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
        name: 'Paracetamol 500mg',
        dosage: '2 tablets',
        frequency: 'As needed (max 4 times daily)',
        instructions: 'Take with food or milk',
        durationLabel: '5 days',
      ),
      // Six in total, and named to match what the demo pharmacy stocks.
      //
      // Two reasons. A script of two meant every shop could fill the whole
      // thing, so the "Not Available" row the Select Medicines screen exists to
      // show was unreachable. And a script naming medicines no shelf carries
      // prices at zero — the basket is priced from the shop's own catalogue,
      // because what a prescription costs depends on who fills it.
      Medication(
        name: 'Metformin 850mg',
        dosage: '1 tablet',
        frequency: 'Twice daily',
        instructions: 'Take with meals',
        durationLabel: '30 days',
      ),
      Medication(
        name: 'Lisinopril 10mg',
        dosage: '1 tablet',
        frequency: 'Once daily',
        instructions: 'Take in the morning',
        durationLabel: '30 days',
      ),
      Medication(
        name: 'Atorvastatin 20mg',
        dosage: '1 tablet',
        frequency: 'Once daily at night',
        instructions: 'Avoid grapefruit',
        durationLabel: '30 days',
      ),
      Medication(
        name: 'Omeprazole 20mg',
        dosage: '1 capsule',
        frequency: 'Once daily',
        instructions: 'Take before breakfast',
        durationLabel: '14 days',
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
  /// The order sheet the demo orders carry.
  ///
  /// Deliberately describes the demo patient and the demo doctor, not the
  /// invented practice the old fixture used — a sample must not model a shape
  /// the real screen can no longer produce.
  static const TestOrderDocument document = TestOrderDocument(
    kindLabel: 'LABORATORY ORDER',
    priorityLabel: 'Priority: Routine',
    reference: 'A1B2C3',
    orderedOn: '22 Aug 2026, 09:15 AM',
    patientName: 'Pat Patient',
    dateOfBirth: '15 Mar 1988',
    clinicalIndication:
        'Fatigue and pallor for six weeks. Rule out iron deficiency anaemia.',
    physicianName: orderingDoctor,
    physicianSpecialty: 'General practice',
    licence: 'LIC-DEMO-0001',
    facility: defaultFacility,
  );

  /// What the ordering doctor wrote back on the reviewed sample order.
  static const String reviewedMessage =
      'Everything is within range. No action needed — we can go over it at '
      'your next visit.';

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
      // A reviewed order the doctor left nothing on is not a state the server
      // produces: `reviewed` is reached only through `PATCH /review`, which
      // requires a message. Without one here the golden documented a reviewed
      // result with no word from the doctor on it — the very bug the screen had.
      reviewMessage: reviewedMessage,
      document: document,
    ),
    TestOrder(
      id: 'test-2',
      discipline: ResultDiscipline.laboratory,
      category: 'Laboratory',
      priority: 'Routine',
      title: testTitle,
      orderedBy: orderingDoctor,
      document: document,
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
      document: document,
      stage: TestStage.requestSent,
    ),
    TestOrder(
      id: 'test-4',
      discipline: ResultDiscipline.radiology,
      category: 'Radiology',
      priority: 'Urgent',
      title: 'MRI • Brain without contrast',
      orderedBy: 'Dr. Elena Reyes',
      document: document,
      stage: TestStage.requestSent,
    ),
    TestOrder(
      id: 'test-5',
      discipline: ResultDiscipline.radiology,
      category: 'Radiology',
      priority: 'Routine',
      title: 'Chest X-ray • PA and lateral',
      orderedBy: 'Dr. Elena Reyes',
      document: document,
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
