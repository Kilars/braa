extends "res://tests/test_case.gd"
## TDD for the 071 scratch feint (P3, PO note 3 "use the scratch as a feint, it's funny").
## DogDirector.play_scratch() plays the real `Scratching` clip ONCE (never looped) and then queues
## idle so the dog stands back to its ambient rest — the same honest one-shot-then-idle pattern as
## play_trick_feint / play_reaction. On a dog with no scratch clip (the CC0 placeholder) it is a
## no-op, so a scratch-less dog never fakes one (the asset gate the licensed Labrador does hold:
## its `Scratching` clip is in the manifest). Built on a synthetic AnimationPlayer like the feint test.

func _ap_with(clips: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for name in clips:
		lib.add_animation(name, Animation.new())
	ap.add_animation_library("", lib)
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ap)
	return ap

func test_scratch_plays_once_then_queues_idle() -> void:
	var ap := _ap_with(["Idle", "Scratching"])
	var dir := DogDirector.new(ap)
	assert_true(dir.has_scratch(), "a dog with a Scratching clip can scratch")
	dir.play_scratch()
	assert_eq(ap.current_animation, "Scratching", "play_scratch plays the real scratch clip")
	assert_eq(ap.get_animation("Scratching").loop_mode, Animation.LOOP_NONE,
		"the scratch plays ONCE, never loops (it's a brief feint, not a hold)")
	assert_true(ap.get_queue().has("Idle"), "after the scratch the dog stands back to idle")
	ap.queue_free()

func test_scratch_is_a_noop_on_a_scratchless_dog() -> void:
	# The CC0 case: idle + locomotion only, no scratch clip. play_scratch must do nothing and not
	# error — never fake a scratch the asset can't perform (the asset gate).
	var ap := _ap_with(["Idle", "Walk"])
	var dir := DogDirector.new(ap)
	assert_false(dir.has_scratch(), "an idle-only/locomotion dog has no scratch clip")
	dir.play_scratch()
	assert_ne(ap.current_animation, "Walk", "a scratch never grabs a generic clip on a scratch-less dog")
	assert_ne(ap.current_animation, "Scratching", "no scratch clip to play")
	ap.queue_free()
