# Bienify

Tu bienestar. Bien simplificado.

Find doctors, consult from anywhere, get medicines delivered — a Flutter app
built on feature-first Clean Architecture with GetX.

## Status

| Module | State |
|---|---|
| Splash | ✅ Done |
| Location permission | ✅ Done (UI; system prompt is a marked seam) |
| Onboarding (3 slides + sign-in panel) | ✅ Done |
| Auth — phone / OTP / profile setup / login / password reset | ✅ Done |
| Shell + bottom navigation (Home / Appointments / Doctors / Pharmacy) | ✅ Done |
| Home feed — lab requests, upcoming appointments, nearby doctors | ✅ Done |
| Doctor search + specialty filters | ✅ Done |
| Doctor details — profile, availability, booking | ✅ Done |
| Payment summary + booking confirmation | ✅ Done |
| Chat thread | ✅ Done |
| Cash Payment Process — how it works, payment points, pending, confirmed | ✅ Done (UI only) |
| Appointments — list, details, reschedule, cancel, review, video call | ✅ Done (UI only) |
| Pharmacy — catalogue, prescription upload, cart, checkout | ✅ Done (UI only) |
| Pharmacy — order status, live tracking, delivery feedback | ✅ Done (UI only) |

Every screen is reachable and every control does something — there are no
placeholder or "coming soon" states left in the app.

**UI only** means the screens, controllers and widgets are complete and the
`domain` layer holds entity names, but there is no repository, use case or
data source behind them — they read static mock data, ready to be made
dynamic. See [Architecture → UI-first features](docs/ARCHITECTURE.md#ui-first-features).

The app runs end to end today against `MockAuthRemoteDataSource`; see
[Architecture → swapping the mock backend](docs/ARCHITECTURE.md#swapping-the-mock-backend-for-the-real-api).

## Getting started

```bash
flutter pub get
flutter run
```

Against a real API:

```bash
flutter run --dart-define=BIENIFY_API_BASE_URL=https://api.example.com
```

Checks:

```bash
flutter analyze
flutter test
```

## Documentation

- **[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** — colour, type, radius,
  spacing and size tokens, plus the full reusable-widget catalogue with usage
  examples. **Read this before building any screen.**
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — layer responsibilities,
  dependency injection, controller conventions, navigation map, localization
  and known seams.

## Design fidelity

Screens are built against the 390 × 876 export frame. Colours, control heights
(50pt), the content width (358pt), corner radii (8pt inputs / 24pt buttons),
gutters and type sizes were sampled from the exported designs rather than
estimated, then expressed as tokens.

`test/golden/` renders each screen to a PNG that is compared against the
design by eye. Regenerate them after any layout change:

```bash
flutter test test/golden --update-goldens
```

This is the only check that catches a stale `Obx` — the controller asserts
pass either way, and only the pixels reveal that nothing repainted.

## Conventions

- No colour, text style or spacing literal appears in a screen — everything
  comes from `core/theme`.
- No user-facing string appears in a screen — `AppStrings` keys resolved with
  `.tr`, backed by English and Spanish dictionaries driven by the in-app
  `En | Spa` toggle.
- Screens are layout only; state, validation and navigation live in GetX
  controllers built on `SubmissionMixin` + `FieldErrorMixin`.
