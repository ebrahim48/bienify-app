import '../../features/Role/doctor_role/domain/entities/doctor_practice.dart';
import '../../features/Role/patient/appointments/domain/entities/appointment.dart';
import '../../features/Role/patient/doctors/domain/entities/doctor.dart';
import '../../features/Role/patient/home/domain/entities/home_feed.dart';
import '../../features/Role/patient/home/domain/entities/lab_request.dart';
import '../../features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import '../../features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import '../../features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';

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

/// The same booking as [appointmentFrom], seen from the other chair.
///
/// The patient's card names the doctor and the doctor's card names the
/// patient, and the two lists group by different things — the doctor's chips
/// are New / Completed / Cancelled, so a booking awaiting payment is still
/// "new" to them.
DoctorAppointment doctorAppointmentFrom(Map<String, dynamic> json) {
  final patientRef = json['patientId'];
  final name = Api.nameOf(patientRef, 'Patient');
  final status = Api.str(json['status']);
  final scheduledAt = Api.date(json['slotStart']);
  final fee = Api.majorUnits(json['feeMinor']);

  return DoctorAppointment(
    id: Api.id(json),
    patientName: name,
    initials: initialsOf(name),
    complaint: Api.str(json['reason'], 'Consultation'),
    scheduledAt: scheduledAt,
    filter: doctorApptFilterFrom(status),
    // The room opens on the hour and the server closes it at `slotEnd`; a
    // muted Join outside that window is what the design shows.
    isJoinable:
        status == 'confirmed' &&
        DateTime.now().isAfter(
          scheduledAt.subtract(const Duration(minutes: 10)),
        ) &&
        DateTime.now().isBefore(Api.date(json['slotEnd'])),
    photoUrl: Api.avatarOf(patientRef),
    fee: fee == 0 ? null : fee,
  );
}

/// The server's appointment states, collapsed to the doctor's three chips.
DoctorApptFilter doctorApptFilterFrom(String raw) => switch (raw) {
  'completed' => DoctorApptFilter.completed,
  'cancelled' || 'no_show' || 'refunded' => DoctorApptFilter.cancelled,
  _ => DoctorApptFilter.fresh,
};

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

// ─── Pharmacy owner ────────────────────────────────────────────────────────

/// The server's order states, collapsed to the six chips the shop filters by.
///
/// `ready` sits under Preparing rather than getting a chip of its own: to the
/// shop it is still an order it is working on, and the design draws six.
ShopOrderStatus shopOrderStatusFrom(String raw) => switch (raw) {
  'accepted' => ShopOrderStatus.accepted,
  'rejected' => ShopOrderStatus.declined,
  'preparing' || 'ready' => ShopOrderStatus.preparing,
  'out_for_delivery' => ShopOrderStatus.outForDelivery,
  'delivered' => ShopOrderStatus.delivered,
  _ => ShopOrderStatus.fresh,
};

/// The state a chip means when the shop moves an order into it.
String shopOrderStatusTo(ShopOrderStatus status) => switch (status) {
  ShopOrderStatus.fresh => 'placed',
  ShopOrderStatus.accepted => 'accepted',
  ShopOrderStatus.declined => 'rejected',
  ShopOrderStatus.preparing => 'preparing',
  ShopOrderStatus.outForDelivery => 'out_for_delivery',
  ShopOrderStatus.delivered => 'delivered',
};

/// `GET /pharmacies/me/orders` — a customer's order as the shop sees it.
///
/// The endpoint does not populate `patientId`, so there is no customer name to
/// print. The card falls back to the order code rather than labelling every
/// row "Customer", which would read as a name and be the same one on all of
/// them. See the note in `docs/API-GAPS.md`.
ShopOrder shopOrderFrom(Map<String, dynamic> json) {
  final id = Api.id(json);
  final code = 'ORD-${id.length >= 4 ? id.substring(id.length - 4) : id}'
      .toUpperCase();
  final name = Api.nameOf(json['patientId'], code);
  final placedAt = Api.date(json['createdAt']);

  return ShopOrder(
    id: id,
    // The server keeps no human-readable order number, so the row prints the
    // tail of the id — short enough to read out over the phone, and unique.
    code: code,
    customerName: name,
    initials: initialsOf(name),
    phone: Api.str(Api.map(json['patientId'])['phone']),
    address: Api.str(json['deliveryAddress']),
    placedAtLabel: _clockLabel(placedAt),
    status: shopOrderStatusFrom(Api.str(json['status'])),
    lines: Api.rows(json['items']).map(shopOrderLineFrom).toList(),
  );
}

OrderLine shopOrderLineFrom(Map<String, dynamic> json) => OrderLine(
  name: Api.str(json['name'], 'Medicine'),
  quantity: Api.integer(json['quantity'], 1),
  unitPrice: Api.majorUnits(json['unitPriceMinor']),
);

/// `10:32 AM`.
String _clockLabel(DateTime at) {
  final hour12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
  return '${hour12.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')} '
      '${at.hour < 12 ? 'AM' : 'PM'}';
}

/// `GET /medicines` — a product on the owner's shelf.
///
/// The server keeps no expiry date and no category; `brand` is the nearest
/// thing to the latter, and the row drops whichever it does not have.
ShopMedicine shopMedicineFrom(Map<String, dynamic> json) => ShopMedicine(
  id: Api.id(json),
  name: Api.str(json['name'], 'Medicine'),
  category: Api.str(json['brand']),
  expiryLabel: '',
  stock: Api.integer(json['stock']),
  price: Api.majorUnits(json['priceMinor']),
  isListed: json['isActive'] != false,
);

/// `GET /notifications` — a row of the shop's feed.
ShopNotification shopNotificationFrom(Map<String, dynamic> json) {
  final data = Api.map(json['data']);
  return ShopNotification(
    title: Api.str(json['title'], 'Notification'),
    body: Api.str(json['body']),
    reference: Api.str(data['reference'], Api.str(data['orderId'])),
    ageLabel: relativeAge(Api.date(json['createdAt'])),
  );
}

/// `1 day ago`, `3 hours ago`, `just now`.
String relativeAge(DateTime at) {
  final gap = DateTime.now().difference(at);
  if (gap.inMinutes < 1) return 'just now';
  if (gap.inHours < 1) return '${gap.inMinutes} minutes ago';
  if (gap.inDays < 1) {
    return '${gap.inHours} ${gap.inHours == 1 ? 'hour' : 'hours'} ago';
  }
  return '${gap.inDays} ${gap.inDays == 1 ? 'day' : 'days'} ago';
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
