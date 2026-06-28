extends Node3D
## Bra! — Phase 1 stage root (scaffold).
##
## Boots a clean, bright 3D stage and loads the dog model from the kept
## CC0 asset. This is the SCAFFOLD: it proves the Godot project boots, the
## glTF dog imports and instantiates, and the web readiness hook fires.
## Phase 1 gameplay — idle / sit-with-apex / the BRA tap / scoring / payoff
## (specs2.md P1-1…P1-9) — is built on top of this in later TDD tasks.
##
## Stack: Godot 4 (ADR-0001), typed GDScript (ADR-0003).

const DOG_SCENE_PATH := "res://assets/models/dog.glb"

## Emitted on every BRA tap with the scored tier (SitWindow.Tier). The payoff
## (voice + SFX + dog reaction, P1-6/024f) and the timing readout (P1-7/024g) hang
## off this — they key off SitWindow.is_successful(tier); a DEAD/MISS stays silent.
signal marked(tier: int)

## Drives the loaded dog's animation (idle now; sit when the dog can, 024b).
var _director: DogDirector

## Owns "is a sit markable right now, and at what t" for the BRA tap (024e). Stays
## closed on the CC0 dog (no Sitt) so every tap is DEAD — no penalty (P1-5).
var _session := SitSession.new()

## The apex tell (024d): the honest pulse that peaks at the same apex the score uses.
## Built only when a real sit opens (sit-capable dog); null on the CC0 dog, so the
## marker stays dark — the tell never fires during idle (P1-4).
var _tell: ApexTell
var _tell_marker: ApexTellMarker

## The mark payoff (024f, P1-6): voice + UI click on a successful mark, gated off the
## scored tier so a MISS/DEAD is silent. The dog's positive reaction runs through the
## director. On the CC0 dog every tap is DEAD, so the payoff never fires until the
## sit-capable Labrador ships (025) — same gate as the tell and the taps.
var _payoff: PayoffPlayer

## Reduced-motion damping for the tell (P1-8), in (0, 1]. 1.0 = full. 024g sets this
## from prefers-reduced-motion before the sit opens; ApexTell dampens (never removes)
## the cue by this factor. Kept as a seam here so the damping has one source.
var _motion_scale := 1.0

func _ready() -> void:
	_setup_environment()
	_setup_light()
	var dog := _load_dog()
	if dog != null:
		_start_dog(dog)
		_frame_camera(dog)
	else:
		_fallback_camera()
	_setup_bra_button()
	_setup_payoff()
	_notify_web_ready()

## Run the sit clock so a tap is scored at the right seconds-into-the-sit, then drive
## the apex tell off that same clock — one source of truth, so the glow peaks exactly
## when a tap scores PERFECT. While no sit is open (the CC0 dog) the marker is held
## dark: the tell never fires during idle (P1-4).
func _process(delta: float) -> void:
	_session.advance(delta)
	if _tell_marker != null:
		if _tell != null and _session.is_open():
			_tell_marker.set_intensity(_tell.intensity(_session.elapsed()))
		else:
			_tell_marker.set_intensity(0.0)

## Bright, clean backdrop (Pokémon-GO-ish) so the dog reads clearly (P1-1).
func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.53, 0.81, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 0.6
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

func _setup_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.light_energy = 1.2
	add_child(sun)

## How much of the tighter frame dimension the dog spans — leaves margin above and
## below so it's centred with breathing room and clears the bottom BRA band, not
## edge-to-edge (P1-2 / D12).
const FRAME_FILL := 0.70

## Centre the dog in portrait and fit the camera to its actual bounds, so it reads
## centred whichever dog ships — the CC0 placeholder or the licensed Labrador, with
## no per-model tuning (P1-2 "centred"; D12 / PO-Change-3). DogFraming is pure +
## unit-tested; this just measures the dog and aims a Camera3D.
func _frame_camera(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		# No measurable mesh (shouldn't happen with the committed dog) — don't ship a
		# blind camera; fall back to a sane default rather than framing on nothing.
		_fallback_camera()
		return
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	# add_child BEFORE look_at_from_position: look_at requires the node to be inside the
	# tree — called before, it errors and no-ops, leaving the camera at identity (origin,
	# -Z) so the dog is never actually framed. (026 — honest gate caught this.)
	add_child(cam)
	var aspect := _viewport_aspect()
	var eye := DogFraming.eye(box, cam.fov, aspect, FRAME_FILL)
	cam.look_at_from_position(eye, DogFraming.target(box), Vector3.UP)
	cam.make_current()

## Default camera if the dog can't be measured/loaded — keeps the scene viewable.
func _fallback_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	add_child(cam)  # before look_at — see _frame_camera (026)
	cam.look_at_from_position(Vector3(0.0, 1.0, 3.0), Vector3(0.0, 0.9, 0.0), Vector3.UP)
	cam.make_current()

## Viewport width/height. The project pins a 720×1280 logical viewport (stretch=keep),
## so this is a stable portrait aspect everywhere — headless, browser, any device.
func _viewport_aspect() -> float:
	# get_viewport() is null when the node isn't inside a SceneTree — e.g. a headless
	# test that instantiates main and calls _ready() directly. Guard it (never call
	# get_visible_rect() on null) so _ready() is headless-safe; fall back to the pinned
	# 720×1280 portrait ratio. This used to throw at _ready and the runner hid it. (026)
	var vp := get_viewport()
	if vp == null:
		return 720.0 / 1280.0
	var size := vp.get_visible_rect().size
	if size.y <= 0.0:
		return 720.0 / 1280.0
	return size.x / size.y

## The dog's bounds in dog-local space, by accumulating node-LOCAL transforms up to
## the dog root. Done this way (not via global_transform) because a skinned glTF dog's
## global transforms only propagate after the first frame — local transforms carry the
## real placement synchronously at _ready, so framing is correct on the very first frame.
func _dog_bounds(dog: Node) -> AABB:
	var have := false
	var box := AABB()
	for vi in _visual_instances(dog):
		var x := Transform3D.IDENTITY
		var n: Node = vi
		while n != null and n != dog.get_parent():
			if n is Node3D:
				x = (n as Node3D).transform * x
			n = n.get_parent()
		var ab: AABB = x * vi.get_aabb()
		if not have:
			box = ab
			have = true
		else:
			box = box.merge(ab)
	return box

func _visual_instances(n: Node) -> Array[VisualInstance3D]:
	var out: Array[VisualInstance3D] = []
	if n is VisualInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_visual_instances(c))
	return out

## Load + instantiate the dog. The committed glb IS the dog — no bare
## primitive geometry stands in for it (P1-1, ADR-0002). Returns the instance,
## or null if it failed to load.
func _load_dog() -> Node:
	var packed := load(DOG_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("[Bra!] dog model failed to load: %s" % DOG_SCENE_PATH)
		return null
	var dog := packed.instantiate()
	dog.name = "Dog"
	add_child(dog)
	print("[Bra!] dog loaded: %s" % DOG_SCENE_PATH)
	return dog

## Bring the dog to life: loop its ambient idle so it isn't a frozen rest pose
## (P1-2). On a sit-capable dog (licensed Labrador) the director also owns the
## build→apex→hold sit (024b); on the CC0 placeholder there is no Sitt clip, so we
## log the gap honestly and stay in idle — never a faked sit (see task 024b).
func _start_dog(dog: Node) -> void:
	var ap := _find_animation_player(dog)
	if ap == null:
		push_warning("[Bra!] dog has no AnimationPlayer — cannot animate")
		return
	_director = DogDirector.new(ap)
	_director.play_idle()
	if _director.has_sit():
		# Sit-capable dog (licensed Labrador, 025): play the sit and open the
		# scoring window over its markable span so the BRA tap scores against the
		# real apex. _process advances the sit clock; the button reads it.
		_director.play_sit()
		var w := _director.sit_window()
		_session.open(w)
		# Tell built from the SAME window: it peaks at w.apex (where the score is
		# PERFECT), dampened by the reduced-motion factor (024g/P1-8).
		_tell = ApexTell.from_window(w, _motion_scale)
		print("[Bra!] dog can Sitt — apex at %.3fs, markable %.3f..%.3fs"
			% [w.apex, w.sit_start, w.sit_end])
	else:
		# CC0 dev fallback: no sit, so the session stays closed and every BRA tap
		# is DEAD (does nothing, no penalty — P1-5). The button still works; it
		# lights up the moment the licensed Sitt ships (024b / ADR-0006 / 025).
		print("[Bra!] dog has no Sitt clip (CC0 dev fallback) — idle only; "
			+ "real Sitt ships with the licensed Labrador, see task 024b / ADR-0006")

func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for child in n.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

## One big, thumb-friendly BRA button anchored across the bottom of the portrait
## frame (P1-5) — the single verb. It fires on release (Button's default
## ACTION_MODE_BUTTON_RELEASE = pointerup, P1-7), never a frame early.
func _setup_bra_button() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var bra := Button.new()
	bra.name = "BraButton"
	bra.text = "BRA"
	bra.add_theme_font_size_override("font_size", 96)
	# Span the bottom band with a comfortable thumb margin: a wide, tall target
	# reachable one-handed in portrait, clear of the dog framed above.
	bra.anchor_left = 0.0
	bra.anchor_right = 1.0
	bra.anchor_top = 1.0
	bra.anchor_bottom = 1.0
	bra.offset_left = 48.0
	bra.offset_right = -48.0
	bra.offset_top = -280.0
	bra.offset_bottom = -88.0
	bra.focus_mode = Control.FOCUS_NONE  # no keyboard focus ring on a touch target
	ui.add_child(bra)
	bra.pressed.connect(_on_bra_pressed)
	_setup_tell_marker(ui)

## The apex-tell pulse (024d/P1-4), centred over the BRA marker. Added ON TOP of the
## button but with mouse input ignored, so it glows around the verb without ever
## eating a tap. Starts dark; _process drives it from the tell during a sit only.
func _setup_tell_marker(ui: CanvasLayer) -> void:
	var marker := ApexTellMarker.new()
	marker.name = "TellMarker"
	# A 200×200 square centred on the BRA button band (button centre ≈ 184px above
	# the bottom edge), so the pulse rings the verb the thumb is reaching for.
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 1.0
	marker.anchor_bottom = 1.0
	marker.offset_left = -100.0
	marker.offset_right = 100.0
	marker.offset_top = -284.0
	marker.offset_bottom = -84.0
	ui.add_child(marker)
	_tell_marker = marker

## The audible payoff player (024f). A plain Node child holding the voice + click
## AudioStreamPlayers; it only sounds on a successful mark (the gate lives in
## MarkPayoff). Mounted once; reused for every tap.
func _setup_payoff() -> void:
	_payoff = PayoffPlayer.new()
	_payoff.name = "Payoff"
	add_child(_payoff)

## Reduced-motion hook (P1-8): 024g calls this with the prefers-reduced-motion factor
## before the sit opens; the tell is then built dampened (never removed) by it.
func set_motion_scale(scale: float) -> void:
	_motion_scale = clampf(scale, 0.0, 1.0)

## The mark: score the tap at the current seconds-into-the-sit, announce the tier, and
## land the payoff. A DEAD/MISS tap is silent and provokes no reaction (no penalty,
## P1-5/P1-6); the readout (024g) also consumes `marked`. Logs every tap for the boot gate.
func _on_bra_pressed() -> void:
	var tier := _session.tap()
	marked.emit(tier)
	_play_payoff(tier)
	if SitWindow.is_successful(tier):
		print("[Bra!] mark: %s" % SitWindow.tier_name(tier))
	else:
		print("[Bra!] tap: %s (no mark)" % SitWindow.tier_name(tier))

## Dispatch the reward for a scored tier (024f, P1-6): the voice + click through the
## PayoffPlayer and the dog's positive reaction through the director. MarkPayoff is the
## single gate — on a MISS/DEAD nothing sounds and the dog doesn't react. On the CC0 dog
## every tap is DEAD, so this is provably silent; it lights up when 025 ships the
## sit-capable Labrador (whose pack also carries the reaction clip).
func _play_payoff(tier: SitWindow.Tier) -> void:
	var payoff := MarkPayoff.for_tier(tier)
	if _payoff != null:
		_payoff.play(payoff)
	if payoff.reacts() and _director != null:
		_director.play_reaction()

## Deterministic readiness signal for the PWA splash / e2e, mirroring the
## old web shell's window.__appReady. No-op off the web export.
func _notify_web_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__appReady = true;", true)
	print("[Bra!] scaffold ready")
