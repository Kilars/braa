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

- [ ] The licensed web export is built with the real `POSTHOG_TOKEN`; the substituted file is **not** committed.
- [ ] A CI check proves the exported bundle has telemetry enabled (token baked) — positive gate, no self-cert.
- [ ] Local `verify.sh` unaffected (CC0 preset, no secret → token stays empty → tests still assert disabled).
- [ ] The deploy stays fail-closed; no regression to the licensed-dog decrypt/boot/Sitt gates.

## Notes

`POSTHOG_ID` (project id) and `POSTHOG_API_KEY` (personal read/write) are **not** used here — they belong to
the deferred reporting cron (read side, CI-only), never the client. After this + 084/085, the base is live
end-to-end; the reporting cron remains ADR-0007-deferred until there is a player base.
