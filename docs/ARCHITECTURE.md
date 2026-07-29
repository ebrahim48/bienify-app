# Bienify Architecture

Feature-first Clean Architecture on GetX. Three layers per feature, and a
`core` that no feature owns.

```
lib/
├── main.dart                      bootstrap: orientation → DI → runApp
├── app.dart                       ScreenUtilInit + GetMaterialApp
│
├── core/                          shared by every feature
│   ├── base/                      SubmissionMixin, FieldErrorMixin
│   ├── constants/                 AppStrings (keys), AppAssets, ApiConstants
│   ├── di/                        DependencyInjection
│   ├── exceptions/                AppException hierarchy
│   ├── localization/              AppTranslations, LocalizationController
│   ├── models/                    Country (shared across features)
│   ├── routes/                    AppRoutes, AppPages
│   ├── services/                  ApiService, StorageService, Cache, Connectivity
│   ├── theme/                     colours, type, radius, spacing, sizes, ThemeData
│   ├── utils/                     Validators, responsive extensions
│   └── widgets/                   the shared component library
│
└── features/
    ├── splash/
    ├── onboarding/
    ├── auth/
    │   ├── data/                  models · datasources · repository impl
    │   ├── domain/                entities · repository interface · use cases
    │   └── presentation/          bindings · controllers · screens · widgets
    ├── main/                      signed-in shell + bottom navigation
    ├── home/                      Home feed
    ├── doctors/                   directory, search, profile + availability
    ├── appointments/              bookings list, shared AppointmentCard
    ├── booking/                   payment summary + confirmation
    ├── chat/                      message threads
    └── pharmacy/                  catalogue, prescription, cart, tracking
```

### UI-first features

`booking`'s cash flow, `appointments` and `pharmacy` were built
presentation-first by request: screens, controllers and widgets are
complete, `domain` holds **entity names only**, and `data` holds a static
mock file. There is no repository, use case or data source under them, and
nothing calls an API — those arrive when the screens are wired to a
backend. Everything else in this document still applies, including the
dependency rule: the controllers already talk to `domain` types, so adding
a repository later is an addition rather than a rewrite.

**Entities live with the feature that owns them**, and other features import
them: `Doctor` in `doctors`, `Appointment` in `appointments`. That is why
`home` imports from both — its `HomeFeed` is an aggregate over other
features' concepts rather than an owner of them.

`main` owns only navigation: `MainNavController` (which tab is showing) and
`MainShellScreen` (an `IndexedStack` of the four tabs under a persistent
`AppBottomNavBar`). Keeping it separate means switching tabs never rebuilds
or disposes a tab's controller.

The Home feed is fetched as one aggregate (`HomeFeed`) rather than four
calls, so the screen has one loading state and one error state instead of
four.

## The dependency rule

```
presentation ──▶ domain ◀── data
```

`domain` imports nothing from the other two. A controller never sees `Dio`,
JSON or `SharedPreferences`; it talks to a use case, which talks to the
`AuthRepository` **interface**. Only `AuthRepositoryImpl` knows there is an
API at all.

### Layer responsibilities

| Layer | Contains | Rule |
|---|---|---|
| `domain/entities` | `UserEntity`, `AuthSession`, `OtpChallenge`, `Gender`, `AgeRange` | Plain Dart. No JSON, no Flutter. |
| `domain/repositories` | `AuthRepository` | Abstract. Throws `AppException` on failure. |
| `domain/usecases` | One callable class per action | Thin; no logic beyond delegation. |
| `data/models` | `UserModel`, `AuthSessionModel` | `fromJson` / `toJson` only. Extend the entity. |
| `data/datasources` | `AuthRemoteDataSource`, `AuthLocalDataSource` | The only place that knows the wire and storage formats. |
| `data/repositories` | `AuthRepositoryImpl` | Coordinates remote + local, caches the session. |
| `presentation/controllers` | GetX controllers | UI state and navigation. No networking. |
| `presentation/screens` | Widgets | Layout only; every value comes from a token. |

Use cases are grouped one file per **flow** (`phone_auth_usecases.dart`,
`email_auth_usecases.dart`, `registration_usecases.dart`,
`password_recovery_usecases.dart`) rather than one file per class — each is a
single-method object and a flow reads better when its steps sit together.

## Dependency injection

`DependencyInjection.init()` runs once before `runApp` and registers, in
order: **services → data sources → repository → use cases**, all `permanent`.

Screen controllers are *not* registered there — they belong to route bindings
(`auth_bindings.dart`) so they are created on route entry and disposed on
exit, and no half-typed form outlives its flow.

Two deliberate exceptions:

- `PhoneAuthController` is `permanent`, shared by the onboarding panel, the
  standalone phone screen and "Forgot password", so a number typed in one is
  still there in the next.
- `ProfileSetupController` is `fenix: true`, spanning the two profile-setup
  screens so step 2 can still see step 1.

### Swapping the mock backend for the real API

`MockAuthRemoteDataSource` implements the full contract in memory so the
entire journey is walkable today. Flip one constant:

```dart
// core/di/dependency_injection.dart
static const bool _useMockBackend = false;   // → ApiAuthRemoteDataSource
```

Set the base URL at build time:
`--dart-define=BIENIFY_API_BASE_URL=https://api.example.com`

Mock behaviour while testing: any 6-digit code works **except** `000000`
(which fails), and `wrong@bienify.app` never signs in — so both the success
and error paths are reachable.

## Controller conventions

Every form controller mixes in both helpers from `core/base`:

```dart
class LoginController extends GetxController
    with SubmissionMixin, FieldErrorMixin {

  Future<void> login() async {
    final ok = validate({                         // FieldErrorMixin
      emailField: Validators.email(emailController.text),
      passwordField: Validators.password(passwordController.text),
    });
    if (!ok) return;

    await submit(() async {                       // SubmissionMixin
      final session = await _loginWithEmail(email: …, password: …);
      Get.offAllNamed(AppRoutes.home);
    });
  }
}
```

- `submit` gives every screen the same loading flag (`isSubmitting`), the same
  double-tap guard, and the same error reporting via `AppSnackbar`. Controllers
  only write the happy path.
- `validate` / `errorOf(field)` / `clearError(field)` drive inline errors that
  clear the moment the user edits the field.
- Field names are `static const` on the controller so screen and controller
  cannot drift apart.

## Navigation map

```
splash ──┬─ signed in ─────────────────────────────────▶ home
         ├─ first run ──▶ locationPermission ─▶ onboarding
         └─ returning ─────────────────────────▶ onboarding

onboarding ─┬─ Google / Apple ─▶ profileSetup | home
            ├─ Continue with phone ─▶ otp(signUp) ─▶ profileSetup
            │                                     └─▶ profileCredentials
            │                                          └─▶ signupSuccess ─▶ home
            └─ Login ─▶ login ─┬─▶ home
                               ├─ Reset Now ─▶ forgotPassword
                               │      └─▶ otp(passwordReset) ─▶ newPassword
                               │             └─▶ passwordUpdated ─▶ login
                               └─ Sign Up Now ─▶ phoneNumber ─▶ otp(signUp)
```

The pharmacy tab has two entry points into the same basket:

```
pharmacy ─┬─ Add (catalogue) ──────────────────────▶ pharmacyCart
          └─ Upload Prescription ─▶ bestMatches ─▶ selectMedicines
                                                        └─▶ pharmacyCart

pharmacyCart ─▶ pharmacyPayment ─▶ pharmacyOrder ─┬─ Back to Home ─▶ home
                                                  └─ Track Now ─▶ liveTracking
                                                        ├─ chat(rider) ─┐
                                                        └─▶ deliveryFeedback
                                                              └─ review ─▶ home
```

`liveTracking`'s chat button opens the existing `ChatScreen` with the rider
as its `ConversationPeer` — the courier thread is the doctor thread with a
different peer, not a second screen. `deliveryFeedback` likewise opens the
appointments `ReviewDialog`, so both flows rate through one blurred popup.

## Localization

The `En | Spa` toggle is real, not decorative.

- `AppStrings` holds **keys only** — never literal copy.
- `AppTranslations` holds the `en_US` and `es_ES` dictionaries.
- Screens render `AppStrings.login.tr`.
- `LocalizationController` persists the choice via `StorageService` and calls
  `Get.updateLocale`, which re-renders every `.tr` string live.

Adding a string is three edits: key → English value → Spanish value.

## Error handling

`ApiService` converts every `DioException` into a typed `AppException`
(`NoInternetException`, `TimeoutException`, `ServerException`,
`ParsingException`, …). `SubmissionMixin` catches them and shows the right
message — `NoInternetException` gets its own translated copy, everything else
falls back to `somethingWentWrong`.

## Testing

```bash
flutter test
```

- `test/validators_test.dart` — the form rules, country lookup and enum
  round-trips (the logic worth protecting).
- `test/auth_screens_smoke_test.dart` — renders every auth and onboarding
  screen at 390 × 876 through the real bindings, theme and translations, and
  fails on any overflow or build error.
- `test/home_screen_test.dart` — the Home feed's loading→content transition,
  every section from the design, tab switching and badge wiring.
- `test/golden/home_golden_test.dart` — renders the shell to
  `test/golden/home.png` for visual comparison against the design export.
  Regenerate with `flutter test test/golden --update-goldens`; a mismatch on
  a different OS is font rendering, not a regression.

**Always call `loadAppFonts()` (from `test/support/test_fonts.dart`) in
`setUpAll` for any test that lays out text.** Without it `flutter_test`
substitutes a placeholder face whose glyphs are far wider than Satoshi's, and
layouts that fit on a real device overflow in tests.

## GetX reactivity: the one trap worth knowing

`Obx` only subscribes to observables **read inside its builder closure**.
Passing an `RxList` (or a predicate that reads one) to a child does not
subscribe, because the child reads it during its own build, outside the
tracking scope. Symptoms are either a stale UI or the runtime's *"improper
use of a GetX"* error.

```dart
// Wrong — never repaints, and throws "improper use of a GetX".
Obx(() => SpecialtyFilterChips(
  specialties: controller.specialties,        // RxList handed over as-is
  isSelected: controller.isSelected,          // predicate read later
))

// Right — both observables are read here.
Obx(() => SpecialtyFilterChips(
  specialties: controller.specialties.toList(),
  selected: controller.selectedSpecialty.value,
))
```

Prefer passing **values** to child widgets rather than predicates or raw
observables, and materialise lists with `.toList()` inside the builder.

The same trap hides inside a lazy `itemBuilder`: it runs *after* the `Obx`
closure has finished, so anything it reads is untracked. Read the observable
above the list and close over a plain value:

```dart
Obx(() {
  final medicines = controller.medicines.toList();
  final cart = controller.cart.toSet();          // read here, not below
  return ListView.builder(
    itemCount: medicines.length,
    itemBuilder: (_, i) => Row(isInCart: cart.contains(medicines[i].id)),
  );
})
```

This bug is silent — state updates, assertions on the controller pass, and
the pixels never change. It has bitten this codebase eight times: the nav
badge, specialty chips, availability slots, the pharmacy cart, the
appointments tab chips and history, the select-medicines checkout bar, the
payment address card, and the order-status panel and timeline. When a tap
"does nothing", check this first.

Two of those were caught only by rendering goldens — the availability-slot
one surfaced because two goldens that should have differed came out
pixel-identical. Assertions on the controller pass either way, so the
golden is the test that actually detects this class of bug.

## Layout traps this codebase has already hit

* `CrossAxisAlignment.stretch` on a **Row** inside a scroll view forces an
  infinite height. `DoctorInfoGrid` pairs its cards with a fixed
  `cardHeight` instead.
* `Container(alignment: ...)` expands to the incoming constraints. Inside a
  `Wrap` that makes every chip full width — `SpecialtyFilterChips` uses
  padding only.
* `IntrinsicHeight` cannot measure a `Row` of `Expanded` children; give the
  row a fixed height instead.
* **A fixed `.h` height around `.sp` text overflows.** `.h` scales with
  screen height and `.sp` with the text scale factor — they do not move
  together, so a box tuned on one device clips on another. This produced
  two reported overflows (`DoctorInfoGrid`, `NeedCareBanner`). Use
  `ConstrainedBox(minHeight:)` or no height at all, and regression-test at
  320pt with 1.2× text scaling.
* **Three items in a narrow row collapse to `"$…"`.** `MedicineCard`'s
  price pair is wrapped in a `FittedBox(scaleDown)` so it shrinks rather
  than ellipsizing; the same applies to store names in header rows.
* `Spacer()` inside a **scrolling** `Column` has no free space to take —
  the delivery-feedback screen uses a fixed gap.

## Known seams

- **Location permission** is UI-only. `LocationPermissionController`
  `_requestSystemPermission()` is the single place to call
  `permission_handler` / `geolocator`.
- **Document capture** on Payment Summary records the intent but has no
  platform picker yet — `PaymentController.addAttachment` /
  `captureFromCamera` are where `image_picker` / `file_picker` plug in.
- **Payment** resolves after a simulated delay in `PaymentController.pay`;
  the gateway call replaces that one `Future.delayed`.
- **Chat** is local: `ChatController.send` appends the outgoing bubble and
  schedules a canned reply. Swap for a socket or polling data source.
- **Pharmacy** is UI-only end to end: the catalogue, the prescription match,
  the basket and the order timeline all read `PharmacyMockData`. Live
  tracking draws a real `GoogleMap` but animates a canned polyline —
  `OrderTrackingController` is where a courier feed plugs in.
- The **Doctor Details hero** uses the bundled circular headshot; drop a
  cut-out portrait in and point `DoctorHero.portraitAsset` at it.
- `attach.svg` and `upload.svg` are **named for the opposite of their
  artwork**. `AppIcons.cloudUpload` and `AppIcons.paperclip` alias them
  correctly — use those, not the file names.
- **Social sign-in** posts an empty `idToken`;
  `AuthRepositoryImpl.signInWithProvider` is where `google_sign_in` /
  `sign_in_with_apple` plugs in.
- **"Join as a Doctor"** enters the same phone-first registration; the extra
  credentialing steps hang off the profile flow once designed.
- The Apple button reads **"Sign in with Apple"**; the mock-up's "Sing in with
  Apple" is a typo and was not reproduced.
