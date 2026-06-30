extends "res://tests/test_case.gd"
## TDD for the anti-mash BRA freeze (046, phase2.md P2-7). TapGate is the pure input-hygiene
## gate the BRA button taps into: after an ACCEPTED tap it locks for a FIXED window (~350 ms),
## swallowing every tap until it re-arms on its own. The window is FIXED, not a hold-open
## debounce — taps during the lock are dropped and do NOT push the re-arm out, so mashing can
## never keep the gate closed. main advances it from _process and gates _on_bra_pressed on
## is_armed(); these tests pin the math in isolation (mirrors SitSession ↔ test_sit_session).

func test_a_fresh_gate_is_armed() -> void:
	var g := TapGate.new()
	assert_true(g.is_armed(), "a fresh gate accepts the first tap")

func test_an_accepted_tap_locks_the_gate() -> void:
	var g := TapGate.new()
	g.lock()
	assert_false(g.is_armed(), "after an accepted tap the gate is locked — it swallows taps")

func test_the_gate_rearms_after_the_lock_window() -> void:
	# Locked right up to the window, armed once it elapses. The second tick overshoots the
	# boundary by a clear margin so the threshold is tested honestly without leaning on exact
	# float cancellation (a frame landing a femtosecond short just re-arms one frame later).
	var g := TapGate.new()
	g.lock()
	g.tick(TapGate.LOCK_S * 0.99)
	assert_false(g.is_armed(), "still locked just before the fixed window elapses")
	g.tick(TapGate.LOCK_S * 0.02)  # total ~1.01 × LOCK_S → just past the window
	assert_true(g.is_armed(), "re-arms once the fixed window has elapsed")

func test_a_partial_tick_does_not_rearm() -> void:
	var g := TapGate.new()
	g.lock()
	g.tick(TapGate.LOCK_S * 0.5)
	assert_false(g.is_armed(), "half the window in → still locked")

func test_the_window_is_fixed_not_extendable_by_mashing() -> void:
	# A masher tapping DURING the lock must not push the re-arm out. Swallowed taps do NOT
	# call lock() (main gates them out before that), so ticking to exactly LOCK_S re-arms on
	# schedule no matter how many taps were attempted in between — the property that makes the
	# window fixed rather than a hold-open debounce.
	var g := TapGate.new()
	g.lock()
	g.tick(0.2)
	# ... a masher's taps land here; main swallows them, so lock() is NOT called again ...
	g.tick(TapGate.LOCK_S - 0.2)
	assert_true(g.is_armed(), "the fixed window re-arms on schedule — mashing can't extend it")

func test_lock_fraction_runs_from_one_down_to_zero() -> void:
	var g := TapGate.new()
	assert_true(is_equal_approx(g.lock_fraction(), 0.0), "an armed gate reads 0 (nothing to show)")
	g.lock()
	assert_true(is_equal_approx(g.lock_fraction(), 1.0), "just-locked reads full")
	g.tick(TapGate.LOCK_S * 0.5)
	assert_true(is_equal_approx(g.lock_fraction(), 0.5), "halfway through the window reads ~0.5")
	g.tick(TapGate.LOCK_S * 0.5)
	assert_true(is_equal_approx(g.lock_fraction(), 0.0), "fully re-armed reads 0")

func test_ticking_an_armed_gate_is_a_safe_noop() -> void:
	# Time passing on an already-armed gate can't drive it negative or otherwise misbehave.
	var g := TapGate.new()
	g.tick(1.0)
	assert_true(g.is_armed(), "an armed gate stays armed as time passes")
	assert_true(is_equal_approx(g.lock_fraction(), 0.0), "lock_fraction never dips below 0")
