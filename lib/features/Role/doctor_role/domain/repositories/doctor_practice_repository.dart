import '../../../patient/medical_vault/domain/entities/medical_record.dart';
import '../entities/doctor_practice.dart';
import '../entities/test_request.dart';

/// Everything the practitioner screens read and write.
///
/// One repository for the whole role rather than one per screen: the doctor's
/// dashboard, appointment list, earnings and schedule are four views of the
/// same practice, and splitting them would mean four objects all holding the
/// same client and re-deriving the same profile.
abstract class DoctorPracticeRepository {
  /// Masthead, the four statistics, the load chart and today's visits.
  Future<DoctorDashboard> dashboard();

  /// Every booking the practitioner is party to, newest first.
  Future<List<DoctorAppointment>> appointments();

  /// What the patient attached to a booking.
  Future<List<UploadedDocument>> patientDocuments(String appointmentId);

  Future<void> cancelAppointment(String appointmentId, {String? reason});

  /// Sends the fee back for a consultation that lapsed without happening.
  ///
  /// Only valid on a `closed` booking the practitioner is the doctor for, and
  /// only once — the server refuses a second attempt.
  Future<void> refundAppointment(String appointmentId);

  Future<DoctorEarnings> earnings();

  Future<List<PayoutAccount>> payoutAccounts();

  /// Files the account a withdrawal can be paid into.
  ///
  /// Without this the payout flow is a dead end: a withdrawal must name an
  /// account the server holds, and nothing else in the app creates one.
  /// [kind] is `bank` or `mobile_money`, as the server names them.
  Future<void> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  });

  /// [amount] is in major units; the server is told minor units.
  Future<void> requestWithdrawal({
    required double amount,
    String? payoutAccountId,
  });

  Future<DoctorProfileDetails> profileDetails();

  Future<void> saveProfileDetails({
    required String specialty,
    required String experience,
    required String biography,
    required String licenceNumber,
    required String language,
  });

  Future<void> saveConsultationFee({
    required double amount,
    required String currency,
  });

  /// The seven days of the week containing [anchor].
  Future<List<ScheduleDay>> availability(DateTime anchor);

  Future<void> saveAvailability(List<ScheduleDay> days);

  /// Sends a script to the patient of [appointmentId].
  Future<void> prescribe({
    required String appointmentId,
    required List<PrescribedMedicine> medicines,
  });

  /// The practitioner's message threads, newest activity first.
  Future<List<PatientThread>> threads();

  /// The patients this practitioner has consulted, as Results to Review lists
  /// them — one entry per person, not one per booking.
  Future<List<ReviewPatient>> reviewPatients();

  /// Orders lab or imaging work for a patient.
  Future<void> orderTest({
    required String patientId,
    required List<String> tests,
    String? notes,
    String? appointmentId,
  });

  /// The lab orders this practitioner requested, newest first.
  ///
  /// `GET /lab-orders` answers "orders I am the subject of" by default; a
  /// doctor asks the same endpoint the opposite question with `role=doctor`.
  Future<List<TestRequest>> labRequests();

  /// Leaves [message] for the patient and marks [labOrderId] reviewed.
  ///
  /// Only valid once the lab has actually finished the order — there is
  /// nothing to review before that — and only for an order this practitioner
  /// requested themselves.
  Future<void> reviewLabOrder({required String labOrderId, required String message});
}
