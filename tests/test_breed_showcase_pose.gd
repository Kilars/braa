extends "res://tests/test_case.gd"
## Scene-level wiring for the breed-showcase DOG POSE (172, PO father-pass-37, X-4). The showcase is
## "here is my dog, shown off" — but before 172 it spotlit the LIVE training rig with the idle-wander
## still running, so the hero roamed out of frame / faced away / clipped the edge. This proves the
## RUNNING scene now poses the spotlit dog as a composed portrait while the showcase is open: the
## wander PAUSES, the roam recenters to the patch centre, and the dog turns to face the camera — then
## both close paths (dismiss + commit) resume the roam so training/menu-behind carries on as before.
##
## Boots the CC0 dog (test_case default): it carries a Walk clip but no Sitt, so the wander runs every
## frame (the cleanest surface for the pause contract, independent of the gitignored licensed asset).
## Hermetic: clear the shared save so a leaked roster can't change what is owned/shown.

func _clear_save() -> void:
	if FileAccess.file_exists(TrickStore.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TrickStore.SAVE_PATH))

func test_opening_the_showcase_pauses_the_wander_and_faces_the_dog() -> void:
	_clear_save()
	var main := instantiate_main()
	for i in 30:
		main._process(0.1)  # let the dog amble off-centre first
	assert_true(main._wander_active, "the wander runs during training (precondition)")
	main._on_showcase_requested()
	assert_false(main._wander_active, "opening the showcase pauses the wander (the dog holds still, not roaming)")
	assert_true(main._facing, "opening the showcase engages the face-the-camera turn (the dog is posed, not turned away)")
	main.queue_free()
	_clear_save()

func test_opening_recenters_and_camera_faces_the_spotlit_dog() -> void:
	_clear_save()
	var main := instantiate_main()
	for i in 30:
		main._process(0.1)  # amble off-centre
	main._on_showcase_requested()
	for i in 40:
		main._process(0.1)  # let the pose settle while the showcase is open
	var off: Vector3 = main._dog.transform.origin - main._dog_rest.origin
	assert_true(off.length() < 0.02, "the spotlit dog holds at the patch centre (composed portrait, in frame)")
	var yaw_err := absf(wrapf(main._dog_yaw() - main._camera_facing_heading(), -PI, PI))
	assert_true(yaw_err < 0.05, "the spotlit dog holds facing the camera (shown off, not its back)")
	main.queue_free()
	_clear_save()

func test_both_close_paths_resume_the_wander() -> void:
	# Dismiss ("Tilbake") and commit ("Tren denne") both route through _close_showcase; each must
	# hand the dog back to its roam so training/menu-behind carries on exactly as before.
	_clear_save()
	var main := instantiate_main()
	main._on_showcase_requested()
	assert_false(main._wander_active, "wander paused while open (dismiss precondition)")
	main._on_showcase_dismissed()
	assert_true(main._wander_active, "dismissing the showcase resumes the wander")

	main._on_showcase_requested()
	assert_false(main._wander_active, "wander paused while open (commit precondition)")
	main._on_showcase_commit()
	assert_true(main._wander_active, "committing from the showcase resumes the wander")
	main.queue_free()
	_clear_save()
