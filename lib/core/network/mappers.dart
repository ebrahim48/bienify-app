import '../../features/Role/doctor_role/domain/entities/doctor_practice.dart';
import '../../features/Role/patient/appointments/domain/entities/appointment.dart';
import '../../features/Role/patient/cash_payment_process/domain/entities/cash_payment.dart';
import '../../features/Role/patient/cash_payment_process/domain/repositories/cash_payment_repository.dart';
import '../../features/Role/patient/chat/domain/entities/conversation.dart';
import '../../features/Role/patient/doctors/domain/entities/doctor.dart';
import '../../features/Role/patient/home/domain/entities/home_feed.dart';
import '../../features/Role/patient/home/domain/entities/lab_request.dart';
import '../../features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import '../../features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import '../../features/Role/patient/profile/domain/entities/profile.dart';
import '../../features/Role/pharmacy_owner_role/domain/entities/pharmacy_shop.dart';
import '../../features/Role/rider_role/domain/entities/rider.dart';

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

// ─── Rider ─────────────────────────────────────────────────────────────────

/// `GET /deliveries/available` and `/riders/me/deliveries` — a job.
///
/// A delivery document carries an order id, two addresses and a status.
/// It carries no fee, no line items, no distance and no customer, and neither
/// list populates its references — so those fields come back empty and the
/// card drops them. See `docs/API-GAPS.md`.
DeliveryRequest deliveryRequestFrom(Map<String, dynamic> json) {
  final orderId = Api.id(json['orderId']);
  final status = Api.str(json['status']);

  return DeliveryRequest(
    id: Api.id(json),
    code:
        'ORD-${orderId.length >= 4 ? orderId.substring(orderId.length - 4) : orderId}'
            .toUpperCase(),
    fee: 0,
    pickupName: Api.str(json['pickupAddress']),
    customerName: Api.nameOf(json['patientId']),
    customerAddress: Api.str(json['dropoffAddress']),
    minutes: 0,
    distanceKm: 0,
    items: '',
    tab: requestTabFrom(status),
  );
}

/// The server's delivery states, collapsed to the three chips above the list.
///
/// A job the courier is carrying and one they have finished both sit under
/// Accepted: the chips separate work they could take from work they took, not
/// how far along it is.
RequestTab requestTabFrom(String raw) => switch (raw) {
  'assigned' ||
  'picked_up' ||
  'in_transit' ||
  'delivered' => RequestTab.accepted,
  'failed' => RequestTab.cancelled,
  _ => RequestTab.fresh,
};

/// A credited wallet transaction, as the courier's history lists it.
DeliveryRecord deliveryRecordFrom(Map<String, dynamic> json) {
  final at = Api.date(json['createdAt']);
  final name = Api.str(json['description'], 'Delivery');
  final reference = Api.id(json['referenceId']);

  return DeliveryRecord(
    customerName: name,
    initials: initialsOf(name),
    whenLabel: _whenLabel(at),
    fee: Api.majorUnits(json['amountMinor']),
    orderCode:
        'ORD-${reference.length >= 4 ? reference.substring(reference.length - 4) : reference}'
            .toUpperCase(),
  );
}

/// `Today, 10:42 AM` for today, `12 Aug, 10:42 AM` otherwise.
String _whenLabel(DateTime at) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final now = DateTime.now();
  final isToday =
      at.year == now.year && at.month == now.month && at.day == now.day;
  final day = isToday ? 'Today' : '${at.day} ${months[at.month - 1]}';
  return '$day, ${_clockLabel(at)}';
}

// ─── Wallet and order history ──────────────────────────────────────────────

/// `GET /wallet/cards` — a saved card.
WalletCard walletCardFrom(Map<String, dynamic> json) {
  final month = Api.integer(json['expiryMonth']);
  final year = Api.integer(json['expiryYear']);

  return WalletCard(
    id: Api.id(json),
    brand: Api.str(json['brand'], 'Card'),
    // Only the last four are stored, which is the whole point of tokenising.
    maskedNumber: '•••• ${Api.str(json['last4'], '••••')}',
    expiry:
        '${month.toString().padLeft(2, '0')}/'
        '${year.toString().padLeft(4, '0').substring(2)}',
    isDefault: json['isDefault'] == true,
  );
}

/// `GET /wallet/transactions` — one movement.
WalletTransaction walletTransactionFrom(Map<String, dynamic> json) =>
    WalletTransaction(
      id: Api.id(json),
      title: Api.str(json['description'], _transactionTitle(json)),
      occurredOn: Api.date(json['createdAt']),
      amount: Api.majorUnits(json['amountMinor']),
      kind: Api.str(json['direction']) == 'debit'
          ? TransactionKind.debit
          : TransactionKind.credit,
    );

/// A readable name for a movement the server did not describe.
String _transactionTitle(Map<String, dynamic> json) =>
    Api.str(json['type']).replaceAll('_', ' ');

/// The server's medicine-order states, collapsed to the three the history
/// groups by.
OrderState orderStateFrom(String raw) => switch (raw) {
  'delivered' => OrderState.delivered,
  'cancelled' || 'rejected' => OrderState.cancelled,
  _ => OrderState.inProgress,
};

/// `GET /medicine-orders` — a row of My Order History.
OrderHistoryEntry orderHistoryEntryFrom(Map<String, dynamic> json) {
  final id = Api.id(json);
  final items = Api.rows(json['items']);

  return OrderHistoryEntry(
    id: id,
    reference: '#${id.length >= 6 ? id.substring(id.length - 6) : id}'
        .toUpperCase(),
    storeName: Api.str(Api.map(json['pharmacyId'])['name'], 'Pharmacy'),
    placedOn: Api.date(json['createdAt']),
    // Units ordered, not lines: two boxes of one medicine is two items.
    itemCount: items.fold(0, (n, i) => n + Api.integer(i['quantity'], 1)),
    total: Api.majorUnits(json['totalMinor']),
    state: orderStateFrom(Api.str(json['status'])),
  );
}

// ─── Cash payment ──────────────────────────────────────────────────────────

/// `GET /payment-points` — a counter that accepts a cash code.
///
/// The server keeps no coordinates and no kind, so every point maps to an
/// agent and the map has nothing to place it at. See `docs/API-GAPS.md`.
PaymentPoint paymentPointFrom(Map<String, dynamic> json) => PaymentPoint(
  id: Api.id(json),
  name: Api.str(json['name'], 'Payment point'),
  kind: PaymentPointKind.agent,
  // Distance needs the patient's position and the point's; neither is here.
  distanceLabel: Api.str(json['city']),
  hoursLabel: Api.str(json['openingHours']),
  isOpen: json['isActive'] != false,
  latitude: Api.decimal(json['latitude']),
  longitude: Api.decimal(json['longitude']),
);

/// `POST /cash-intents` — an issued code.
PaymentCode paymentCodeFrom(Map<String, dynamic> json) {
  final amount = Api.majorUnits(json['amountMinor']);
  final expiresAt = Api.date(json['expiresAt']);
  final label = '\$${amount.toStringAsFixed(2)}';

  return PaymentCode(
    code: '#${Api.str(json['reference'])}',
    amountLabel: label,
    itemsLabel: label,
    // Read back from the expiry the server set rather than assumed: the two
    // disagreeing is what makes a countdown outlive its code.
    validFor: expiresAt.difference(Api.date(json['createdAt'])).inHours,
    expiresAt: expiresAt,
  );
}

CashIntentState cashIntentStateFrom(String raw) => switch (raw) {
  'confirmed' => CashIntentState.confirmed,
  'expired' => CashIntentState.expired,
  'cancelled' => CashIntentState.cancelled,
  _ => CashIntentState.pending,
};

// ─── Messaging ─────────────────────────────────────────────────────────────

/// `GET /consultations/:id/messages` — one bubble.
///
/// The payload says who sent it, not whether that was you, so the side of the
/// thread it sits on is decided by comparing the sender to [myUserId].
ChatMessage chatMessageFrom(Map<String, dynamic> json, String myUserId) =>
    ChatMessage(
      id: Api.id(json),
      text: Api.str(json['body']),
      sentAt: Api.date(json['createdAt']),
      author: Api.id(json['senderId']) == myUserId
          ? MessageAuthor.patient
          : MessageAuthor.doctor,
    );

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
