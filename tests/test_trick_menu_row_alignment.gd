extends "res://tests/test_case.gd"
## Task 195 (PO father-pass-69, X-6): the four completion-menu selection sections must share
## ONE flush row-name left edge. The trick (`_draw_row`) and difficulty (`_draw_difficulty_row`)
## names both start at `rect.x + 14.0`, but the marker-word rows drew a decorative leading pip
## (134's pre-unification "make words distinct" leftover) + an extra indent that pushed their
## names to `rect.x + 20.0` — the lone section with a purely-decorative bullet. This pins every
## section's name inset onto one shared `NAME_INSET`, flush at 14.0.

func test_shared_name_inset_is_the_flush_fourteen() -> void:
	assert_eq(TrickMenu.NAME_INSET, 14.0,
		"the shared row-name inset is the flush 14px the trick/difficulty rows already use")

func test_word_name_left_equals_the_trick_difficulty_left_edge() -> void:
	# Given any row's left x, the marker-word name must resolve to the SAME left edge the
	# trick and difficulty names use — one flush column, no per-section drift.
	var row_x := 40.0
	var trick_and_diff_left := row_x + 14.0        # what _draw_row / _draw_difficulty_row draw at
	assert_eq(TrickMenu.row_name_left(row_x), trick_and_diff_left,
		"marker-word row names start flush with the trick/difficulty names")

func test_word_name_no_longer_carries_the_old_pip_indent() -> void:
	# The pre-195 word name started at rect.x + WORD_ROW_INDENT(8) + WORD_PIP_R*2(6) + 6 = +20.0,
	# ~6px right of the flush names. The shared inset must NOT reproduce that misaligned value.
	var row_x := 40.0
	assert_ne(TrickMenu.row_name_left(row_x), row_x + 20.0,
		"the decorative pip + extra indent (old +20.0 word inset) is gone")
