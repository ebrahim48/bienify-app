import 'package:flutter/material.dart';

import '../../domain/entities/cash_payment.dart';

/// Maps a [PaymentPointKind] to the glyph used on the map pin and in the
/// list.
///
/// Kept in one place so a new kind cannot pick up different icons in the two
/// views.
IconData iconForPaymentPoint(PaymentPointKind kind) => switch (kind) {
  PaymentPointKind.agent => Icons.payments_outlined,
  PaymentPointKind.bank => Icons.account_balance_outlined,
  PaymentPointKind.store => Icons.storefront_outlined,
  PaymentPointKind.pharmacy => Icons.inventory_2_outlined,
  PaymentPointKind.postOffice => Icons.payments_outlined,
};
