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
    ├── pharmacy/                  catalogue, prescription, cart, tracking
    ├── profile/                   account hub, wallet, settings, partner
    ├── doctor/                    practitioner shell, dashboard, schedule
    └── medical_vault/             prescriptions, past visits, tests, reports
```

### UI-first features

`booking`'s cash flow, `appointments`, `pharmacy`, `profile`, `doctor` and
`medical_vault` were built presentation-first by request: screens,
controllers and widgets are complete, `domain` holds **entity names only**,
and `data` holds a static mock file. There is no repository, use case or data source under them, and
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

The account section hangs off the Home header's avatar:

```
home ─ avatar ─▶ profile ─┬─ My Health profile ─▶ healthProfile ─┐
                          ├─ My tests and results ─▶ testResults ─┤
                          ├─ My Wallet ─▶ wallet ─┬─ Add Account ─┐      │
                          │                       └─ transactions │      │
                          │   paymentOptions ─ Next ─▶ addDebitCard      │
                          │        └─ Add Debit card ─▶ walletAccounts   │
                          ├─ Settings ─┬─▶ changePassword          │
                          │            └─▶ legal(about|terms|privacy)
                          ├─ Partner With Bienify ─▶ becomePartner│
                          └─ Log out ─▶ onboarding                │
                                                                  │
healthProfile ─┬─ All Prescriptions ─▶ allPrescriptions ──────────┤
               │        ├─ Your Prescriptions ─▶ reportReview     │
               │        └─ Your Medical vault ─▶ prescriptionDetails
               ├─ All Test Reports ─▶ allTestReports ─▶ prescriptionDetails
               ├─ Past Appintments ─▶ pastAppointments            │
               ├─ Order History ─▶ orderHistory ─▶ reviewShop     │
               ├─ Chat With Us ─▶ chat(support)                   │
               └─ Delete Account ─ confirm dialog                 │
                                                                  │
testResults ─ card action ─┬─▶ testOrder ─▶ testingCentres ───────┘
                           │       └─ I Completed My Test ─┐
                           ├─▶ uploadTestReport ◀──────────┘
                           │       └─▶ resultsSubmitted ─┐
                           └─▶ reportReview ◀────────────┘
                                    └─ Accept follow-up ─▶ search
```

Three route-level reuses hold that together. `legal` is one screen for
About Us, Terms and Privacy, chosen by a `LegalDocument` argument.
`pastAppointments` renders the Appointments tab's own `NeedCareBanner`,
`AppointmentHistoryCard` and `ReviewDialog` against its controller — it
only picks the completed slice. And `testOrder`, `uploadTestReport` and
`reportReview` each carry several designs in one screen, switched on the
chosen centre and the doctor's outcome rather than on separate routes —
`reportReview` covers five: waiting, an offer to talk, a Message box, a
Refer & Escalation box, and a further test the doctor ordered.

## The doctor role

"Join as a Doctor" on the sign-in panel enters a second shell:

```
onboarding ─ Join as a Doctor ─▶ doctorHome
                                    ├─ Home            (complete)
                                    ├─ Appointments ─┐
                                    ├─ Messsage      ├ "Not available yet"
                                    └─ Profile      ─┘
doctorHome ─┬─ Set Schedule ─▶ doctorSetSchedule
            ├─ Set Fees ─ bottom sheet
            ├─ Results to review ─▶ testResults
            └─ bell ─▶ home            (leaves the practitioner role)
```

`DoctorShellController` is deliberately separate from `MainNavController`:
the two shells have different destinations, and a doctor switching tabs must
not disturb the patient shell's state or vice versa. `AppBottomNavBar` and
`NavDestination` are already generic over their destinations, so the bar
itself is reused rather than rebuilt — only the four entries differ, with
`AppIcons.bottomMessage` in place of the patient shell's Pharmacy tab.

Three tabs show an explicit "Not available yet" placeholder because their
designs have not arrived. That is the one place in the app with a
deliberately unfinished state, and it was asked for — a doctor tapping
Appointments should be told the section is coming, not shown a blank page.

`AppointmentsChart` draws the seven weekday bars with widgets rather than a
charting package: a dependency for seven bars against a fixed axis would be
heavier than the layout it replaces.

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
the pixels never change. It has bitten this codebase nine times: the nav
badge, specialty chips, availability slots, the pharmacy cart, the
appointments tab chips and history, the select-medicines checkout bar, the
payment address card, the order-status panel and timeline, and the doctor
dashboard's upcoming-visits card. When a tap "does nothing", check this
first.

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
  the delivery-feedback screen uses a fixed gap. Where a design really does
  pin something to the foot of the page, set `AppScaffold(scrollable: false)`
  and use a `Spacer` (Profile, Become a Partner), then guard the fit at 320pt
  with 1.3× text.
* **A tall golden viewport inflates every `.h`.** `.h` scales against the
  viewport height, so a 1500pt-tall test surface renders a 132pt card at
  226pt and the capture stops resembling the device. Render at the true
  390×876 and scroll for the lower half — `doctor_golden_test.dart` does
  both.
* **`Get.offNamedUntil` clears the stack when its predicate never matches.**
  `AccountController.saveCard` used to pop its own route and wiped the app
  whenever a card was saved from anywhere else. Controllers now mutate only;
  the caller decides where to go, and `AddCardController` unwinds its two
  steps with a `Get.until` predicate that falls through safely.
* **A `const` list assigned to an `RxList` is unmodifiable.**
  `cards.value = ProfileMockData.cards` made the backing list const, so saving
  a card threw *"Cannot add to an unmodifiable list"* — on device, not just in
  tests. Wrap const mocks in `List.of(...)` whenever the observable is later
  mutated.
* **Nested `Flexible`s divide the row instead of sizing to content.** A
  `Flexible` inside a `mainAxisSize: min` `Row` still splits the incoming
  `maxWidth`, so two tags that would both fit came out as `"Laborat…"` and
  `"Routine"`. `TestResultCard` uses a `Wrap` with `spaceBetween`: labels
  from a fixed vocabulary drop to a second line rather than truncate.

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
- **Profile editing** reuses the sign-up `ProfileSetupScreen`; both the Edit
  pill and the camera badge open it. A dedicated edit form and a real photo
  picker replace `ProfileController.edit` / `changePhoto`.
- **Payment options and Add Debit Card have no supplied design.** They use the
  app's card list and labelled-field form; replace them freely when designs
  land. `AddCardController` keeps only the last four digits — the full number
  never leaves the form — and a real gateway replaces its one
  `Future.delayed`.
- **Order History lives inside My Health Profile**, because the Profile design
  gave that slot to "My tests and results". "My tests and results" is reachable
  from both levels, which is intentional — nothing became unreachable.
- **"Chat With Us"** opens the existing `ChatScreen` with `ChatMockData.support`
  as the peer. **"Call With US"** and **Delete Account** acknowledge the tap;
  placing a call and deleting an account are marked seams.
- **All Test Reports lists the same records under both disciplines**, which is
  what the design draws — the toggle currently only drives the pill.
- **Legal copy is not translated.** `LegalCopy` holds the three documents
  verbatim, Terms in Spanish as designed. Wording is a legal decision, not a
  UI one, so it sits outside `AppTranslations`.
- **The order sheet's identifiers** are Satoshi with tabular figures, not a
  monospaced face: `fontFamily: 'monospace'` resolves on Android, not on
  Apple platforms, and not under `flutter_test`. See `_identifierStyle`.
- **PDF export and card capture** acknowledge the tap and stop —
  `DocumentsController.download`, `TestResultsController.downloadDocument`
  and `AccountController.addPaymentMethod` are where those plug in.
- **Google Maps needs console setup, not code.** The key is wired into
  `AndroidManifest.xml`. A blank map grid plus `Authorization failure` in
  logcat means the project has the Maps SDK for Android disabled, billing
  off, or an Android-apps key restriction that does not list this package
  and certificate. The manifest comment carries the checklist and the debug
  SHA-1.

## Lifecycle traps

* **A `TextEditingController` must be owned by the widget, never by a GetX
  controller.** GetX disposes a route's dependencies while the outgoing
  route is still painting its pop transition, so the field rebuilds against
  a disposed controller and throws *"A TextEditingController was used after
  being disposed"*. `DoctorSearchField` owns its own; controllers keep a
  plain `RxString query`.
* **Clearing the whole stack needs a frame.** `Get.offAllNamed` unmounts
  every route at once, and if one still holds focus the `Overlay`'s
  inherited element is torn down with dependents still attached —
  `'_dependents.isEmpty': is not true`. Always go through
  `AppNavigator.resetTo`, which unfocuses and defers by one frame.
