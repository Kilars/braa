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

## Per-trick learned-progress persistence (049, P2-5 "leave and come back" / X-7 offline). The
## save store loads on boot into _progress (so a returning player sees their filled / mastered
## bar immediately) and is written after every progress change. Keyed per trick from day one
## by the named id below — today exactly one trick, Sitt; the selector (P2-1) drops more into
## the same map later. Local user:// (IndexedDB on web): no backend, no account, no network.
var _store := TrickStore.new()
const TRICK_ID_SITT := "sitt"

## The procedural "confused beat" on a bad tap (045, P2-4) — the mirror of the joyful mark:
## the dog briefly recoils, then settles. It is PROCEDURAL (a damped yaw wobble restored
## exactly to the dog's rest transform), NOT a faked clip — the licensed pack carries no
## confused animation, so synthesising one would be a stub. `_confused_age < 0` = inactive.
var _dog: Node3D
var _dog_rest: Transform3D
var _confused_age := -1.0

## The bounded-patch ambient wander (050, P2-8 locomotion): between offers the dog ambles a
## small disc on the grass (turning back at the edges), so it reads as a dog with a mind of its
## own rather than parked dead-centre (the PO's P2-8 note). The math lives in the pure WanderField;
## main glides the dog ROOT from it each frame and plays the real walk clip while it's stepping.
## Built only on a dog that carries a walk clip (never a faked gait); null otherwise.
var _wander: WanderField
## False while a sit/feint is in progress so locomotion PAUSES and the dip/seat reads clearly
## (composes with 048 — the dog settles for the offer, then resumes roaming).
var _wander_active := true
## Whether the walk clip is currently driving (vs idle), so play_walk/play_idle only fire on a
## change instead of restarting the clip every frame.
var _ambling := false
## The contact-shadow blob (031) kept so it can TRACK the wandering dog — the dog must stay
## grounded by its shadow as it roams (050). `_shadow_rest` is the blob's boot position; the
## wander offset is added to its XZ each frame. Null when no shadow was mounted.
var _contact_shadow: MeshInstance3D
var _shadow_rest: Vector3

func _ready() -> void:
	_apply_reduced_motion()  # set _motion_scale BEFORE _start_dog builds the tell (P1-8)
	_load_progress()         # restore saved learned progress BEFORE the bar is built (049/P2-5)
	_setup_environment()
	_setup_light()
	var dog := _load_dog()
	if dog != null:
		_start_dog(dog)
		_frame_camera(dog)
		_setup_ground_plane(dog)    # grass ground plane at the foot plane (047/P2-10)
		_setup_contact_shadow(dog)  # blob shadow ON the grass (031/P1-1)
		_setup_sun_disc(dog)        # explicit sun disc in the sky (047/P2-10)
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
	_drive_wander(delta)   # roam the patch + place the dog at its wander spot (050/P2-8)
	_drive_confused(delta) # layer the bad-tap wobble on top of the wander base (045)

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
		SitLoop.Intent.START_FEINT:
			_begin_feint()  # play the dip; do NOT open _session/_window/_tell (P2-8)
		SitLoop.Intent.END_FEINT:
			_end_feint()     # stand back to the ambient idle

## Begin one sit: play it, open the scoring window over its markable span, and build the
## apex tell from that SAME window so the glow peaks exactly where a tap scores PERFECT
## (P1-4 honest tell — one source of truth). _process advances the clock; the button reads it.
func _begin_sit() -> void:
	_pause_wander()  # settle the roam so the seat reads (050, P2-8 — composes with 048)
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
	_resume_wander()  # come back round to roaming the patch (050)

## Begin a feint (048, P2-8): the dog visibly dips toward a sit and aborts. CRUCIALLY this
## leaves _session/_window/_tell UNTOUCHED — no scoring window opens for a feint, so the apex
## tell stays dark (P1-4 honest, the same path P2-9 will fade) and a tap during the dip flows
## through the existing _on_bra_pressed → _session.tap() → DEAD → gentle erosion + confused
## beat, with ZERO new downstream branches. Only the dog's animation differs from idle.
func _begin_feint() -> void:
	_pause_wander()  # settle so the dip reads as a deliberate fake-sit, not a stride (050)
	_director.play_feint()

## End a feint (048, P2-8): the dip is over; stand back to the ambient idle so the loop comes
## round to the next offer. The session was never opened, so there is nothing to close here.
func _end_feint() -> void:
	_director.play_idle()
	_resume_wander()  # back to roaming the patch (050)

## Garden backdrop (P2-10): a ProceduralSkyMaterial sky gradient with a clean readable sun
## disc above and a horizon split where the grass ground meets the sky — replaces the old
## flat sky-blue BG_COLOR void. GL-Compatibility-safe (no Forward+-only features). Ambient
## light from the sky so the dog reads naturally lit from above. The sun disc aligns with
## the DirectionalLight3D direction in _setup_light (upper sky for a look-down view).
func _setup_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	# Sky gradient: deep blue at the zenith, warm bright horizon so the sun disc pops
	sky_mat.sky_top_color = Color(0.18, 0.48, 0.92)
	sky_mat.sky_horizon_color = Color(0.90, 0.90, 0.75)   # warm bright near-horizon haze
	sky_mat.sky_curve = 0.15                    # gradual, not banded
	# Ground half of the procedural sky (below horizon) — warm haze, not used directly
	# since a real mesh plane covers this half, but set to a warm neutral so any gap
	# between the plane edge and the horizon reads as warm rather than void black.
	sky_mat.ground_bottom_color = Color(0.55, 0.72, 0.40)
	sky_mat.ground_horizon_color = Color(0.72, 0.86, 0.98)
	sky_mat.ground_curve = 0.1
	# Sun disc: aligned with the DirectionalLight3D so the disc IS the key light. A clean,
	# readable disc — sun_angle_max sets the disc radius; sun_curve sharpens the inner glow.
	# 25° radius: large disc clearly legible at phone scale near the horizon. A high
	# sun_curve value keeps the core bright and makes the disc distinct vs the gradient.
	sky_mat.sun_angle_max = 25.0
	sky_mat.sun_curve = 0.5
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Ambient from sky so the dog's unlit surfaces (belly, paws) stay readable, not pitch black.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.6   # mix: bright sky bounce, not blown out
	env.ambient_light_energy = 0.8
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

## Garden look-down light (047/P2-10): the DirectionalLight3D rotation determines WHERE the
## ProceduralSkyMaterial sun disc appears. The look-down camera shows a sky band from roughly
## 15°–40° above the horizon (depending on composition); the sun elevation must sit inside
## that band to be visible. X=-22° puts the disc ~22° above the horizon — comfortably in
## the sky band with the target ~30–35% sky / ~65–70% grass composition. Y=-40° means the
## sun comes from slightly left of front-facing, lighting the dog's front-left coat well.
func _setup_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	# Light direction matches the 3D sun sphere position (upper-right in the sky band):
	# X=-30° moderate elevation, Y=-40° from the right side. Good coat highlight and matches
	# where the visible SunDisc sphere sits. The ProceduralSkyMaterial sun disc (fragment
	# shader) may or may not render in all GL paths, but the explicit SunDisc sphere always
	# does — the light direction just needs to be roughly consistent with the sphere's bearing.
	sun.rotation_degrees = Vector3(-30.0, -40.0, 0.0)
	sun.light_energy = 1.3
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

## Garden look-down camera constants (047/P2-10): Pokémon-GO-style above-and-behind view.
## Goal: horizon at ~30–35% from the top of the 390×844 frame — a real sky band (with a
## visible sun disc) above, green grass below, dog centred and PROMINENT on the grass.
##
## LOOK_DOWN_HEIGHT: how far above the DogFraming eye the camera rises (metres). Lower
## values keep the dog bigger in frame; too high pulls the camera up and shrinks the dog.
## 0.5 m gives a gentle look-down pitch without sacrificing dog size.
const LOOK_DOWN_HEIGHT := 0.5
## LOOK_DOWN_BACK: extra rearward offset so the camera doesn't clip into the dog as it
## rises. Less pullback = larger dog. 0.4 m is enough clearance.
const LOOK_DOWN_BACK := 0.4
## LOOK_DOWN_TARGET_Y: factor of bounding-box height for the look-at point. 0.55 = mid-
## torso area. The camera pitches slightly down; the horizon appears in the upper third
## and a real sky band (with sun disc) is visible above it.
const LOOK_DOWN_TARGET_Y := 0.55

## Centre the dog in portrait, look DOWN into the garden (P2-10 Pokémon-GO view), and fit
## the camera to the dog's actual bounds — the dog stays centred and fully framed at 390×844
## while the horizon split and grass/sky composition emerge from the downward pitch.
## DogFraming is pure + unit-tested; this just measures the dog and aims a Camera3D.
## The DogFraming.eye() computation is UNCHANGED (tests stay green); we then LIFT and
## PULL the camera back so it looks down — the ground plane and sky fill the frame.
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
	# The standard DogFraming eye (tests are written against this — keep it as the base).
	var eye := DogFraming.eye(box, cam.fov, aspect, FRAME_FILL)
	# Lift and pull back for the look-down view. The extra height raises the horizon into
	# the upper third of the portrait frame; the extra rear offset avoids the dog.
	eye.y += LOOK_DOWN_HEIGHT
	eye.z += LOOK_DOWN_BACK
	# Look at a point on the dog's mid-torso (slightly below bounding-box centre) so the
	# dog reads in the lower half of frame with the grass beneath it and sky above.
	var target_pos := DogFraming.target(box)
	target_pos.y = box.position.y + box.size.y * LOOK_DOWN_TARGET_Y
	cam.look_at_from_position(eye, target_pos, Vector3.UP)
	cam.make_current()

## Grass ground plane (047/P2-10): a large PlaneMesh at the dog's FOOT PLANE so the dog
## stands visibly ON grass. Sized 40×40 m so the horizon split (where the plane meets the
## sky) is well inside view at any reasonable look-down angle. The foot-plane Y is read
## from DogBounds (the same source the contact-shadow uses in ContactShadow.position) so
## this is model-agnostic — correct for both the CC0 idle dog and the licensed Labrador.
## Stylized green StandardMaterial3D — honest real geometry, not a Phase-7-polish thing.
## GL-Compatibility-safe: StandardMaterial3D, no shader, no Forward+-only feature.
func _setup_ground_plane(dog: Node) -> void:
	var box := _dog_bounds(dog)
	# Foot plane Y: same as ContactShadow.position() uses — the AABB minimum Y (floor level).
	var foot_y := box.position.y  # ContactShadow.position already computes this
	var foot_center := Vector3(box.get_center().x, foot_y, box.get_center().z)
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(40.0, 40.0)  # large enough that horizon is within the plane
	var mat := StandardMaterial3D.new()
	# Stylized garden green — a slightly desaturated mid-green reads naturally under the sky.
	mat.albedo_color = Color(0.28, 0.60, 0.22)
	mat.roughness = 0.95   # matte grass, no specular glint
	mat.metallic = 0.0
	# Allow the sun's directional shadow / shading to land on it naturally.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var ground := MeshInstance3D.new()
	ground.name = "GrassGround"
	ground.mesh = plane_mesh
	ground.material_override = mat
	ground.position = foot_center
	add_child(ground)

## Explicit sun disc in the sky (047/P2-10): a SphereMesh placed in the visible sky band,
## positioned 1.2 m above and 5 m in front of the dog (-Z direction = away from camera),
## 0.8 m right of centre so it clears the centred learned-bar UI. The ProceduralSkyMaterial
## sun disc (fragment shader) renders correctly on deployed hardware (confirmed by PO on
## live site), but the local headless capture environment (Godot WASM → "WebKit WebGL"
## device name regardless of browser or GL flags) does not render it — so this sphere is
## an additive explicit geometry sun that renders in ALL GL paths including software renderers.
## Unshaded + emissive so it glows bright against the sky gradient. GL-Compatibility-safe:
## StandardMaterial3D only, no shader, no Forward+-only feature.
func _setup_sun_disc(dog: Node) -> void:
	var box := _dog_bounds(dog)
	var dog_center := box.get_center()
	# Place the sun disc in the visible sky band. The camera is behind the dog (+Z) and pitched
	# slightly downward toward mid-torso. The sky band (top ~30% of frame) maps to roughly
	# 10-25° above the camera's look-at point. At 5 m in front of dog and 1.2 m above centre,
	# the disc sits at atan2(1.2-0.5, 5) ≈ ~8° above camera eye — safely in the sky band.
	# Offset +0.8 m right so the disc clears the learned-bar (centred UI element) and
	# reads as off-axis — more natural sun position, not dead-center on the bar.
	var sun_pos := Vector3(dog_center.x + 0.8, dog_center.y + 1.2, dog_center.z - 5.0)
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.42   # ~0.84 m diameter at ~5.5 m = ~9° — clearly legible sun
	sphere_mesh.height = 0.84
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.95, 0.60)   # warm golden — clearly visible sun colour
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # self-luminous, not lit by the scene
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.90, 0.40)       # warm golden glow
	mat.emission_energy_multiplier = 3.0         # bright enough to read against sky gradient
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var disc := MeshInstance3D.new()
	disc.name = "SunDisc"
	disc.mesh = sphere_mesh
	disc.material_override = mat
	disc.position = sun_pos
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)

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
	var blob_pos := ContactShadow.position(box)
	# Lift 1 mm above the grass ground plane to prevent Z-fighting (047/P2-10): both the
	# grass plane and the blob are at the foot Y, so without an offset they fight and the
	# shadow flickers or disappears. 0.001 m is invisible at phone scale but resolves the
	# depth conflict reliably.
	blob_pos.y += 0.001
	blob.position = blob_pos
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # it IS the shadow
	add_child(blob)
	# Keep the blob + its boot position so the wander can track it under the roaming dog (050).
	_contact_shadow = blob
	_shadow_rest = blob_pos

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
	# Hold the dog's rest transform so the procedural confused beat (045) and the ambient
	# wander (050) can drive the root and restore EXACTLY to it — the AnimationPlayer animates
	# the skeleton, not this root node, so a transform nudge here never fights the idle/sit clips.
	if dog is Node3D:
		_dog = dog
		_dog_rest = _dog.transform
	# The ambient wander (050, P2-8): on a dog that can actually walk, build the bounded-patch
	# roam so it ambles the grass between offers instead of standing dead-centre. Gated on a real
	# walk clip — a dog with none stays put rather than gliding a standing pose (never a faked
	# gait). Production seeds a random RNG; the patch math is unit-tested via the seeded WanderField.
	if _dog != null and _director.has_walk():
		_wander = WanderField.new()
		print("[Bra!] dog ambles a bounded patch between offers (P2-8 wander, clip '%s')" % _director.clips.walk)
	# The repeating round loop (027/P1-9) drives the rest from _process: it waits a calm
	# beat, plays the sit + opens the scoring window (_begin_sit), holds the seat, then
	# stands back to idle (_end_sit) and comes round again — the mark never stalls after
	# one sit. On the CC0 dog (no Sitt) the loop simply parks in idle; no faked sit.
	_loop = SitLoop.new()
	if _director.has_sit():
		# Sit-capable dog (licensed Labrador, 025): the loop offers a sit on a VARYING gap
		# (P2-8, no metronome) and sometimes feints; each real sit's apex (the score's PERFECT
		# instant) is the single source the tell is built from in _begin_sit. _process advances
		# the sit clock.
		print("[Bra!] dog can Sitt — varying the offer cadence %.1f–%.1fs, sometimes feinting (real apex from the licensed Labrador)"
			% [SitLoop.MIN_INTER_SIT_GAP, SitLoop.MAX_INTER_SIT_GAP])
	else:
		# CC0 dev fallback: no sit, so the loop parks in idle and every BRA tap is DEAD
		# (does nothing, no penalty — P1-5). The button still works; it lights up the
		# moment the licensed Sitt ships (024b / ADR-0006 / 025).
		print("[Bra!] dog has no Sitt clip (CC0 dev fallback) — idle only; "
			+ "real Sitt ships with the licensed Labrador, see task 024b / ADR-0006")

## One big, thumb-friendly BRA button anchored across the bottom of the portrait
## frame (P1-5) — the single verb. It fires on release (Button's default
## ACTION_MODE_BUTTON_RELEASE = pointerup, P1-7), never a frame early.
## Garden (047/P2-10): the button FLOATS over the grass — its opaque panel background
## is removed via StyleBoxEmpty so only the "BRA" word is visible over the lower grass
## area. Position, size, and the apex-tell coupling (TELL_OFFSET_*) are unchanged; the
## button remains a large thumb target (P1-5) — just no opaque control strip behind it.
func _setup_bra_button() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var bra := Button.new()
	bra.name = "BraButton"
	bra.text = "BRA"
	bra.add_theme_font_size_override("font_size", 96)
	# Float the verb over the grass: clear the Button's opaque panel background by
	# assigning an empty StyleBox for all four visual states. The text + apex ring still
	# render; only the opaque band behind them is removed (P2-10).
	var empty := StyleBoxEmpty.new()
	bra.add_theme_stylebox_override("normal",   empty)
	bra.add_theme_stylebox_override("hover",    empty)
	bra.add_theme_stylebox_override("pressed",  empty)
	bra.add_theme_stylebox_override("disabled", empty)
	bra.add_theme_stylebox_override("focus",    empty)
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
	_save_progress()  # persist after every change so the bar survives a reload (049/P2-5)

## Load saved per-trick progress on boot (049/P2-5). Restores the current trick's saved entry
## into _progress so _setup_learned_bar shows the returning player's filled / mastered bar
## immediately. First run (or a corrupt / wrong-version save) restores nothing → clean zero
## (TrickStore degrades to {}). An unknown trick id in the save is simply never looked up.
func _load_progress() -> void:
	var saved := _store.load()
	var entry: Variant = saved.get(TRICK_ID_SITT, {})
	if typeof(entry) == TYPE_DICTIONARY:
		_progress.restore(entry)

## Persist the current trick's progress (049/P2-5). One JSON map keyed per trick (today just
## Sitt) to user:// — IndexedDB on web, no backend / account / network (X-7 offline).
func _save_progress() -> void:
	_store.save({TRICK_ID_SITT: _progress.to_dict()})

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
	# Recoil/settle around the dog's CURRENT base transform — its wander spot if it's roaming
	# (050), else its rest — so the wobble composes with the wander instead of snapping the dog
	# back to origin mid-roam.
	var base := _dog_base_transform()
	if _confused_age >= CONFUSED_DURATION:
		_dog.transform = base  # settle exactly back — no drift
		_confused_age = -1.0
		return
	var t := _confused_age / CONFUSED_DURATION
	var damp := 1.0 - t  # the wobble decays to nothing as it settles
	var angle := sin(t * TAU * CONFUSED_WOBBLES) * CONFUSED_AMPLITUDE * damp * _motion_scale
	_dog.transform = base
	_dog.rotate_object_local(Vector3.UP, angle)

## Drive the ambient wander (050, P2-8): while active (between offers), advance the bounded-patch
## roam and switch the dog between its walk clip (ambling) and idle (paused at a target) — only on
## a change, so the clip isn't restarted every frame. Each frame it places the dog ROOT at its
## wander spot (frozen while a sit/feint pauses the roam) and slides the contact shadow to match,
## UNLESS the confused beat is mid-recoil — that frame _drive_confused owns the transform and
## composes its wobble off the same wander base. A no-op on a dog with no walk clip (no _wander).
func _drive_wander(delta: float) -> void:
	if _wander == null or _dog == null:
		return
	if _wander_active:
		_wander.advance(delta)
		if _wander.is_moving() and not _ambling:
			_director.play_walk()   # step the legs while the root glides
			_ambling = true
		elif not _wander.is_moving() and _ambling:
			_director.play_idle()   # paused at a target — stand and look around
			_ambling = false
	if _confused_age < 0.0:
		_dog.transform = _wander_base()
	_track_contact_shadow()

## Pause the wander for an offer (sit/feint): freeze the roam so the dip/seat reads, and clear the
## ambling flag so the walk clip is re-selected when roaming resumes (050, composes with 048).
func _pause_wander() -> void:
	_wander_active = false
	_ambling = false

## Resume the wander after an offer ends (050). play_idle has already been issued by the caller,
## so leave _ambling false — the next moving frame re-selects the walk clip.
func _resume_wander() -> void:
	_wander_active = true

## The dog's base transform this frame: its wander spot (offset + heading on the grass plane) when
## roaming (050), else its boot rest. The confused beat layers its wobble on top of this.
func _dog_base_transform() -> Transform3D:
	if _wander != null:
		return _wander_base()
	return _dog_rest

## Build the wander transform from the pure WanderField: translate the rest spot by the XZ offset
## (keep the rest Y so the feet stay on the grass) and yaw the rest basis to the travel heading so
## the dog faces where it's walking (reads as roaming, not sliding).
func _wander_base() -> Transform3D:
	var off := _wander.position()
	var basis := _dog_rest.basis.rotated(Vector3.UP, _wander.heading())
	return Transform3D(basis, _dog_rest.origin + Vector3(off.x, 0.0, off.y))

## Slide the contact-shadow blob to stay under the wandering dog (050) — its XZ tracks the wander
## offset; its Y (the grass foot plane, with the Z-fight lift) is untouched so the dog stays
## grounded as it roams. A no-op if no shadow was mounted.
func _track_contact_shadow() -> void:
	if _contact_shadow == null or _wander == null:
		return
	var off := _wander.position()
	_contact_shadow.position = _shadow_rest + Vector3(off.x, 0.0, off.y)

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
