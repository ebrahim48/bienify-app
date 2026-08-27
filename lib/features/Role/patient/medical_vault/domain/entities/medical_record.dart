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
    this.reviewMessage,
    this.document,
  });

  final String id;
  final ResultDiscipline discipline;

  /// `Laboratory` — the blue tag.
  final String category;

  /// `Routine` — the slate tag.
  final String priority;

  /// `Complete Blood Count • CBC with Differential`.
  final String title;

  /// What the doctor wrote when they reviewed the result. Null until they have.
  final String? reviewMessage;

  /// The signed order sheet, built from this same row. Carried here so the
  /// detail screen does not have to re-fetch to render it.
  final TestOrderDocument? document;

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
/// The signed order sheet, built from the order itself.
///
/// This used to carry twenty-four fields and was filled from a single `const`
/// fixture: a practice, a physician, an NPI, a DEA registration and a patient
/// — "Margaret Sullivan", born March 1978 — none of whom were the person
/// holding the phone. Every patient opening their own order read someone
/// else's name, date of birth, insurer and member id.
///
/// It now carries only what `GET /lab-orders` and the signed-in account
/// actually know. Practice address, NPI, DEA, insurance, member id and medical
/// record number are gone rather than invented: NPI and DEA are US federal
/// registrations that do not apply here at all, and insurance is a billing
/// domain the platform has no model for.
class TestOrderDocument {
  const TestOrderDocument({
    required this.kindLabel,
    required this.priorityLabel,
    required this.reference,
    required this.orderedOn,
    required this.patientName,
    required this.clinicalIndication,
    required this.physicianName,
    this.dateOfBirth,
    this.modality,
    this.bodyRegion,
    this.physicianSpecialty,
    this.licence,
    this.facility,
  });

  /// `LAB ORDER` or `IMAGING ORDER`, in the badge beside the title.
  final String kindLabel;

  /// `Priority: Routine`.
  final String priorityLabel;

  /// A short, stable handle for the order, derived from its id.
  final String reference;

  final String orderedOn;

  final String patientName;

  /// Null when the account has no date of birth on it — an empty row is
  /// honest, a made-up birthday on a medical order is not.
  final String? dateOfBirth;

  /// Imaging only.
  final String? modality;
  final String? bodyRegion;

  /// Why the doctor ordered it, written at request time.
  final String clinicalIndication;

  final String physicianName;
  final String? physicianSpecialty;

  /// The practitioner's licence number, from their verified profile.
  final String? licence;

  /// Where the patient chose to be tested, once they have.
  final String? facility;

  bool get isImaging => modality != null || bodyRegion != null;
}

/// What the doctor decided once they read the result.
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
