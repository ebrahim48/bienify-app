# Security

**Last updated:** 27 August 2026, after a supply-chain backdoor was found in
this repository's `main` branch.

This document is in three parts:

1. **[What happened](#1-what-happened)** — the incident, and exactly what is affected
2. **[Do this now](#2-do-this-now)** — the ordered response, most urgent first
3. **[Preventing the next one](#3-preventing-the-next-one)** — controls, and how to verify each

If you read only one line: **revoke every GitHub credential on the
`QuantumAlliance/bienify-app` account before cleaning anything**, because the
attacker force-pushed a commit forged in the owner's name, and cleaning a
branch someone else can still push to achieves nothing.

---

## 1. What happened

### 1.1 The attack, in three files

A disguised payload, a trigger that runs it, and a setting that removes the
warning. Removing any one of them alone leaves the attack working — which is
why it survived four separate removals.

| Part | File | What it does |
|---|---|---|
| **Payload** | `public/fonts/fa-solid-400.woff2` | Not a font. First bytes are `20 20 20 20` (spaces), not `wOF2`. 507 spaces of padding so a hex preview looks blank, then obfuscated Node.js. |
| **Trigger** | `.vscode/tasks.json` | Labelled `eslint-check`. Runs `node ./public/fonts/fa-solid-400.woff2` under `runOn: folderOpen`, trying the Unix path then the Windows one, with `hide`, `reveal: never`, `echo: false`, `close: true`. |
| **Suppressor** | `.vscode/settings.json` | `task.allowAutomaticTasks: true` removes VS Code's "Allow automatic tasks?" prompt. `terminal.integrated.hideOnStartup: always` hides the terminal it runs in. |

The filename is a tell in itself: FontAwesome's solid face ships as
`fa-solid-**900**`. There is no `fa-solid-400`.

### 1.2 What the payload does — and the limit of what is knowable

Its recovered string table contains Ethereum RPC endpoints
(`ethereum-rpc.publicnode.com`, `1rpc.io/eth`, `eth-mainnet.drpc.org`,
`eth.blockscout.com`), an Etherscan-style query
(`module=account&action=txlist&address=…`), and `child_process` + `require`.

This is **EtherHiding**: it reads transactions sent from a hardcoded
blockchain address, extracts the next stage from them, and executes it.

What it does **not** contain is as important. There are no strings for `.env`,
`.ssh`, `readFile`, `readdir`, wallet files, browser cookies or credential
paths.

> **It is a loader, not a stealer.** It steals nothing by itself — it runs
> whatever the operator publishes to that blockchain address, and that can be
> changed at any time. **What was actually taken cannot be determined from
> this repository.** Anyone who tells you otherwise is guessing. Respond by
> assuming everything reachable was reached.

### 1.3 The commit was forged

On 15 August at 09:01:25 +0600 the owner made commit `5a80e09` — a one-line
change to `docs/LIVE-API-CHECK.md`. Commit `c11b90d` on GitHub has the **same
parent, the same message, and the same author timestamp**, but also carries
the payload, the `.vscode/` trigger, and the removal of the `.vscode/` line
from `.gitignore`.

| | `5a80e09` (real) | `c11b90d` (on GitHub) |
|---|---|---|
| Author | jakuanultimate777, `+0600` | jakuanultimate777, `+0600` |
| **Committer** | jakuanultimate777, **`+0600`** | jakuanultimate777, **`−0700`** |
| In the owner's reflog | yes | **no — never made on that machine** |
| Files changed | 1 | 8 |

`c11b90d` is **the only commit in the entire history** whose author and
committer timezones disagree. It was committed from a machine set to US
Pacific time, carrying the owner's identity, and force-pushed over the branch
— which is why `git fetch` reported *"forced update"* on two branches.

**Inference, not proof:** a GitHub credential was taken from the owner's
machine during the exposure window below, then used on 15 August to push a
commit forged in their name. It fits every observed fact.

### 1.4 The `.gitignore` line that was deleted

On 11 August, `fdd6e80` added `.vscode` to `.gitignore` with this comment:

> *Editor tasks and launch configs are not shared. A committed VS Code task
> can execute on folderOpen, which is how a backdoor reached this repo once.*

`c11b90d` deleted exactly that line and replaced it with `.gitignore` — a
no-op for an already-tracked file — so the diff reads as one trivial change.
**The attacker read the defence and removed it.**

### 1.5 Timeline

```
27 Jul  6176595  first setup (Md. Ebrahim Hossen)
01 Aug  1112a18  payload + .vscode arrive     ← merge PR #9 from ebrahim_dev
        9fd5604  ".vscode directory deleted for secuirity purpose"
06 Aug  10:38    owner clones at 1112a18      ← EXPOSURE BEGINS
11 Aug  fdd6e80  ".vscode" added to .gitignore, with a warning comment
        9519a5c  "Delete public/fonts/fa-solid-400.woff2"
        14:44    owner checks out the cleaned tree  ← EXPOSURE ENDS (~5 days)
        717cbe6  ".vscode directory deleted for secuirity purpose"
        d9311fb  "security: remove the disguised payload still present…"
15 Aug  5a80e09  owner's real commit (1 file)
        c11b90d  FORGED COPY: all five files return, ignore rule removed
27 Aug           found during a merge; blocked by the global pre-commit hook
```

### 1.6 Exposure

**From 6 August 10:38 to 11 August 14:44 — roughly five days — both the
payload and the trigger were on disk in the owner's clone.** The trigger
fires on VS Code folder-open with no prompt and the terminal hidden. On a
project under active development, assume it ran.

Anyone else who pulled `main`, `ebrahim_dev` or `api-integration` **after 15
August** and opened the folder in VS Code is in the same position.

### 1.7 What is affected, precisely

| Repository | Branch | State |
|---|---|---|
| **bienify-app** | `origin/main` | **INFECTED** — all three files present |
| **bienify-app** | `origin/ebrahim_dev` | **INFECTED** |
| **bienify-app** | `origin/api-integration` | **INFECTED** |
| bienify-app | local `main`, `ebrahim_dev`, `api-integration`, `messaging-reactions-and-uploads`, `security/remove-areawins-payload` | clean (fixed 27 Aug) |
| **Backend-Beinify** | all, local and remote | **not affected** — never present |
| **Dashboard** | all, local and remote | **not affected** — never present |

**History is not clean even where the tip is.** The blob stays reachable from
`1112a18`, `9519a5c`, `717cbe6` and `c11b90d`. Checking out any of those still
writes the file to disk. Only a history rewrite removes it.

An asset scan of **375 binary files across all three repositories** found no
other disguised file. Seven were flagged and all seven cleared: the
FontAwesome faces carry correct TrueType/EOT headers with
`https://fontawesome.com` in vendor metadata, and `web/favicon.png` is a valid
PNG carrying Adobe XMP namespaces. No `postinstall` hooks, no obfuscated
source.

---

## 2. Do this now

Ordered. Later steps are wasted effort if the earlier ones are skipped.

### Step 1 — Revoke GitHub access (do this first)

The attacker force-pushed a forged commit. Until that route is closed, every
clean-up can be undone.

- Revoke **all** personal access tokens on the account
- Revoke **all** SSH keys, then add a freshly generated one
- Review **Settings → Applications** and revoke unrecognised OAuth apps
- Review **repository collaborators** and **deploy keys** on
  `QuantumAlliance/bienify-app`
- Turn on 2FA if it is not already on
- Read the **security log** (`github.com/settings/security-log`) around 14–15
  August and note every unfamiliar IP or location

### Step 2 — Rotate every credential the machine could reach

These were readable on the exposed machine. Rotate all of them; do not
triage.

| Source | Rotate |
|---|---|
| `Backend-Beinify/.env` | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `MONGODB_URI` (change the DB password), `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `SMTP_PASSWORD`, `AGORA_APP_CERTIFICATE`, `GOOGLE_CLIENT_ID`, `APPLE_CLIENT_ID` |
| Off-repo | GitHub tokens and SSH keys, npm tokens, browser sessions, any cloud CLI profile on that machine |

Rotating the JWT secrets signs every existing session out. That is the point:
a stolen refresh token stops working.

**AWS specifically:** deactivate the old key rather than only creating a new
one, then read CloudTrail for the exposure window. A key that is merely
replaced still works.

### Step 3 — Tell everyone who has cloned it

They may be infected without knowing. Ask each person to run:

```bash
ls public/fonts/fa-solid-400.woff2   # must not exist
ls .vscode/tasks.json                # must not exist
```

If either exists: delete both, then treat that machine as compromised and
rotate anything it held.

### Step 4 — Clean the remote branches

Local branches are already fixed (commit `b273f23`). Pushing is what
disinfects GitHub. **Do not push before Step 1** — otherwise the attacker
simply pushes back.

```bash
git push origin main
git push --force-with-lease origin ebrahim_dev
git push --force-with-lease origin api-integration
```

`--force-with-lease` rather than `--force`: it refuses if the remote moved
since your last fetch, which is exactly the signal you want if someone else
is still pushing.

### Step 5 — Purge it from history

Step 4 fixes the branch tips. The blob is still recoverable from four older
commits. Removing it needs a rewrite, and everyone re-clones afterwards.

```bash
pip install git-filter-repo
git clone --mirror https://github.com/QuantumAlliance/bienify-app.git
cd bienify-app.git
git filter-repo --invert-paths \
    --path public/fonts/fa-solid-400.woff2 \
    --path .vscode/tasks.json \
    --path .vscode/settings.json \
    --path .vscode/launch.json \
    --path .vscode/extensions.json \
    --path .vscode/spellright.dict
git push --force --all
git push --force --tags
```

Announce this before doing it. Every existing clone becomes unusable and must
be re-cloned — an unrewritten clone can push the old history straight back.

### Step 6 — Work out how `c11b90d` was pushed

This is the one that decides whether it happens again. The candidates:

- **A stolen GitHub token** — most consistent with the evidence. The security
  log will show a session from an unexpected location.
- **A compromised contributor machine** in US Pacific time.
- **A contributor acting deliberately.** The payload arrived through PR #9,
  and the commit that reinstated it also deleted the defence written against
  it. That sequence deserves an answer.

Until this is settled, treat the repository as still reachable by whoever did
it.

---

## 3. Preventing the next one

### 3.1 Already in place

| Control | Where | Covers |
|---|---|---|
| Global `pre-commit` hook | `~/.security/hooks/pre-commit` | `.env` files, `.vscode/`, `.claude/`, `runOn: folderOpen`, `task.allowAutomaticTasks`, terminal/debug stealth settings, fake-font magic bytes, suspicious font names |
| Global `pre-push` hook | `~/.security/hooks/pre-push` | the same, on the way out |
| `.gitignore` | all three repos | `.vscode/`, `.claude/`, with a comment saying why |
| Asset scanner | `tools/asset-scan/scan-disguised-assets.py` | every binary asset: extension vs magic bytes, whitespace padding, script markers |

**This is what caught the attack.** The pre-commit hook blocked the merge and
named both the wrong magic bytes and the `-400` filename.

The hooks are wired through `core.hooksPath` **globally**, so they apply to
every repository on the machine. Do not set a repository-local
`core.hooksPath` — it silently overrides the global one and disables all of
this.

Verify they are live:

```bash
git config --global core.hooksPath      # → C:/Users/<you>/.security/hooks
```

### 3.2 Never do this

- **`git commit --no-verify` / `git push --no-verify`.** The hook offers it,
  and using it defeats the only control that caught this attack. If a hook
  fires, read the finding. It is right far more often than it is wrong.
- **Committing `.vscode/` or `.claude/`.** Editor and agent state is
  per-machine and is an execution vector. Both are ignored and both are
  blocked by the hooks.
- **Trusting a file because of its extension.** The whole attack rests on a
  `.woff2` that was never a font.

### 3.3 Add these

**Require review on `main`.** The payload entered through a merge (PR #9) and
returned through a mislabelled commit. On GitHub: Settings → Branches →
protect `main` with *Require a pull request before merging*, *Require
approvals*, and *Do not allow bypassing*.

**Block force-pushes to `main`.** The forged commit was force-pushed. The same
branch-protection screen has *Do not allow force pushes*.

**Require signed commits.** This is the specific defence against what
happened: a forged author line is trivial, a forged signature is not. Enable
*Require signed commits* in branch protection, and have each contributor set
up a signing key:

```bash
git config --global commit.gpgsign true
git config --global user.signingkey <key-id>
```

An unsigned commit claiming to be from you then stands out immediately.

**Run the asset scanner after any merge you did not write.**

```bash
python -X utf8 tools/asset-scan/scan-disguised-assets.py
```

**Add it to CI** so nobody has to remember. Any non-zero finding fails the
build.

### 3.4 Reviewing a pull request

The attack was visible in a diff to anyone reading it. Four questions:

1. **Does any binary file appear?** A PR about API responses has no reason to
   add a font. Check magic bytes: `head -c 4 <file> | xxd`.
2. **Does the diff match the message?** `c11b90d` said *"Record the latest
   live API check"* and changed eight files, six of which were `.vscode/` and
   a font.
3. **Is a protection being removed?** The same commit deleted `.vscode/` from
   `.gitignore`. A commit that removes a defence needs to say why in its
   message.
4. **Does the committer look right?** Compare author and committer:

   ```bash
   git log --format='%h  A:%ai  C:%ci  %an  %s' -20
   ```

   Mismatched timezones on a commit from a known contributor is the signal
   that exposed this one.

### 3.5 Spotting a disguised file

```bash
head -c 4 suspect.woff2 | xxd      # wOF2 = 77 4f 46 32
head -c 4 suspect.png   | xxd      # PNG  = 89 50 4e 47
head -c 4 suspect.ttf   | xxd      # TTF  = 00 01 00 00
```

Leading spaces where a binary header belongs means the file is padded to look
empty. Then check the name against what the vendor actually ships —
`fa-solid-400` does not exist.

### 3.6 Secrets

- `.env` is ignored and blocked by the hooks; keep `.env.example` with keys
  and no values
- A secret that has been committed once is compromised. Deleting it does not
  help — the blob stays in history. **Rotate it.**
- Never paste a real secret into an issue, a PR, or a chat

### 3.7 Dependencies

The payload arrived in a merge, not a package — but the same class of attack
comes through npm and pub:

- Commit lockfiles and read the diff when they change
- Be suspicious of a lockfile change in a PR that should not touch
  dependencies
- `npm audit` and `flutter pub outdated` on a schedule
- Never run `npm install` on an untrusted branch: `postinstall` executes
  before you have read anything

---

## Reporting a vulnerability

Do not open a public issue. Contact the repository owner directly and give
them time to fix it before disclosing.

## Related

- `docs/SECURITY-INCIDENT-2026-08-27.md` — the forensic write-up
- `tools/asset-scan/scan-disguised-assets.py` — the scanner
- `~/.security/README.md` — the machine-wide hooks
