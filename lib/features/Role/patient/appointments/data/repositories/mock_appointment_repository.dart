import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../static/appointment_mock_data.dart';

/// In-memory appointments, so the flow is walkable without a server and so
/// widget tests render a known list rather than whatever a database holds.
class MockAppointmentRepository implements AppointmentRepository {
  MockAppointmentRepository({DateTime Function() clock = DateTime.now})
    : _clock = clock;

  final DateTime Function() _clock;
  static const Duration _latency = Duration(milliseconds: 400);

  List<Appointment>? _items;

  List<Appointment> get _store =>
      _items ??= List.of(AppointmentMockData.all(now: _clock()));

  @override
  Future<List<Appointment>> list() async {
    await Future<void>.delayed(_latency);
    return List.of(_store);
  }

  @override
  Future<Appointment> book({
    required String doctorProfileId,
    required DateTime slotStart,
    required String type,
    String? reason,
  }) async {
    await Future<void>.delayed(_latency);
    final booked = Appointment(
      id: 'mock-${_store.length + 1}',
      doctorName: 'Dr Demo',
      specialty: type,
      scheduledAt: slotStart,
    );
    _store.add(booked);
    return booked;
  }

  @override
  Future<void> pay(String appointmentId) async =>
      Future<void>.delayed(_latency);

  @override
  Future<void> cancel(String appointmentId, {String? reason}) async {
    await Future<void>.delayed(_latency);
    final index = _store.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return;
    final existing = _store[index];
    _store[index] = Appointment(
      id: existing.id,
      doctorName: existing.doctorName,
      specialty: existing.specialty,
      scheduledAt: existing.scheduledAt,
      status: AppointmentStatus.cancelled,
      doctorPhotoUrl: existing.doctorPhotoUrl,
    );
  }

  @override
  Future<void> review({
    required String appointmentId,
    required int rating,
    String? comment,
  }) async => Future<void>.delayed(_latency);
}
