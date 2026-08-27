# Bienify — screen previews

Eleven screens across the platform's four roles, at 1170×2628 (phone
resolution, 3×). Suitable for slides, a PDF or a client email.

## Patient

| File | Screen |
|---|---|
| `01-patient-home.png` | Home — search, lab request, upcoming appointment, nearby doctors |
| `02-patient-appointments.png` | Appointments — upcoming, past and cancelled |
| `03-patient-doctors.png` | Find a doctor — categories and directory |
| `04-patient-pharmacy.png` | Pharmacy — catalogue and stores |
| `05-patient-chat.png` | Consultation chat — delivery/read receipts, shared document, seen marker |

## Doctor

| File | Screen |
|---|---|
| `06-doctor-dashboard.png` | Practice dashboard — earnings, today's schedule |
| `07-doctor-appointments.png` | Appointments — patient bookings by state |

## Pharmacy owner

| File | Screen |
|---|---|
| `08-pharmacy-dashboard.png` | Shop dashboard — balance, new orders, low stock |
| `09-pharmacy-orders.png` | Orders — filtered by fulfilment state |

## Rider

| File | Screen |
|---|---|
| `10-rider-dashboard.png` | Courier dashboard — availability and today's work |
| `11-rider-deliveries.png` | Deliveries — jobs by state |

## What these are

Real renders of the real screens: the same widgets the device runs, the app's
own fonts and theme, driven through the same bindings. They are **not**
mockups or design comps.

The **data is demo data**, not production records — which is what makes the
images stable and safe to share outside the team. Names, amounts and order
numbers are invented.

## Known gap

Emoji **message reactions** are not shown. They work on a device, but the
offline renderer used to produce these images has no emoji face it can
rasterise, so the glyphs come out as empty boxes. A reaction screenshot has to
be captured from a running device instead.

## Regenerating

```bash
flutter test test/delivery_screenshots_test.dart
```

Deterministic — the clock is pinned to 2026-02-20, so re-running produces
identical files rather than a diff every time.
