extends "res://tests/test_case.gd"
## TDD for the dog's positive reaction on a successful mark (024f, P1-6). DogClips
## resolves the reaction clip (test_dog_clips); here the director must PLAY it once on
## a sit-capable dog and stay graceful (a logged no-op, never a faked celebration) on a
## dog with no reaction clip — the CC0 placeholder. Built on a synthetic AnimationPlayer
## so the play path is exercised without the licensed asset.

# A dog whose pack has idle + a real Sitt + a positive reaction (illustrative names).
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

func test_director_plays_the_reaction_clip_on_a_reactive_dog() -> void:
	var ap := _ap_with(["Idle", "Sitting_start", "Sitting_loop_1", "Tail_wag"])
	var dir := DogDirector.new(ap)
	assert_true(dir.has_reaction(), "a dog with a reaction clip can react")
	dir.play_reaction()
	assert_eq(ap.current_animation, "Tail_wag", "play_reaction plays the reaction clip")
	# A one-shot celebration, not a loop — it must not get stuck wagging forever.
	assert_eq(ap.get_animation("Tail_wag").loop_mode, Animation.LOOP_NONE,
		"the reaction is a one-shot, not a loop")
	ap.queue_free()

func test_reaction_is_a_noop_on_a_dog_with_no_reaction_clip() -> void:
	# The CC0 case: idle-only. play_reaction must do nothing (stay idle) and not error —
	# never fake a celebration the asset can't perform (the 024f asset gate).
	var ap := _ap_with(["Idle", "Walk", "Jump"])
	var dir := DogDirector.new(ap)
	assert_false(dir.has_reaction(), "an idle-only dog has no reaction")
	dir.play_reaction()
	assert_ne(ap.current_animation, "Jump", "a generic Jump is never used as a reaction")
	ap.queue_free()
