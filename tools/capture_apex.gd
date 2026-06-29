extends Node
## Pixel-repro harness for the apex tell (task 030). Mounts the real main.tscn with the
## licensed (sit-capable) dog, steps the REAL _process by hand to the sit's apex — driving
## the genuine ApexTell at the genuine motion_scale, no forced override — and saves the
## framebuffer. This reproduces exactly what the player sees at the seated apex on a normal
## browser (motion_scale 1.0; desktop GL == web GL Compatibility renderer), so the gold ring
## either lands in pixels here or it doesn't.
##
## Run:  nix develop -c godot --path . --resolution 720x1280 res://tools/capture_apex.tscn
## Optional env BRA_CAPTURE_OUT (png path), BRA_FORCE_INTENSITY=1 (bypass ApexTell, force 1.0).

const LICENSED_DOG_PATH := "res://assets/models/dog_licensed.glb"

func _ready() -> void:
	var out := OS.get_environment("BRA_CAPTURE_OUT")
	if out == "":
		out = "res://.screenshots/030-apex-live.png"
	var force := OS.get_environment("BRA_FORCE_INTENSITY") == "1"
	_run(out, force)

func _run(out: String, force: bool) -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.dog_path_override = LICENSED_DOG_PATH
	add_child(main)              # fires main._ready: loads the licensed dog, builds the loop
	main.set_process(false)      # take the clock — we step _process by hand, deterministically

	# Step the loop until a sit opens (idle gap), then march to the apex.
	var dt := 1.0 / 60.0
	var opened := false
	for _i in 2400:              # up to 40s of frames — generous; the gap is ~1.2s
		main._process(dt)
		if main._session.is_open():
			opened = true
			# Walk to the apex instant (elapsed == tell.apex), the score's PERFECT peak.
			while main._session.elapsed() < main._tell.apex:
				main._process(dt)
			break
	if not opened:
		push_error("[capture] no sit ever opened — is the licensed dog sit-capable?")
		get_tree().quit(1)
		return

	if force:
		main._tell_marker.set_intensity(1.0)

	var tell := main._tell
	print("[capture] apex=%.3f elapsed=%.3f motion_scale=%.3f live_intensity=%.3f marker_a=%.3f size=%s" % [
		tell.apex, main._session.elapsed(), main.motion_scale(),
		tell.intensity(main._session.elapsed()),
		main._tell_marker.self_modulate.a, str(main._tell_marker.size)])

	# Let the marker's queued redraw composite, then grab the framebuffer.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(out)
	if err != OK:
		push_error("[capture] save_png failed: %d" % err)
		get_tree().quit(1)
		return
	print("[capture] saved %s" % out)
	get_tree().quit(0)
