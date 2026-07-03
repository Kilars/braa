# ADR-0007: Anonymous telemetry & feedback — transport and privacy posture

- **Status:** Proposed
- **Date:** 2026-07-03
- **Deciders:** Lars (owner), Claude

## Context

The phased spec (`.docs/specs/`) is all gameplay; there is no instrumentation. The
owner wants **anonymous, cookieless analytics** (PostHog) plus a **free-text feedback**
entrypoint, feeding a two-tier loop: Tier 1 = autonomous numeric/UX tuning from quant
signals; Tier 2 = proposal/ADR drafts from quant + qual, human sign-off before code.
The app is **Godot 4 + GDScript → Web/PWA** (ADR-0001/0003/0004) — there is no JS/TS app
layer, so the PostHog **JS SDK** isn't a natural fit, and `JavaScriptBridge` has bitten
this repo before (a web bool marshalled back as a null Variant — see the P1-4 fix). A
transport + privacy decision is needed before any wiring.

## Decision

- **Transport = direct HTTP from GDScript.** Capture events by POSTing JSON to PostHog's
  `/capture/` endpoint from a single autoload choke-point (`scripts/telemetry.gd`) via
  `HTTPRequest`. **No PostHog JS SDK, no `JavaScriptBridge`.** Engine-native, works in the
  editor *and* every export target, **headless-testable** (so `verify.sh` can cover it),
  and it sidesteps the web-marshal gotcha.
- **One choke-point.** Nothing calls the endpoint directly — all capture goes through
  `telemetry.gd`. Single audit point for what's collected; swappable backend later.
- **Fire-and-forget.** Telemetry must never affect gameplay: async, errors swallowed,
  no blocking, no retspinning on failure. A dropped event is acceptable; a stalled frame
  is not.
- **Privacy posture.** No cookies, no persisted visitor id, no session recording. An
  **ephemeral in-memory `session_id`** (regenerated each load, never written to `user://`)
  correlates events *within one session* so funnels work **without cross-session tracking**.
  Nothing is written to the device, so **no cookie banner is required** (the banner is
  triggered by device storage, not by server-side processing). **Disable IP/geoip capture**
  so "anonymous" is literally true (IP is personal data under GDPR even without a cookie). A
  short privacy note sits near the feedback form (free text may contain PII → processing, not
  device storage — still no banner).
- **Key handling.** The PostHog **project/ingestion key** (`phc_…`) is **public by design** —
  a write-only client key that ships in the bundle regardless (like the ADR-0006 encryption
  key ends up in the wasm). Keeping it as a GH secret (`POSTHOG_API_KEY`) is fine for
  repo-hygiene / export-time injection, but it is **not sensitive**. The **personal/read API
  key** used for the reporting pull is the real secret and is a **separate** credential.
- **Scope this pass = ADR only, no code** (owner choice). When built, it lands as its own
  **cross-cutting workstream** — not inside a gameplay phase — TDD'd against the choke-point.

## Consequences

- **Good:** native, testable, export-agnostic; one choke-point; funnels-without-tracking via
  the ephemeral id; no cookie banner; no JS-bridge fragility.
- **Cost:** we forgo PostHog autocapture / session-replay and **hand-instrument every event**
  (fine — the taxonomy is tiny for a one-screen game); we own batching/failure-swallow; the
  `/capture/` payload shape becomes a dependency we version.
- **Loop guardrails live in the prompts, not here.** Before Tier-1 auto-tuning is enabled,
  `process/mother_prompt.md` + the father prompt must encode: Tier-1 (numeric tuning only —
  small, reversible, its own commit) vs Tier-2 (proposal/ADR only); *never invent mechanics
  from numbers*; *never auto-remove a feature from usage data — flag only*; and **the spec
  stays source of truth over any numeric tweak.** Follow-up edit when telemetry is built.
- **Affected:** extends ADR-0001/0003 (GDScript/web); independent of the gameplay phases.

## Open (owner-gated, deferred until build)

- **Host region:** EU (`eu.i.posthog.com`) vs US (`us.i.posthog.com`) — tied to audience/GDPR.
- **Feedback sink:** PostHog event props vs a separate inbox (Formspree / Tally).
- **Privacy note** text + retention stance (free text may contain PII).
- **Personal/read API key** for the reporting pull (separate secret from the ingestion key).

## Reporting cron (deferred; shape decided)

A scheduled **GitHub Actions** job (CI already holds the secret, runs on `schedule:`) does a
**read-only aggregate pull** via the personal/read key and **emits, never edits**: a dated
report (`.telemetry/reports/YYYY-MM-DD.md` — ranked usage / drop-off / timing + raw feedback
**verbatim**) plus, on a strong signal, files into the **task board** — a `backlog/` task for
**Tier-1** (numeric tuning, small/reversible/logged) or a **FLAG / proposal** for **Tier-2**
(no code, awaits owner). It **never writes `.docs/specs/` and never removes a feature**, and
**no-ops below a session threshold** so thin data can't manufacture signal.

## Deferred taxonomy (Bra!-specific, when built)

Not the generic combat/levels/rooms set. The real events for a watch-and-tap timing game:
`session_start` / `session_end`, `trick_shown{trick,breed,difficulty}`, `apex_tell_shown`,
`bra_tapped{latency_ms_from_apex, bucket: perfect|good|early|late|miss}`, `dead_click`,
`trick_mastered`, `breed_adopted`, `difficulty_changed`, `feedback_submitted{text,tags[],rating?,screen_context,session_id}`.
The **`bra_tapped` timing distribution is the primary signal** — it is this game's core loop.
Every event is stamped with a session-relative `ms_since_session_start` (anonymous clock).

### Target metrics (what the taxonomy must answer)

Chosen so each falls out by querying on the ephemeral `session_id` — no cross-session identity:

- **Time to first successful BRA** — `session_start` → first `bra_tapped{bucket ∈ perfect|good}`;
  trivial via the `ms_since_session_start` stamp on that event.
- **Per-trick completion rate** — sessions emitting `trick_mastered{trick}` ÷ sessions emitting
  `bra_tapped{trick}` (i.e. that started training it).
- **Where players leave** — `session_end{last_trick, attempts, best_progress, mastered_count}`
  is the quit_point; cluster on `last_trick` / `best_progress`.
- **Attempts-to-master & timing quality** — the `bra_tapped{bucket, latency_ms_from_apex,
  attempt_number}` distribution per trick.

**Caveat — per-session, not per-person.** The no-persisted-id / no-cookie-banner choice means
"users" = **sessions**: one human across three sessions is three rows. That is sufficient for
tuning and drop-off. True unique-human cohorts would need a persisted analytics id → a consent
prompt (the game's own `user://` save is strictly-necessary and banner-free, but reusing it as an
analytics id is not) — a separate decision, **deferred**, not part of this ADR.
