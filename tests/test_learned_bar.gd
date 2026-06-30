extends "res://tests/test_case.gd"
## TDD for the on-screen learned bar (045, P2-4). LearnedBar is a dumb renderer driven by
## TrickProgress's value; these assert its render-free behaviour (value clamp, mastered
## state, the setback wash firing + fading) without a framebuffer — the same approach
## TierReadout's tests use (visibility read off public fields, not pixels).

func test_fresh_bar_is_empty_and_not_flashing() -> void:
	var bar := LearnedBar.new()
	assert_eq(bar.value, 0.0, "a fresh bar starts empty")
	assert_false(bar.is_flashing(), "nothing tapped yet — no setback wash")

func test_set_value_clamps_to_unit_range() -> void:
	var bar := LearnedBar.new()
	bar.set_value(1.5)
	assert_eq(bar.value, 1.0, "value clamps to 1.0")
	bar.set_value(-0.3)
	assert_eq(bar.value, 0.0, "value clamps to 0.0")

func test_mastered_state_is_carried() -> void:
	var bar := LearnedBar.new()
	bar.set_value(1.0, true)
	assert_true(bar.mastered, "the bar shows a mastered trick when told so")

func test_setback_wash_fires_then_fades() -> void:
	var bar := LearnedBar.new()
	bar.pulse_setback()
	assert_true(bar.is_flashing(), "a setback lights the red wash")
	bar.advance(LearnedBar.FLASH_FADE)  # a full fade window
	assert_false(bar.is_flashing(), "the wash fades fully out so it never lingers")

func test_advance_is_inert_without_a_setback() -> void:
	var bar := LearnedBar.new()
	bar.advance(1.0)
	assert_false(bar.is_flashing(), "advancing with no pending setback does nothing")
