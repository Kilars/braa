extends "res://tests/test_case.gd"
## Scene-level wiring for the anti-mash freeze (046, P2-7). TapGate's fixed-window math is
## proven in isolation (test_tap_gate.gd); this proves the running scene actually GATES the
## press on it: the first tap is accepted (scores + locks the button), an immediate second tap
## is SWALLOWED (no `marked` emit — the score session and the learned bar never see it), and
## _process re-arms the gate after the fixed window so the next tap is accepted again. On the
## committed CC0 dog every accepted tap is DEAD, which is fine — we assert the GATE, not the
## score (mirrors test_payoff_wiring's intent).

var _marks := 0

func _count_mark(_tier: int) -> void:
	_marks += 1

func test_first_tap_is_accepted_and_locks_the_button() -> void:
	var main := instantiate_main()
	main.marked.connect(_count_mark)
	main._on_bra_pressed()
	assert_eq(_marks, 1, "the first tap is accepted and scored (marked emitted once)")
	assert_false(main._tap_gate.is_armed(), "an accepted tap locks the gate (P2-7)")
	main.queue_free()

func test_taps_during_the_lock_are_swallowed() -> void:
	# Mashing while locked must not score: the second/third presses return before SitSession,
	# so `marked` fires exactly once and the learned bar (045) is never touched by the spam.
	var main := instantiate_main()
	main.marked.connect(_count_mark)
	main._on_bra_pressed()  # accepted → locks
	main._on_bra_pressed()  # mash during the lock → swallowed
	main._on_bra_pressed()  # mash during the lock → swallowed
	assert_eq(_marks, 1, "taps during the lock are swallowed — not scored (P2-7)")
	main.queue_free()

func test_a_swallowed_tap_does_not_extend_the_lock() -> void:
	# The fixed window is the whole point: a masher tapping through the lock can't push the
	# re-arm out. Advance just past LOCK_S via the real frame loop, tapping every frame, and
	# the gate must still re-arm on schedule.
	var main := instantiate_main()
	var frame := 0.05
	var steps := int(ceil(TapGate.LOCK_S / frame)) + 1
	main._on_bra_pressed()  # accepted → locks
	for i in steps:
		main._on_bra_pressed()  # masher taps every frame — all swallowed, none re-lock
		main._process(frame)
	assert_true(main._tap_gate.is_armed(), "the fixed window re-arms on schedule despite mashing")
	main.queue_free()

func test_the_gate_rearms_then_accepts_again() -> void:
	var main := instantiate_main()
	main.marked.connect(_count_mark)
	main._on_bra_pressed()  # accepted → locks
	var frame := 0.05
	var steps := int(ceil(TapGate.LOCK_S / frame)) + 1
	for i in steps:
		main._process(frame)  # _process ticks the gate; no taps this time
	assert_true(main._tap_gate.is_armed(), "_process re-arms the gate after the fixed window")
	main._on_bra_pressed()  # accepted again
	assert_eq(_marks, 2, "a tap after re-arm is accepted again")
	main.queue_free()

func test_the_bra_button_reads_locked_then_restored() -> void:
	# The lock is legible without motion: a locked button is disabled and visibly dimmed, an
	# armed button is enabled and at full brightness. Static states, so the read survives
	# reduced motion (X-5) — no animation required.
	var main := instantiate_main()
	main._on_bra_pressed()  # lock
	main._process(0.0)      # let _process reflect the gate onto the button
	assert_true(main._bra_button.disabled, "the button is disabled while locked")
	assert_true(main._bra_button.modulate.a < 1.0, "the button visibly dims while locked")
	var frame := 0.05
	var steps := int(ceil(TapGate.LOCK_S / frame)) + 1
	for i in steps:
		main._process(frame)
	assert_false(main._bra_button.disabled, "the button is re-enabled once armed")
	assert_true(is_equal_approx(main._bra_button.modulate.a, 1.0), "the button restores to full brightness")
	main.queue_free()

func test_force_lock_seam_pins_the_button_locked() -> void:
	# The web-only visual-review seam (?bra_force_lock=1) pins the locked look even with the gate
	# armed, so a single screenshot proves the dim renders. Here we drive the seam directly (the
	# query itself is web-only) and assert it overrides an armed gate — keeps the seam honest.
	var main := instantiate_main()
	main._force_lock = true
	main._process(0.0)
	assert_true(main._tap_gate.is_armed(), "the gate itself is armed — the pin is the only reason it reads locked")
	assert_true(main._bra_button.disabled, "force_lock pins the button disabled for capture")
	assert_true(main._bra_button.modulate.a < 1.0, "force_lock pins the dim for capture")
	main.queue_free()
