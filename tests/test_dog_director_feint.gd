extends "res://tests/test_case.gd"
## TDD for the P2-8 feint (048): the dog starts a sit then ABORTS it. DogDirector.play_feint()
## plays the real sit BUILD-IN (`Sitting_start`) and stands straight back up to idle — it must
## NOT queue the seated loop, so the dip never reaches a held apex (a feint opens no scoring
## window; main keeps the session closed). On a sit-less dog (the CC0 placeholder) it is a no-op
## — never a faked dip the asset can't perform (P1-1 / the 024b asset gate). Built on a synthetic
## AnimationPlayer so the play path runs without the licensed asset, mirroring the reaction test.

# A dog whose pack has idle + a real Sitt build/hold (illustrative names).
func _ap_with(clips: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for name in clips:
		lib.add_animation(name, Animation.new())
	ap.add_animation_library("", lib)
	# In-tree so play() has a valid context (mirrors the scene-level tests).
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(ap)
	return ap

func test_feint_plays_the_buildin_then_returns_to_idle() -> void:
	var ap := _ap_with(["Idle", "Sitting_start", "Sitting_loop_1"])
	var dir := DogDirector.new(ap)
	assert_true(dir.has_sit(), "a sit-capable dog can feint")
	dir.play_feint()
	assert_eq(ap.current_animation, "Sitting_start", "a feint plays the real sit build-in")
	assert_eq(ap.get_animation("Sitting_start").loop_mode, Animation.LOOP_NONE,
		"the feinted dip does not loop")
	var queue := ap.get_queue()
	assert_true(queue.has("Idle"), "after the dip the dog stands straight back to idle")
	assert_false(queue.has("Sitting_loop_1"),
		"a feint NEVER queues the seated hold — it has no markable apex")
	ap.queue_free()

func test_feint_is_a_noop_on_a_sitless_dog() -> void:
	# The CC0 case: idle-only, no Sitt build-in. play_feint must do nothing and not error —
	# never fake a dip the asset can't perform (the 024b asset gate).
	var ap := _ap_with(["Idle", "Walk"])
	var dir := DogDirector.new(ap)
	assert_false(dir.has_sit(), "an idle-only dog can't sit (so can't feint)")
	dir.play_feint()
	assert_ne(ap.current_animation, "Walk", "a feint never grabs a generic clip on a sit-less dog")
	ap.queue_free()
