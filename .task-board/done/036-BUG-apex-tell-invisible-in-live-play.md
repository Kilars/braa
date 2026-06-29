# BUG: The apex tell renders only under the force seam — invisible in live play (P1-4 — blocker, carried over)

**Status**: Done
**Created**: 2026-06-29
**Completed**: 2026-06-30
**Priority**: P0 for Phase 1 — the PO's one carried-over blocker. P1-4 is the core
"now" cue; without it timing is a blind guess and the BRA marker is a dead grey slab
through every apex.
**Labels**: bug, godot, phase-1, visual, p1-4, live-path, web-marshaling
**Source**: `.docs/specs/po-review.md` → PO Review 2026-06-29 → Bugfixes → "The apex
tell still never renders in live play (P1-4 — blocker, carried over)."

## What's wrong (PO re-play of the real licensed web build, 2026-06-29)

Under the `?bra_force_tell=1` capture seam the warm-gold halo+ring renders boldly
(saturated-gold detector: 1647 gold px, 6/6 frames). In **normal play it never
appears**: a free-run 90-frame burst across multiple full sit cycles scored 0 gold px
in 0/90 frames, and the seated apex frame captured the instant a live PERFECT fired
(`?bra_autotap=1`) showed a plain grey BRA slab. The forced-only pixel-proof masked it.

The PO sharpened the diagnosis: the draw and the curve are both proven good
(forced `set_intensity(1.0)` draws; `ApexTell.intensity()` returns ~0.65→1.0 near the
apex; autotap confirms the clock reaches the band). The fault is the **live-intensity
value reaching the marker as 0**.

## Root cause (empirically traced)

The chain is `_apply_reduced_motion()` → `ReducedMotion.query()` →
`set_motion_scale(scale_for(reduced))` → `ApexTell.from_window(_window, _motion_scale)`.
On the **Web export only**, `ReducedMotion.query()` used
`JavaScriptBridge.eval("<bare boolean>", true)`, and a bare JS-boolean result marshals
back as a **null Variant** on wasm — which collapsed the motion scale to 0, so every
apex tell was built with damping 0 → permanently invisible. Headless never caught it:
off-web `query()` short-circuits to `false` → scale 1.0, so the live path was never
exercised (hollow green). This is the same null-Variant marshaling gotcha the
force-tell / force-tier seams already dodge by reading a String.

## Fix

1. **`scripts/reduced_motion.gd`** — `query()` now evals a **string sentinel**
   `… ? '1' : '0'` and compares `== "1"`, the same reliable String-marshaling path
   `main._query_force_tell` already uses. The read can never yield null again.
2. **`scripts/main.gd`** — `set_motion_scale()` now treats any non-finite or `<= 0`
   scale as full motion (1.0). Belt-and-suspenders: the P1-8 contract is (0, 1]
   ("dampened, never removed"), so whatever upstream feeds in, the cue can never
   silently blank.

## Tests (TDD regression, `tests/test_tell_wiring.gd`)

- `test_live_tell_lights_up_at_the_apex_on_a_sit_capable_dog` — drives a **real sit**
  (injected sit-capable director, no capture seam) through `_process` and asserts the
  marker actually pulses to a clear peak (≥ 0.5) at the seated apex (~1.0 s), and stays
  dark whenever no sit is open. This is the headless guard for "the live tell renders,"
  not just the forced seam — the test the CC0-only wiring tests structurally could not
  provide (the placeholder never sits).
- `test_motion_scale_never_zeros_out_the_tell` — `set_motion_scale(0 / -1 / NAN)` must
  not blank the cue; valid factors (1.0, DAMPED) pass through unchanged. A future
  regression of this exact shape now reads red headless instead of only on the live site.

## Cleanup

Removed the temporary diagnostic instrumentation used to trace this live
(`main.gd` `TEMP-PROBE-030b` → `window.__bra_tell`, and the throwaway probes
`tools/diag_tell_probe.mjs`, `tools/diag_clip_lengths.gd`).

## Verification

`nix develop -c bash verify.sh` → green (import · boot · test · export). Test leg:
117 tests, 0 failures (incl. the two new regression tests). Placeholder check on the
`scripts/` diff: clean.

## Note for the PO

The **binding proof is a live capture** — a no-seam free-run burst with max gold > 0, or
a `?bra_autotap=1` apex frame showing the ring — on the deployed licensed build. The loop
cannot run that build (encryption key / live site are owner-gated; see `FLAGS.md`), so
this fix is verified by the headless live-path test + the traced root cause; the pixel
sign-off remains a PO action on the deployed site.
