extends Node
## Reaction capture — the visual gate for task 034 / P1-6 ("the mark reads as joy, not a
## lone bark"). Mounts the REAL main.tscn with the licensed, reaction-capable dog and lets
## the real round loop run until the dog is genuinely SEATED at the scoring apex, then fires
## a PERFECT mark through the real wiring (main._on_bra_pressed) so the genuine
## DogDirector.play_reaction() blends the joyful in-place hop (Jump_Place_IP) out of the
## seated pose. main._process is frozen the instant the mark fires so the loop can't yank the
## dog back to idle mid-hop; the AnimationPlayer keeps advancing on its own (it ticks with the
## tree), and we grab a wall-clock-spaced burst across the celebration + return-to-seat.
##
## The licensed reaction can only be seen NATIVELY: the local Web export ships the CC0 dog,
## which has no reaction (every tap DEAD). So this renders the licensed glb directly, the same
## native pixel path capture_apex.gd uses for the 030 apex tell.
##
## Run: nix develop -c godot --path . --resolution 390x844 res://tools/capture_reaction.tscn

const LICENSED_DOG_PATH := "res://assets/models/dog_licensed.glb"
const FRAMES := 14         ## burst length (covers ~1.4s — the hop plus the blend back to seat)
const FRAME_GAP := 0.10    ## wall-clock seconds of animation between saved frames

func _ready() -> void:
	await _run()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.dog_path_override = LICENSED_DOG_PATH
	add_child(main)              # fires main._ready: loads the licensed dog, builds the loop
	if main._director == null or not main._director.has_sit():
		push_error("[capture] licensed dog isn't sit-capable — wrong asset?")
		get_tree().quit(1)
		return
	if not main._director.has_reaction():
		push_error("[capture] licensed dog resolves NO reaction clip — 034 vocab regressed")
		get_tree().quit(1)
		return
	print("[capture] reaction clip = %s" % main._director.clips.reaction)

	# Let the real loop run until a sit opens and the clock reaches the apex (dog seated).
	var guard := 0
	while not (main._session.is_open() and main._tell != null
			and main._session.elapsed() >= main._tell.apex):
		await get_tree().process_frame
		guard += 1
		if guard > 6000:
			push_error("[capture] sit never reached apex (is the loop running?)")
			get_tree().quit(1)
			return

	var ap: AnimationPlayer = main._director._ap
	# Seated baseline (frame 00) — the pose the hop must blend cleanly OUT of.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	_grab(main, ap, 0)

	# Fire the PERFECT mark through the real wiring, then freeze the loop so it can't pull the
	# dog to idle mid-hop. The AnimationPlayer keeps animating because the tree keeps ticking.
	main._on_bra_pressed()
	main.set_process(false)
	print("[capture] PERFECT mark fired at apex; now playing %s" % ap.current_animation)

	for i in range(1, FRAMES + 1):
		await get_tree().create_timer(FRAME_GAP).timeout  # wall-clock: the hop advances in real time
		await RenderingServer.frame_post_draw
		_grab(main, ap, i)
	get_tree().quit(0)

func _grab(main: Node, ap: AnimationPlayer, i: int) -> void:
	var img := get_viewport().get_texture().get_image()
	var out := "res://.screenshots/034-reaction-%02d.png" % i
	var err := img.save_png(out)
	if err != OK:
		push_error("[capture] save_png failed (%d) for %s" % [err, out])
		return
	print("[capture] %s  clip=%s  pos=%.2f" % [out, ap.current_animation, ap.current_animation_position])
