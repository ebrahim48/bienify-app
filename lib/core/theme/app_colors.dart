import 'package:flutter/material.dart';

/// Single source of truth for every colour used in Bienify.
///
/// Palettes are exported as full 50→950 ramps so that new screens can pick a
/// shade without inventing a hex value. Never hard-code a `Color(0x...)`
/// outside this file — add a token here instead.
class AppColors {
  AppColors._();

  // =========================
  // Brand (Primary)
  // =========================
  static const Color primary50 = Color(0xFFF2F6FF);
  static const Color primary100 = Color(0xFFE8EEFF);
  static const Color primary200 = Color(0xFFD4E0FF);
  static const Color primary300 = Color(0xFFB2C5FF);
  static const Color primary400 = Color(0xFF869EFF);
  static const Color primary500 = Color(0xFF556DFD);
  static const Color primary600 = Color(0xFF3242F5);
  static const Color primary700 = Color(0xFF202CE1);
  static const Color primary800 = Color(0xFF1B25BC);
  static const Color primary900 = Color(0xFF18209A);
  static const Color primary950 = Color(0xFF0B135D);

  static const Color primary = primary500;

  // =========================
  // Cathedral (Neutral / Gray)
  // =========================
  static const Color gray50 = Color(0xFFF8F4F5);
  static const Color gray100 = Color(0xFFE4E0E1);
  static const Color gray200 = Color(0xFFD2CCCD);
  static const Color gray300 = Color(0xFFBFB8BA);
  static const Color gray400 = Color(0xFFADA6A6);
  static const Color gray500 = Color(0xFF8D868A);
  static const Color gray600 = Color(0xFF6F6667);
  static const Color gray700 = Color(0xFF514949);
  static const Color gray800 = Color(0xFF352E2E);
  static const Color gray900 = Color(0xFF1A1515);
  static const Color gray950 = Color(0xFF040202);

  // =========================
  // Stoplight (Error / Danger)
  // =========================
  static const Color error50 = Color(0xFFFFDBC9);
  static const Color error100 = Color(0xFFFFBEB1);
  static const Color error200 = Color(0xFFFF9C8E);
  static const Color error300 = Color(0xFFFF7A6B);
  static const Color error400 = Color(0xFFF15448);
  static const Color error500 = Color(0xFFE00E0E);
  static const Color error600 = Color(0xFFC60000);
  static const Color error700 = Color(0xFFA20000);
  static const Color error800 = Color(0xFF7B0000);
  static const Color error900 = Color(0xFF520000);
  static const Color error950 = Color(0xFF2C0000);

  static const Color error = error500;

  // =========================
  // Vegetarian (Success)
  // =========================
  static const Color success50 = Color(0xFFC9F7BC);
  static const Color success100 = Color(0xFFA8F3A1);
  static const Color success200 = Color(0xFF85DE79);
  static const Color success300 = Color(0xFF5DC94F);
  static const Color success400 = Color(0xFF28B405);
  static const Color success500 = Color(0xFF009900);
  static const Color success600 = Color(0xFF007D00);
  static const Color success700 = Color(0xFF005F00);
  static const Color success800 = Color(0xFF004100);
  static const Color success900 = Color(0xFF002400);
  static const Color success950 = Color(0xFF001A00);

  static const Color success = success500;

  // =========================
  // Maizena (Warning)
  // =========================
  static const Color warning50 = Color(0xFFFFF8A7);
  static const Color warning100 = Color(0xFFFFEB61);
  static const Color warning200 = Color(0xFFEED200);
  static const Color warning300 = Color(0xFFC3AE00);
  static const Color warning400 = Color(0xFFA88F00);
  static const Color warning500 = Color(0xFF956D00);
  static const Color warning600 = Color(0xFF7E5000);
  static const Color warning700 = Color(0xFF633400);
  static const Color warning800 = Color(0xFF471B00);
  static const Color warning900 = Color(0xFF2A0A00);
  static const Color warning950 = Color(0xFF080E00);

  static const Color warning = warning500;

  // =========================
  // Common Colors
  // =========================
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // =========================
  // Text Colors
  // =========================
  static const Color textPrimary = gray950;
  static const Color textSecondary = gray600;
  static const Color textHint = gray400;
  static const Color textOnPrimary = white;

  // =========================
  // Background
  // =========================
  static const Color scaffoldBackground = white;
  static const Color cardBackground = white;
  static const Color divider = gray200;
  static const Color border = gray300;

  // =========================
  // Status Colors
  // =========================
  static const Color info = primary500;
  static const Color successColor = success500;
  static const Color warningColor = warning500;
  static const Color errorColor = error500;

  // =========================
  // Semantic aliases — sampled from the Bienify screens
  // =========================
  // Every auth/onboarding screen sits on this warm off-white.
  static const Color authBackground = gray50;

  /// Ink used for headings, labels and links on auth screens.
  static const Color authInk = primary950;

  /// Filled call-to-action (Allow / Login / Next / Continue …).
  static const Color actionFill = primary800;

  /// Label colour on top of [actionFill] — the design uses primary50, not
  /// pure white, so the label reads slightly cooler than the background.
  static const Color actionLabel = primary50;

  /// Dark secondary CTA used for the social sign-in buttons.
  static const Color socialFill = primary950;

  /// The tinted panel that holds the sign-in options on onboarding.
  static const Color authPanel = primary200;

  /// The palest blue panel — the Diagnosis block and other inset notes.
  static const Color authPanelSoft = primary50;

  /// Neutral "Deny"/dismiss button fill on the permission screen.
  static const Color denyFill = Color(0xFFE8E8E8);

  /// Ink on top of [denyFill].
  static const Color denyLabel = gray900;

  /// 1px outline around inputs, chips and option cards.
  static const Color fieldBorder = gray100;

  /// Input fill.
  static const Color fieldFill = white;

  /// Placeholder + trailing icon colour inside inputs.
  static const Color fieldHint = gray600;

  /// Body copy under a heading.
  static const Color bodyInk = gray800;

  /// Inactive page-indicator dot.
  static const Color indicatorInactive = gray100;

  // =========================
  // Home surfaces
  // =========================

  /// Card fill on the Home feed.
  static const Color surface = white;

  /// Hairline around Home cards and the bottom navigation.
  static const Color surfaceBorder = gray100;

  /// Tinted circle behind the appointment icon.
  static const Color accentSurface = primary50;

  /// Low-emphasis pill fill ("Join").
  static const Color mutedFill = gray100;

  /// Inline text link ("Review request", "See all").
  static const Color link = primary600;

  /// Active / inactive bottom-navigation items.
  static const Color navActive = primary800;
  static const Color navInactive = gray600;

  /// Unread-count badge.
  static const Color badge = error600;

  // =========================
  // Status tags
  // =========================
  // The lab-request card uses a cooler, slate-and-amber set that does not
  // belong to any brand ramp, so the exact design values live here.

  /// Informational tag ("Laboratory").
  static const Color tagInfoSurface = Color(0xFFEEF0FF);
  static const Color tagInfoInk = Color(0xFF3B46E0);

  /// Neutral tag ("Routine").
  static const Color tagNeutralSurface = Color(0xFFF1F5F9);
  static const Color tagNeutralInk = Color(0xFF334155);

  /// Pending tag ("Request sent").
  static const Color tagPendingSurface = Color(0xFFFFFBEB);
  static const Color tagPendingInk = Color(0xFFB45309);

  /// Resolved tag ("Reviewed"), which also carries a leading dot.
  static const Color tagSuccessSurface = Color(0xFFECFDF5);
  static const Color tagSuccessInk = Color(0xFF047857);

  /// Action-needed tag ("Awaiting review").
  static const Color tagWarningSurface = Color(0xFFFFF7ED);
  static const Color tagWarningInk = Color(0xFFC2410C);

  /// Rating star.
  static const Color star = Color(0xFFFBBF24);

  // =========================
  // Chat
  // =========================

  /// Presence pill in the thread header.
  static const Color online = Color(0xFF10B981);

  /// Fill behind the composer input and its attach button.
  static const Color chatFieldFill = Color(0xFFF5F5F5);

  // =========================
  // Cash payment process
  // =========================

  /// Near-black surface of the payment-code card.
  static const Color codeSurface = Color(0xFF0A0A0A);

  /// The lighter disc decorating that card's top-right corner.
  static const Color codeSurfaceAccent = Color(0xFF1E1F22);

  /// The code itself, and the pill behind "Copy Code".
  static const Color codeInk = primary200;

  /// Track behind the Map / List segmented toggle; the active segment is
  /// [codeSurface].
  static const Color segmentTrack = Color(0xFFF3F4F6);

  /// "Open" / "Open Now" availability badge.
  static const Color openSurface = Color(0xFFECFDF3);
  static const Color openInk = Color(0xFF12B76A);

  /// "Closed" badge.
  static const Color closedSurface = gray100;
  static const Color closedInk = gray600;

  /// Waiting-for-payment hero panel and its icon disc.
  static const Color pendingSurface = primary200;
  static const Color pendingIconSurface = Color(0xFFB4BED9);

  /// Countdown accent on the pending screen.
  static const Color timerAccent = Color(0xFFA3C900);

  // =========================
  // Profile & account
  // =========================

  /// Destructive red for "Log out" — its own value, not [error600], because
  /// `log-out.svg` is stroked with it and the two must match exactly.
  static const Color logoutFill = Color(0xFFD00416);

  /// Muted indigo of the profile menu labels. Lighter than [authInk]: the
  /// rows are navigation, not content.
  static const Color menuLabel = Color(0xFF888AAF);

  /// Camera glyph on the profile photo's badge — a slate-indigo, lighter
  /// than [authInk] but darker than [menuLabel].
  static const Color photoBadgeInk = Color(0xFF6D719E);

  /// Outline of the pill-shaped "Edit" button on the profile card.
  static const Color editBorder = Color(0xFFB9C2FE);

  // =========================
  // Order state pills
  // =========================
  // A brighter set than the [tagSuccessSurface] family used on test results —
  // the order-history design draws these three specifically.

  static const Color orderDeliveredSurface = Color(0xFFF0FDF4);
  static const Color orderDeliveredInk = Color(0xFF008236);

  static const Color orderPendingSurface = warning50;
  static const Color orderPendingInk = warning400;

  static const Color orderCancelledSurface = error50;
  static const Color orderCancelledInk = error600;

  // =========================
  // Uploaded documents
  // =========================

  /// Grey tile behind an uploaded file's thumbnail glyph.
  static const Color fileSurface = Color(0xFFE8E8E8);

  /// Orange used for an uploaded document's glyph and its "Lab Result" tag.
  static const Color fileAccent = Color(0xFFE67229);

  /// Fill behind that tag.
  static const Color fileAccentSurface = Color(0xFFFDF6EF);

  /// Grey fill of the inputs inside the card-details panel.
  static const Color cardFieldFill = Color(0xFFF1F1EC);

  // =========================
  // Wallet
  // =========================

  /// Near-black balance card, and the olive discs decorating its corners.
  static const Color walletSurface = Color(0xFF121509);
  static const Color walletAccent = Color(0xFF1C2009);

  /// "↑ Active saver" — an olive-lime, distinct from the success ramp.
  static const Color saverAccent = Color(0xFF9BBB00);

  /// Debit / credit badges in the transaction list, and the credit amount.
  static const Color debitSurface = Color(0xFFFEECEC);
  static const Color debitInk = Color(0xFFFF6467);
  static const Color creditSurface = Color(0xFFDCFCE7);
  static const Color creditInk = Color(0xFF16A34A);

  // =========================
  // Doctor dashboard
  // =========================

  /// The navy masthead, and the lighter panel holding the balance inside it.
  static const Color doctorHeader = Color(0xFF1722BB);
  static const Color doctorHeaderPanel = Color(0xFF3D45C6);

  /// Tinted discs behind the four dashboard statistics.
  static const Color statWarnSurface = Color(0xFFFFF7ED);
  static const Color statWarnInk = Color(0xFFF59E0B);
  static const Color statInfoSurface = Color(0xFFEAEBFA);
  static const Color statInfoInk = primary800;
  static const Color statUpSurface = Color(0xFFECFDF5);
  static const Color statUpInk = Color(0xFF16A34A);
  static const Color statPeopleSurface = Color(0xFFF3E8FF);
  static const Color statPeopleInk = Color(0xFF9333EA);

  /// Weekday bars on the appointments chart, in the design's order.
  static const List<Color> chartBars = [
    Color(0xFFEF4444),
    Color(0xFF84CC16),
    Color(0xFF22D3EE),
    Color(0xFFEAB308),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
  ];

  /// Time-slot chips on Set Schedule.
  static const Color slotSurface = Color(0xFFE7F8EF);
  static const Color slotInk = Color(0xFF15803D);

  /// "Confirmed" / "Pending" outlined pills on the dashboard's list.
  static const Color confirmedInk = primary600;
  static const Color pendingOutlineInk = Color(0xFFD97706);
}
