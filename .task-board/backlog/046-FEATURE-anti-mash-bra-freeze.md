# FEATURE: 046 — One tap, then a beat (anti-mash BRA freeze) (P2-7)

**Status**: Backlog
**Created**: 2026-06-30
**Type**: FEATURE (input-hygiene logic — **test-first / TDD**; the locked/restored button state
gets a Visual Review)
**Priority**: High — self-contained, independent of 045, and it's the input-hygiene floor that
makes the erodible learned bar (P2-4/045) and the future feints (P2-8) honest: mashing must never
be a strategy before difficulty proper (P4) exists.
**Labels**: phase-2, logic, input, anti-mash, tdd, p2-7, p2-6
**Estimated Effort**: Small–Medium (one focused session)

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-7 — One tap, then a beat** is unimplemented. Today `_on_bra_pressed`
(`main.gd:526`) scores **every** press immediately — a player can mash the BRA button and the
only thing stopping a spam-PERFECT is the narrow scoring window. With P2-4's erodible bar landing
(045), mashing needs to be curbed by **input hygiene**, not penalty. This also delivers the
secondary P2-6 ("mashing should lose") by making spam taps simply not register.

Acceptance from the spec (P2-7, PO-Directive 2026-06-29):

- After **every** tap (any tier, **including a dead/empty tap**), BRA **locks for a fixed
  ~350 ms**, then re-arms. Taps during the lock are **swallowed** (not scored) and do **not**
  reset or extend the timer — a **fixed re-arm window**, not a hold-open debounce a masher could
  keep alive by tapping.
- The button **visibly reads as locked** (e.g. dims) and then restored, and that state stays
  **legible under reduced motion** (X-5 / P1-8).

## Technical approach

### 1. New pure class `TapGate` (TDD — write the failing tests first)

A `RefCounted` timer-driven gate, pure and unit-testable (mirrors `scripts/sit_session.gd` ↔
`tests/test_sit_session.gd`). It owns "is BRA armed right now?" given elapsed time, with the
**fixed-window, non-resettable** semantics the spec demands.

**Before:** _(no file)_

**After — `scripts/tap_gate.gd`:**

```gdscript
class_name TapGate
extends RefCounted
## Anti-mash freeze for the BRA button (P2-7). After an accepted tap the gate locks for a
## FIXED LOCK_S, swallowing taps until it re-arms. Pure + tickable; main advances it in _process.

const LOCK_S := 0.35  ## fixed re-arm window (~350 ms)

var _remaining := 0.0  ## seconds left in the current lock; <= 0 means armed

## True only when a tap should be accepted (gate armed). Does NOT mutate — query freely.
func is_armed() -> bool:
	return _remaining <= 0.0

## Call when a tap is ACCEPTED. Starts a fresh fixed lock. (Swallowed taps must NOT call this —
## that is what makes the window fixed, not a masher-extendable hold-open debounce.)
func lock() -> void:
	_remaining = LOCK_S

## Advance the lock clock. Re-arms automatically when it elapses.
func tick(delta: float) -> void:
	if _remaining > 0.0:
		_remaining = maxf(0.0, _remaining - delta)

## 0..1 for the lock UI (1 = just locked, 0 = armed) so the button can dim/restore.
func lock_fraction() -> float:
	return _remaining / LOCK_S
```

### 2. Gate the press + advance the clock (`main.gd`)

**Before (`scripts/main.gd:526`):**

```gdscript
func _on_bra_pressed() -> void:
	var tier := _session.tap()
	marked.emit(tier)
	...
```

**After:**

```gdscript
func _on_bra_pressed() -> void:
	if not _tap_gate.is_armed():
		return                 # swallowed during the lock — not scored, timer NOT touched
	_tap_gate.lock()           # fixed re-arm window starts on the ACCEPTED tap only
	var tier := _session.tap()
	marked.emit(tier)
	...
```

And in `_process(delta)` (alongside the existing sit clock / readout advance):

```gdscript
	_tap_gate.tick(delta)
	if _bra_button != null:
		_bra_button.disabled = not _tap_gate.is_armed()   # or a dim modulate; see step 3
```

Note: a **dead/empty** tap (no sit open) still goes through `_on_bra_pressed`, so it too locks
the gate — the spec requires the freeze after *any* tap, dead included. The gate sits **before**
`_session.tap()`, so a swallowed tap never reaches the learned bar (045) either — the two compose
cleanly.

### 3. Locked/restored button state (UI — Visual Review)

While locked, the BRA button reads as **dimmed/locked** and then restores when armed — driven off
`_tap_gate.lock_fraction()` or `is_armed()`. Must stay **legible under reduced motion** (the lock
reads by a static dim/label state, not only an animation). Follow the existing button setup in
`main.gd:_setup_bra_button` and the `is_inside_tree()` guard for any `.play()`.

## TDD — behaviors to test first (`tests/test_tap_gate.gd`)

Per `.claude/skills/tdd/SKILL.md` — red first. Assert observable behavior through `TapGate`'s
public surface:

1. **Starts armed** — a fresh gate `is_armed()`.
2. **Locks on an accepted tap** — after `lock()`, `is_armed()` is false.
3. **Re-arms after exactly the lock window** — `tick(LOCK_S)` (or just over) re-arms; `tick`
   of less than `LOCK_S` does not.
4. **Fixed window, not extendable** — `lock()`, `tick(0.2)`, then **swallowed** taps must NOT
   call `lock()`; assert that after a further `tick` totalling `LOCK_S` the gate re-arms on
   schedule (a masher tapping during the lock can't push the re-arm out).
5. **`lock_fraction` monotonically decreases** from 1.0 at lock to 0.0 at re-arm.
6. **Wiring (if observably assertable):** a press during the lock returns without emitting
   `marked` / without advancing the learned bar — in the spirit of `tests/test_payoff_wiring.gd`;
   otherwise covered by Visual Review.

## Acceptance criteria

- [ ] **Red first:** `tests/test_tap_gate.gd` written and failing before `tap_gate.gd` exists.
- [ ] `scripts/tap_gate.gd` implements the gate; behaviors 1–5 pass (green); `LOCK_S` is a named constant (~0.35 s).
- [ ] After **every** accepted tap (any tier, dead included) BRA locks for the fixed window and re-arms automatically.
- [ ] Taps during the lock are **swallowed** — not scored, `marked` not emitted, learned bar (045) untouched — and do **not** reset or extend the lock (fixed window, masher-proof).
- [ ] Button **visibly** reads locked then restored; state legible under reduced motion (reads statically, not only via motion).
- [ ] **Placeholder check** clean on the diff.
- [ ] Visual Review (phone-portrait 390×844) of the lock→restore button state, including under reduced motion — findings blocking.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).
