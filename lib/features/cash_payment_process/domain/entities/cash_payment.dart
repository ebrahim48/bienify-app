/// Shapes used by the Cash Payment Process screens.
///
/// **Names only, by design.** This feature is UI-first: there is no
/// repository, use case or data source here, and nothing talks to an API.
/// The models below exist so the widgets have typed inputs and so the swap to
/// live data later is a matter of filling these in from a backend rather than
/// rewriting the screens.
library;

/// One numbered instruction in the "How to Payment Works" list.
class PaymentStep {
  const PaymentStep({required this.title, required this.description});

  final String title;
  final String description;
}

/// The cash code the patient shows at an agent.
class PaymentCode {
  const PaymentCode({
    required this.code,
    required this.amountLabel,
    required this.itemsLabel,
    required this.validFor,
    required this.expiresAt,
  });

  /// Displayed with its leading `#`, e.g. `#BIE12345`.
  final String code;

  /// Pre-formatted total, e.g. `$74.89`.
  final String amountLabel;

  /// What is being paid for, e.g. `$74.89 · 6 medicines`.
  final String itemsLabel;

  /// How long the code stays valid, in hours.
  final int validFor;

  /// When the countdown reaches zero.
  final DateTime expiresAt;
}

/// The kind of place a payment can be made, which selects the map and list
/// icon.
enum PaymentPointKind { agent, bank, store, pharmacy, postOffice }

/// Which glyph a booking-detail row shows.
enum BookingDetailKind { orderId, date, delivery, pharmacy, prescription }

/// One labelled row in the confirmation's booking summary.
class BookingDetail {
  const BookingDetail({
    required this.kind,
    required this.label,
    required this.value,
  });

  final BookingDetailKind kind;

  /// Translation key for the left-hand label.
  final String label;

  /// Already-formatted value, e.g. `Today • 25—35 min`.
  final String value;
}

/// A dispensed item on the confirmation receipt.
class MedicineLine {
  const MedicineLine({
    required this.name,
    required this.dosage,
    required this.quantity,
    required this.priceLabel,
  });

  final String name;

  /// e.g. `500mg`.
  final String dosage;

  final int quantity;

  /// e.g. `$12.50`.
  final String priceLabel;
}

/// Everything the Payment Confirmed screen renders.
class PaymentConfirmation {
  const PaymentConfirmation({
    required this.details,
    required this.medicines,
    required this.totalLabel,
    required this.paidViaLabel,
  });

  final List<BookingDetail> details;
  final List<MedicineLine> medicines;

  /// e.g. `$74.89`.
  final String totalLabel;

  /// e.g. `Paid via Cash at Agent • Code #BIE12345`.
  final String paidViaLabel;
}

/// A place that accepts the cash code.
class PaymentPoint {
  const PaymentPoint({
    required this.id,
    required this.name,
    required this.kind,
    required this.distanceLabel,
    required this.hoursLabel,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final PaymentPointKind kind;

  /// Pre-formatted distance, e.g. `0.3 km`.
  final String distanceLabel;

  /// Opening hours, e.g. `8:00 AM — 10:00 PM`.
  final String hoursLabel;

  final bool isOpen;

  final double latitude;
  final double longitude;
}
