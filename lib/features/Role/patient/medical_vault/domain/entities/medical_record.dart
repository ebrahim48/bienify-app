/// Shapes behind My Health profile: prescriptions, test orders and reports.
///
/// **Names only, by design.** No repository, use case or data source sits
/// under this feature and nothing calls an API — see the pharmacy and profile
/// features for the same arrangement.
library;

// ─── Prescriptions ─────────────────────────────────────────────────────────

/// Whether a prescription can still be dispensed.
enum PrescriptionState { active, expired }

/// One line on a digital prescription.
class Medication {
  const Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.instructions,
    required this.durationLabel,
  });

  /// `Amoxicillin 500mg` — strength included, as the design prints it.
  final String name;

  final String dosage;
  final String frequency;
  final String instructions;

  /// `7 days`, shown in the pill on the right of the row.
  final String durationLabel;
}

/// A prescription issued after a consultation.
class DigitalPrescription {
  const DigitalPrescription({
    required this.id,
    required this.reference,
    required this.doctorName,
    required this.specialty,
    required this.issuedOn,
    required this.diagnosis,
    required this.medications,
    this.state = PrescriptionState.active,
  });

  final String id;

  /// `RX-784875`.
  final String reference;

  final String doctorName;
  final String specialty;
  final DateTime issuedOn;
  final String diagnosis;
  final List<Medication> medications;
  final PrescriptionState state;
}

/// Which tab All Prescriptions is showing: the patient's own uploads, or the
/// prescriptions Bienify holds for them.
enum PrescriptionSource { uploads, medicalVault }

/// A file the patient uploaded themselves.
class UploadedDocument {
  const UploadedDocument({
    required this.id,
    required this.fileName,
    required this.kindLabel,
    required this.uploadedOn,
  });

  final String id;

  /// `image (7).png` — shown verbatim, as the design does.
  final String fileName;

  /// `Lab Result`, in the orange tag.
  final String kindLabel;

  final DateTime uploadedOn;
}

// ─── Tests and results ─────────────────────────────────────────────────────

/// Which list the results screen is showing.
enum ResultDiscipline { laboratory, radiology }

/// How far a test order has progressed. The order matters: the filter chips
/// group several of these under one heading.
enum TestStage {
  /// The doctor has ordered it; nothing booked yet.
  requestSent,

  /// Booked or completed, waiting for the patient to upload the report.
  awaitingUpload,

  /// Report uploaded, waiting on the doctor.
  awaitingReview,

  /// The doctor has read it.
  reviewed,
}

/// Which chip is active above the results list.
enum ResultFilter { all, activeOrders, resultsReady, reviewed }

/// A test the patient has been sent for.
class TestOrder {
  const TestOrder({
    required this.id,
    required this.discipline,
    required this.category,
    required this.priority,
    required this.title,
    required this.orderedBy,
    required this.stage,
    this.facility,
  });

  final String id;
  final ResultDiscipline discipline;

  /// `Laboratory` — the blue tag.
  final String category;

  /// `Routine` — the slate tag.
  final String priority;

  /// `Complete Blood Count • CBC with Differential`.
  final String title;

  /// `Dr. Reed`.
  final String orderedBy;

  final TestStage stage;

  /// Where the test is booked, once a centre has been chosen.
  final String? facility;
}

/// A laboratory or imaging centre the patient can book at.
class TestingCentre {
  const TestingCentre({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceLabel,
  });

  final String id;
  final String name;
  final String address;
  final String distanceLabel;
}

/// The full order document — the navy-headed sheet the doctor signed.
class TestOrderDocument {
  const TestOrderDocument({
    required this.practiceName,
    required this.practiceLine,
    required this.practiceAddress,
    required this.practiceContact,
    required this.kindLabel,
    required this.priorityLabel,
    required this.reference,
    required this.orderedOn,
    required this.validForLabel,
    required this.patientName,
    required this.dateOfBirth,
    required this.medicalRecordNumber,
    required this.insurance,
    required this.memberId,
    required this.modality,
    required this.bodyRegion,
    required this.clinicalIndication,
    required this.specialInstructions,
    required this.physicianName,
    required this.physicianSpecialty,
    required this.boardCertification,
    required this.npi,
    required this.dea,
    required this.licence,
    required this.signedOn,
  });

  final String practiceName;
  final String practiceLine;
  final String practiceAddress;
  final String practiceContact;

  /// `RADIOLOGY ORDER`, in the badge beside the practice name.
  final String kindLabel;

  final String priorityLabel;
  final String reference;
  final String orderedOn;
  final String validForLabel;

  final String patientName;
  final String dateOfBirth;
  final String medicalRecordNumber;
  final String insurance;
  final String memberId;

  final String modality;
  final String bodyRegion;
  final String clinicalIndication;
  final String specialInstructions;

  final String physicianName;
  final String physicianSpecialty;
  final String boardCertification;
  final String npi;
  final String dea;
  final String licence;
  final String signedOn;
}

/// What the doctor decided after reading an uploaded report.
enum ReviewOutcome {
  /// Still with the doctor.
  pending,

  /// The doctor wants to talk it through.
  followUpOffered,

  /// The doctor left a written note back.
  messaged,

  /// The doctor is referring or escalating the case.
  referred,

  /// The doctor has ordered a further test.
  furtherTestRequested,
}

/// A further test the doctor ordered off the back of a report.
class FollowUpRequest {
  const FollowUpRequest({
    required this.name,
    required this.detail,
    required this.priorityLabel,
    required this.statusLabel,
  });

  /// `Cardiac Markers`.
  final String name;

  /// `Troponin I`.
  final String detail;

  /// `Urgent`, in the amber tag beside the name.
  final String priorityLabel;

  /// `Request sent`, in the dotted pill underneath.
  final String statusLabel;
}
