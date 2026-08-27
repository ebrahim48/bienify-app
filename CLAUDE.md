# Bienify App — CLAUDE.md

Flutter client for the Bienify telemedicine platform, against
`../Backend-Beinify`. Four role shells: patient, doctor, pharmacy_owner,
rider.

## Stack

- Flutter + Dart, **GetX** for state, routing and DI
- `flutter_screenutil` for responsive sizing
- Repository pattern: every feature has a `domain/repositories` contract with
  paired `Api*Repository` and `Mock*Repository` implementations, selected by
  `DependencyInjection.init(useMocks:)` / `BIENIFY_USE_MOCKS`
- `socket_io_client` for realtime, `dio` for HTTP
- Golden tests for screens, widget tests for behaviour

## Testing

```bash
flutter test                       # everything
flutter test --update-goldens      # after an intended visual change
flutter analyze lib test           # must be clean before finishing
```

- **A test must fail if the behaviour it names is removed.** Break the
  specific line the test claims to cover, watch *that* test go red, restore.
  Do it per test, not for a sample of a new suite — a courier-thread test once
  asserted two threads could not leak into each other and passed with the room
  naming deliberately collapsed, because the two ids differed by construction.
  It could never have failed. A test whose subject you have not seen fail is
  an unverified claim.

- **A test cannot be more truthful than its fixture.** A mock standing in for
  a real collaborator must return what that collaborator would. The chat mock
  served a doctor's sample conversation to *every* thread, so a regenerated
  golden showed a courier quoting a consultation fee and offering a video
  call. The screen was right; the picture documenting it was not.

- **Look at every regenerated golden.** `--update-goldens` will happily bake
  in a bug. Read the PNG back before accepting it — that is how the courier
  conversation above was caught.

- **Pin the clock.** A controller reading `DateTime.now()` directly makes a
  golden that fails tomorrow. Inject the clock and pin it in the test.

## GetX traps that have bitten this codebase

- **`Obx` must wrap the observable read, not the widget.** `Obx(() => _Grid())`
  watches nothing — the read happens inside `_Grid`'s own build. Put the `Obx`
  inside, around the `.value` access. This has caused a silently non-rebuilding
  screen twice.
- **`copyWith` must carry every field.** An omitted field silently reverts to
  its default: `Rider.copyWith` dropped rating, review count, completed
  deliveries, zones and the GPS setting, so going online reset a courier's own
  masthead to zero.
- A controller reached through `Get.find` in a constructor default must be
  registered globally, or the screen throws only on the route that opens it.

## Before writing a helper, look for it

Grep for the name first. The messaging refactor reimplemented an emoji check
that the file it was already importing from exports, and got the rule wrong.
One `grep <name> lib/` is the whole discipline.

## Honesty rules for UI

These are not style preferences — each one is a bug that shipped:

- **Delete rather than fake.** No invented ETAs, road names, "minutes away",
  payment codes, ratings or receipts. If the server does not supply it, the
  screen omits it.
- **A control that does nothing must not look live.** A chat button opening a
  sample conversation, or a dialog whose fields are `Text` widgets, reads as a
  working feature.
- **Stale comments are worse than none.** A doc comment saying a feature is
  UI-only, after it was wired to an API, sends the next reader away without
  checking.
