/// Shapes behind the pharmacy owner's section.
///
/// **Names only, by design.** Like the doctor role this is UI-first: no
/// repository, use case or data source sits under it and nothing calls an API.
library;

/// Which tab of the pharmacy shell is showing.
enum ShopTab { home, orders, medicines, profile }

/// Where an order has got to. The chip row above the list and the pill on each
/// card both print these.
enum ShopOrderStatus {
  fresh,
  accepted,
  declined,
  preparing,
  outForDelivery,
  delivered,
}

/// The shop, as the dashboard masthead shows it.
class Shop {
  const Shop({
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.location,
    required this.availableBalance,
    required this.email,
    required this.country,
    required this.address,
    this.licenceNumber = '',
  });

  /// `Aid Plus+`.
  final String name;

  /// `Mohammod Jakuan` — who the Profile tab greets.
  final String ownerName;

  /// `+880 189* ****`, already masked.
  final String phone;

  /// `Los Angels, USA` — the line under the shop name.
  final String location;

  final double availableBalance;
  final String email;
  final String country;

  /// `Limasol , cyprus` — the editable pharmacy address.
  final String address;

  /// `PH-DEMO-0001` — what the shop is licensed under.
  final String licenceNumber;

  /// `$160`, whole units as the design prints it.
  String get balanceLabel => '\$${availableBalance.toStringAsFixed(0)}';
}

/// One line of a prescription order.
class OrderLine {
  const OrderLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;

  /// `Qty: 2 × $16.00`.
  String get quantityLabel =>
      'Qty: $quantity × \$${unitPrice.toStringAsFixed(2)}';

  String get totalLabel => '\$${total.toStringAsFixed(2)}';
}

/// A customer's order, from the dashboard row through to its detail.
class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.code,
    required this.customerName,
    required this.initials,
    required this.phone,
    required this.address,
    required this.placedAtLabel,
    required this.status,
    required this.lines,
    this.prescriptionFile,
  });

  final String id;

  /// `ORD-2841`.
  final String code;

  final String customerName;

  /// `SJ`, on the tinted disc.
  final String initials;

  final String phone;
  final String address;

  /// `10:32 AM`.
  final String placedAtLabel;

  final ShopOrderStatus status;
  final List<OrderLine> lines;

  /// `Prescription.jpg`, when the customer attached one.
  final String? prescriptionFile;

  /// Summed from the lines, not carried as a field. The design prints
  /// $45.50 against lines that come to $66.50; adding them up is what keeps
  /// the arithmetic on screen right.
  double get total => lines.fold(0, (sum, line) => sum + line.total);

  String get totalLabel => '\$${total.toStringAsFixed(2)}';

  /// `ORD-2841 • 10:32 AM`, the dashboard row's second line.
  String get summaryLine => '$code • $placedAtLabel';

  ShopOrder copyWith({ShopOrderStatus? status}) => ShopOrder(
    id: id,
    code: code,
    customerName: customerName,
    initials: initials,
    phone: phone,
    address: address,
    placedAtLabel: placedAtLabel,
    status: status ?? this.status,
    lines: lines,
    prescriptionFile: prescriptionFile,
  );
}

/// A product on the shelf.
class ShopMedicine {
  const ShopMedicine({
    required this.id,
    required this.name,
    required this.category,
    required this.expiryLabel,
    required this.stock,
    required this.price,
    required this.isListed,
    this.imageAsset,
  });

  final String id;
  final String name;

  /// `Pain Relief`.
  final String category;

  /// `2028-03`, printed after `Exp`.
  final String expiryLabel;

  final int stock;
  final double price;

  /// Whether the toggle on the row is on — the medicine is offered for sale.
  final bool isListed;

  final String? imageAsset;

  /// `Pain Relief • Exp 2028-03`, dropping whichever half is missing.
  ///
  /// A medicine on the server carries a brand but no expiry date, so a row
  /// that always printed both would read "Pain Relief • Exp " on real stock.
  String get subtitle => [
    if (category.isNotEmpty) category,
    if (expiryLabel.isNotEmpty) 'Exp $expiryLabel',
  ].join(' • ');

  String get stockLabel => 'Stock: $stock';

  String get priceLabel => '\$${price.toStringAsFixed(2)}';

  ShopMedicine copyWith({bool? isListed}) => ShopMedicine(
    id: id,
    name: name,
    category: category,
    expiryLabel: expiryLabel,
    stock: stock,
    price: price,
    isListed: isListed ?? this.isListed,
    imageAsset: imageAsset,
  );
}

/// A line of the dashboard's Low Stock Alerts panel.
class StockAlert {
  const StockAlert({required this.medicineName, required this.remaining});

  final String medicineName;

  /// Zero means the shelf is empty, which the panel calls out in red.
  final int remaining;

  bool get isOut => remaining == 0;
}

/// A row of the shop's notification feed.
class ShopNotification {
  const ShopNotification({
    required this.title,
    required this.body,
    required this.reference,
    required this.ageLabel,
  });

  final String title;
  final String body;

  /// `OC-2026-4587`, printed in blue under the body.
  final String reference;

  /// `1 day ago`.
  final String ageLabel;
}
