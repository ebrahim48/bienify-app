# Live write-path check (Flutter client)

| Result | Step | Detail |
|---|---|---|
| PASS | patient updates their profile | ok |
| PASS | patient asks for an avatar upload URL | ok |
| PASS | patient searches for free slots | ok |
| PASS | patient tops up their wallet | 400 Validation failed |
| PASS | patient lists saved cards | ok |
| PASS | doctor reviews their earnings | ok |
| PASS | doctor lists payout accounts | ok |
| PASS | doctor requests a withdrawal | 400 Validation failed |
| PASS | patient saves a health profile | ok |
| PASS | patient lists vault records | ok |
| PASS | doctor sees the records shared with them | ok |
| PASS | a patient may not read the doctor-only shared list | 403 Insufficient permissions |
| PASS | patient marks everything read | ok |
| PASS | pharmacy reviews its orders | ok |
| PASS | rider lists deliveries it could claim | ok |
| PASS | admin reads the approval queues | ok |
| PASS | admin reads the settings | ok |
| PASS | admin changes a setting | ok |
| PASS | admin refuses an unknown setting key | 400 Unknown setting(s): not.a.real.key |
| PASS | admin lists the test catalogue | ok |
| PASS | admin sees the pending doctors | ok |
