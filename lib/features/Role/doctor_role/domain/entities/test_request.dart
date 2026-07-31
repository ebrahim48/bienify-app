/// Shapes behind Results to Review — the practitioner's test-ordering and
/// result-review flow.
///
/// **Names only, by design.** Like the rest of the doctor section this is
/// UI-first: no repository, use case or data source sits under it.
library;

/// Which of the three segments of Results to Review is showing.
enum ResultsTab { patients, labRequests, radiologyRequests }

/// The chip row under the Lab / Radiology segments.
enum RequestFilter { all, inProgress, toReview, resultsReady }

/// Whether an order goes to a laboratory or an imaging department. The whole
/// request wizard is one screen; this is what it switches on.
enum OrderKind { lab, radiology }

/// How soon the test is needed.
enum OrderPriority { routine, urgent, stat }

/// Where an order has reached. The detail screen's tracker prints these in
/// order and fills every circle up to [TestRequest.stage].
enum OrderStage {
  ordered,
  facilitySelected,
  testCompleted,
  resultsReceived,
  reviewed,
}

/// The pill on a request card.
enum RequestStatus { requestSent, awaitingReview, reviewed }

/// What the doctor decides to do once results are in.
enum ReviewOption { messagePatient, followUpVisit, additionalTest, refer }

/// A patient in the Patients segment, and the subject of every order.
class ReviewPatient {
  const ReviewPatient({
    required this.id,
    required this.name,
    required this.code,
    required this.age,
    required this.gender,
    required this.complaint,
    required this.seenOn,
    this.photoAsset,
  });

  final String id;
  final String name;

  /// `CXR-2` — the study code the row prints under the name.
  final String code;

  final int age;

  /// `Female`, printed beside the age under the title.
  final String gender;

  /// `Persistent chest pain` — why they came.
  final String complaint;

  final DateTime seenOn;
  final String? photoAsset;

  /// `34 • Female`.
  String get ageGenderLine => '$age • $gender';

  /// `Jul 12, 2026`, hand-formatted like every other date in the app.
  String get seenOnLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[seenOn.month - 1]} ${seenOn.day}, ${seenOn.year}';
  }
}

/// One ordered test, from the request through to the doctor's review.
class TestRequest {
  const TestRequest({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.status,
    required this.stage,
    required this.patient,
    required this.orderedOn,
    this.isCritical = false,
    this.hospitalName,
    this.hospitalAddress,
    this.clinicalNotes,
    this.documentAsset,
  });

  final String id;
  final OrderKind kind;

  /// `Cardiac Markers`.
  final String title;

  /// `Troponin I` — the subtest, printed underneath.
  final String subtitle;

  final OrderPriority priority;
  final RequestStatus status;
  final OrderStage stage;
  final ReviewPatient patient;
  final DateTime orderedOn;

  /// Draws the red "Critical" pill beside the status.
  final bool isCritical;

  /// Where the patient chose to be tested. Null until they have chosen, which
  /// is what the detail screen's "Awaiting patient upload" state means.
  final String? hospitalName;
  final String? hospitalAddress;

  final String? clinicalNotes;

  /// The report the patient uploaded, once there is one.
  final String? documentAsset;

  bool get hasResults => documentAsset != null;

  /// `Ordered 20/07/2026`, hand-formatted like every other date in the app.
  String get orderedOnLabel =>
      '${orderedOn.day.toString().padLeft(2, '0')}/'
      '${orderedOn.month.toString().padLeft(2, '0')}/'
      '${orderedOn.year}';
}
