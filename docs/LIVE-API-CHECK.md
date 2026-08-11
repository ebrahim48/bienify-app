# Live API check (Flutter client)

Ran against `http://localhost:3500` through `ApiClient`.

| Metric | Result |
|---|---|
| Calls | 47 |
| Passed | 47 |
| Failed | 0 |

| Result | Role | Method | Path | Detail |
|---|---|---|---|---|
| PASS | patient | POST | `/api/v1/auth/login` | ok |
| PASS | doctor | POST | `/api/v1/auth/login` | ok |
| PASS | pharmacy_owner | POST | `/api/v1/auth/login` | ok |
| PASS | rider | POST | `/api/v1/auth/login` | ok |
| PASS | admin | POST | `/api/v1/auth/login` | ok |
| PASS | anon | GET | `/api/v1/doctors` | ok |
| PASS | anon | GET | `/api/v1/medicines` | ok |
| PASS | anon | GET | `/api/v1/diagnostic-tests` | ok |
| PASS | anon | GET | `/api/v1/pharmacies` | ok |
| PASS | anon | GET | `/api/v1/testing-centres` | ok |
| PASS | anon | GET | `/api/v1/payment-points` | ok |
| PASS | anon | GET | `/api/v1/users/me` | 401 Missing or malformed Authorization header |
| PASS | patient | GET | `/api/v1/users/me` | ok |
| PASS | patient | GET | `/api/v1/home/feed` | ok |
| PASS | patient | GET | `/api/v1/appointments` | ok |
| PASS | patient | GET | `/api/v1/prescriptions` | ok |
| PASS | patient | GET | `/api/v1/medicine-orders` | ok |
| PASS | patient | GET | `/api/v1/lab-orders` | ok |
| PASS | patient | GET | `/api/v1/wallet` | ok |
| PASS | patient | GET | `/api/v1/wallet/transactions` | ok |
| PASS | patient | GET | `/api/v1/notifications` | ok |
| PASS | patient | GET | `/api/v1/vault/records` | ok |
| PASS | patient | GET | `/api/v1/admin/users` | 403 Insufficient permissions |
| PASS | doctor | GET | `/api/v1/users/me` | ok |
| PASS | doctor | GET | `/api/v1/appointments` | ok |
| PASS | doctor | GET | `/api/v1/doctors/me` | ok |
| PASS | doctor | GET | `/api/v1/doctors/me/stats` | ok |
| PASS | doctor | GET | `/api/v1/wallet/transactions` | ok |
| PASS | pharmacy_owner | GET | `/api/v1/users/me` | ok |
| PASS | pharmacy_owner | GET | `/api/v1/medicine-orders` | ok |
| PASS | pharmacy_owner | GET | `/api/v1/wallet` | ok |
| PASS | rider | GET | `/api/v1/users/me` | ok |
| PASS | rider | GET | `/api/v1/deliveries/available` | ok |
| PASS | rider | GET | `/api/v1/wallet` | ok |
| PASS | admin | GET | `/api/v1/admin/users` | ok |
| PASS | admin | GET | `/api/v1/admin/dashboard/stats` | ok |
| PASS | admin | GET | `/api/v1/admin/settings` | ok |
| PASS | admin | GET | `/api/v1/admin/tests` | ok |
| PASS | admin | GET | `/api/v1/admin/appointments` | ok |
| PASS | admin | GET | `/api/v1/admin/withdrawals` | ok |
| PASS | admin | GET | `/api/v1/admin/partner-applications` | ok |
| PASS | anon | GET | `/api/v1/doctors/6a7aaebd9edac194dd587765` | ok |
| PASS | anon | GET | `/api/v1/appointments/slots` | ok |
| PASS | anon | GET | `/api/v1/reviews/doctors/6a7aaebd9edac194dd587765` | ok |
| PASS | patient | GET | `/api/v1/appointments/6a7aaebb68ba3172df927840` | ok |
| PASS | patient | GET | `/api/v1/medicine-orders/6a7afebb06b849db15077900` | ok |
| PASS | patient | GET | `/api/v1/prescriptions/6a7aaebc68ba3172df927843` | ok |
