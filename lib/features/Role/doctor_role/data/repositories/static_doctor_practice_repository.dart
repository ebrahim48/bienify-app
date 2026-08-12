import '../../../patient/medical_vault/domain/entities/medical_record.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/entities/test_request.dart';
import '../../domain/repositories/doctor_practice_repository.dart';
import '../static/doctor_orders_data.dart';
import '../static/doctor_practice_data.dart';

/// The practice, served from the design's sample data.
///
/// Golden and widget tests assert on rendering; a screen that reaches for a
/// real server would make them depend on a backend being up and on whatever
/// happens to be in its database that day. Writes are accepted and dropped —
/// the screens already show their own confirmation.
class StaticDoctorPracticeRepository implements DoctorPracticeRepository {
  const StaticDoctorPracticeRepository();

  @override
  Future<DoctorDashboard> dashboard() async => DoctorDashboard(
    practitioner: DoctorPracticeData.practitioner,
    pendingRequests: DoctorPracticeData.pendingRequests,
    todaysPatients: DoctorPracticeData.todaysPatients,
    totalEarned: DoctorPracticeData.totalEarned,
    totalPatients: DoctorPracticeData.totalPatients,
    load: List.of(DoctorPracticeData.weeklyLoad),
    visits: List.of(DoctorPracticeData.upcomingVisits),
    consultationFee: 440,
    currency: 'CAD',
  );

  @override
  Future<List<DoctorAppointment>> appointments() async =>
      DoctorPracticeData.appointments();

  @override
  Future<List<UploadedDocument>> patientDocuments(String appointmentId) async =>
      DoctorPracticeData.patientDocuments();

  @override
  Future<void> cancelAppointment(
    String appointmentId, {
    String? reason,
  }) async {}

  @override
  Future<DoctorEarnings> earnings() async => DoctorEarnings(
    availableLabel: DoctorPracticeData.availableBalanceLabel,
    totalEarnedLabel: DoctorPracticeData.totalEarnedLabel,
    paidOutLabel: DoctorPracticeData.paidOutLabel,
    consultations: DoctorPracticeData.earnings(),
  );

  @override
  Future<List<PayoutAccount>> payoutAccounts() async => const [];

  @override
  Future<void> requestWithdrawal({
    required double amount,
    String? payoutAccountId,
  }) async {}

  @override
  Future<DoctorProfileDetails> profileDetails() async =>
      const DoctorProfileDetails(
        fullName: 'Tamim',
        email: 'alex@gmail.com',
        specialty: 'General Practice',
        experience: '8',
        biography: '',
        licenceNumber: '',
        language: 'en',
        consultationFee: 440,
        currency: 'USD',
      );

  @override
  Future<void> saveProfileDetails({
    required String specialty,
    required String experience,
    required String biography,
    required String licenceNumber,
    required String language,
  }) async {}

  @override
  Future<void> saveConsultationFee({
    required double amount,
    required String currency,
  }) async {}

  @override
  Future<List<ScheduleDay>> availability(DateTime anchor) async =>
      DoctorPracticeData.week();

  @override
  Future<void> saveAvailability(List<ScheduleDay> days) async {}

  @override
  Future<void> prescribe({
    required String appointmentId,
    required List<PrescribedMedicine> medicines,
  }) async {}

  @override
  Future<List<PatientThread>> threads() async =>
      List.of(DoctorPracticeData.threads);

  @override
  Future<List<ReviewPatient>> reviewPatients() async =>
      List.of(DoctorOrdersData.patients);

  @override
  Future<void> orderTest({
    required String patientId,
    required List<String> tests,
    String? notes,
    String? appointmentId,
  }) async {}
}
