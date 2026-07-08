extends "res://tests/test_case.gd"
## Pure model tests for FeedbackForm — tag toggle, validation, and payload construction.
## The form is a RefCounted dumb model that builds feedback payloads (text + tags + optional rating
## + screen context). These tests pin the classify/validate/build contract render-free.

func test_tags_are_the_fixed_adr_set() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	assert_eq(f.TAGS.size(), 6, "ADR-0007 defines six feedback tags")
	assert_true(f.TAGS.has("bug"), "bug tag present")
	assert_true(f.TAGS.has("idea"), "idea tag present")
	assert_true(f.TAGS.has("too_hard"), "too_hard tag present")
	assert_true(f.TAGS.has("too_easy"), "too_easy tag present")
	assert_true(f.TAGS.has("confusing"), "confusing tag present")
	assert_true(f.TAGS.has("other"), "other tag present")

func test_tag_labels_are_norwegian() -> void:
	# 181 (PO father-pass-54): the whole game is Norwegian — the tag chips must be too.
	var f: FeedbackForm = FeedbackForm.new()
	assert_eq(f.TAG_LABELS["bug"], "Feil", "bug → Feil")
	assert_eq(f.TAG_LABELS["idea"], "Idé", "idea → Idé")
	assert_eq(f.TAG_LABELS["too_hard"], "For vanskelig", "too_hard → For vanskelig")
	assert_eq(f.TAG_LABELS["too_easy"], "For lett", "too_easy → For lett")
	assert_eq(f.TAG_LABELS["confusing"], "Forvirrende", "confusing → Forvirrende")
	assert_eq(f.TAG_LABELS["other"], "Annet", "other → Annet")

func test_toggle_tag_adds_then_removes() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	assert_false(f.is_tag_on("bug"), "bug starts off")
	f.toggle_tag("bug")
	assert_true(f.is_tag_on("bug"), "bug is on after toggle")
	f.toggle_tag("bug")
	assert_false(f.is_tag_on("bug"), "bug is off after second toggle")

func test_toggle_ignores_unknown_tag() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.toggle_tag("nope")
	assert_false(f.is_tag_on("nope"), "unknown tag is never on")
	assert_true(f.selected_tags().is_empty(), "no tags selected")

func test_selected_tags_follow_tag_order() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.toggle_tag("confusing")
	f.toggle_tag("bug")
	var tags: Array = f.selected_tags()
	assert_eq(tags, ["bug", "confusing"], "selected tags follow TAGS order, not insertion order")

func test_has_text_ignores_whitespace() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.text = "   "
	assert_false(f.has_text(), "whitespace-only text is empty")
	f.text = " hi "
	assert_true(f.has_text(), "non-empty text after strip is non-empty")

func test_payload_carries_text_tags_and_context() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.text = " love it "
	f.toggle_tag("idea")
	var p: Dictionary = f.build_payload({"trick": "sitt"})
	assert_eq(p["text"], "love it", "text is stripped")
	assert_eq(p["tags"], ["idea"], "tags are collected")
	assert_eq(p["screen_context"], {"trick": "sitt"}, "screen_context is passed through")

func test_payload_omits_rating_when_not_shown() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.rating = 5
	f.rating_shown = false
	var p: Dictionary = f.build_payload({})
	assert_false(p.has("rating"), "rating omitted unless shown")

func test_payload_includes_rating_when_shown_and_set() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.rating = 4
	f.rating_shown = true
	var p: Dictionary = f.build_payload({})
	assert_eq(p["rating"], 4, "rating is included when shown and >= 1")

func test_payload_omits_rating_when_shown_but_unset() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	f.rating_shown = true
	f.rating = 0
	var p: Dictionary = f.build_payload({})
	assert_false(p.has("rating"), "unset rating (0) never travels")

func test_empty_text_still_builds() -> void:
	var f: FeedbackForm = FeedbackForm.new()
	var p: Dictionary = f.build_payload({})
	assert_eq(p["text"], "", "empty text is valid")
	assert_eq(p["tags"], [], "no tags when none selected")
