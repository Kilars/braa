# 084 — FEATURE: wire the telemetry call-sites into the game (X-8 / ADR-0007)

**Type:** FEATURE (game-logic TDD + wiring) · **Phase:** 3 — Dog breeds (**current-phase**, part of the
Phase-3 done bar per the phase3.md instrumentation note; **NOT** work-ahead — this preempts the dormant
Phase-4 tasks by the phasing rule) · **Source:** `.docs/specs/index.md` **X-8**, `.docs/specs/phase3.md`
(Instrumentation), `adr/0007-telemetry-and-feedback.md` · **Priority:** first telemetry follow-on; the base
(`scripts/telemetry*.gd`) is landed and green but emits nothing until it is wired.

## What it addresses

The ADR-0007 base is a dormant choke-point — no call-site drives it yet. Wire the one `Telemetry` node into
`main.gd` and emit the Phase-3 events X-8 lists, so the target metrics (time-to-first-successful-BRA,
per-trick completion, quit-point, timing quality) become queryable once the token is injected (086).

## Technical approach

- Instantiate `Telemetry` as a child of `main` in `_ready()` (hold a `_telemetry` ref). It stays a no-op
  locally (empty token) — fire-and-forget, never blocks gameplay (X-7).
- Emit, routing **every** call through `_telemetry.capture(event, props)` (no ad-hoc PostHog calls — X-8):
  - `session_start` on boot — props: `platform` (`OS.get_name()`), viewport size.
  - `session_end` on teardown — props: `last_trick`, `attempts`, `best_progress`, `mastered_count`.
    ⚠️ **Web-unload wrinkle:** an in-flight `HTTPRequest` may not flush on tab close. Fire `session_end`
    opportunistically on `visibilitychange → hidden` (via the existing web seam), and/or add a `sendBeacon`
    path. If a reliable beacon needs a spike, file a `SPIKE-` first — do not fake a flush.
  - `bra_tapped` at the mark-eval site — props: `trick`, `bucket` (perfect|good|early|late|miss),
    `latency_ms_from_apex`, `attempt_number`. **This is the primary signal** (ADR-0007).
  - `trick_mastered` at the mastery latch — props: `trick`.
  - `breed_adopted` at `_on_breed_adopt` (on a successful spend) — props: `breed`.
- The `bucket`/latency already exist in the mark-eval path (SitWindow/tier). Reuse them — do not recompute.

### TDD (RED first)

- Add a **recording sink** test seam on `Telemetry` (e.g. an overridable `_emit(payload)` or a `last_event`
  captured list gated to tests) so wiring tests assert the event **name + props** off `build_event()` with
  **no network** — telemetry stays disabled in tests.
- Wiring tests (extend `instantiate_main`-style): a scored mark emits `bra_tapped` with the right
  `trick`/`bucket`; a mastery emits `trick_mastered{trick}`; a successful adopt emits `breed_adopted{breed}`;
  boot emits `session_start`. Assert props, not just the call.

## Acceptance criteria

- [x] `main` owns one `Telemetry` node; every capture routes through it (grep: no other node calls PostHog).
- [x] TDD (RED→GREEN) proves each event fires with the correct name + props via the recording seam (no net).
- [x] Default local run still green + byte-identical play (telemetry disabled, no gameplay effect).
- [x] `session_end` reliability addressed (visibilitychange/beacon) or a `SPIKE-` filed if the flush is unknown.
- [x] Placeholder check clean. `nix develop -c bash verify.sh` green (import·boot·test·export).

## Resolution

Files touched: `scripts/telemetry.gd` (recording sink: `captured` array, `_remember()`, `last()`),
`scripts/sit_window.gd` (`bucket()` static classifier), `scripts/sit_session.gd` (`apex_offset()`),
`scripts/main.gd` (`_telemetry` + `_attempts` fields; `_telem()` choke-point; session_start in
`_ready()`; bra_tapped in `_on_bra_pressed()`; trick_mastered in `_apply_progress()`; breed_adopted
in `_on_breed_adopt()`; `_notification()` + `_emit_session_end()` for session_end).

session_end reliability decision: engine-native `NOTIFICATION_APPLICATION_PAUSED` (Page Visibility API
"hidden" → backgrounded tab on web) + `NOTIFICATION_WM_CLOSE_REQUEST` (desktop close), both surfaced
by Godot's standard notification system — no JavaScriptBridge or sendBeacon spike needed. Fire-and-forget
posture tolerates a hard tab-kill dropping the final event (ADR-0007).

## Notes

Base is `scripts/telemetry.gd` (`capture`, `build_event`, `ms_since_session_start`, ephemeral `session_id`).
Pairs with **085** (feedback UI → `feedback_submitted`) and **086** (inject the token so events actually
ship). The reporting cron stays **deferred** (no player base yet) — ADR-0007 only, not a backlog task.
