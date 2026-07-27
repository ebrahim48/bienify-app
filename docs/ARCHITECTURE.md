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
    └── home/                      placeholder — next milestone
```

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

## Known seams

- **Location permission** is UI-only. `LocationPermissionController`
  `_requestSystemPermission()` is the single place to call
  `permission_handler` / `geolocator`.
- **Social sign-in** posts an empty `idToken`;
  `AuthRepositoryImpl.signInWithProvider` is where `google_sign_in` /
  `sign_in_with_apple` plugs in.
- **"Join as a Doctor"** shows a "coming soon" notice — it is a separate
  provider-facing journey.
- The Apple button reads **"Sign in with Apple"**; the mock-up's "Sing in with
  Apple" is a typo and was not reproduced.
