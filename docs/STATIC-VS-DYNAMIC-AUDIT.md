# Static vs Dynamic Audit — What Still Isn't Talking to the API

**Written:** 22 August 2026
**Scope:** whole Flutter app, focusing on the doctor appointment overview and
every attachment/upload path.

The app defaults to **API mode** — `BIENIFY_USE_MOCKS` is off unless built with
`--dart-define`, so `Api*Repository` is what actually runs
(`dependency_injection.dart:100`). Static data reaching a live screen is
therefore a leak, not a mode.

Not everything under `data/static/` is a bug: onboarding pages, legal copy, and
option lists (currencies, specialties, languages, vehicle types) are legitimately
static. This audit separates those out.

---

## 1. Doctor "Appointments Overview" — no new API needed

The chart on the doctor home screen has a **Weekly / Monthly** toggle that does
nothing.

- `selectRange` (`doctor_home_controller.dart:122`) is
  `void selectRange(v) => range.value = v;` — it changes the label and never
  refetches.
- `dashboard()` (`api_doctor_practice_repository.dart:31`) calls
  `GET /doctors/me/stats` **without a `range` parameter**.
- The backend already supports it: `range: z.enum(['weekly','monthly'])`,
  `platform.routes.ts:126`, feeding `getPracticeStats` which returns 7 or 30
  zero-filled days (`doctor.service.ts:264`).

So the bars are always the last 7 days, whatever the label says.

**Fix:** thread `range` through `dashboard(range)` and make `selectRange` refetch.
**API needed: none.** ~2 hours.

The rest of the doctor role is genuinely API-backed —
`ApiDoctorPracticeRepository` has no static references at all. Two exceptions:

| Leak | Location |
|---|---|
| Radiology tab is entirely static | `results_to_review_controller.dart` → `DoctorOrdersData.radiologyRequests` |
| Patient fallback when none selected | `doctor_bindings.dart:134` → `DoctorOrdersData.patients.first` |

---

## 2. Attachments and uploads — the real gap

Every upload in this app is a two-step dance: ask for a presigned URL, PUT the
bytes, then post the returned `s3Key` to the endpoint that files it. Where the
first step is missing, the feature cannot work at all.

| Flow | Picker | Upload URL endpoint | Filing endpoint | Status |
|---|---|---|---|---|
| Chat attachment | ✅ | `POST /consultations/:id/attachments/upload-url` | message send | ✅ **works** |
| Vault document | ✅ | `POST /vault/records/upload-url` | `POST /vault/records` | ✅ **works** |
| Booking document | ✅ | reuses vault | `POST /vault/records` | ✅ **works** |
| **Lab result** | — | `POST /lab-orders/:id/result/upload-url` | `POST /lab-orders/:id/result` | ⚠️ **backend built today, app not wired** |
| **Profile avatar** | `PhotoPickerService` exists | `POST /users/me/avatar/upload-url` | `POST /users/me/avatar/confirm` | ❌ **endpoints exist, app never calls them** |
| **Rider documents** (5 photos) | ✅ captured | **missing** | `POST /riders/me/documents` (wants `s3Key`) | ❌ **no upload URL endpoint** |
| **Doctor credentials** | — | **missing** | `POST /doctors/me/credentials` (wants `s3Key` under `credentials/{userId}/`) | ❌ **no upload URL endpoint** |

The rider case is the most visible: `rider_application_screen.dart` collects
five photos across the application flow, and `rider_application_controller.dart:141`
says outright — *"The photos are captured but not uploaded: `POST /riders/me/documents`
takes an S3 key, and the app has no route to the bucket yet."* A courier
completes the whole application and none of their documents arrive.

---

## 3. Static data still reaching live screens

Counts are references outside `data/static/` and outside the mock repositories.

| Static class | Live refs | Where it leaks | Backend exists? |
|---|---|---|---|
| `PharmacyMockData` | 39 | patient pharmacy: cart, prescription, order tracking, live tracking, order status | Mostly — `medicines`, `medicine-orders`, `deliveries` |
| `RiderData` | 29 | rider: application, orders, profile, delivered screens | Mostly — `riders/*`, `deliveries/*` |
| `PharmacyShopData` | 11 | shop owner: medicines, profile, forms, home | Mostly — `pharmacies/*`, `medicines` |
| `DoctorMockData` | 8 | patient find-doctor: repository impl + bindings + controller | Yes — `GET /doctors` |
| `MedicalMockData` | 6 | vault: test results, prescription details, test order | Partly |
| `ChatMockData` | 5 | chat | Yes — `consultations/threads`, messages |
| `CashPaymentData` | 5 | cash payment | Yes — `cash-intents`, `payment-points` |
| `AppointmentMockData` | 1 | appointments | Yes |
| `HomeMockData` | 1 | home | Yes — `GET /home/feed` |
| `ProfileMockData` | 0 | — | clean |
| `NotificationMockData` | 0 | — | clean |

`DoctorMockData` appearing inside `doctor_repository_impl.dart` is worth a
closer look — a repository named `Impl` holding mock data is the pattern most
likely to be silently serving fake doctors in production.

**Caveat:** these counts locate the leaks, they do not prove each one is a
functional bug. Some references will be option lists or empty-state copy. Each
area needs opening individually before estimating.

---

## 4. Suggested order

1. **Doctor Appointments Overview range** — 2 hours, no API, visible immediately.
2. **Wire the patient lab-result upload** — backend shipped today, closes the
   flow the provider portal work depends on.
3. **Avatar upload** — endpoints already exist, pure app work.
4. **Rider documents** — needs one new backend endpoint first.
5. **Doctor credentials** — needs one new backend endpoint first.
6. **Pharmacy / rider / shop static leaks** — largest surface, needs an
   area-by-area pass.
