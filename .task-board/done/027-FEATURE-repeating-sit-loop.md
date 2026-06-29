# FEATURE: 027 — The loop actually repeats (idle → sit → apex → tap → reaction → idle, forever)

**Status**: Done
**Created**: 2026-06-28
**Completed**: 2026-06-28
**Parent**: 024 (Phase 1 — the perfect single mark)
**Priority**: High (the one buildable, **non-owner-gated** Phase-1 gap — P1-9)
**Labels**: gameplay, godot, phase-1, tdd, logic
**Estimated Effort**: Small–Medium

## Why now (the gap, verified in code)

P1-9 requires: *"The loop (idle → sit → apex tell → tap → reaction → back to idle)
repeats indefinitely without degrading."* It does **not**. `scripts/main.gd::_start_dog`
(lines 215–239) calls `_director.play_sit()` and `_session.open(w)` **exactly once**, and
`_process` (lines 92–96) only advances the clock and updates the tell marker. Nothing ever
closes the session, returns the dog to idle, or re-triggers a new sit. `SitSession.close()`
exists (`scripts/sit_session.gd:35`) but is **never called in production**. So even locally
with the licensed Labrador the dog sits **once** and holds the seated loop forever; the
player gets one mark per page load.

This is the highest-value buildable Phase-1 work that does **not** cross the owner gate
(025 / ADR-0006 encryption): it needs no licensed asset, is pure/testable headless, and
degrades correctly on the CC0 dog (no sit → stays idle, exactly as today). It closes the
last non-gated Phase-1 functional hole and is a prerequisite for the P1-10 done-gate.

## Technical Approach (TDD: red → green, pure state machine first)

Add a pure `class_name SitLoop extends RefCounted` that owns the loop's timing/state and
emits **intents** — it never touches a Node, so it's unit-testable exactly like `SitWindow`
/ `SitSession`. `main.gd` translates each intent into the existing director/session calls.

States: `IDLE → SITTING → IDLE …`. Config: `inter_sit_gap` (seconds idle before the next
sit) and `sit_hold` (seconds to hold the seated pose past the markable window before
standing). On a dog that cannot sit, `SitLoop` parks in `IDLE` permanently (CC0 graceful).

Intent enum: `NONE`, `START_SIT`, `END_SIT`. `tick(delta, has_sit, session_elapsed,
sit_end) -> Intent`:
- in `IDLE`: accumulate `delta`; once `>= inter_sit_gap` **and** `has_sit`, return
  `START_SIT` and move to `SITTING` (reset gap timer).
- in `SITTING`: once `session_elapsed >= sit_end + sit_hold`, return `END_SIT` and move
  to `IDLE`. (Optional fast-path: a successful mark can request a shorter hold — keep
  minimal; the timeout path is the contract.)

`main.gd` wiring — replace the one-shot trigger in `_start_dog` with loop ownership, and
drive it from `_process`:

```gdscript
# BEFORE — scripts/main.gd::_start_dog (one-shot, never repeats)
_director.play_idle()
if _director.has_sit():
    _director.play_sit()
    var w := _director.sit_window()
    _session.open(w)
    _tell = ApexTell.from_window(w, _motion_scale)
# (no else-path change)

# AFTER — _start_dog sets up the loop; _process drives it
_director.play_idle()
_loop = SitLoop.new(_motion_scale)      # holds config; tracks IDLE/SITTING

# scripts/main.gd::_process
func _process(delta: float) -> void:
    _session.advance(delta)
    var sit_end := _window.sit_end if _window != null else 0.0
    match _loop.tick(delta, _director.has_sit(), _session.elapsed(), sit_end):
        SitLoop.Intent.START_SIT:
            _director.play_sit()
            _window = _director.sit_window()
            _session.open(_window)
            _tell = ApexTell.from_window(_window, _motion_scale)  # same window → honest tell
        SitLoop.Intent.END_SIT:
            _session.close()
            _tell = null
            _director.play_idle()        # stand back down to the ambient idle
    if _tell != null and _session.is_open():
        _tell_marker.set_intensity(_tell.intensity(_session.elapsed()))
    else:
        _tell_marker.set_intensity(0.0)  # dark between sits (P1-4 "never fires with nothing to mark")
```

Note the `_window` field becomes the single source for `sit_end`; `_tell` is rebuilt from
that **same** window each sit (the P1-4 honest-tell invariant — assert it in tests, covering
the previously-untested tell.apex == window.apex coupling). When the licensed pack later
ships a `Sitting_end` / stand-up clip, `DogDirector` can play it on `END_SIT`; the loop
contract here doesn't change.

## Behaviors to unit-test (`tests/test_sit_loop.gd`)

- starts in `IDLE`, first `tick` returns `NONE`.
- a no-sit dog (`has_sit=false`) **never** returns `START_SIT`, however long it ticks (CC0).
- a sit-capable dog returns `START_SIT` exactly once after `inter_sit_gap` elapses.
- after `START_SIT`, ticks return `NONE` until `session_elapsed >= sit_end + sit_hold`,
  then return `END_SIT` exactly once.
- after `END_SIT` the gap timer resets and a **second** full cycle fires `START_SIT` again
  (assert the loop repeats — two complete cycles).
- (wiring/invariant) the tell opened with each sit is built from the same window the
  session scores against: `tell.apex == window.apex` (folds the honest-tell unit gap).

## Acceptance Criteria

- [ ] `tests/test_sit_loop.gd` written first and failing, then green (red→green per `tdd`).
- [ ] `scripts/sit_loop.gd` is a pure `RefCounted` (no Node/AnimationPlayer references).
- [ ] `main.gd` drives the loop from `_process`; the one-shot `play_sit()`/`open()` in
      `_start_dog` is removed in favor of `START_SIT`.
- [ ] On the CC0 dog the scene still boots clean and stays in idle (no faked sit, no error).
- [ ] The tell marker goes dark between sits and is rebuilt from the active sit's window.
- [ ] `_session.close()` is called on `END_SIT` (taps DEAD between sits).
- [x] `tests/test_sit_loop.gd` written first and failing (RED: runner went 90→ "1 failure,
      failed to parse" on the missing `SitLoop`), then green.
- [x] `scripts/sit_loop.gd` is a pure `RefCounted` (no Node/AnimationPlayer references).
- [x] `main.gd` drives the loop from `_process` (`_advance_loop`); the one-shot
      `play_sit()`/`open()` in `_start_dog` is replaced by `_begin_sit()` on `START_SIT`.
- [x] On the CC0 dog the scene boots clean and stays idle (loop parks in IDLE; no faked sit).
- [x] The tell marker goes dark between sits (`_tell` dropped on `END_SIT`) and is rebuilt
      from the active sit's window in `_begin_sit`.
- [x] `_session.close()` is called on `END_SIT` (taps DEAD between sits).
- [x] Full gate green: `nix develop -c bash verify.sh` (import · boot · test · export),
      test count 90 → 96.

## What was built (TDD: red → green)

- **`scripts/sit_loop.gd`** — `class_name SitLoop`, a pure `RefCounted` state machine
  (`IDLE`/`SITTING`) returning a per-frame `Intent` (`NONE`/`START_SIT`/`END_SIT`) from
  `tick(delta, has_sit, session_elapsed, sit_end)`. Config `inter_sit_gap` (1.2s) +
  `sit_hold` (0.5s past the markable window). On `has_sit == false` (CC0) it parks in
  IDLE forever — never a faked sit (P1-1).
- **`tests/test_sit_loop.gd`** — 6 tests: starts IDLE; CC0 never starts a sit; sit after
  the gap; holds then ends after `sit_end + hold`; **repeats two full cycles** (the P1-9
  contract); and the honest-tell invariant `ApexTell.from_window(w).apex == w.apex`.
- **`scripts/main.gd`** — `_advance_loop()` drives the loop each frame; `_begin_sit()`
  plays the sit, opens the session, and builds the tell from the SAME window;
  `_end_sit()` closes the session, drops the tell (marker dark), and returns to idle.
  Added `_loop`/`_window` fields; `_start_dog` now sets up the loop instead of a one-shot.

## Verification

- `nix develop -c bash verify.sh` → **green** (import · boot · test · export), exit 0;
  unit tests 90 → 96, 0 failures.
- **Runtime probe on the real licensed Labrador** (throwaway SceneTree script, deleted
  after): over 22 simulated seconds it logged **5 sit BEGINs / 4 ENDs**, a steady ~4.7s
  cycle (1.2s idle + ~3.5s sit), each `window.apex = 1.250s` — proving the loop genuinely
  repeats end-to-end, not just in unit tests. Before 027 the dog sat exactly once.

## Note for the P1-10 done-gate

This closes the last **non-owner-gated** Phase-1 functional gap. The visible Sitt loop on
the **public** deploy + the live visual review remain gated on **025** (ADR-0006 encrypted
licensed pack — owner secret). Locally (licensed dog) the full loop now runs.
