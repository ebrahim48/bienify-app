import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

/// Appointments, served by the API.
class ApiAppointmentRepository implements AppointmentRepository {
  const ApiAppointmentRepository(this._api);

  final ApiClient _api;

  /// The server caps a page at 100. A patient with more appointments than that
  /// would need paging in the UI, which the design does not have — so the
  /// oldest fall off rather than the screen silently showing a partial list
  /// it claims is complete.
  static const int _pageSize = 100;

  @override
  Future<List<Appointment>> list() async {
    final rows = await _api.getList(
      ApiConstants.appointments,
      query: {'role': 'patient', 'limit': _pageSize},
    );
    final items = rows.map(appointmentFrom).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return items;
  }

  @override
  Future<Appointment> book({
    required String doctorProfileId,
    required DateTime slotStart,
    String? reason,
  }) async {
    // No `type`: a booking no longer picks a channel. The server defaults the
    // column so rows written before this still read, and the consultation is
    // reached the same way whatever it holds — a thread the two of them can
    // message in and call from.
    final data = await _api.postMap(
      ApiConstants.postAppointments,
      body: {
        'doctorProfileId': doctorProfileId,
        'slotStart': slotStart.toUtc().toIso8601String(),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return appointmentFrom(data);
  }

  @override
  Future<void> pay(String appointmentId) async {
    // The fee and the commission split are the server's to decide; sending an
    // amount from here would let a client name its own price.
    await _api.post(ApiConstants.postPaymentsAppointmentsPay(appointmentId));
  }

  @override
  Future<void> complete(String appointmentId) async {
    await _api.post(ApiConstants.postAppointmentsComplete(appointmentId));
  }

  @override
  Future<void> cancel(String appointmentId, {String? reason}) async {
    await _api.post(
      ApiConstants.postAppointmentsCancel(appointmentId),
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }

  @override
  Future<void> requestRefund(String appointmentId) async {
    await _api.post(ApiConstants.postAppointmentsRequestRefund(appointmentId));
  }

  @override
  Future<Appointment> reschedule({
    required String appointmentId,
    required DateTime slotStart,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postAppointmentsReschedule(appointmentId),
      // UTC, like every other slot the app sends: the server matches the
      // instant against the doctor's calendar, and a local-time string would
      // land on a slot they never offered.
      body: {'slotStart': slotStart.toUtc().toIso8601String()},
    );
    return appointmentFrom(Api.map(data['replacement']));
  }

  @override
  Future<void> review({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async {
    await _api.post(
      ApiConstants.postReviews,
      body: {
        'subjectKind': 'doctor',
        'transactionId': appointmentId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }
}
