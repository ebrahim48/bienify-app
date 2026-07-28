/// Where a lab request currently sits.
enum LabRequestStatus { requestSent, inProgress, ready }

/// A diagnostic order raised by a doctor, surfaced at the top of the feed so
/// the patient can review and accept it.
class LabRequest {
  const LabRequest({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.requestedBy,
    this.status = LabRequestStatus.requestSent,
  });

  final String id;

  /// e.g. `Laboratory`.
  final String category;

  /// e.g. `Routine`.
  final String priority;

  /// e.g. `Complete Blood Count • CBC with Differential`.
  final String title;

  /// Ordering clinician, e.g. `Dr. Reed`.
  final String requestedBy;

  final LabRequestStatus status;
}
