extends "res://tests/test_case.gd"
## TDD for 065 / BUST-064: DogDirector drives a NAMED trick via a generic (start, loop, end) bundle,
## so a second trick (Ligg / lie down — clips already present in the licensed asset) rides the exact
## same machinery as Sitt with a clip-name swap and no new code path. Proves play_trick / trick_window
## / play_trick_end / play_trick_feint / is_ending_trick work for "ligg", degrade honestly on a dog
## that lacks the clips, and that the existing Sitt methods are unchanged wrappers over the generic
## path. Built on a synthetic AnimationPlayer so the play path runs without the licensed asset.

func _ap_with(clips: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for name in clips:
		var anim := Animation.new()
		anim.length = 1.0  # non-zero so trick_window has real clip lengths to band
		lib.add_animation(name, anim)
	ap.add_animation_library("", lib)
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ap)
	return ap

# A licensed-style pack with BOTH tricks present (Sitt + Ligg), plus the belly/sleep decoys.
func _dual_trick_ap() -> AnimationPlayer:
	return _ap_with(["Idle",
		"Sitting_start", "Sitting_1", "Sitting_end",
		"Lie_start", "Lie_1", "Lie_end",
		"Lie_belly_start", "Lie_belly_1", "Lie_Sleep_loop"])

func test_play_trick_ligg_builds_into_the_lie_then_holds() -> void:
	var dir := DogDirector.new(_dual_trick_ap())
	assert_true(dir.has_trick("ligg"), "the pack resolves a real Ligg")
	dir.play_trick("ligg")
	assert_eq(dir._ap.current_animation, "Lie_start", "Ligg plays the lie build-in first")
	assert_true(dir._ap.get_queue().has("Lie_1"), "then queues the fully-down hold loop")
	assert_eq(dir._ap.get_animation("Lie_1").loop_mode, Animation.LOOP_LINEAR, "the down hold loops")
	dir._ap.queue_free()

func test_trick_window_ligg_returns_a_real_scoring_window() -> void:
	var dir := DogDirector.new(_dual_trick_ap())
	var w := dir.trick_window("ligg")
	assert_true(w != null, "Ligg opens a real scoring window off its own clip lengths")
	assert_true(w.apex > 0.0, "the Ligg apex is the end of its build-in (non-zero)")
	dir._ap.queue_free()

func test_play_trick_end_ligg_stands_up_then_settles_to_idle() -> void:
	var dir := DogDirector.new(_dual_trick_ap())
	dir.play_trick_end("ligg")
	assert_eq(dir._ap.current_animation, "Lie_end", "Ligg exits through its authored stand-up clip")
	assert_eq(dir._ap.get_animation("Lie_end").loop_mode, Animation.LOOP_NONE, "the stand-up plays once")
	assert_true(dir._ap.get_queue().has("Idle"), "then settles into the ambient idle")
	assert_true(dir.is_ending_trick("ligg"), "is_ending_trick is true while the Ligg stand-up plays")
	assert_false(dir.is_ending_trick("sitt"), "and it is trick-specific — Sitt is not ending")
	dir._ap.queue_free()

func test_play_trick_feint_ligg_dips_without_reaching_the_hold() -> void:
	var dir := DogDirector.new(_dual_trick_ap())
	dir.play_trick_feint("ligg")
	assert_eq(dir._ap.current_animation, "Lie_start", "a Ligg feint plays the build-in dip")
	assert_eq(dir._ap.get_animation("Lie_start").loop_mode, Animation.LOOP_NONE, "the dip plays once")
	assert_false(dir._ap.get_queue().has("Lie_1"), "a feint never reaches the down hold (no markable apex)")
	assert_true(dir._ap.get_queue().has("Idle"), "the dog stands straight back up to idle")
	dir._ap.queue_free()

func test_a_dog_without_lie_clips_cannot_perform_ligg() -> void:
	# Honest asset gate (mirrors has_sit): a Sitt-only pack resolves no Ligg, so play_trick("ligg")
	# no-ops rather than faking a lie-down it can't perform.
	var dir := DogDirector.new(_ap_with(["Idle", "Sitting_start", "Sitting_1"]))
	assert_false(dir.has_trick("ligg"), "a Sitt-only dog can't do Ligg")
	dir.play_trick("ligg")
	assert_ne(dir._ap.current_animation, "Lie_start", "no Ligg clip to play — it never fakes the lie")
	dir._ap.queue_free()

func test_sit_methods_are_unchanged_wrappers_over_the_generic_trick_path() -> void:
	# The existing Sitt API must behave identically after generalization (no regression): play_sit ==
	# play_trick("sitt"), is_standing_up == is_ending_trick("sitt"), sit_window == trick_window("sitt").
	var dir := DogDirector.new(_dual_trick_ap())
	assert_eq(dir.has_sit(), dir.has_trick("sitt"), "has_sit is has_trick('sitt')")
	dir.play_sit()
	assert_eq(dir._ap.current_animation, "Sitting_start", "play_sit still plays the sit build-in")
	assert_true(dir._ap.get_queue().has("Sitting_1"), "and queues the seated hold")
	dir.play_sit_end()
	assert_true(dir.is_standing_up(), "is_standing_up mirrors is_ending_trick('sitt')")
	var w := dir.sit_window()
	assert_true(w != null and w.apex > 0.0, "sit_window still returns the Sitt scoring window")
	dir._ap.queue_free()
