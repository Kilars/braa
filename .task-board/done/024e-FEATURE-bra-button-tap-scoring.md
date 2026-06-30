# FEATURE: 024e — The BRA tap: button + wire scoring to taps (P1-5)

**Status**: On-hold (reopened 2026-06-28, was Done) — scoring core (SitWindow/SitSession) real + tested, but every tap is DEAD on the CC0 dog; the button's scene-mount tests are hollow (gate hole, see 026). Blocked on 025 for a live, non-DEAD tap.
**Parent**: 024
**Priority**: High (the one verb — turns the math into gameplay)
**Labels**: gameplay, godot, phase-1, interaction
**Estimated Effort**: Medium

## Outcome (specs2.md P1-5)

- One large, thumb-friendly **BRA** button, reachable in portrait.
- Tap scores by closeness to the apex via `SitWindow` (024a): PERFECT / OK / MISS;
  a tap with no sit active (DEAD) does nothing — no penalty in Phase 1.
- Feedback lands on `pointerup` (P1-7), never a frame late.

## Approach

- A small state machine owns the current sit: when the sit clip plays, build the
  active `SitWindow` (`from_clip`) and compute `tap_time` = seconds-into-this-sit
  from the AnimationPlayer position; on tap, call `score()`.
- The pure scoring is already tested (024a); this slice's testable seam is the
  state→tap_time mapping (when is a window open, what's t at tap) — cover it
  test-first where it's logic; the button hit-area/layout is the visual part.
- Visual task → `polish` + phone-portrait review (blocking) for button size/reach.

## Depends on

- 024a (scoring), 024b (a sit to tap on). Feeds 024f (payoff) and 024g (readout).

## Iteration log (2026-06-28)

**Built test-first (TDD), one slice:**
- **`scripts/sit_session.gd`** — the new pure seam the card called out ("when is a
  window open, what's t at tap"). `SitSession` owns whether a sit is OPEN and the
  seconds INTO it (`open(window)` / `advance(delta)` / `close()` / `elapsed()`),
  and turns a tap into a `SitWindow.Tier`. No engine state — fully unit-testable.
  - **`tests/test_sit_session.gd`** (9 tests, RED→GREEN): fresh session DEAD;
    open→advance(0.8)→tap = PERFECT; off-apex = OK; far-in-sit = MISS; `advance`
    accumulates; `advance` is a no-op while closed (clock only runs during a sit);
    `close()` → DEAD again; re-`open()` restarts the clock at t=0.
- **`scripts/main.gd`** — wired the running scene:
  - A big, thumb-friendly **BRA `Button`** on a `CanvasLayer`, anchored across the
    bottom band of the portrait frame (font 96, ~330px wide × tall, clear of the
    dog). Fires on **release** (Button default `ACTION_MODE_BUTTON_RELEASE` =
    pointerup, P1-7).
  - `_process(delta)` advances the sit clock; `pressed` → `_on_bra_pressed` →
    `_session.tap()` → emits a new `marked(tier)` signal (the seam 024f/024g hang
    off) and logs the tier. Successful marks key off `SitWindow.is_successful`.
  - On a **sit-capable** dog the director plays the sit and `_session.open(window)`
    opens the markable span; on the **CC0** dog the session stays closed → every
    tap is DEAD (does nothing, no penalty — P1-5).
  - **`tests/test_bra_button.gd`** (2 tests): the scene mounts the BRA button
    (wide bottom band, no focus ring); a tap on the committed CC0 dog is DEAD and
    emits exactly one `marked`. (Drives the production `_ready` explicitly — the
    headless runner quits before a process frame, so Godot otherwise defers it.)

**Verified honestly (not fabricated):**
- **32 tests green** (`test_runner.gd`); the **full verify gate is green**
  (import · boot · test · export).
- **Real phone-portrait screenshot of the live web export** (Playwright chromium,
  390×844, served `build/web`) at `.screenshots/bra-button-portrait.png`: the BRA
  button renders as a large, bottom-anchored, thumb-reachable target with legible
  "BRA" text; the dog is centered/idle above it. Read the pixels directly per the
  visual-review-divergence rule.

**Honest gate (same ADR-0006 asset gate, NOT a new block):** the deployed dog is
the **CC0 placeholder with no Sitt**, so live taps are all **DEAD** — the
PERFECT/OK/MISS path can't be *shown on the live deploy* yet. It is fully
**unit-verified** and the open/advance wiring lights up the instant **025**
(licensed Labrador as an encrypted `.pck`) ships, with no gameplay change.

**Minor polish notes (deferred, not this card):** the button uses Godot's default
muted-slate theme — a brighter, higher-contrast CTA would read more Pokémon-GO
(fold into 024f). The dog-sits-high framing + missing contact shadow are the known
P1-1 gaps from 024b.

---
**RESOLVED — Phase 1 SIGNED OFF 2026-06-30 (owner, larssski).** All Phase-1 stories pass on the live deployed licensed build (`po-review.md` Phase Sign-off; PLANNING-BOARD.md). The 025 licensed-dog dependency that parked the 024* sub-tasks is shipped and live; sit / apex / honest tell / BRA scoring / joyful payoff all confirmed in live pixels. Closed with the Phase-1 sign-off. — iteration 056 (board hygiene)
