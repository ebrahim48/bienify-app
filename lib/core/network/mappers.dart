import '../../features/Role/patient/appointments/domain/entities/appointment.dart';
import '../../features/Role/patient/doctors/domain/entities/doctor.dart';
import '../../features/Role/patient/home/domain/entities/home_feed.dart';
import '../../features/Role/patient/home/domain/entities/lab_request.dart';

/// Turns backend documents into the entities the screens already render.
///
/// Kept in one place rather than spread across data sources because the same
/// document shows up in several features — a doctor appears in the home feed,
/// in search, and in a booking — and three hand-written copies of the same
/// mapping is three chances to disagree about which field holds the name.
///
/// Every accessor tolerates a missing or differently-typed value. Mongo
/// populates references only sometimes: `doctorUserId` is an id string on one
/// endpoint and an expanded object on another, and a screen should not crash
/// because a payload took the other shape.
class Api {
  Api._();

  static String id(dynamic v) {
    if (v is Map) return (v['_id'] ?? v['id'] ?? '').toString();
    return (v ?? '').toString();
  }

  static String str(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v.isEmpty ? fallback : v;
    return v.toString();
  }

  static int integer(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double decimal(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime date(dynamic v) {
    if (v is DateTime) return v;
    final parsed = DateTime.tryParse(v?.toString() ?? '');
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static Map<String, dynamic> map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : const {};

  static List<Map<String, dynamic>> rows(dynamic v) {
    if (v is! List) return const [];
    return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  /// The display name out of a populated user reference.
  static String nameOf(dynamic userRef, [String fallback = '']) {
    final user = map(userRef);
    final profile = map(user['profile']);
    return str(profile['name'], str(user['name'], fallback));
  }

  static String? avatarOf(dynamic userRef) {
    final profile = map(map(userRef)['profile']);
    final url =
        profile['avatarUrl'] ?? profile['photoUrl'] ?? profile['avatar'];
    final s = url?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// Money crosses the wire in minor units (integer cents) so no arithmetic
  /// ever happens in floating point. The UI wants a major-unit amount.
  static double majorUnits(dynamic minor) => integer(minor) / 100;
}

/// `GET /doctors` and the doctor entries embedded in other payloads.
Doctor doctorFrom(Map<String, dynamic> json) {
  final specialties = json['specialties'];
  final rating = Api.map(json['rating']);

  return Doctor(
    id: Api.id(json),
    name: Api.nameOf(json['userId'], 'Doctor'),
    // The server keeps a list; the card shows one.
    specialty: specialties is List && specialties.isNotEmpty
        ? Api.str(specialties.first)
        : Api.str(json['specialty'], 'General'),
    photoUrl: Api.avatarOf(json['userId']),
    rating: Api.decimal(rating['average']),
    reviewCount: Api.integer(rating['count']),
    consultationFee: Api.majorUnits(json['consultationFeeMinor']),
    isAvailable: json['isAcceptingPatients'] != false,
  );
}

/// The server's appointment states, collapsed to the three the UI groups by.
AppointmentStatus appointmentStatusFrom(String raw) => switch (raw) {
  'completed' => AppointmentStatus.completed,
  'cancelled' || 'no_show' || 'refunded' => AppointmentStatus.cancelled,
  _ => AppointmentStatus.upcoming,
};

Appointment appointmentFrom(Map<String, dynamic> json) {
  // `doctorUserId` arrives populated on the home feed and as a bare id on the
  // list endpoint, so fall back through both.
  final doctorRef = json['doctorUserId'] ?? json['doctorId'];
  final profile = Api.map(json['doctorProfileId']);
  final specialties = profile['specialties'];

  return Appointment(
    id: Api.id(json),
    doctorName: Api.nameOf(doctorRef, 'Doctor'),
    specialty: specialties is List && specialties.isNotEmpty
        ? Api.str(specialties.first)
        : Api.str(json['type'], 'Consultation'),
    scheduledAt: Api.date(json['slotStart']),
    status: appointmentStatusFrom(Api.str(json['status'])),
    doctorPhotoUrl: Api.avatarOf(doctorRef),
  );
}

LabRequestStatus labStatusFrom(String raw) => switch (raw) {
  'in_progress' || 'collected' || 'processing' => LabRequestStatus.inProgress,
  'ready' || 'completed' || 'resulted' => LabRequestStatus.ready,
  _ => LabRequestStatus.requestSent,
};

LabRequest labRequestFrom(Map<String, dynamic> json) {
  final tests = json['tests'];
  final title = tests is List && tests.isNotEmpty
      ? tests.map(Api.str).join(', ')
      : Api.str(json['title'], 'Lab test');

  return LabRequest(
    id: Api.id(json),
    category: Api.str(json['discipline'], 'Laboratory'),
    priority: Api.str(json['priority'], 'Routine'),
    title: title,
    requestedBy: Api.nameOf(json['requestedByDoctorId'], 'Your doctor'),
    status: labStatusFrom(Api.str(json['status'])),
  );
}

/// `GET /home/feed` — the whole patient home screen in one payload.
HomeFeed homeFeedFrom(Map<String, dynamic> json) => HomeFeed(
  patientName: Api.str(json['patientName']),
  location: Api.str(json['location']),
  labRequests: Api.rows(json['labRequests']).map(labRequestFrom).toList(),
  upcomingAppointments: Api.rows(
    json['upcomingAppointments'],
  ).map(appointmentFrom).toList(),
  nearbyDoctors: Api.rows(json['nearbyDoctors']).map(doctorFrom).toList(),
  unreadAppointments: Api.integer(json['unreadAppointments']),
  unreadMessages: Api.integer(json['unreadMessages']),
  unreadNotifications: Api.integer(json['unreadNotifications']),
);
