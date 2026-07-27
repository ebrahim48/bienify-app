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
| Home | 🚧 Placeholder — next milestone |

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

## Conventions

- No colour, text style or spacing literal appears in a screen — everything
  comes from `core/theme`.
- No user-facing string appears in a screen — `AppStrings` keys resolved with
  `.tr`, backed by English and Spanish dictionaries driven by the in-app
  `En | Spa` toggle.
- Screens are layout only; state, validation and navigation live in GetX
  controllers built on `SubmissionMixin` + `FieldErrorMixin`.
