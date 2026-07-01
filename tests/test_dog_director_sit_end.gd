extends "res://tests/test_case.gd"
## TDD for 059 (P2 dead-seam fix): the sit cycle's missing third beat. DogDirector.play_sit_end()
## stands the dog back up with its AUTHORED stand-up clip (`Sitting_end`, resolved into
## clips.sit_end but — before 059 — never played by any director method) then settles into idle.
## On a dog with no stand-up clip it degrades to a plain idle so the dog is never frozen mid-sit
## (never a faked pose; the CC0 asset gate holds). is_standing_up() lets main hold the ambient
## roam in place while the stand-up reads, without touching the SitLoop cadence. Built on a
## synthetic AnimationPlayer so the play path runs without the licensed asset (mirrors the feint test).

# A dog whose pack has idle + a real Sitt build/hold/stand-up (illustrative names).
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

func test_sit_end_plays_the_standup_then_settles_to_idle() -> void:
	var ap := _ap_with(["Idle", "Sitting_start", "Sitting_1", "Sitting_end"])
	var dir := DogDirector.new(ap)
	assert_eq(dir.clips.sit_end, "Sitting_end", "the licensed-style pack resolves a stand-up clip")
	dir.play_sit_end()
	assert_eq(ap.current_animation, "Sitting_end", "standing up plays the authored stand-up clip")
	assert_eq(ap.get_animation("Sitting_end").loop_mode, Animation.LOOP_NONE,
		"the stand-up plays once, never loops")
	assert_true(ap.get_queue().has("Idle"), "after standing up the dog settles into the ambient idle")
	ap.queue_free()

func test_is_standing_up_true_only_while_the_standup_plays() -> void:
	var ap := _ap_with(["Idle", "Sitting_start", "Sitting_1", "Sitting_end"])
	var dir := DogDirector.new(ap)
	assert_false(dir.is_standing_up(), "not standing up before the stand-up is played")
	dir.play_sit_end()
	assert_true(dir.is_standing_up(), "standing up while the stand-up clip is the current animation")
	dir.play_idle()
	assert_false(dir.is_standing_up(), "no longer standing up once idle takes over")
	ap.queue_free()

func test_sit_end_falls_back_to_idle_with_no_standup_clip() -> void:
	# A dog with a sit build/hold but NO stand-up clip: play_sit_end must still leave it alive at
	# rest (idle), never frozen on the seated pose and never faking a stand-up it can't perform.
	var ap := _ap_with(["Idle", "Sitting_start", "Sitting_1"])
	var dir := DogDirector.new(ap)
	assert_eq(dir.clips.sit_end, "", "no authored stand-up clip in this pack")
	dir.play_sit_end()
	assert_eq(ap.current_animation, "Idle", "with no stand-up clip the dog settles straight to idle")
	assert_false(dir.is_standing_up(), "a plain idle fallback is not a stand-up in progress")
	ap.queue_free()
