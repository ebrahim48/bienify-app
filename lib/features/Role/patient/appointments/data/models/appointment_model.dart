import '../../domain/entities/appointment.dart';

/// Serialisation layer for [Appointment].
class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.doctorName,
    required super.specialty,
    required super.scheduledAt,
    super.status,
    super.doctorPhotoUrl,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      doctorName: json['doctor_name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      // `.toLocal()`: a UTC instant read for its `.hour` prints someone
      // else's clock. Same reason as `Api.date`.
      scheduledAt:
          DateTime.tryParse(json['scheduled_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      status: _statusFrom(json['status'] as String?),
      doctorPhotoUrl: json['doctor_photo_url'] as String?,
    );
  }

  static AppointmentStatus _statusFrom(String? value) {
    return switch (value) {
      'completed' => AppointmentStatus.completed,
      'cancelled' => AppointmentStatus.cancelled,
      _ => AppointmentStatus.upcoming,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctor_name': doctorName,
    'specialty': specialty,
    'scheduled_at': scheduledAt.toIso8601String(),
    'status': status.name,
    'doctor_photo_url': doctorPhotoUrl,
  };
}
