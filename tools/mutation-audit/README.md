# Mutation audit

Breaks one behaviour at a time and checks that the test claiming to cover it
actually goes red. A test that stays green under its own mutation is not
testing anything — it is an unverified claim wearing a passing tick.

```bash
python -X utf8 tools/mutation-audit/backend.py
python -X utf8 tools/mutation-audit/app.py
```

Each run edits a source file in place, runs the one suite that should notice,
then **restores the file in a `finally`** — so an interrupted run still leaves
the tree clean. Check `git status` afterwards regardless.

## Why this exists

Three near-misses in one session, all of the same shape: a test that passed
for the wrong reason.

- A courier-thread test asserted two conversations could not leak into each
  other. It passed with the room naming deliberately collapsed, because the
  two ids differ by construction. It could never have failed.
- A doctor's patient-count test created a cancelled appointment for a patient
  who *already had a completed one*, so removing the `status: 'completed'`
  filter still produced the same total. The test named the filter and could
  not see it.
- Three app behaviours had no test at all: a blank delivery address reaching
  the server, the patients-consulted figure being mapped, and the courier
  being told why no chat opened.

The first was caught by hand. The rest were caught by this.

## Adding a mutation

One tuple per behaviour:

```python
('what you are breaking, in plain words',
 'path/to/source.ts',
 'the exact text to remove or change',
 'what to put in its place',
 'the suite that should go red')
```

Anchors are matched literally, whitespace included. A `SKIP` means the anchor
no longer matches the source — treat it as a failure, not a pass: the audit
did not run, so nothing was proved.

## What a survivor means

The behaviour has no test. Either write one, or delete the behaviour — it is
not doing anything anyone has committed to keeping.
