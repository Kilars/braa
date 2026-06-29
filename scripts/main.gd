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

## The tracked CC0 placeholder dog — public, no Sitt clip. Fallback only.
const DOG_SCENE_PATH := "res://assets/models/dog.glb"
## The licensed Labrador (gitignored, ADR-0002/0006) — carries the real
## `Sitting_start/loop/end`, idle, and reaction clips. Present in local dev; absent in
## public CI until the ADR-0006 encrypted pack ships. When here, it's preferred.
const LICENSED_DOG_PATH := "res://assets/models/dog_licensed.glb"

## Emitted on every BRA tap with the scored tier (SitWindow.Tier). The payoff
## (voice + SFX + dog reaction, P1-6/024f) and the timing readout (P1-7/024g) hang
## off this — they key off SitWindow.is_successful(tier); a DEAD/MISS stays silent.
signal marked(tier: int)

## Drives the loaded dog's animation (idle now; sit when the dog can, 024b).
var _director: DogDirector

## Owns "is a sit markable right now, and at what t" for the BRA tap (024e). Stays
## closed on the CC0 dog (no Sitt) so every tap is DEAD — no penalty (P1-5).
var _session := SitSession.new()

## The repeating round loop (027, P1-9): drives idle → sit → idle → sit … each frame so
## the mark never stalls after one sit. Pure state machine; main acts on its Intent.
var _loop: SitLoop
## The scoring window of the sit currently open (or null between sits) — the single
## source the score, the tell, and the loop's sit_end all read, so they never disagree.
var _window: SitWindow

## The apex tell (024d): the honest pulse that peaks at the same apex the score uses.
## Built only when a real sit opens (sit-capable dog); null on the CC0 dog, so the
## marker stays dark — the tell never fires during idle (P1-4).
var _tell: ApexTell
var _tell_marker: ApexTellMarker

## The honest timing readout (024g, P1-7): flashes PERFECT / OK / MISS on each tap and
## fades. Driven from _on_bra_pressed (the tier) + _process (the fade). A DEAD tap shows
## nothing — so on the CC0 dog (every tap DEAD) it stays blank, matching the silent payoff.
var _readout: TierReadout

## The mark payoff (024f, P1-6): voice + UI click on a successful mark, gated off the
## scored tier so a MISS/DEAD is silent. The dog's positive reaction runs through the
## director. On the CC0 dog every tap is DEAD, so the payoff never fires until the
## sit-capable Labrador ships (025) — same gate as the tell and the taps.
var _payoff: PayoffPlayer

## Reduced-motion damping for the tell (P1-8), in (0, 1]. 1.0 = full. 024g sets this
## from prefers-reduced-motion before the sit opens; ApexTell dampens (never removes)
## the cue by this factor. Kept as a seam here so the damping has one source.
var _motion_scale := 1.0

## Test seam (024g): force the prefers-reduced-motion read without a browser. -1 = auto
## (use ReducedMotion.query() — false in headless/desktop), 0 = force not-reduced,
## 1 = force reduced. Set before _ready. Production leaves it -1 → real query.
var reduced_motion_override := -1

## Visual-review seam (030/P1-4): set true by _query_force_tell() when the web page URL
## carries `?bra_force_tell=1`, pinning the apex tell to full intensity every frame so a
## SINGLE screenshot deterministically proves the gold ring renders. The live tell peaks for
## only ~0.2s per sit cycle — too brief for a non-deterministic screenshot burst to reliably
## catch — so this is the visual gate's deterministic hook. Web-only and off by default, so
## desktop, headless, and normal web play are untouched. Mirrors dog_path_override.
var _force_tell := false

func _ready() -> void:
	_apply_reduced_motion()  # set _motion_scale BEFORE _start_dog builds the tell (P1-8)
	_setup_environment()
	_setup_light()
	var dog := _load_dog()
	if dog != null:
		_start_dog(dog)
		_frame_camera(dog)
		_setup_contact_shadow(dog)  # anchor the dog to the ground, not floating (031/P1-1)
	else:
		_fallback_camera()
	_setup_bra_button()
	_setup_payoff()
	_force_tell = _query_force_tell()  # deterministic apex-tell pixel proof (030, web-only seam)
	_notify_web_ready()

## Visual-review seam (030/P1-4): true only when the live web page URL carries
## `?bra_force_tell=1`. The live tell peaks for ~0.2s per sit cycle — too brief for a
## non-deterministic screenshot burst to reliably catch — so the capture harness loads the
## build with this query to PIN the tell on for one deterministic gold-ring screenshot.
## Web-only (the query lives in window.location), so desktop/headless/normal play never trip
## it; JavaScriptBridge.eval is a no-op off the web export.
func _query_force_tell() -> bool:
	if not OS.has_feature("web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	return typeof(search) == TYPE_STRING and (search as String).contains("bra_force_tell=1")

## Resolve prefers-reduced-motion (the test seam wins, else the live query) into the
## single motion-scale the tell is built from (P1-8). Called first in _ready so the
## damping is in place before any cue is constructed.
func _apply_reduced_motion() -> void:
	var reduced: bool
	if reduced_motion_override >= 0:
		reduced = reduced_motion_override == 1
	else:
		reduced = ReducedMotion.query()
	set_motion_scale(ReducedMotion.scale_for(reduced))

## The motion-scale the authored cues (the apex tell) are built with — 1.0 full, < 1.0
## dampened for reduced motion (never 0). Exposed for the P1-8 wiring test.
func motion_scale() -> float:
	return _motion_scale

## Run the sit clock so a tap is scored at the right seconds-into-the-sit, then drive
## the apex tell off that same clock — one source of truth, so the glow peaks exactly
## when a tap scores PERFECT. While no sit is open (the CC0 dog) the marker is held
## dark: the tell never fires during idle (P1-4).
func _process(delta: float) -> void:
	_session.advance(delta)
	_advance_loop(delta)
	if _tell_marker != null:
		if _force_tell:
			_tell_marker.set_intensity(1.0)  # deterministic capture seam (030) — web-only
		elif _tell != null and _session.is_open():
			_tell_marker.set_intensity(_tell.intensity(_session.elapsed()))
		else:
			_tell_marker.set_intensity(0.0)
	if _readout != null:
		_readout.advance(delta)  # fade the last tier's flash (024g/P1-7)

## Drive the repeating round loop (027, P1-9): each frame SitLoop decides whether to begin
## the next sit or stand the dog back to idle. A no-op until _start_dog builds _loop, and a
## permanent idle on the CC0 dog (has_sit == false) — never a faked sit.
func _advance_loop(delta: float) -> void:
	if _loop == null or _director == null:
		return
	var sit_end := _window.sit_end if _window != null else 0.0
	match _loop.tick(delta, _director.has_sit(), _session.elapsed(), sit_end):
		SitLoop.Intent.START_SIT:
			_begin_sit()
		SitLoop.Intent.END_SIT:
			_end_sit()

## Begin one sit: play it, open the scoring window over its markable span, and build the
## apex tell from that SAME window so the glow peaks exactly where a tap scores PERFECT
## (P1-4 honest tell — one source of truth). _process advances the clock; the button reads it.
func _begin_sit() -> void:
	_director.play_sit()
	_window = _director.sit_window()
	_session.open(_window)
	_tell = ApexTell.from_window(_window, _motion_scale)

## End the sit: close the session (taps DEAD again, no penalty between sits — P1-5), drop
## the tell so the marker goes dark, and stand the dog back down to the ambient idle so the
## loop can come round to the next sit (P1-9).
func _end_sit() -> void:
	_session.close()
	_window = null
	_tell = null
	_director.play_idle()

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

## Portrait layout constants (029). The project pins a 720×1280 logical viewport
## (stretch=keep), so these are stable everywhere — headless, browser, any device.
## The BRA button band and the apex-tell marker are deliberately coupled: the marker
## sits 4 px outside the button on every edge so the pulse *rings* the verb. Expressing
## the tell offsets in terms of the button's keeps that coupling alive across a resize,
## instead of two bare literals that can silently drift apart.
const VIEWPORT_W := 720.0
const VIEWPORT_H := 1280.0
## BRA button: anchored across the bottom band, a comfortable thumb margin in (P1-5).
const BRA_OFFSET_LEFT := 48.0
const BRA_OFFSET_RIGHT := -48.0
const BRA_OFFSET_TOP := -280.0
const BRA_OFFSET_BOTTOM := -88.0
## Apex-tell marker: 4 px outside the button band so the pulse rings the verb (024d).
const TELL_RING_MARGIN := 4.0
const TELL_HALF_WIDTH := 100.0  ## half of the 200px-wide pulse square, centred on the band
const TELL_OFFSET_TOP := BRA_OFFSET_TOP - TELL_RING_MARGIN
const TELL_OFFSET_BOTTOM := BRA_OFFSET_BOTTOM + TELL_RING_MARGIN
## Timing readout: a band across the upper portrait area, clear of dog and button (024g).
const READOUT_OFFSET_LEFT := 24.0
const READOUT_OFFSET_RIGHT := -24.0
const READOUT_OFFSET_TOP := 96.0
const READOUT_OFFSET_BOTTOM := 220.0

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

## A cheap blob contact shadow under the feet so the dog reads as standing ON something
## (031/P1-1), not floating against flat blue. A flat unshaded soft-alpha disc laid on the
## ground at the dog's foot plane and sized to its footprint via the SAME DogBounds the
## camera frames from — so it's model-agnostic (CC0 + licensed Labrador) and ships unchanged
## in the encrypted pck (ADR-0006). Chosen over real-time shadow mapping: cheaper (one
## unshaded quad, no per-frame shadow-map cost — Phase 7 mobile budget), reduced-motion-safe
## (static), and it needs no separate ground plane to catch a projected shadow.
func _setup_contact_shadow(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		# No measurable mesh — no honest foot plane to anchor to; skip rather than guess.
		return
	var blob := MeshInstance3D.new()
	blob.name = "ContactShadow"
	var disc := PlaneMesh.new()  # lies flat in the XZ plane (normal +Y), centred — a ground decal
	var diameter := ContactShadow.radius(box) * 2.0
	disc.size = Vector2(diameter, diameter)
	blob.mesh = disc
	blob.material_override = _contact_shadow_material()
	blob.position = ContactShadow.position(box)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # it IS the shadow
	add_child(blob)

## The blob's material: an unshaded flat-black disc whose alpha is a soft radial falloff
## (dark at the centre, transparent at the rim) so it reads as a smudge of shadow, not a
## hard coaster. The falloff is a procedural radial GradientTexture2D (no shader to compile
## — headless-safe) on an unshaded, double-sided, alpha-blended StandardMaterial3D.
func _contact_shadow_material() -> StandardMaterial3D:
	var grad := Gradient.new()
	grad.set_color(0, Color(0.0, 0.0, 0.0, 0.45))  # centre: soft dark, under the budget
	grad.set_color(1, Color(0.0, 0.0, 0.0, 0.0))   # rim: fully transparent
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)  # centre of the disc
	tex.fill_to = Vector2(0.5, 1.0)    # reaches transparent by the rim
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # visible even if the camera dips below
	return mat

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
		return VIEWPORT_W / VIEWPORT_H
	var size := vp.get_visible_rect().size
	if size.y <= 0.0:
		return VIEWPORT_W / VIEWPORT_H
	return size.x / size.y

## The dog's bounds in dog-local space. Delegates to the pure, unit-tested DogBounds:
## it prefers the skeleton REST-POSE BONE SPAN (the honest standing extent — feet on the
## floor) over the skinned mesh's get_aabb(), whose authoring frame need not match the
## rig. The CC0 mesh box happened to match its bones, but the licensed Labrador's mesh
## box is centred below the floor, so framing off it aimed under the dog and cut the head
## off (024c regression). Bones fix it model-agnostically, with no per-model tuning.
func _dog_bounds(dog: Node) -> AABB:
	return DogBounds.measure(dog)

## Pick the dog to load: the licensed Labrador (real Sitt) when it's present locally,
## else the tracked CC0 placeholder. ResourceLoader.exists() is a presence check that
## doesn't error when the licensed asset is absent (public CI), so the scene degrades
## cleanly to the CC0 dog there until the ADR-0006 encrypted pack ships. (025)
## Test seam: when set (before _ready), forces a specific dog so scene-mount tests are
## deterministic regardless of which assets sit on disk locally. Production leaves it ""
## → auto-select below. (025)
var dog_path_override := ""

func _dog_path() -> String:
	if dog_path_override != "":
		return dog_path_override
	if ResourceLoader.exists(LICENSED_DOG_PATH):
		return LICENSED_DOG_PATH
	return DOG_SCENE_PATH

## Load + instantiate the dog. The loaded glb IS the dog — no bare primitive geometry
## stands in for it (P1-1, ADR-0002). Returns the instance, or null if it failed to load.
func _load_dog() -> Node:
	var path := _dog_path()
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("[Bra!] dog model failed to load: %s" % path)
		return null
	var dog := packed.instantiate()
	dog.name = "Dog"
	add_child(dog)
	var flattened := CoatOpaque.flatten(dog)  # kill the translucent fur-mask panels (032/P1-1/P1-9)
	print("[Bra!] dog loaded: %s (%d coat surface(s) forced opaque)" % [path, flattened])
	return dog

## Bring the dog to life: loop its ambient idle so it isn't a frozen rest pose
## (P1-2). On a sit-capable dog (licensed Labrador) the director also owns the
## build→apex→hold sit (024b); on the CC0 placeholder there is no Sitt clip, so we
## log the gap honestly and stay in idle — never a faked sit (see task 024b).
func _start_dog(dog: Node) -> void:
	var ap := DogClips.find_animation_player(dog)
	if ap == null:
		push_warning("[Bra!] dog has no AnimationPlayer — cannot animate")
		return
	_director = DogDirector.new(ap)
	_director.play_idle()
	# The repeating round loop (027/P1-9) drives the rest from _process: it waits a calm
	# beat, plays the sit + opens the scoring window (_begin_sit), holds the seat, then
	# stands back to idle (_end_sit) and comes round again — the mark never stalls after
	# one sit. On the CC0 dog (no Sitt) the loop simply parks in idle; no faked sit.
	_loop = SitLoop.new()
	if _director.has_sit():
		# Sit-capable dog (licensed Labrador, 025): the loop sits every inter_sit_gap
		# seconds; each sit's apex (the score's PERFECT instant) is the single source the
		# tell is built from in _begin_sit. _process advances the sit clock.
		print("[Bra!] dog can Sitt — looping a sit every %.1fs (real apex from the licensed Labrador)"
			% _loop.inter_sit_gap)
	else:
		# CC0 dev fallback: no sit, so the loop parks in idle and every BRA tap is DEAD
		# (does nothing, no penalty — P1-5). The button still works; it lights up the
		# moment the licensed Sitt ships (024b / ADR-0006 / 025).
		print("[Bra!] dog has no Sitt clip (CC0 dev fallback) — idle only; "
			+ "real Sitt ships with the licensed Labrador, see task 024b / ADR-0006")

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
	bra.offset_left = BRA_OFFSET_LEFT
	bra.offset_right = BRA_OFFSET_RIGHT
	bra.offset_top = BRA_OFFSET_TOP
	bra.offset_bottom = BRA_OFFSET_BOTTOM
	bra.focus_mode = Control.FOCUS_NONE  # no keyboard focus ring on a touch target
	ui.add_child(bra)
	bra.pressed.connect(_on_bra_pressed)
	_setup_tell_marker(ui)
	_setup_readout(ui)

## The apex-tell pulse (024d/P1-4), centred over the BRA marker. Added ON TOP of the
## button but with mouse input ignored, so it glows around the verb without ever
## eating a tap. Starts dark; _process drives it from the tell during a sit only.
func _setup_tell_marker(ui: CanvasLayer) -> void:
	var marker := ApexTellMarker.new()
	marker.name = "TellMarker"
	# A 200×200 square centred on the BRA button band (button centre ≈ 184px above
	# the bottom edge), so the pulse rings the verb the thumb is reaching for. The
	# top/bottom offsets are derived from the button band (± TELL_RING_MARGIN), so the
	# ring follows the verb if the button band ever moves.
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 1.0
	marker.anchor_bottom = 1.0
	marker.offset_left = -TELL_HALF_WIDTH
	marker.offset_right = TELL_HALF_WIDTH
	marker.offset_top = TELL_OFFSET_TOP
	marker.offset_bottom = TELL_OFFSET_BOTTOM
	ui.add_child(marker)
	_tell_marker = marker

## The timing readout (024g/P1-4... P1-7): a big centred word that flashes the scored
## tier in the upper third — well clear of the dog's centre and the bottom BRA band —
## then fades. Mouse-transparent so it never eats a tap. Starts blank; driven by
## _on_bra_pressed (display) + _process (fade).
func _setup_readout(ui: CanvasLayer) -> void:
	var readout := TierReadout.new()
	readout.name = "TierReadout"
	# A band across the upper portrait area: full width, anchored near the top so the
	# word sits above the centred dog and never collides with the BRA button below.
	readout.anchor_left = 0.0
	readout.anchor_right = 1.0
	readout.anchor_top = 0.0
	readout.anchor_bottom = 0.0
	readout.offset_left = READOUT_OFFSET_LEFT
	readout.offset_right = READOUT_OFFSET_RIGHT
	readout.offset_top = READOUT_OFFSET_TOP
	readout.offset_bottom = READOUT_OFFSET_BOTTOM
	ui.add_child(readout)
	_readout = readout

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
	if _readout != null:
		_readout.display(tier)  # flash PERFECT/OK/MISS now; DEAD shows nothing (024g/P1-7)
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
