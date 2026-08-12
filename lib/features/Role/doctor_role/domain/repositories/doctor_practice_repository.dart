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

  Future<DoctorEarnings> earnings();

  Future<List<PayoutAccount>> payoutAccounts();

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
}
