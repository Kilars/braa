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

## Anti-mash freeze for the BRA button (046, P2-7 "one tap, then a beat"). After an ACCEPTED
## tap the gate locks for a fixed ~350 ms, swallowing taps until it re-arms — _on_bra_pressed
## gates on it and _process ticks it + reflects the locked state onto the button. Pure +
## tickable (scripts/tap_gate.gd); makes mashing never a strategy, input hygiene not penalty.
var _tap_gate := TapGate.new()
## The BRA button, kept so _process can dim + disable it while the gate is locked (046).
var _bra_button: Button

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

## Visual-review seam (033/P1-7): set by _query_force_tier() from the web URL
## `?bra_force_tier=miss|ok|perfect`, pinning the timing readout to that tier every frame
## so a SINGLE screenshot deterministically proves the word reads against the bright sky
## (the live readout flashes only ~0.6s per tap — too brief and tap-timing-dependent for a
## reliable burst, and MISS in particular is hard to provoke on demand). -1 = off. Web-only
## and off by default, so desktop, headless, and normal web play are untouched.
var _force_tier := -1

## Visual-review seam (034/P1-6): set by _query_autotap() from the web URL `?bra_autotap=1`.
## When on, the game fires ONE PERFECT mark at each sit's apex (the same instant a player
## scores PERFECT) so the dog's joyful reaction plays deterministically for a capture burst —
## the live reaction is too brief and tap-timing-dependent to catch reliably otherwise. The
## mark runs through the real wiring (_on_bra_pressed), so it's the genuine reaction, not a
## stub. Web-only and off by default; desktop, headless, and normal web play are untouched.
var _autotap := false
var _autotapped := false  ## one auto-mark per sit; reset when the sit ends

## Visual-review seam (046/P2-7): set by _query_force_lock() from the web URL `?bra_force_lock=1`.
## When on, the BRA button is PINNED to its locked (dimmed + disabled) state every frame so a
## SINGLE screenshot deterministically proves the lock reads. The real lock lasts only ~350 ms
## per tap — shorter than a headless screenshot's latency — so a non-deterministic burst can't
## reliably catch it (the lock's behaviour/timing is proven in-engine by test_tap_gate_wiring;
## this seam proves the locked pixels are legible). Web-only and off by default; desktop,
## headless, and normal web play are untouched.
var _force_lock := false

## Learned-progress model + on-screen bar (045, P2-4 "feel the dog learning"). Sitt is the
## only trick today (the licensed pack ships no other trick clip), so main holds a single
## TrickProgress; the selector (P2-1) and persistence (P2-5) make it per-trick later. A
## well-timed BRA fills the bar; a mistimed / wrong-moment tap erodes it.
var _progress := TrickProgress.new()
var _learned_bar: LearnedBar

## The procedural "confused beat" on a bad tap (045, P2-4) — the mirror of the joyful mark:
## the dog briefly recoils, then settles. It is PROCEDURAL (a damped yaw wobble restored
## exactly to the dog's rest transform), NOT a faked clip — the licensed pack carries no
## confused animation, so synthesising one would be a stub. `_confused_age < 0` = inactive.
var _dog: Node3D
var _dog_rest: Transform3D
var _confused_age := -1.0

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
	_force_tier = _query_force_tier()  # deterministic readout-contrast pixel proof (033, web-only)
	_autotap = _query_autotap()        # deterministic reaction-capture mark (034, web-only)
	_force_lock = _query_force_lock()  # deterministic anti-mash lock pixel proof (046, web-only)
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

## Visual-review seam (033/P1-7): read `?bra_force_tier=miss|ok|perfect` off the live web
## URL into a SitWindow.Tier to pin the readout for one deterministic legibility screenshot.
## Returns -1 (off) on desktop/headless/normal play or an unrecognised value, so the readout
## behaves exactly as in play everywhere except a deliberately-flagged capture URL.
func _query_force_tier() -> int:
	if not OS.has_feature("web"):
		return -1
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	if typeof(search) != TYPE_STRING:
		return -1
	var s := (search as String).to_lower()
	if s.contains("bra_force_tier=perfect"):
		return SitWindow.Tier.PERFECT
	if s.contains("bra_force_tier=miss"):
		return SitWindow.Tier.MISS
	if s.contains("bra_force_tier=ok"):
		return SitWindow.Tier.OK
	return -1

## Visual-review seam (034/P1-6): true only when the live web URL carries `?bra_autotap=1`.
## Lets the reaction-capture harness pin a deterministic PERFECT mark at each apex so the
## dog's joyful hop plays for a screenshot burst. Web-only (off desktop/headless/normal play).
func _query_autotap() -> bool:
	if not OS.has_feature("web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	return typeof(search) == TYPE_STRING and (search as String).contains("bra_autotap=1")

## Visual-review seam (046/P2-7): true only when the live web URL carries `?bra_force_lock=1`.
## Pins the BRA button locked so the anti-mash dim renders for one deterministic screenshot (the
## live lock is ~350 ms — briefer than a headless screenshot's latency). Web-only (off
## desktop/headless/normal play); reads a STRING sentinel, never a bare bool, to dodge the
## Web-export null-Variant marshalling that bit the apex tell (036).
func _query_force_lock() -> bool:
	if not OS.has_feature("web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	return typeof(search) == TYPE_STRING and (search as String).contains("bra_force_lock=1")

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
	_tap_gate.tick(delta)        # advance the anti-mash freeze (046/P2-7)
	_update_bra_lock_visual()    # reflect armed/locked onto the BRA button
	_advance_loop(delta)
	# Reaction-capture seam (034, web-only): once per sit, auto-fire a PERFECT mark the
	# instant the clock reaches the apex, so the joyful hop plays deterministically for the
	# capture burst. Goes through the real _on_bra_pressed — genuine reaction, not a stub.
	if _autotap and not _autotapped and _window != null and _session.is_open() \
			and _session.elapsed() >= _window.apex - _window.perfect_radius:
		_autotapped = true
		_on_bra_pressed()  # fire as the clock enters the PERFECT band so the capture scores PERFECT
	if _tell_marker != null:
		if _force_tell:
			_tell_marker.set_intensity(1.0)  # deterministic capture seam (030) — web-only
		elif _tell != null and _session.is_open():
			_tell_marker.set_intensity(_tell.intensity(_session.elapsed()))
		else:
			_tell_marker.set_intensity(0.0)
	if _readout != null:
		if _force_tier >= 0:
			_readout.display(_force_tier as SitWindow.Tier)  # pin tier for capture (033) — web-only
		_readout.advance(delta)  # fade the last tier's flash (024g/P1-7)
	if _learned_bar != null:
		_learned_bar.advance(delta)  # fade the setback wash (045/P2-4)
	_drive_confused(delta)

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
	_autotapped = false  # arm the next sit's capture mark (034 seam)
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

## The BRA button's alpha while the anti-mash gate is locked (046/P2-7): a clear, STATIC dim so
## the lock reads without motion (X-5); restored to 1.0 the instant the gate re-arms.
const BRA_LOCKED_ALPHA := 0.4
## Apex-tell marker: centred on the button so the pulse rings the verb (024d, 037).
const TELL_HALF_WIDTH := ApexTellMarker.SIZE * 0.5  ## 160 — half the pulse square (037)
## Button-band centre above the bottom edge (anchor_*=1.0 space): keep the ring concentric
## with the centred "BRA" glyphs so it frames the word instead of crossing it (P1-4, 037).
const BRA_CENTER_Y := (BRA_OFFSET_TOP + BRA_OFFSET_BOTTOM) * 0.5
const TELL_OFFSET_TOP := BRA_CENTER_Y - TELL_HALF_WIDTH
const TELL_OFFSET_BOTTOM := BRA_CENTER_Y + TELL_HALF_WIDTH
## Timing readout: a band across the upper portrait area, clear of dog and button (024g).
const READOUT_OFFSET_LEFT := 24.0
const READOUT_OFFSET_RIGHT := -24.0
## Lifted into the clear sky above the dog's crown (P1-7 polish, 038): the centred dog's
## ears reached the old 96–220 band, so the flashed tier overlapped the head. Pulled up
## ~40 px (band height unchanged) while keeping a comfortable top margin off the letterbox.
const READOUT_OFFSET_TOP := 56.0
const READOUT_OFFSET_BOTTOM := 180.0
## Learned bar (045, P2-4): a thin persistent meter pinned at the readout's proven-safe top
## edge (038), in the clear sky above the dog. Full width inset like the button; the transient
## readout word flashes below it. Reads by FILL LENGTH so it's legible under reduced motion.
const LEARNED_BAR_OFFSET_TOP := READOUT_OFFSET_TOP
const LEARNED_BAR_HEIGHT := 16.0
const LEARNED_BAR_MARGIN_X := 48.0
## Confused-beat shape (045): a short damped yaw wobble on a bad tap, scaled by the reduced-
## motion factor so it dampens (never a hard snap) when motion is reduced (X-5).
const CONFUSED_DURATION := 0.45
const CONFUSED_WOBBLES := 2.0
const CONFUSED_AMPLITUDE := 0.12  ## radians (~7°) at full motion

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
	# Hold the dog's rest transform so the procedural confused beat (045) can recoil and
	# restore EXACTLY to it — the AnimationPlayer animates the skeleton, not this root node,
	# so a brief transform nudge here never fights the idle/sit clips.
	if dog is Node3D:
		_dog = dog
		_dog_rest = _dog.transform
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
	_bra_button = bra  # _process reflects the anti-mash lock onto it (046/P2-7)
	_setup_tell_marker(ui)
	_setup_readout(ui)
	_setup_learned_bar(ui)

## The apex-tell pulse (024d/P1-4), centred over the BRA marker. Added ON TOP of the
## button but with mouse input ignored, so it glows around the verb without ever
## eating a tap. Starts dark; _process drives it from the tell during a sit only.
func _setup_tell_marker(ui: CanvasLayer) -> void:
	var marker := ApexTellMarker.new()
	marker.name = "TellMarker"
	# A 320×320 square centred on the BRA button band, so the ring frames the "BRA" word
	# rather than crossing it (P1-4 polish, 037). The top/bottom offsets are derived from
	# the button band's centre, so the ring stays concentric with the verb if it ever moves.
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

## The learned bar (045/P2-4): a thin meter across the top safe edge that fills as Sitt is
## learned and drops on a bad tap. Mouse-transparent so it never eats a tap. Starts at the
## model's current value; driven by _on_bra_pressed (fill/drop) + _process (setback fade).
func _setup_learned_bar(ui: CanvasLayer) -> void:
	var bar := LearnedBar.new()
	bar.name = "LearnedBar"
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.anchor_top = 0.0
	bar.anchor_bottom = 0.0
	bar.offset_left = LEARNED_BAR_MARGIN_X
	bar.offset_right = -LEARNED_BAR_MARGIN_X
	bar.offset_top = LEARNED_BAR_OFFSET_TOP
	bar.offset_bottom = LEARNED_BAR_OFFSET_TOP + LEARNED_BAR_HEIGHT
	ui.add_child(bar)
	_learned_bar = bar
	_learned_bar.set_value(_progress.value, _progress.mastered)

## Reflect the anti-mash gate onto the BRA button (046/P2-7): while locked it is disabled and
## dimmed to BRA_LOCKED_ALPHA, then re-enabled at full brightness when it re-arms. Both are
## STATIC states (not animations), so the lock reads under reduced motion (X-5). Disabling also
## blocks the press signal during the lock — belt-and-suspenders with the is_armed() guard in
## _on_bra_pressed, which still covers the autotap / direct-call paths. Called each frame.
func _update_bra_lock_visual() -> void:
	if _bra_button == null:
		return
	var armed := _tap_gate.is_armed() and not _force_lock  # _force_lock pins locked for capture (046)
	_bra_button.disabled = not armed
	_bra_button.modulate = Color(1.0, 1.0, 1.0, 1.0 if armed else BRA_LOCKED_ALPHA)

## The audible payoff player (024f). A plain Node child holding the voice + click
## AudioStreamPlayers; it only sounds on a successful mark (the gate lives in
## MarkPayoff). Mounted once; reused for every tap.
func _setup_payoff() -> void:
	_payoff = PayoffPlayer.new()
	_payoff.name = "Payoff"
	add_child(_payoff)

## Reduced-motion hook (P1-8): 024g calls this with the prefers-reduced-motion factor
## before the sit opens; the tell is then built dampened (never removed) by it.
##
## The factor is contractually in (0, 1] — reduced motion *dampens* the apex tell, it
## never *removes* it (ReducedMotion.DAMPED, ApexTell.damping). A zero or non-finite
## scale would blank the cue entirely: that is exactly the live-play P1-4 regression
## where a null `prefers-reduced-motion` read (a bare-boolean JavaScriptBridge.eval
## marshalled back as null on the Web export) collapsed scale_for() to 0.0 and the apex
## tell went permanently invisible in real play. Treat any such bad value as full motion
## so the cue can never silently disappear, whatever upstream feeds in.
func set_motion_scale(scale: float) -> void:
	if not is_finite(scale) or scale <= 0.0:
		scale = 1.0
	_motion_scale = clampf(scale, 0.0, 1.0)

## The mark: score the tap at the current seconds-into-the-sit, announce the tier, and
## land the payoff. A DEAD/MISS tap is silent and provokes no reaction (no penalty,
## P1-5/P1-6); the readout (024g) also consumes `marked`. Logs every tap for the boot gate.
func _on_bra_pressed() -> void:
	if not _tap_gate.is_armed():
		return  # swallowed during the fixed lock — not scored, the gate's clock untouched (046/P2-7)
	_tap_gate.lock()  # the fixed re-arm window starts on the ACCEPTED tap only — mashing can't extend it
	var tier := _session.tap()
	marked.emit(tier)
	_play_payoff(tier)
	if _readout != null:
		_readout.display(tier)  # flash PERFECT/OK/MISS now; DEAD shows nothing (024g/P1-7)
	_apply_progress(tier)  # fill / erode the learned bar + the felt feedback (045/P2-4)
	if SitWindow.is_successful(tier):
		print("[Bra!] mark: %s" % SitWindow.tier_name(tier))
	else:
		print("[Bra!] tap: %s (no mark)" % SitWindow.tier_name(tier))

## Feed the scored tier into the learned-progress model (045, P2-4) and drive the feel:
## a good mark fills the bar (and, on the tap that hits 100%, fires the celebratory beat —
## the existing joyful reaction); a bad tap erodes the bar (a brief red setback wash) and the
## dog reads confused (the procedural recoil). The model decides; main only reflects it.
func _apply_progress(tier: SitWindow.Tier) -> void:
	var delta := _progress.apply(tier)
	if _learned_bar != null:
		_learned_bar.set_value(_progress.value, _progress.mastered)
		if delta < 0.0:
			_learned_bar.pulse_setback()
	if _progress.just_mastered(delta):
		_play_mastery_beat()
	elif not SitWindow.is_successful(tier):
		_play_confused_beat()  # a mistimed / wrong-moment tap — the dog reads confused (P2-4)

## The celebratory beat when a trick reaches mastery (045/P2-4): reuse the dog's real joyful
## reaction (the same clip a PERFECT mark plays) as the one-shot celebration. A no-op on a dog
## with no reaction clip (the CC0 placeholder) — never a faked celebration.
func _play_mastery_beat() -> void:
	if _director != null:
		_director.play_reaction()

## Begin the procedural confused beat (045/P2-4): the mirror of the joyful mark. _process
## drives a brief damped recoil from here and restores the dog to its rest transform. Scaled
## by reduced motion. No-op if the dog isn't a Node3D we can nudge.
func _play_confused_beat() -> void:
	if _dog != null:
		_confused_age = 0.0

## Step the procedural confused beat (045/P2-4): a damped yaw wobble that settles back to the
## dog's rest transform within CONFUSED_DURATION, then goes inactive. The AnimationPlayer
## drives the skeleton (not this root node), so the nudge never fights a clip and is always
## restored EXACTLY to rest — no drift, no framing regression. Dampened by the reduced-motion
## factor so it eases rather than snaps when motion is reduced (X-5).
func _drive_confused(delta: float) -> void:
	if _dog == null or _confused_age < 0.0:
		return
	_confused_age += delta
	if _confused_age >= CONFUSED_DURATION:
		_dog.transform = _dog_rest  # settle exactly back — no drift
		_confused_age = -1.0
		return
	var t := _confused_age / CONFUSED_DURATION
	var damp := 1.0 - t  # the wobble decays to nothing as it settles
	var angle := sin(t * TAU * CONFUSED_WOBBLES) * CONFUSED_AMPLITUDE * damp * _motion_scale
	_dog.transform = _dog_rest
	_dog.rotate_object_local(Vector3.UP, angle)

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
		# Web-only capture/e2e signal: a counter the reaction-capture harness watches so it
		# can sync its screenshot burst to the exact frame the hop starts (034). No-op
		# off the web export; harmless in normal play.
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__bra_reaction_n = (window.__bra_reaction_n||0)+1;", true)

## Deterministic readiness signal for the PWA splash / e2e, mirroring the
## old web shell's window.__appReady. No-op off the web export.
func _notify_web_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__appReady = true;", true)
	print("[Bra!] scaffold ready")
