# 086 — CHORE: inject `POSTHOG_TOKEN` into the web export in CI (ADR-0007)

**Type:** CHORE (deploy pipeline — **CI-only, unverifiable in local `verify.sh`**, like the ADR-0006
proof) · **Phase:** 3 — Dog breeds (**current-phase**, closes the Phase-3 telemetry loop) · **Source:**
`adr/0007-telemetry-and-feedback.md` (Key handling), `.docs/specs/index.md` **X-8** · **Priority:** makes the
wired events (084) actually reach PostHog on the live site. **Depends on 084** — no point injecting a token
with no call-sites emitting.

## What it addresses

`scripts/telemetry_config.gd` ships `PROJECT_TOKEN := ""` → telemetry disabled. The live web export must
carry the real project token so capture reaches PostHog. The token is the PostHog **project** key
(`phc_…`) — **public by design** (it ships in every client bundle), so this is repo-hygiene, not a secret
leak; low blast radius. It is held as the `POSTHOG_TOKEN` GitHub secret.

## Technical approach

- In the **deploy** workflow (`.github/workflows/deploy-licensed.yml`), before `godot … --export`, substitute
  the empty `PROJECT_TOKEN` const in `scripts/telemetry_config.gd` with `${{ secrets.POSTHOG_TOKEN }}` (a
  scoped `sed` on that one const line — do not commit the substituted file; it is export-time only, mirroring
  how the encryption key is CI-injected and never in the tree).
- **Prove it, don't self-certify:** extend the existing headless-Chromium boot check to assert the exported
  bundle has telemetry **enabled** (`is_configured()` true / token present) — a positive gate — without
  actually depending on a live PostHog round-trip in CI.
- ⚠️ This edits the deploy workflow that auto-publishes to Pages. Keep the change **surgical and reviewed**;
  a bad edit must fail-closed (leave the live site stale, never broken), consistent with the deploy's gates.

## Acceptance criteria

- [x] The licensed web export is built with the real `POSTHOG_TOKEN`; the substituted file is **not** committed.
- [x] A CI check proves the exported bundle has telemetry enabled (token baked) — positive gate, no self-cert.
- [x] Local `verify.sh` unaffected (CC0 preset, no secret → token stays empty → tests still assert disabled).
- [x] The deploy stays fail-closed; no regression to the licensed-dog decrypt/boot/Sitt gates.

## Resolution (2026-07-03)

CI-only (unverifiable in local `verify.sh`, like the ADR-0006 pipeline) — authored, and everything
locally verifiable was verified.

Files touched:
- `.github/workflows/deploy-licensed.yml` — new **"Inject PostHog project token"** step (runs before
  `--import` so the packed script cache carries the token): a scoped `sed` swaps the one
  `const PROJECT_TOKEN := ""` line for `${{ secrets.POSTHOG_TOKEN }}`, asserts the empty const is gone
  AND the token landed, and sets `TELEMETRY_EXPECTED` in `$GITHUB_ENV`. The substituted file is **never
  committed** (export-time only, mirrors the encryption-key handling). If the secret is absent, telemetry
  ships dormant (allowed) and the enabled-gate is skipped so the deploy still publishes.
- `.github/workflows/deploy-licensed.yml` — the **browser boot check** now conditionally adds
  `--require "telemetry enabled"` when `TELEMETRY_EXPECTED == true`: a **positive** runtime gate (not a
  self-cert) — the real headless-Chromium boot must print that signal, proving the baked token makes
  `is_enabled()` true at runtime, or the deploy fails closed (live site stays stale). Base licensed-dog
  gates (`dog_licensed.glb`, `dog can Sitt`) unchanged.
- `scripts/main.gd` — `_notify_web_ready()` prints `"[Bra!] telemetry enabled (anonymous PostHog capture)"`
  **only when** `_telemetry.is_enabled()` (a real baked token). Locally / CC0 the token is empty → disabled
  → silent, so `verify.sh`'s boot leg and normal play are byte-identical. No change to `web_boot_check.mjs`
  (it already supports `--require` console-signal gates).

Verified locally: YAML parses; the `sed` pattern swaps the const on a copy while the real
`scripts/telemetry_config.gd` stays `""` (git clean); `nix develop -c bash verify.sh` → **✓ verify gate
green** (import · boot · test · export), telemetry-disabled tests still pass. The end-to-end CI proof
(token actually reaches PostHog on the live site) can only be observed on a real deploy run with the
`POSTHOG_TOKEN` secret set — inherent to a CI-only chore.

## Notes

`POSTHOG_ID` (project id) and `POSTHOG_API_KEY` (personal read/write) are **not** used here — they belong to
the deferred reporting cron (read side, CI-only), never the client. After this + 084/085, the base is live
end-to-end; the reporting cron remains ADR-0007-deferred until there is a player base.
