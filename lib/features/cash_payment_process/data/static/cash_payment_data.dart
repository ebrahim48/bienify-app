import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/cash_payment.dart';

/// The content the Cash Payment Process screens render.
///
/// Static on purpose — this feature is UI-only for now. Point the controllers
/// at a repository when the endpoints exist; the widgets will not change.
class CashPaymentData {
  CashPaymentData._();

  /// Translation keys for the four numbered instructions.
  static const List<PaymentStep> steps = [
    PaymentStep(
      title: AppStrings.payStep1Title,
      description: AppStrings.payStep1Body,
    ),
    PaymentStep(
      title: AppStrings.payStep2Title,
      description: AppStrings.payStep2Body,
    ),
    PaymentStep(
      title: AppStrings.payStep3Title,
      description: AppStrings.payStep3Body,
    ),
    PaymentStep(
      title: AppStrings.payStep4Title,
      description: AppStrings.payStep4Body,
    ),
  ];

  static const int validForHours = 24;

  static PaymentCode code({String amountLabel = '\$74.89'}) => PaymentCode(
    code: '#BIE12345',
    amountLabel: amountLabel,
    itemsLabel: '$amountLabel · 6 medicines',
    validFor: validForHours,
    expiresAt: DateTime.now().add(const Duration(hours: validForHours)),
  );

  /// The receipt shown once an agent confirms the cash payment.
  static PaymentConfirmation confirmation({
    String totalLabel = '\$74.89',
    String code = '#BIE12345',
  }) => PaymentConfirmation(
    details: const [
      BookingDetail(
        kind: BookingDetailKind.orderId,
        label: AppStrings.orderId,
        value: '#RX8841',
      ),
      BookingDetail(
        kind: BookingDetailKind.date,
        label: AppStrings.date,
        value: 'Jul 13, 2026',
      ),
      BookingDetail(
        kind: BookingDetailKind.delivery,
        label: AppStrings.estimatedDelivery,
        value: 'Today • 25—35 min',
      ),
      BookingDetail(
        kind: BookingDetailKind.pharmacy,
        label: AppStrings.pharmacyLabel,
        value: 'MediQuick Pharmacy',
      ),
      BookingDetail(
        kind: BookingDetailKind.prescription,
        label: AppStrings.prescription,
        value: 'Dr. Sarah Mitchell',
      ),
    ],
    medicines: const [
      MedicineLine(
        name: 'Amoxicillin',
        dosage: '500mg',
        quantity: 1,
        priceLabel: '\$12.50',
      ),
      MedicineLine(
        name: 'Metformin',
        dosage: '850mg',
        quantity: 1,
        priceLabel: '\$8.90',
      ),
      MedicineLine(
        name: 'Lisinopril',
        dosage: '10mg',
        quantity: 1,
        priceLabel: '\$15.20',
      ),
      MedicineLine(
        name: 'Atorvastatin',
        dosage: '20mg',
        quantity: 1,
        priceLabel: '\$22.00',
      ),
      MedicineLine(
        name: 'Omeprazole',
        dosage: '20mg',
        quantity: 1,
        priceLabel: '\$9.80',
      ),
      MedicineLine(
        name: 'Paracetamol',
        dosage: '500mg',
        quantity: 1,
        priceLabel: '\$3.50',
      ),
    ],
    totalLabel: totalLabel,
    paidViaLabel: code,
  );

  /// Centre of the sample map — the "your location" dot.
  static const double originLatitude = 34.0522;
  static const double originLongitude = -118.2437;

  static const List<PaymentPoint> points = [
    PaymentPoint(
      id: 'pp-1',
      name: 'QuickPay Agent',
      kind: PaymentPointKind.agent,
      distanceLabel: '0.3 km',
      hoursLabel: '8:00 AM — 10:00 PM',
      isOpen: true,
      latitude: 34.0551,
      longitude: -118.2451,
    ),
    PaymentPoint(
      id: 'pp-2',
      name: 'First Bank Branch',
      kind: PaymentPointKind.bank,
      distanceLabel: '0.7 km',
      hoursLabel: '9:00 AM — 5:00 PM',
      isOpen: true,
      latitude: 34.0498,
      longitude: -118.2502,
    ),
    PaymentPoint(
      id: 'pp-3',
      name: 'PayZone Store',
      kind: PaymentPointKind.store,
      distanceLabel: '1.1 km',
      hoursLabel: 'Open 24 hours',
      isOpen: true,
      latitude: 34.0563,
      longitude: -118.2381,
    ),
    PaymentPoint(
      id: 'pp-4',
      name: 'CityMart Pharmacy',
      kind: PaymentPointKind.pharmacy,
      distanceLabel: '1.4 km',
      hoursLabel: '7:00 AM — 9:00 PM',
      isOpen: true,
      latitude: 34.0471,
      longitude: -118.2396,
    ),
    PaymentPoint(
      id: 'pp-5',
      name: 'Post Office Agent',
      kind: PaymentPointKind.postOffice,
      distanceLabel: '1.9 km',
      hoursLabel: '9:00 AM — 4:00 PM',
      isOpen: false,
      latitude: 34.0589,
      longitude: -118.2519,
    ),
  ];
}
