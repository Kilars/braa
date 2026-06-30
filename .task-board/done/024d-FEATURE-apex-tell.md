# FEATURE: 024d — The apex tell (P1-4)

**Status**: On-hold (reopened 2026-06-28, was Done) — tell logic real + unit-tested, but DORMANT on the CC0 dog (sit never opens → tell never fires). P1-4 unverifiable on live until 025.
**Parent**: 024
**Priority**: High (timing must be readable, not a guess)
**Labels**: gameplay, godot, phase-1, visual
**Estimated Effort**: Small

## Outcome (specs2.md P1-4)

- A subtle visual tell (soft pulse / ring / glow) fires at the apex — on the BRA
  marker and/or the dog.
- **Honest:** it marks the *actual* scoring peak (the same `apex` 024a/024b use),
  not slightly before/after.
- Never fires when there's nothing to mark (only on the sit apex; never during idle).

## Approach

- Trigger the tell off the same apex time fed to `SitWindow` — one source of truth, so
  the tell can't drift from the PERFECT band. Tie the tell's peak frame to `apex`.
- Reduced-motion (P1-8) must dampen, not remove, the tell — keep it distinguishable.
- Visual task → `polish` + screenshot review (blocking).

## Depends on

- 024a (apex time / band) and 024b (the sit that has an apex).

## Iteration findings (2026-06-28)

Built honest, single-source-of-truth, TDD:

- **`scripts/apex_tell.gd` (`ApexTell`)** — the pure envelope. `intensity(elapsed)`
  is a cosine bell peaking **exactly at the apex** and 0 outside the markable span,
  so the cue can't drift from the band. `ApexTell.from_window(SitWindow, damping)`
  takes the apex + bounds straight from the scoring window — the SAME value
  `SitWindow.score()` returns PERFECT at — and ramps over the OK window, so the glow
  spans exactly the scorable window and is brightest at the PERFECT centre.
  `damping` (reduced-motion, P1-8) scales the peak but, as a positive shape-preserving
  factor, can never remove the cue.
- **`scripts/apex_tell_marker.gd` (`ApexTellMarker`)** — a dumb `Control` renderer:
  a warm (not alarm-red) soft halo + crisp ring that bloom slightly toward the apex.
  Its whole opacity = `intensity` via `self_modulate.a`, so 0 is genuinely invisible.
  `mouse_filter = IGNORE` so the marker, sitting over the BRA button, never eats a tap.
- **`main.gd`** — builds the tell from the same window when a real sit opens, drives
  the marker each `_process` frame off the same sit clock as the score, and holds it
  dark whenever no sit is open. `set_motion_scale()` is the seam 024g routes
  prefers-reduced-motion into (P1-8 wiring itself is 024g's job).

**TDD:** `tests/test_apex_tell.gd` (8 — peak-at-apex, symmetry, monotonic falloff /
no early false peak, cosine midpoint, dark at/beyond the ramp, **dark during idle**,
from_window ties the tell to the scoring apex, reduced-motion dampens-not-removes) +
`tests/test_tell_wiring.gd` (4 — scene mounts the marker, marker never eats a BRA tap,
**dark through idle frames on the CC0 dog**, opacity tracks/clamps intensity).
**54 tests green; full verify gate green** (import · boot · test · export).

**Verified honestly (not fabricated):**
- Real phone-portrait (390×844) screenshot of the **live web export** at
  `.screenshots/024d-tell-idle.png`, captured via Playwright/Chromium on a plain
  server (single-threaded export → no COOP/COEP), gated on `window.__appReady`, zero
  page errors. I read the pixels myself (per the visual-review-divergence rule): the
  CC0 dog idles centred on the bright backdrop, the BRA button below, and **no stray
  glow/ring over the button** — the new overlay node is genuinely **dormant during
  idle**, which is exactly P1-4's "never fires when there's nothing to mark."

**025 gate (why the *visible* pulse isn't on the live deploy yet):** the deployed CC0
dog has **no Sitt clip**, so no sit ever opens → the tell legitimately never fires on
the live build (it can only ever show its dormant state there). The apex pulse is
**unit-verified to peak exactly at the apex** and lights up on the live deploy the
moment **025/ADR-0006** ships the sit-capable Labrador — identical gating to 024e's
scoring taps, which shipped the same way. The one P1-4 criterion observable on CC0
("dark during idle") IS verified on the live build above.

---
**RESOLVED — Phase 1 SIGNED OFF 2026-06-30 (owner, larssski).** All Phase-1 stories pass on the live deployed licensed build (`po-review.md` Phase Sign-off; PLANNING-BOARD.md). The 025 licensed-dog dependency that parked the 024* sub-tasks is shipped and live; sit / apex / honest tell / BRA scoring / joyful payoff all confirmed in live pixels. Closed with the Phase-1 sign-off. — iteration 056 (board hygiene)
