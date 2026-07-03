extends "res://tests/test_case.gd"
## TrickMenu feedback row tests — the "Give feedback" row is reachable in the menu and emits
## a signal when tapped. Mirrors the tap-simulation + signal-flag pattern used in test_trick_menu.gd.

const SITT := DogClips.TRICK_SITT

func test_menu_has_feedback_row_center() -> void:
	var m: TrickMenu = TrickMenu.new()
	m.size = Vector2(390.0, 844.0)  # headless: pin the phone-portrait size
	m.set_rows([{"id": SITT, "state": TrickMenu.State.LEARNED}], 30)
	var center: Vector2 = m.feedback_row_center()
	assert_ne(center, Vector2.ZERO, "feedback row center is non-zero once menu has a size")
	m.free()

func test_tapping_feedback_row_emits_feedback_requested() -> void:
	var m: TrickMenu = TrickMenu.new()
	m.size = Vector2(390.0, 844.0)
	m.set_rows([{"id": SITT, "state": TrickMenu.State.LEARNED}], 30)
	var got := {"feedback_requested": false}
	m.feedback_requested.connect(func(): got.feedback_requested = true)
	var ev: InputEventMouseButton = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = m.feedback_row_center()
	m._gui_input(ev)
	assert_true(got.feedback_requested, "tapping the feedback row emits feedback_requested")
	m.free()
