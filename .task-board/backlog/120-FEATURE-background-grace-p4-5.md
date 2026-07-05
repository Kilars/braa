# 120 — FEATURE — Background grace: ignore taps right after resume (P4-5)

**Phase:** 9 (Difficulty) — current. **Independent** of 118/119.
**Story:** P4-5 "taps right after the app resumes from background are ignored, so a
notification or lock never causes a false mark."
**Type:** FEATURE (logic, TDD) + a thin `main.gd` notification hook.

## What it addresses

On mobile, returning to the app from background/lock often delivers a stray touch on
the first frame — which, in this game, would land as a **false BRA mark** (an
undeserved erosion/penalty). P4-5: for a short grace window right after resume,
ignore BRA taps so a resume never causes a false mark.

## Technical approach

1. **Pure grace model** (TDD) — a tiny testable value object, not time-of-day logic:

```gdscript
# NEW scripts/background_grace.gd
class_name BackgroundGrace
extends RefCounted
## After a resume-from-background, BRA taps within GRACE_S are ignored so a stray
## resume-touch (notification/lock) never lands a false mark (P4-5). Pure + clock-injected
## (caller passes elapsed seconds) so it is unit-testable with no real timer.
const GRACE_S := 0.35
var _armed_at := -1.0   # seconds; -1 = not armed
func arm(now: float) -> void:
	_armed_at = now
func is_grace_active(now: float) -> bool:
	return _armed_at >= 0.0 and (now - _armed_at) < GRACE_S
```

2. **Hook resume in `main.gd`** — `_notification(what)` on
`NOTIFICATION_APPLICATION_FOCUS_IN` (and/or `NOTIFICATION_WM_WINDOW_FOCUS_IN` for the
desktop/web parity) arms the grace with the current monotonic clock. The BRA tap
handler consults `is_grace_active(now)` and, if active, **swallows the tap** — no
score, no erosion, no payoff — exactly as if it never happened (not a miss, not a
mark).

```gdscript
# BEFORE — _on_bra_pressed scores every tap
func _on_bra_pressed() -> void:
	_score_tap()

# AFTER — swallow taps inside the post-resume grace window
func _on_bra_pressed() -> void:
	if _grace.is_grace_active(_now()):
		return   # stray resume-touch — ignore, neither mark nor miss
	_score_tap()
```

Use the same monotonic seconds source the rest of `main.gd` uses (e.g.
`Time.get_ticks_msec() / 1000.0`); inject it in tests. Guard the notification hook so
it is inert headless (no crash when there is no window focus event).

3. Grace must NOT block a legitimate tap once the window passes — only the ~0.35 s
right after resume. Confirm the constant reads fine in play; keep it a named const.

## Acceptance criteria

- [ ] RED first: `BackgroundGrace` — not armed → `is_grace_active` false; `arm(t)` then
  a tap at `t + 0.1` → active (swallow); at `t + GRACE_S` and later → inactive (normal).
- [ ] RED first: a `main`-level test that a BRA tap while grace is active neither scores
  nor erodes (no mark, no miss); a tap after the grace window scores normally.
- [ ] GREEN: resume-from-background arms the grace; the first stray tap inside the window
  is swallowed; play resumes normally after.
- [ ] Headless-safe: the notification hook does not error in the verify boot/test legs.
- [ ] `nix develop -c bash verify.sh` green; placeholder check clean; committed + pushed.
