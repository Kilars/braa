extends "res://tests/test_case.gd"
## Scene-level wiring for the post-resume tap grace (120, P4-5). The unit tests prove BackgroundGrace's
## arm/expire logic in isolation; these prove the running scene actually SWALLOWS a BRA tap while the
## grace is active (neither a mark nor a miss — no attempt counted, no erosion) and processes a tap
## normally once the window passes. Observed via _attempts, which _on_bra_pressed bumps only for a tap
## that is NOT swallowed (the grace swallow returns before the counter, like the anti-mash gate).

func test_tap_during_resume_grace_is_swallowed() -> void:
	var main := instantiate_main()
	var before: int = main._attempts
	main._grace.arm(main._now())  # simulate a resume this instant → grace active
	main._on_bra_pressed()
	assert_eq(main._attempts, before,
		"a BRA tap inside the resume grace is swallowed — no attempt counted, no mark, no erosion")
	main.queue_free()

func test_tap_after_resume_grace_is_processed() -> void:
	var main := instantiate_main()
	var before: int = main._attempts
	main._grace.arm(main._now() - 1.0)  # armed a full second ago → the grace window has expired
	main._on_bra_pressed()
	assert_eq(main._attempts, before + 1,
		"a BRA tap after the grace window is processed normally (the tap counts again)")
	main.queue_free()

func test_grace_is_not_armed_on_a_fresh_boot() -> void:
	# Dormancy: with no resume notification yet, the grace never swallows — default play is untouched.
	var main := instantiate_main()
	assert_false(main._grace.is_grace_active(main._now()),
		"a fresh boot (no resume) is never in grace — no regression to normal tapping")
	main.queue_free()
