# Bienify Design System

Everything visual in the app comes from this system. **Before writing a new
widget, check this file** — nine times out of ten the component already
exists and only needs a parameter.

Two rules keep the app consistent:

1. **No literals in screens.** No `Color(0x...)`, no `TextStyle(...)`, no
   `EdgeInsets.all(17)`. Use a token.
2. **Design pixels, scaled at build time.** Every number is authored against
   the 390 × 876 canvas the mock-ups use, then scaled with ScreenUtil
   (`.w` `.h` `.r` `.sp`). The shared widgets already do this — a screen just
   passes the design value.

---

## 1. Tokens

### 1.1 Colour — `core/theme/app_colors.dart`

Full 50→950 ramps for five palettes: `primary`, `gray`, `error`, `success`,
`warning`. On top of the ramps sit **semantic aliases**, which is what screens
should actually use, because they say *why* rather than *which shade*:

| Alias | Value | Used for |
|---|---|---|
| `authBackground` | `gray50` `#F8F4F5` | Page background on every auth screen |
| `authInk` | `primary950` `#0B135D` | Headings, field labels, links |
| `actionFill` | `primary800` `#1B25BC` | Primary buttons, selected chips/cards |
| `actionLabel` | `primary50` `#F2F6FF` | Label on top of `actionFill` |
| `socialFill` | `primary950` | Google / Apple buttons |
| `authPanel` | `primary200` `#D4E0FF` | Onboarding sign-in panel |
| `denyFill` / `denyLabel` | `#E8E8E8` / `gray900` | The neutral "Deny" button |
| `fieldFill` / `fieldBorder` | `white` / `gray100` | Input surface + 1px outline |
| `fieldHint` | `gray600` `#6F6667` | Placeholders and trailing icons |
| `bodyInk` | `gray800` | Body copy under a heading |
| `indicatorInactive` | `gray100` | Inactive onboarding dot |

Home adds a second group:

| Alias | Value | Used for |
|---|---|---|
| `surface` / `surfaceBorder` | `white` / `gray100` | Feed card fill and hairline |
| `accentSurface` | `primary50` | Tinted disc behind the appointment icon |
| `mutedFill` | `gray100` | Low-emphasis pill ("Join") |
| `link` | `primary600` | Inline links ("Review request", "See all") |
| `navActive` / `navInactive` | `primary800` / `gray600` | Bottom-navigation items |
| `badge` | `error600` | Unread-count bubble |
| `star` | `#FBBF24` | Rating star |
| `tagInfo*` | `#EEF0FF` / `#3B46E0` | "Laboratory" tag |
| `tagNeutral*` | `#F1F5F9` / `#334155` | "Routine" tag |
| `tagPending*` | `#FFFBEB` / `#B45309` | "Request sent" tag |

> Every one of these was sampled from the exported designs, not eyeballed.
> The three tag pairs are a cooler slate-and-amber set that belongs to no
> brand ramp, which is why they carry literal values.

### 1.2 Type — `core/theme/app_text_styles.dart`

Family: **Satoshi** (`assets/fonts`, weights 300/400/500/700/900). Satoshi has
no 600 cut, so `w600` tokens render with Bold — this is intentional and
matches the mock-ups.

Scale: `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`,
`titleLarge/Medium/Small`, `bodyLarge/Medium/Small`, `labelLarge/Medium/Small`,
`buttonLarge/Medium/Small`, `caption`, `overline`.

**Which token goes where** (as used across the auth screens):

| Element | Token |
|---|---|
| Screen heading ("Code sent-Check…", onboarding title) | `headlineSmall` 24/700 |
| App-bar title ("Login", "Get OTP") | `titleMedium` 18/600 |
| Standalone label ("Allow your Location", "OR") | `titleSmall` 16/600 |
| Field label ("Email*") | `labelLarge` 14/600 |
| Body copy, input text, hints, chips | `bodyMedium` 14/400 |
| Button label | `buttonLarge` 16/600 |
| Inline validation message | `bodySmall` 12/400 |

Always append `.r` (or `.rc(color)`) from `core/utils/responsive.dart` so the
size scales:

```dart
Text('Login',      style: AppTextStyles.titleMedium.r);
Text('Login',      style: AppTextStyles.titleMedium.rc(AppColors.authInk));
Text('Login',      style: AppTextStyles.titleMedium.rw(AppColors.white, FontWeight.w700));
```

### 1.3 Radius — `core/theme/app_radius.dart`

`none 0 · sm 2 · md 4 · lg 8 · xl 12 · xl2 16 · xl3 24 · xl4 32 · xl5 48 · full 999`

In practice: **inputs, chips and option cards use `lg` (8); buttons and the
onboarding phone pill use `xl3` (24)**. Use the responsive getters —
`AppRadius.rLg`, `AppRadius.rXl3`, `AppRadius.rFull`.

### 1.4 Spacing — `core/theme/app_spacing.dart`

`zero 0 · px 1 · xxs 2 · xs2 4 · xs 8 · sm 12 · base 16 · md 20 · lg 24 ·
xl 28 · xl2 32 · xl3 40 · xl4 48 · xl5 60 · xl6 72`

Named layout constants derived from the designs:

- `screenPadding` = 16 → the 358pt content width every control is drawn at
- `screenTop` = 24 → app bar to first element
- `labelGap` = 8 → label to its input
- `fieldGap` = 20 → one form group to the next

Helpers instead of raw `SizedBox`:

```dart
AppSpacing.gapV(AppSpacing.base);   // vertical 16
AppSpacing.gapH(AppSpacing.xs);     // horizontal 8
Padding(padding: AppSpacing.pagePadding, child: ...);
```

### 1.5 Sizes — `core/theme/app_sizes.dart`

Raw scale `0 2 4 8 12 16 20 24 32 40 48` plus the fixed component metrics:
`controlHeight 50`, `contentWidth 358`, `appBarHeight 56`,
`optionCardHeight 64`, `choiceChipHeight 36`, `statusBadgeSize 176`,
`languageToggle 80×32`, `dotSize 8` / `dotActiveWidth 18`.

---

## 2. Widget catalogue — `core/widgets/`

### `AppScaffold` — page shell

Handles background, safe area, the 16pt gutter, tap-to-dismiss-keyboard, and
scroll-only-when-needed. **Start every screen with it.**

```dart
AppScaffold(
  topBar: AppTopBar(title: AppStrings.login.tr),   // optional
  bottomBar: AppButton(label: 'Get Started', onPressed: ...), // pinned
  scrollable: true,     // false for vertically-centred screens
  padded: true,         // false to go edge-to-edge
  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...]),
)
```

Companions: `ScreenTopGap()` (the 24pt gap under the app bar, compressed on
short devices) and `FlexibleGap(value)`.

> Do **not** wrap the body in `IntrinsicHeight` — several screens contain rows
> of `Expanded` children and `RenderFlex` cannot report intrinsics for those.

### `AppTopBar` — `‹ Title` header

```dart
AppTopBar(title: AppStrings.setUpYourProfile.tr)          // pops on back
AppTopBar(title: 'X', onBack: myHandler, trailing: icon)  // customised
AppTopBar(title: 'X', showBack: false)
```

### `AppButton` — every button in the app

358 × 50, 24pt radius, 18/10 padding, 10pt icon gap.

```dart
AppButton(label: 'Login', onPressed: c.login, isLoading: c.isSubmitting.value)

AppButton(                                   // Google / Apple
  label: 'Sign in with Google',
  variant: AppButtonVariant.dark,
  iconAsset: AppAssets.googleLogo,
  onPressed: ...,
)

AppButton(label: 'Deny', variant: AppButtonVariant.neutral, onPressed: ...)
AppButton(label: 'X', variant: AppButtonVariant.outlined, onPressed: ...)
AppButton(label: 'X', expanded: false, onPressed: ...)   // inside a Row
```

Variants: `primary` (default) · `dark` · `neutral` · `outlined`.
`isEnabled: false` dims to 50 % and blocks taps.

### `AppTextField` — every input

358 × 50, `lg` radius, 1px `gray100` border, white fill. The error message
renders **below** the box so the 50pt height never changes and the layout
never jumps.

```dart
AppTextField(
  controller: c.emailController,
  hint: AppStrings.emailHint.tr,
  keyboardType: TextInputType.emailAddress,
  errorText: c.errorOf(LoginController.emailField),
  onChanged: (_) => c.clearError(LoginController.emailField),
)

AppTextField(hint: '…', obscureText: true, showPasswordToggle: true)  // eye icon
AppTextField(prefixIcon: Icon(Icons.person_outline_rounded), …)
```

### `AppFieldLabel` / `AppLabeledField` — `Name*` + input

```dart
AppLabeledField(
  label: AppStrings.email.tr,       // renders "Email*"
  child: AppTextField(hint: '…'),
)
AppFieldLabel('Gender')                       // standalone
AppFieldLabel('Nickname', isRequired: false)  // no asterisk
```

### `AppPhoneField` + `CountryPickerSheet`

Flag · dial code · chevron · divider · number input. Two looks, one widget:

```dart
AppPhoneField(          // standalone screen: white, 8pt radius, bordered
  controller: c.phoneController,
  country: c.country.value,
  onCountryChanged: c.selectCountry,
  errorText: c.errorOf(PhoneAuthController.phoneField),
)

AppPhoneField.panel(…)  // onboarding panel: gray50, 24pt radius, borderless
```

Countries live in `core/models/country.dart`; flags are derived from the ISO
code as regional-indicator emoji, so **adding a country needs no asset** —
append one `Country(...)` to `Countries.all`.

### `AppOptionCard` — icon + label selection card (Gender)

```dart
Row(children: [
  Expanded(child: AppOptionCard(
    label: Gender.male.labelKey.tr,
    icon: Icons.person,
    isSelected: c.gender.value == Gender.male,
    onTap: () => c.selectGender(Gender.male),
  )),
  AppSpacing.gapH(AppSpacing.xs),
  Expanded(child: AppOptionCard(…)),
])
```

### `AppChoiceChip` + `AppChoiceChipGrid` — compact chips (Age)

`AppChoiceChipGrid` lays chips on a fixed column grid so rows stay aligned
instead of reflowing by text width.

```dart
AppChoiceChipGrid(
  columns: 4,
  children: [
    for (final range in AgeRange.values)
      AppChoiceChip(
        label: range.label,
        isSelected: c.ageRange.value == range,
        onTap: () => c.selectAgeRange(range),
      ),
  ],
)
```

### `AppInlineLink` / `AppUnderlinedLink`

The `Prompt?  Action` row under almost every form.

```dart
AppInlineLink(
  prompt: AppStrings.areYouNewMember.tr,
  action: AppStrings.signUpNow.tr,
  onTap: c.goToSignUp,
  alignment: MainAxisAlignment.start,
  isEnabled: true,          // false dims the action (OTP resend cool-down)
)

AppUnderlinedLink(label: AppStrings.joinAsADoctor.tr, onTap: …)
```

### `AppPageIndicator`

Active page becomes an 18 × 8 pill; the rest stay 8 × 8 dots.

```dart
AppPageIndicator(count: 3, currentIndex: i, onDotTap: c.goToPage)
```

### `AppLanguageToggle`

The `En | Spa` segmented control. Reads and writes `LocalizationController`,
so flipping it re-renders every `.tr` string and persists the choice. Drop it
in with no arguments.

### `StatusBadge` — scalloped success seal

Painted, not imported, so one widget covers both success screens.

```dart
const StatusBadge(color: AppColors.success)      // sign-up complete
const StatusBadge(color: AppColors.actionFill)   // password updated
const StatusBadge(color: …, size: 120, lobes: 10)
```

### `LocationPin`

The 64 × 79 map pin, painted with an `evenOdd` path so the centre is a true
hole and inherits the page background.

```dart
const LocationPin()
const LocationPin(color: AppColors.primary800, width: 48, height: 60)
```

### `AppSnackbar`

One place for transient feedback.

```dart
AppSnackbar.success('…');
AppSnackbar.error('…');
AppSnackbar.info('…');
```

### `AppSvgIcon` — the icon set

The exported SVGs in `assets/icons` carry their own fills, so a raw
`SvgPicture.asset` ignores the theme. `AppSvgIcon` sizes and tints them.

```dart
AppSvgIcon(AppIcons.notification)                       // as exported
AppSvgIcon(AppIcons.home, color: AppColors.navActive)   // tinted
AppSvgIcon(AppIcons.heart, size: 32, color: AppColors.primary500)
```

Paths live in `AppIcons` — never inline an asset string.

> `profile.svg` is a *finished* 40pt avatar (navy disc plus white figure), so
> draw it untinted and unwrapped. Tinting it turns the whole thing one colour.

### `AppCard` — content surface

Shared radius, hairline and soft shadow for every Home card.

```dart
AppCard(child: ...)
AppCard(onTap: c.open, padding: EdgeInsets.all(AppSpacing.base.w), child: ...)
```

### `AppTag` — status pill

```dart
AppTag('Laboratory',   tone: AppTagTone.info)
AppTag('Routine')                                  // neutral is the default
AppTag('Request sent', tone: AppTagTone.pending)
AppTag('Results ready', tone: AppTagTone.success)
```

### `AppAvatar` — circular profile image

Falls back photo → initials → glyph, so a missing URL reads as a deliberate
monogram rather than a broken image. The mock feed ships no photos, which is
why the doctor rows render `AP`, `BT`, `SM`…

```dart
AppAvatar(imageUrl: doctor.photoUrl, name: doctor.name, size: 44)
```

### Auth status screen

Both success designs are one widget with named constructors:

```dart
AuthStatusScreen.signUpComplete()    // green badge  · "Get Started"
AuthStatusScreen.passwordUpdated()   // primary badge · "Login Now"
```

### Bottom navigation

`MainShellScreen` holds the four tabs in an `IndexedStack` (so each keeps its
scroll position) with a persistent `AppBottomNavBar` underneath.

Geometry from the design: 72pt tall over a 1px `gray100` rule, white fill,
24pt icons, 6pt gap, 12pt label, equal-width tabs. Active items tint
`primary800`; the rest `gray600`. Badges come from the feed:

```dart
Get.find<MainNavController>().setBadge(1, feed.unreadAppointments);
```

> Reactivity gotcha: pass `controller.destinations.toList()` from inside the
> `Obx`. Handing over the `RxList` itself does not subscribe — the child reads
> it during its own build, outside the tracking scope, and badge changes never
> repaint.

### Home feed rows

`LabRequestCard`, `UpcomingAppointmentCard` and `DoctorListCard` compose the
primitives above. `DoctorListCard` is shared by the Home feed and (later) the
search results, and fixes its action button at 100pt so long names such as
`Dr.Sophia Martinez,MSW` never get truncated.

### Pharmacy — `features/pharmacy/presentation/widgets/`

| Widget | Use it for |
| --- | --- |
| `MedicineCard` | catalogue tile: discount ribbon, shot, name, dosage, price, Add |
| `PharmacySectionHeader` | section title with a trailing **See all** |
| `StoreAvatar` | circular pharmacy logo + name |
| `QuantityStepper` | `− n +` control, shared by the cart and the picker |
| `LocationDialog` | address sheet; `isEditing` switches Add ↔ Change |

`MedicineCard` puts its price pair inside a `FittedBox(scaleDown)` because
three items in a ~95pt grid cell will otherwise ellipsize the price itself
into `"$…"`. Header rows that pair a store name with an ETA do the same.

### Reuse by condition, not by copy

Three screens serve two flows each, selected by what they are handed rather
than by a second implementation:

| Screen | Also used for | Switch |
| --- | --- | --- |
| `ChatScreen` | the delivery rider | `ConversationPeer` |
| `ReviewDialog` | rating a delivery | caller |
| `PaymentSummaryScreen` | booking from the Doctors tab | the doctor passed in |
| `PaymentMethodTile` | pharmacy checkout | the method list passed in |

When a new flow needs one of these, pass it different data — do not fork
the screen.

### One screen, two flows

`PhoneNumberScreen` and `OtpScreen` each appear twice in the designs. Rather
than duplicating them, `AuthFlow` (`signUp` | `passwordReset`) selects the
title, the button label and the destination:

```dart
GetPage(name: AppRoutes.phoneNumber,
        page: () => const PhoneNumberScreen());
GetPage(name: AppRoutes.forgotPassword,
        page: () => const PhoneNumberScreen(flow: AuthFlow.passwordReset));
```

---

## 4. Adding a new screen — checklist

1. `AppScaffold` + `AppTopBar` for the shell.
2. `ScreenTopGap()` as the first child.
3. `AppLabeledField` + `AppTextField` per input, `AppSpacing.fieldGap` between
   groups.
4. `AppButton` for the action, bound to `controller.isSubmitting`.
5. Copy goes in `AppStrings` (key) **and** both dictionaries in
   `AppTranslations`; render it with `.tr`.
6. Controller extends `GetxController with SubmissionMixin, FieldErrorMixin`.
7. Register the route in `AppRoutes` + `AppPages`, with a binding in
   `auth_bindings.dart`.
8. Add a render case to `test/auth_screens_smoke_test.dart`.

---

## 5. Responsiveness

- `ScreenUtilInit(designSize: Size(390, 876))` in `app.dart` is the reference
  frame; `.w` `.h` `.r` `.sp` scale from it.
- `AppScaffold` caps the content column at 520pt and centres it, so tablets
  get the phone layout centred rather than a stretched one.
- `context.isCompactHeight` (< 700pt) compresses fixed vertical gaps; used by
  `ScreenTopGap` and `FlexibleGap`.
- Text scaling is clamped to 0.9–1.2 in `app.dart` so system font settings
  cannot break the fixed 50pt controls.
- The onboarding split is proportional (53.7 % / 46.3 %) rather than a fixed
  pixel height, so the panel keeps its designed weight on every device.
