/// Lifecycle of a booking.
///
/// [pendingPayment] used to collapse into [upcoming] — the app had no way to
/// tell an unpaid booking from a confirmed one, so a pending-payment card
/// showed the same live "Join Visit" button a paid one does. Tapping it
/// reached the server, which correctly refuses ("Cannot join a consultation
/// that is pending_payment") — the patient's first and only sign that payment
/// was ever outstanding.
/// [closed] is a slot that came and went with neither side acting — the
/// server retires it rather than leaving it sitting under Upcoming forever.
enum AppointmentStatus { upcoming, pendingPayment, completed, cancelled, closed }

/// The three tabs on the Appointments screen.
enum AppointmentTab { upcoming, past, cancelled }

/// Opens Doctor Details to move a lapsed consultation rather than book a new
/// one.
///
/// Carried as a route argument so one screen serves both journeys: the slot
/// picker, the availability rules and the doctor's calendar are identical, and
/// a second copy of that screen would be a second set of rules to keep in
/// step. What differs is only what the confirm button does at the end.
class RescheduleRequest {
  const RescheduleRequest({required this.appointment});

  final Appointment appointment;
}

/// A date heading plus the appointments filed under it, e.g. `Today` or
/// `23 February`.
class AppointmentGroup {
  const AppointmentGroup({required this.label, required this.items});

  final String label;
  final List<Appointment> items;
}

/// How a consultation is held. The three the server accepts
/// (`appointment.model.ts:39`).
enum ConsultationType {
  video('video'),
  chat('chat'),
  inPerson('in_person');

  const ConsultationType(this.wire);

  /// What the API calls it. The enum doubles as the wire format so no mapping
  /// table can drift from it.
  final String wire;

  static ConsultationType fromWire(String? value) {
    for (final type in ConsultationType.values) {
      if (type.wire == value) return type;
    }
    // An unknown type is not a reason to fail a booking that already exists;
    // video is what the platform has always defaulted to.
    return ConsultationType.video;
  }

  /// Only a video or chat consultation has something to open at its hour.
  /// An in-person visit happens at the clinic.
  bool get isRemote => this != ConsultationType.inPerson;
}

/// A scheduled consultation.
class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.scheduledAt,
    this.status = AppointmentStatus.upcoming,
    this.doctorPhotoUrl,
    this.consultationFee = 0,
    this.doctorProfileId = '',
    this.doctorUserId = '',
    this.lapseChoice,
    this.isRefunded = false,
    this.isRescheduled = false,
    this.type = ConsultationType.video,
  });

  final String id;
  final String doctorName;
  final String specialty;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String? doctorPhotoUrl;

  /// How the consultation happens.
  ///
  /// Every booking used to be sent as `video` because there was no picker —
  /// so a patient who wanted to be seen in person, and a doctor who only
  /// consults that way, both got a video call neither had asked for.
  final ConsultationType type;

  /// What the consultation costs, in major units.
  ///
  /// The server decides the fee and sends it with the appointment, so the
  /// payment screen shows what will actually be charged rather than a figure
  /// the client worked out for itself.
  final double consultationFee;

  /// Needed to rebook with the same doctor when a lapsed consultation is
  /// rescheduled — the slot list is per doctor profile, not per booking.
  final String doctorProfileId;

  /// The doctor's *user* id, which is not [doctorProfileId].
  ///
  /// Needed to share a medical document with them: sharing is per-record and
  /// per-doctor, and it is the user the record is shared with. Empty when the
  /// payload carried the profile only.
  final String doctorUserId;

  /// What the patient chose after this lapsed: `refund`, `reschedule`, or null
  /// while they have not decided.
  final String? lapseChoice;

  final bool isRefunded;
  final bool isRescheduled;

  /// A lapsed consultation the patient has not yet resolved.
  ///
  /// Both remedies close it, which is why either flag is enough to stop
  /// offering the choice again.
  bool get needsLapseChoice =>
      status == AppointmentStatus.closed && !isRefunded && !isRescheduled;

  /// Waiting on the doctor to actually send the money back.
  bool get isRefundPending =>
      status == AppointmentStatus.closed && lapseChoice == 'refund' && !isRefunded;

  /// A video room only opens shortly before the slot, so the Join affordance
  /// is a property of the appointment rather than of the button.
  bool get canJoin =>
      status == AppointmentStatus.upcoming &&
      scheduledAt.difference(DateTime.now()) <= const Duration(minutes: 15);
}
