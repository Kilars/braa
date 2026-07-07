extends "res://tests/test_case.gd"
## Task 157 (PO father-pass-21): the kennel inspect modal's trick line read «Kan laere: …»
## — the Norwegian «æ» written as a bare ASCII "ae" — sitting directly under a correctly
## spelled «Læreevne» stat label, so the misspelling was glaring. The Baloo 2 body font
## renders æ fine (proven by «Læreevne» in the same modal), so this was a plain typo, not a
## deliberate glyph-avoidance. Fix = the one literal at kennel_screen.gd:1419 → «Kan lære: ».
## These assert the wired label carries the correct æ ligature and no ASCII "ae" fallback.

func test_trick_line_uses_correct_ae_ligature() -> void:
	var ks := KennelScreen.new()
	var detail := {"trick_ids": [DogClips.TRICK_SITT, DogClips.TRICK_LIGG, DogClips.TRICK_LEGG_DEG]}
	var lbl: Label = ks._build_modal_trick_list(detail)
	assert_true(lbl.text.begins_with("Kan lære: "),
		"trick line must read «Kan lære: » with the real æ ligature (got «%s»)" % lbl.text)
	ks.free()

func test_trick_line_has_no_ascii_ae_misspelling() -> void:
	var ks := KennelScreen.new()
	var detail := {"trick_ids": [DogClips.TRICK_SITT]}
	var lbl: Label = ks._build_modal_trick_list(detail)
	assert_true(not lbl.text.contains("laere"),
		"trick line must not contain the ASCII «laere» misspelling (got «%s»)" % lbl.text)
	ks.free()

func test_trick_line_still_lists_the_trick_names() -> void:
	# Guard the fix didn't disturb the payload — the trick display names still follow the label.
	var ks := KennelScreen.new()
	var detail := {"trick_ids": [DogClips.TRICK_SITT, DogClips.TRICK_LIGG, DogClips.TRICK_LEGG_DEG]}
	var lbl: Label = ks._build_modal_trick_list(detail)
	assert_eq(lbl.text, "Kan lære: Sitt · Ligg · Legg deg",
		"trick line renders the correct label plus the interpuncted trick names")
	ks.free()
