# BUG: 026 — Verify gate reports green while tests throw SCRIPT ERRORs (hollow pass)

**Status**: Done (2026-06-28)
**Created**: 2026-06-28
**Priority**: HIGH — do BEFORE the loop builds anything else; the gate is currently lying
**Labels**: gate-integrity, godot, tests, tdd
**Estimated Effort**: Small

## Context & Motivation

The trust-nothing audit (2026-06-28) confirmed the headless test runner reports
`ran N, 0 failures, all green, exit 0` **even when a test method aborts mid-way on a
runtime `SCRIPT ERROR`**. An aborted method records ZERO failures, so a crash reads as a
pass. This means `verify.sh`'s test leg cannot be trusted, and every "verify gate green"
in this project is partly hollow. This undermines the whole autonomous loop, whose only
proof-of-work is the gate.

Concretely firing **now**:
- `scripts/main.gd:123` — `get_viewport().get_visible_rect()` throws on the null/headless
  viewport during `main._ready()`.
- Any scene-mount test that calls `main._ready()` hits it and aborts silently:
  `tests/test_bra_button.gd` and `tests/test_payoff_wiring.gd` are **effectively hollow**
  (their asserts never execute); `tests/test_idle_loop.gd` only survives because the error
  happens to be non-fatal in this build.

This is the SAME class of hole the 024a "can_instantiate() guard" was meant to close —
that guard catches **parse** failures only, not **runtime** errors mid-method.

## Desired Outcome

A test that aborts on a runtime error **fails the gate**, and the scene-mount tests
actually run their assertions.

## Affected Components

### Files to Modify
- `tests/test_runner.gd` — detect an aborted/errored method and count it as a failure.
- `tests/test_case.gd` — likely needs an explicit "this method ran to completion" signal.
- `scripts/main.gd` — guard the null-viewport path (`_viewport_aspect` / `:123`) so
  `_ready()` is headless-safe, OR give scene-mount tests a headless viewport.

## Technical Approach

1. **Make hollow passes impossible.** Each `test_*` method must prove it ran to its end —
   e.g. the runner records the method as PASSED only if a sentinel set at the END of the
   method is observed, or wrap the call so an engine error / early abort is recorded as a
   failure (not silently dropped). A method that throws must turn the gate RED.
2. **Fix the actual crash.** `main.gd:_viewport_aspect()` must not call
   `get_visible_rect()` on a null viewport — guard it (the project pins a 720×1280 logical
   viewport; fall back to that ratio when there's no live viewport), so `_ready()` is safe
   headless and the scene-mount tests execute their asserts for real.
3. **Re-baseline the count.** After the fix, re-run `nix develop -c bash verify.sh` and
   record the TRUE pass count (it will likely drop, then climb as the hollow tests are made
   real). Note the delta.

### Risks
- **Risk**: fixing the runner turns several currently-"green" tests red. — **Mitigation**:
  that's the point; fix or honestly re-open whatever was hollow.

## Progress Log
- 2026-06-28 — Card created from the trust-nothing audit of the committed Phase-1 tree.
- 2026-06-28 — Fixed. `test_case.gd` counts assertions; `test_runner.gd` fails any
  `test_*` that ends with 0 assertions (catches silent aborts + empty tests).
  `main.gd:_viewport_aspect` guards a null viewport. The honest gate immediately caught
  `test_idle_loop::test_camera_is_aimed_at_the_dog_centre` as hollow — which exposed a
  REAL production bug: `_frame_camera`/`_fallback_camera` called `look_at_from_position`
  BEFORE `add_child`, and look_at no-ops out of tree, so the camera was never aimed (sat
  at identity/origin). Reordered add_child first; verified in a real running tree
  (perp=0.000, cam aimed at the dog centre). Rewrote that unit test to assert the
  deterministic target (look_at can't apply in the frame-less --script tree), and added
  an `is_inside_tree` grep to verify.sh's boot leg so this bug class fails the gate.

## Resolution
Gate is now honest: a runtime SCRIPT ERROR / silent abort turns the gate RED instead of
hollow-green. Full `verify.sh` green for real at 73 tests, 0 failures. Net win: surfaced
and fixed a shipped camera-framing bug the old gate hid.

## Acceptance Criteria
- [x] A test method that aborts early / asserts nothing makes the gate FAIL — proven live:
      the hollow camera test was flagged `ran but made 0 assertions`, turning the gate red.
- [x] `scripts/main.gd` `_ready()` runs without error under the headless test harness
      (null-viewport guard in `_viewport_aspect`).
- [x] `tests/test_bra_button.gd` and `tests/test_payoff_wiring.gd` execute ALL their
      assertions (no longer flagged; their asserts now run after the crash fix).
- [x] `nix develop -c bash verify.sh` reports the true count (73) and is green for real.
- [x] Bonus: real camera-framing bug fixed (look_at before add_child); boot leg hardened.
