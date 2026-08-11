import '../../features/Role/patient/appointments/domain/entities/appointment.dart';
import '../../features/Role/patient/doctors/domain/entities/doctor.dart';
import '../../features/Role/patient/home/domain/entities/home_feed.dart';
import '../../features/Role/patient/home/domain/entities/lab_request.dart';
import '../../features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import '../../features/Role/patient/pharmacy/domain/entities/pharmacy.dart';

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
    consultationFee: Api.majorUnits(json['feeMinor']),
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

// ─── Pharmacy ───────────────────────────────────────────────────────────────

/// `GET /medicines`.
Medicine medicineFrom(Map<String, dynamic> json) => Medicine(
  id: Api.id(json),
  name: Api.str(json['name'], 'Medicine'),
  // The catalogue keeps the strength inside the name ("Amoxicillin 250mg")
  // rather than as its own field, so the card's second line comes from what
  // the row actually carries: whether a script is needed.
  dosage: json['requiresPrescription'] == true
      ? 'Prescription required'
      : 'Over the counter',
  price: Api.majorUnits(json['priceMinor']),
  packSize: json['packSize'] == null ? null : Api.str(json['packSize']),
  // Out of stock is not the same as delisted; both make the row unbuyable.
  isAvailable: json['isActive'] != false && Api.integer(json['stock']) > 0,
);

/// `GET /pharmacies`.
///
/// Distance, ETA, basket price and stock coverage are all relative to a
/// basket and a location the server is not told about, so they are left empty
/// rather than invented — a fabricated "1.2 km" is worse than a blank.
PharmacyStore pharmacyFrom(Map<String, dynamic> json) {
  final rating = Api.map(json['rating']);
  final city = Api.str(json['city']);
  final line = Api.str(json['addressLine']);

  return PharmacyStore(
    id: Api.id(json),
    name: Api.str(json['name'], 'Pharmacy'),
    address: [line, city].where((s) => s.isNotEmpty).join(', '),
    distanceLabel: '',
    rating: Api.decimal(rating['average']),
    reviewCount: Api.integer(rating['count']),
    etaLabel: json['isOpen'] == false ? 'Closed' : '',
    price: 0,
    availableCount: 0,
    totalCount: 0,
  );
}

/// One line of a `GET /medicine-orders` row.
CartLine orderLineFrom(Map<String, dynamic> json) => CartLine(
  medicine: Medicine(
    id: Api.id(json['medicineId']),
    name: Api.str(json['name'], 'Medicine'),
    dosage: '',
    price: Api.majorUnits(json['unitPriceMinor']),
  ),
  quantity: Api.integer(json['quantity'], 1),
);

// ─── Medical vault ──────────────────────────────────────────────────────────

Medication medicationFrom(Map<String, dynamic> json) {
  final days = Api.integer(json['durationDays']);
  return Medication(
    name: Api.str(json['medicineName'], 'Medicine'),
    dosage: Api.str(json['dosage']),
    frequency: Api.str(json['frequency']),
    instructions: Api.str(json['instructions']),
    durationLabel: days > 0 ? '$days day${days == 1 ? '' : 's'}' : '',
  );
}

/// `GET /prescriptions`.
DigitalPrescription prescriptionFrom(Map<String, dynamic> json) {
  final id = Api.id(json);
  final expires = Api.date(json['expiresAt']);

  return DigitalPrescription(
    id: id,
    // The server has no human reference number, so the tail of the id is used
    // rather than a made-up one that would not match anything on the record.
    reference: id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id,
    doctorName: Api.nameOf(json['doctorUserId'], 'Your doctor'),
    specialty: Api.str(json['specialty']),
    issuedOn: Api.date(json['createdAt']),
    diagnosis: Api.str(json['diagnosis']),
    medications: Api.rows(json['items']).map(medicationFrom).toList(),
    // A prescription past its expiry no longer unlocks a pharmacy order, so
    // the badge has to say so rather than showing it as usable.
    state: expires.isAfter(DateTime.now())
        ? PrescriptionState.active
        : PrescriptionState.expired,
  );
}

/// Where a lab order has reached, in the four stages the screen shows.
TestStage testStageFrom(String raw) => switch (raw) {
  'sample_collected' => TestStage.awaitingUpload,
  'processing' => TestStage.awaitingReview,
  'completed' => TestStage.reviewed,
  _ => TestStage.requestSent,
};

/// `GET /lab-orders`.
TestOrder testOrderFrom(Map<String, dynamic> json) {
  final tests = json['tests'];
  final discipline = Api.str(json['discipline'], 'laboratory');

  return TestOrder(
    id: Api.id(json),
    discipline: discipline == 'radiology'
        ? ResultDiscipline.radiology
        : ResultDiscipline.laboratory,
    category: Api.str(json['category'], 'Diagnostics'),
    priority: Api.str(json['priority'], 'Routine'),
    title: tests is List && tests.isNotEmpty
        ? tests.map(Api.str).join(', ')
        : Api.str(json['title'], 'Test'),
    orderedBy: Api.nameOf(json['requestedByDoctorId'], 'Your doctor'),
    stage: testStageFrom(Api.str(json['status'])),
    facility: json['facility'] == null ? null : Api.str(json['facility']),
  );
}

/// `GET /testing-centres`.
TestingCentre testingCentreFrom(Map<String, dynamic> json) {
  final city = Api.str(json['city']);
  final line = Api.str(json['addressLine']);
  return TestingCentre(
    id: Api.id(json),
    name: Api.str(json['name'], 'Testing centre'),
    address: [line, city].where((s) => s.isNotEmpty).join(', '),
    // The server holds no coordinates for the caller to measure against.
    distanceLabel: '',
  );
}

/// `GET /vault` — a stored document.
UploadedDocument vaultRecordFrom(Map<String, dynamic> json) => UploadedDocument(
  id: Api.id(json),
  fileName: Api.str(json['title'], 'Document'),
  kindLabel: _recordTypeLabel(Api.str(json['type'])),
  uploadedOn: Api.date(json['recordedAt'] ?? json['createdAt']),
);

String _recordTypeLabel(String type) => switch (type) {
  'lab_report' => 'Lab report',
  'imaging' => 'Imaging',
  'prescription_scan' => 'Prescription',
  'discharge_summary' => 'Discharge summary',
  'vaccination' => 'Vaccination',
  _ => 'Document',
};
