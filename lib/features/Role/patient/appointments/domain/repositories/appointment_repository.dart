import '../entities/appointment.dart';

/// Booking, attending and settling appointments.
abstract class AppointmentRepository {
  /// Every appointment for the signed-in patient, across all three tabs.
  ///
  /// Fetched in one call rather than per tab: the tabs are a filter over the
  /// same list, and three calls would let them disagree about what exists.
  Future<List<Appointment>> list();

  /// Reserves [slotStart] with a doctor.
  ///
  /// Throws a `ConflictException` if someone else took the slot first — the
  /// server claims it atomically, so two patients cannot both win.
  Future<Appointment> book({
    required String doctorProfileId,
    required DateTime slotStart,
    required String type,
    String? reason,
  });

  /// Pays the consultation fee from the patient's wallet.
  Future<void> pay(String appointmentId);

  Future<void> cancel(String appointmentId, {String? reason});

  /// Closes the consultation once it has been held.
  ///
  /// The doctor's own action: nothing else moves a booking off
  /// `in_progress`, so without it a consultation already given sits in
  /// their New list for ever, still offering to be joined.
  Future<void> complete(String appointmentId);

  /// Rates the doctor seen at [appointmentId].
  ///
  /// Keyed by the appointment rather than the doctor so nobody can rate a
  /// doctor they never saw.
  Future<void> review({
    required String appointmentId,
    required int rating,
    String? comment,
  });
}
