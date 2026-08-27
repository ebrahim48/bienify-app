# Security incident — disguised payload in `bienify-app`

**Found:** 27 August 2026, during a merge of `origin/main`.
**Status:** local machine clean; **GitHub still infected**.
**Repository:** `github.com/QuantumAlliance/bienify-app`

---

## 1. What the file is

`public/fonts/fa-solid-400.woff2` — 31,303 bytes. It is not a font.

| Check | Expected | Actual |
|---|---|---|
| Magic bytes | `wOF2` (`77 4f 46 32`) | `20 20 20 20` — spaces |
| Leading padding | none | **507 spaces** |
| Contents after padding | compressed font tables | obfuscated JavaScript |

The padding is deliberate: a hex preview or `head` of the first bytes looks
blank, so the file passes a glance.

After the padding:

```js
global.i="A8-*#new";const _0xb40cd9=_0x4963;(function(_0x28261c,_0x1c6ad4){…
```

`global` is a **Node.js** object, not a browser one — this is written to run
in a Node process, not to be loaded as a web font. The identifiers
(`_0xb40cd9`) and arithmetic-obfuscated constants are standard JavaScript
obfuscator output, whose only purpose is to make the code unreadable.

The filename is itself a tell. FontAwesome's solid face ships as
`fa-solid-**900**`; there is no `fa-solid-400`. The genuine FontAwesome files
sitting beside it in `public/fonts/` all carry correct magic bytes.

## 2. How it got there, and how it came back

```
2026-08-01  1112a18  Merge pull request #9 from QuantumAlliance/ebrahim_dev
                     ← payload first appears
2026-08-11  9519a5c  JAKUAN_AHMED: "Delete public/fonts/fa-solid-400.woff2"
2026-08-11  d9311fb  "security: remove the disguised payload still present on
                      this branch"
2026-08-15  c11b90d  "Record the latest live API check"
                     ← THE PAYLOAD RETURNS, inside a commit whose message
                       claims to be a routine API-check record
```

**It was found and removed on 11 August, and reappeared four days later.** The
commit that reinstated it is named after an unrelated, innocuous change. That
combination — a removal, a silent reinstatement, and a misleading commit
message — is not consistent with an accident.

## 3. Where it is now

| Location | Payload present |
|---|---|
| Working tree (all three repos) | **no** |
| Local branch `main` | no |
| Local `messaging-reactions-and-uploads`, `api-integration`, `ebrahim_dev` | no |
| **`origin/main`** | **YES** |
| **`origin/ebrahim_dev`** | **YES** |
| **`origin/api-integration`** | **YES** |
| `bienify-backend` repo | no |
| `Dashboard` repo | no |

Local git history still *references* the blob through the fetched `origin/*`
refs and the 1 Aug commit. It cannot run from there — a blob only becomes a
file when something checks it out — but it is not gone until history is
rewritten.

## 4. What stopped it

A pre-commit hook (`~/.security/`) blocked the merge commit, naming both the
wrong magic bytes and the `-400` filename. It offered `git commit --no-verify`
as an override. **That override was not used.** Bypassing the hook would have
defeated the only control that caught this.

The merge was aborted with `git merge --abort`. Nothing was pushed.

## 5. A full asset scan

375 binary assets across all three repositories were checked for the same
signature — wrong magic bytes, whitespace padding, or script markers inside a
font or image.

**No other disguised file was found.** Seven files were flagged for containing
an embedded URL and all seven cleared on inspection: the FontAwesome faces
carry `https://fontawesome.com` in their vendor metadata and correct
TrueType/EOT headers, and `web/favicon.png` carries Adobe XMP namespace
declarations and a valid PNG header.

## 6. What still needs doing

Ordered by urgency. None of these have been done — they affect a shared
remote and other people's clones.

1. **Treat the remote as compromised.** Anyone who has pulled `main`,
   `ebrahim_dev` or `api-integration` since 15 August has this file on disk.
   They should check `public/fonts/` and delete it.
2. **Work out what the payload does** before assuming what it touched. It has
   not been deobfuscated — it must be analysed statically and never executed.
   Until then, assume any secret reachable from a machine that ran it is
   exposed: `.env`, AWS keys, the Mongo URI, Twilio and JWT secrets.
3. **Remove it from GitHub**, on all three branches.
4. **Purge it from history** (`git filter-repo` or BFG) and force-push. This
   rewrites shared history and needs coordinating — everyone re-clones.
5. **Find out how it was reinstated.** The 15 August commit is the important
   question: a compromised developer machine, a stolen token, or a malicious
   contributor are very different problems with different responses.
6. **Rotate credentials** once (2) tells you what was reachable.
7. **Require review on merges to `main`.** The payload entered through a merge
   commit and returned through a mislabelled one.

## 7. Reproducing the finding

```bash
git cat-file -p origin/main:public/fonts/fa-solid-400.woff2 | head -c 16 | xxd
#   expect: 77 4f 46 32 ("wOF2")
#   actual: 20 20 20 20 20 20 20 20 …

git log --all --format='%h | %an | %ad | %s' --date=short \
    -- public/fonts/fa-solid-400.woff2
```

The asset scanner that cleared the other 374 files is kept at
`tools/asset-scan/scan-disguised-assets.py`. It checks every binary asset's
extension against its magic bytes, flags whitespace padding, and looks for
script markers inside files that should contain none:

```bash
python -X utf8 tools/asset-scan/scan-disguised-assets.py
```

Run it after any merge from a branch you did not write.
