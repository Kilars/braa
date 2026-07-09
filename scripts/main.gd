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
## Post-resume tap grace (120, P4-5): after the app resumes from background/lock, BRA taps within a
## short window are swallowed so a stray resume-touch (a notification, a lock) never lands a false mark.
## Armed on the focus-in notification, consulted at the top of _on_bra_pressed. Pure + clock-injected.
var _grace := BackgroundGrace.new()
## The BRA button, kept so _process can dim + disable it while the gate is locked (046).
var _bra_button: Button

## The active breed's temperament (075, P3-3): a pure value object whose four traits resolve the
## difficulty levers (learn speed, distractibility, window stability, energy). One breed today —
## the Labrador (#1) — feeding TrickProgress gains, SitLoop feint chance + gap, and SitWindow radii,
## so a breed is a temperament not a paint job. The multi-breed selector wires in once 074/roster land.
var _breed := BreedPersonality.labrador()

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

## The approach-cue trainer ring (058, P2-9): shrinks onto the BRA button and lands at
## the apex, fading as the learned bar fills and gone at mastery. Parallel to the tell:
## built only when a real sit opens (never during feints), null on the CC0 dog.
var _trainer: TrainerRing
var _trainer_marker: TrainerRingMarker

## Visual-review seam (058/P2-9): set by _query_force_trainer() from the web URL
## `?bra_force_trainer=1`. When on, the ring is pinned to a mid-approach radius at full
## teach every frame so a SINGLE screenshot deterministically proves the approach ring
## renders (the live ring sweeps in ~0.2s per sit — too brief for a non-deterministic
## burst to reliably catch, the same reason 030 added ?bra_force_tell=1). Web-only and
## off by default, so desktop, headless, and normal web play are untouched.
var _force_trainer := false

## The honest timing readout (024g, P1-7): flashes PERFECT / OK / MISS on each tap and
## fades. Driven from _on_bra_pressed (the tier) + _process (the fade). A DEAD tap shows
## nothing — so on the CC0 dog (every tap DEAD) it stays blank, matching the silent payoff.
var _readout: TierReadout

## The marker-word burst (094, P5-3): pops the effective fired word ("Dyktig!" / "Bra!" etc.)
## on a successful mark, floats it up from the BRA button, and fades. Dumb renderer driven
## from _process via advance(delta). Distinct from the top-centre TierReadout: it lives in the
## lower band above the button, making the Phase-5 collection mechanic visible at the mark.
var _word_pop: WordPop

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

## Visual-review seam (071, PO note 3): set by _query_force_scratch() from the web URL
## `?bra_force_scratch=1`. When on, the round loop is pinned so EVERY offer is a scratch feint
## (feint_chance + scratch_feint_chance → 1.0), making the otherwise brief+rare scratch (~5% of
## offers, ~0.45 s) reliably catchable in a capture burst — the same "force a brief event" idiom as
## `?bra_force_tell` / `?bra_force_lock`. Web-only and off by default; normal play is untouched.
var _force_scratch := false

## Learned-progress model + on-screen bar (045, P2-4 "feel the dog learning"). Progress is keyed
## PER TRICK (`_progress_by_trick`, id → TrickProgress) now that Ligg is wired alongside Sitt
## (065, BUST-064): the licensed asset holds `Lie_*` too, so "one trick" was behavior, not inventory.
## `_progress` ALIASES the current trick's model so the whole scoring/erosion/bar path stays unchanged;
## select_trick (driven by the 072 completion menu) repoints it when the player switches trick. A
## well-timed BRA fills the bar; a mistimed / wrong-moment tap erodes it.
var _progress_by_trick := {}
var _progress: TrickProgress
var _learned_bar: LearnedBar

## The completion menu (072, PO note 1 "one active trick + a completion menu"): the game trains ONE
## trick at a time; when the active trick is mastered this modal pops up showing the collection — the
## just-learned trick (Learned), the other performable tricks (Available, tap to train next), the coin
## balance, and the genuinely-absent tricks (Locked/greyed, never trainable — the never-fake gate). It
## SUPERSEDES the always-on 066 chip row: picking a trick is now this between-rounds surface, not a
## permanent second in-round verb. `_menu_open` pauses offers while it is up; `_tricks_button` reopens
## it between rounds so switching is never a dead-end. The `?bra_trick=` web debug reach is KEPT (off
## by default) to boot the Visual-Review capture harness straight into a specific trick.
var _menu: TrickMenu
var _menu_open := false
var _tricks_button: Button
var _feedback: FeedbackFormView  ## The feedback form modal (085, X-8); mounted ABOVE the menu, hidden.
## The spotlit breed-select / showcase screen (087, P3-4). `_showcase` is the dumb view (mounted above
## the menu, hidden); `_showcase_model` is the pure cursor over the owned roster; `_sun_base_energy`
## remembers the garden key-light level so the stage brighten is restored exactly on close.
var _showcase: BreedShowcaseView
var _showcase_model := BreedShowcase.new()
var _showcase_fill: OmniLight3D
var _sun_base_energy := -1.0
## How much the showcase brightens the garden key light + the viewer-side fill it adds (087, P3-4).
const SHOWCASE_LIGHT_BOOST := 1.7    ## key-light multiplier while the showcase is open
const SHOWCASE_FILL_ENERGY := 2.2    ## the added camera-side OmniLight fill energy
const SHOWCASE_FILL_RANGE := 24.0    ## its range (m) — comfortably covers the framed dog
## The kennel browse-grid screen (105, Phase 8 K-1/K-3). A dumb renderer mounted on the
## same CanvasLayer; opened by _open_kennel(), closed by _close_kennel(). Browse-only this
## slice — no modal, no adopt, no economy mutation (those land with K-2/K-4/K-5).
var _kennel: KennelScreen
## The kennel entry button in the training HUD — a small top-area pill mirroring _tricks_button.
## Included in _set_training_hud_visible so it hides while the kennel itself is open.
var _kennel_button: Button
## The persisted kennel-dog owned roster (109, Phase 8 K-3/K-4/K-7). A pure value object —
## the set of owned KennelDog ids + the one active id. Replaces the STARTER-only stubs
## _kennel_owned()/_kennel_active() with a real persisted roster saved under the new "kennel"
## key in the ONE TrickStore blob (byte-compatible: a pre-109 save decodes to Bella-only).
var _kennel_roster := KennelRoster.new()
## In-flight guard for _on_kennel_adopt (K-4): a second press mid-adopt is swallowed so
## there is no double-spend. Mirrors the _menu_open / mastery-complete guard pattern.
var _kennel_adopt_busy := false
## The genuinely-absent tricks (BUST-064 residual, owner-gated): the licensed Labrador ships no paw /
## roll / spin clip, so these are shown as display-only Locked roadmap rows — never selectable, never
## playing a faked clip. They wire as real tricks only once the owner supplies clips.
const ROADMAP_LOCKED_TRICKS := ["gi_labb", "rull", "snurr"]

## Per-trick learned-progress persistence (049, P2-5 "leave and come back" / X-7 offline). The save
## store loads on boot into the per-trick map (so a returning player sees each trick's filled /
## mastered bar immediately) and is written after every change. Keyed per trick from day one — Sitt
## and Ligg today; more drop into the same map as they wire. Local user:// (IndexedDB on web): no
## backend, no account, no network.
var _store := TrickStore.new()
const TRICK_ID_SITT := DogClips.TRICK_SITT
const TRICK_ID_LIGG := DogClips.TRICK_LIGG
const TRICK_ID_LEGG_DEG := DogClips.TRICK_LEGG_DEG
## The trick the dog is currently training (065). Defaults to Sitt everywhere (desktop / headless /
## normal play), so the PO-verified default experience is unchanged; players switch it via the 072
## completion menu, and the `?bra_trick=ligg` web reach (below) boots a specific trick for Visual Review.
var _current_trick := TRICK_ID_SITT

## The coin economy (068, Phase-3 P3-D3 "unlock breeds via a light economy"): mastering a trick earns
## coins toward adopting a breed. The balance rides the SAME save file as the learned bars (TrickStore)
## so a returning player keeps their coins across a reload (X-7 offline). `_coin_readout` shows the
## running balance in the HUD. Earning + balance + persistence build now; the adopt/select UI that
## SPENDS coins waits on the owner-gated extra breed models (BUST-068 residual), so no spend caller
## exists yet — CoinPurse.spend()/can_afford() are covered by unit tests, ready for that UI.
var _purse := CoinPurse.new()
var _coin_readout: CoinReadout
const COIN_REWARD_MASTERY := 10  # coins per trick mastered (light — 3 tricks = 30 toward a breed)

## The owned-breeds roster + the collect-and-train loop (079, P3-1/P3-D3/P3-4). The player owns the
## starter yellow Labrador from the first run; mastering tricks earns coins (above) that can be SPENT to
## adopt the already-built chocolate Lab (076), and the active breed can be switched between owned dogs —
## all persisted alongside the coins + learned bars in the ONE TrickStore save blob (X-7 offline). The
## adopt/switch surface is the completion menu's breeds section (TrickMenu); `_breed` (above) tracks the
## active breed's temperament + coat. A fresh/corrupt/legacy save degrades to owning just the Labrador.
var _roster := BreedRoster.new()
const BREED_ADOPT_COST := 30  # the chocolate Lab's price: exactly the 3-trick mastery payout (3 × 10)

## Which roster last set the trained dog on the rig (174, PO father-pass-39 X-4): the KENNEL switch
## («Tren med Nova», _apply_active_kennel_dog) sets true, a Phase-3 BREED switch (_apply_active_breed) sets
## false. Last-writer-wins mirrors the coat, so the "show-off" surfaces (breed showcase + «Raser» row) name
## the dog actually on screen. Default false: the starter boot rides the Phase-3 breed default (K-7 gate).
var _active_from_kennel := false

## The EFFECTIVE global difficulty mode (080, P4-1 "Choose how hard"). Pure value object; Normal =
## identity (reproduces today's tuning EXACTLY, no regression). Defaults to Normal on boot; set by the
## player via the completion-menu selector (118), overridable by `?bra_difficulty=`, and FORCED to a
## dog's locked mode while a special dog trains (119). 081+ apply the bundle to resolve the read levers.
## The player's free pick lives in `_chosen_difficulty` (below); this is what a special-dog lock overrides.
var _difficulty := Difficulty.normal()

## The player's CHOSEN difficulty (119, P4-1). Distinct from the EFFECTIVE `_difficulty`: a special dog
## (RARE/EPIC/SECRET) forces its locked mode over the top, but the player's free pick is remembered here
## so switching back to a normal dog RESTORES it. This — not the effective mode — is what persists, so a
## special dog forcing Hard never clobbers the player's real preference in the save. Normal on a fresh
## boot; set from the persisted setting in _resolve_difficulty and updated only in _on_difficulty_chosen.
var _chosen_difficulty := Difficulty.normal()

## The marker-word catalog + progressive unlock (091, P5-1). A pure value object: the set of
## unlocked word ids + the one active word id, persisted alongside tricks/coins/roster/difficulty
## in the ONE TrickStore save blob. Base "bra" is always unlocked; new words unlock as tricks are
## mastered (mastered_count → unlock_up_to). The active word's clip is played by PayoffPlayer on
## every successful mark. Defaults to "bra" only so pre-Phase-5 play is byte-identical.
var _words := MarkerWords.new()

## The ADR-0007 telemetry choke-point (084, X-8): the ONE Telemetry node for this scene.
## Every capture routes through _telem() — a single audit point. Instantiated in _ready()
## and kept so wiring tests can read _telemetry.captured (the recording sink). Null-guarded
## in _telem() so headless paths that skip _ready() never throw.
var _telemetry: Telemetry

## Total accepted BRA taps this session (084, X-8): incremented once per accepted tap in
## _on_bra_pressed (after the gate locks, so mash-swallowed taps are never counted). Reported
## in the session_end event. Starts at 0 for every session.
var _attempts := 0

## The procedural "confused beat" on a bad tap (045, P2-4) — the mirror of the joyful mark:
## the dog briefly recoils, then settles. It is PROCEDURAL (a damped yaw wobble restored
## exactly to the dog's rest transform), NOT a faked clip — the licensed pack carries no
## confused animation, so synthesising one would be a stub. `_confused_age < 0` = inactive.
var _dog: Node3D
var _dog_rest: Transform3D
var _confused_age := -1.0

## The procedural "joyful beat" on a successful mark (077, PO Note 7) — the positive twin of the
## confused beat, driven by JoyBeat off the same dog root. It REPLACES the authored `Jump_Place_IP`
## reaction as the mark celebration: that hop rotated the dog rear-to-camera (tail up) and snapped
## through a side profile (the "chaotic, unnatural" payoff the PO caught), and the manifest ships no
## wag/tail clip to swap to. This facing-preserving bounce stays on the seated hold and can't spin
## the dog. `_joy_age < 0` = inactive. (DogDirector.play_reaction stays a tested asset capability but
## is no longer the mark celebration — see _play_payoff / _play_mastery_beat.)
var _joy_age := -1.0

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

## Face-the-camera turn on a real trick (061, P2-11 "face me for the trick"). The scene camera is
## fixed; when a real (non-feint) sit begins the dog must turn to face the camera POV so the apex
## reads head-on. `_camera` is the framed Camera3D (kept so the target heading is computed from its
## real position). `_face` is the pure bounded-speed turner (scripts/face_turn.gd) — null while
## roaming (the wander drives the yaw directly, unchanged), built when a trick engages and dropped
## once a post-trick release re-aligns with the roam. `_facing` is true while turning IN to / holding
## the camera; false during the eased release. `_sit_face_heading` caches the camera-facing target
## for the current sit (the dog is frozen for the sit, so it's constant). A FEINT never engages any
## of this — feints don't call `_engage_face_for_sit`, so the dog keeps its wander heading (P2-11).
var _camera: Camera3D
var _face: FaceTurn
var _facing := false
var _resting_face := false   ## true while easing the PAUSED dog to face the player between offers (071, PO note 3)
var _sit_face_heading := 0.0

## The natural in-character turn rate (rad/s, ~200°/s — a brisk dog pivot) used for the release and
## as the floor for the turn-in; the turn-in is sped UP from here only as much as it must to finish
## before the apex (FACE_APEX_FRACTION of the time-to-apex, floored by FACE_MIN_DEADLINE). Reduced
## motion (X-5) swaps in FACE_REDUCED_SPEED so the facing resolves near-instantly (still resolves —
## a dampened/near-instant turn is fine). FACE_DEFAULT_APEX is the fallback when no window is open.
const FACE_ROAM_SPEED := 3.5
const FACE_APEX_FRACTION := 0.6
const FACE_MIN_DEADLINE := 0.15
const FACE_REDUCED_SPEED := 100.0
const FACE_DEFAULT_APEX := 1.0

func _ready() -> void:
	# (116 retired the offline CC0 portrait bake — the kennel now renders the game's actual dog via a
	# live SubViewport in kennel_screen.gd, so no ?bra_bake_portrait route / static PNG remains.)
	_load_roster()                   # restore the owned-breeds roster + active breed BEFORE the dog loads (079/P3-4)
	_load_kennel_roster()            # restore the kennel-dog owned roster (109, Phase 8 K-7)
	_words.restore(_store.load_words())  # restore the marker-word unlock state + active word (091/P5-1)
	_breed = _resolve_active_breed() # the ACTIVE breed: the persisted roster pick, or the ?bra_breed= capture override (076/079); must precede _load_dog (coat tint) + _start_dog (levers)
	_current_trick = _query_trick()  # the INITIAL trick; the 072 completion menu switches it at runtime (?bra_trick= is a kept web-only debug default for the capture harness)
	_chosen_difficulty = _resolve_difficulty()  # the player's CHOSEN mode: persisted or ?bra_difficulty= (080/P4-1/119)
	_difficulty = _chosen_difficulty     # the EFFECTIVE mode starts as the chosen one; a special active dog forces its lock in _apply_active_kennel_dog (119)
	_apply_reduced_motion()  # set _motion_scale BEFORE _start_dog builds the tell (P1-8)
	# Mount the ADR-0007 telemetry choke-point (084, X-8): the one node all captures route through.
	# Instantiated here, before any capture, so session_start is the first event this session.
	# Fire-and-forget: disabled locally (empty token) — never blocks gameplay (X-7).
	_telemetry = Telemetry.new()
	add_child(_telemetry)
	var _vp := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(720, 1280)
	_telem("session_start", {"platform": OS.get_name(), "viewport": [_vp.x, _vp.y]})
	_load_progress()         # restore saved learned progress BEFORE the bar is built (049/P2-5)
	_load_coins()            # restore the saved coin balance BEFORE the readout is built (068/P3-D3)
	_setup_environment()
	_setup_light()
	var dog := _load_dog()
	if dog != null:
		_start_dog(dog)
		_frame_camera(dog)
		_setup_ground_plane(dog)    # grass ground plane at the foot plane (047/P2-10)
		_setup_path_to_house(dog)   # winding tan path curving back to a small house (099/Phase 6)
		_setup_fence_line(dog)      # white picket fence across the mid-ground (099/Phase 6)
		_setup_border_bushes(dog)   # low bushes framing the bottom corners (099/Phase 6)
		_setup_ground_coins(dog)    # ambient gold coins resting on the grass (099/Phase 6)
		_setup_hedge_band(dog)      # stylized hedge at the horizon for depth (078/Note-6)
		_setup_contact_shadow(dog)  # blob shadow ON the grass (031/P1-1)
		_setup_sun_disc(dog)        # explicit sun disc in the sky (047/P2-10)
	else:
		_fallback_camera()
	# K-7: boot into the active KENNEL dog — re-tint the shared rig to that dog's coat + apply its stat
	# levers, so a returning player lands on the exact dog they last chose to train. Runs AFTER _start_dog
	# (needs _loop + _dog + _progress_by_trick). Gated to when the player has actually DIVERGED the kennel
	# from its starter (active != Bella): at the default we defer to the Phase-3 breed-roster boot (079) so
	# that system + its ?bra_breed= capture seam stay unclobbered — and since kennel-Bella IS the yellow
	# Labrador the breed default already boots, the visible dog is identical either way. So the kennel only
	# takes over the boot once the player has chosen a kennel dog through it.
	# Visual-Review seam (119): `?bra_kennel=<id>` forces that dog active on boot (adopt if needed), so the
	# harness can boot straight into a special dog to prove the locked-difficulty read. Dormant off web.
	var _forced_kennel := _query_kennel_id()
	if _forced_kennel != "":
		_kennel_roster.adopt(_forced_kennel)
		_kennel_roster.set_active(_forced_kennel)
	if _dog != null and _query_breed_id() == "" and _kennel_roster.active != KennelDog.STARTER_ID:
		_apply_active_kennel_dog(_kennel_roster.active)
	_publish_kennel_active()  # seed the capture/e2e hook with the booted active kennel dog
	_setup_bra_button()
	_setup_payoff()
	_payoff.set_active_word(_words.active())  # point the payoff player at the restored active word (091/P5-1)
	_force_tell = _query_force_tell()        # deterministic apex-tell pixel proof (030, web-only seam)
	_force_tier = _query_force_tier()        # deterministic readout-contrast pixel proof (033, web-only)
	_autotap = _query_autotap()              # deterministic reaction-capture mark (034, web-only)
	_force_lock = _query_force_lock()        # deterministic anti-mash lock pixel proof (046, web-only)
	_force_scratch = _query_force_scratch()  # deterministic scratch-feint capture (071, web-only)
	_force_trainer = _query_force_trainer()  # deterministic approach-ring pixel proof (058, web-only)
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

## Trick-selection seam (065/067, BUST-064): read `?bra_trick=ligg` / `=legg_deg` (or `=sitt`) off the
## live web URL to boot the dog straight into a specific trick, so each wired trick is drivable +
## Visual-Reviewable in a capture burst without hand-driving the completion menu. Defaults to Sitt
## everywhere else (desktop / headless / normal play), so the PO-verified default experience is
## unchanged. Reads a STRING (never a bare bool) to dodge the Web-export null-Variant marshalling that
## bit the apex tell (036); unknown values fall back to Sitt.
func _query_trick() -> String:
	if not OS.has_feature("web"):
		return TRICK_ID_SITT
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	if typeof(search) != TYPE_STRING:
		return TRICK_ID_SITT
	var q := (search as String).to_lower()
	# Legg deg checked before Ligg: `legg_deg` and `ligg` are distinct substrings, but keep the
	# more specific id first so the branch reads unambiguously as more tricks wire.
	if q.contains("bra_trick=legg_deg"):
		return TRICK_ID_LEGG_DEG
	if q.contains("bra_trick=ligg"):
		return TRICK_ID_LIGG
	return TRICK_ID_SITT

## Resolve the ACTIVE breed for this boot (079): the `?bra_breed=` capture override wins (a kept dev seam
## so the Visual-Review harness can boot straight into a breed without owning it), else the persisted
## roster's active breed. So a returning player boots into the dog they last chose, and the in-game
## select works with no debug URL — the URL is now just the capture shortcut, not the only path (076).
func _resolve_active_breed() -> BreedPersonality:
	var forced := _query_breed_id()
	if forced != "" and BreedPersonality.is_known(forced):
		return BreedPersonality.by_id(forced)  # capture-harness override — shows the breed without needing it owned
	return BreedPersonality.by_id(_roster.active)

## Breed-capture seam (076, BUST-074 → 079 dev seam): read `?bra_breed=chocolate` off the live web URL to
## boot the dog straight into a breed for Visual Review, returning its id ("" = no override → use the
## roster). Reads a STRING (never a bare bool) to dodge the Web-export null-Variant marshalling that bit
## the apex tell (036); unknown values return "" (fall back to the roster's active breed).
func _query_breed_id() -> String:
	if not OS.has_feature("web"):
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	if typeof(search) != TYPE_STRING:
		return ""
	if (search as String).to_lower().contains("bra_breed=chocolate"):
		return "chocolate_labrador"
	return ""

## Active-kennel-dog seam (119, P4-1): read `?bra_kennel=<id>` off the live web URL so the Visual-Review
## harness can boot straight into a specific kennel dog (e.g. a special dog, to prove the locked
## difficulty read) without grinding the coins to adopt it in-game. Returns the dog id, or "" (no
## override → the persisted kennel roster). Reads a STRING (never a bare bool) to dodge the Web-export
## null-Variant marshalling that bit the apex tell (036); an unknown id returns "".
func _query_kennel_id() -> String:
	if not OS.has_feature("web"):
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	if typeof(search) != TYPE_STRING:
		return ""
	var q := (search as String).to_lower()
	for d in KennelDog.catalog():
		if q.contains("bra_kennel=" + (d as KennelDog).id):
			return (d as KennelDog).id
	return ""

## Resolve the GLOBAL difficulty for this boot (080/P4-1): the `?bra_difficulty=` web seam
## override wins (a debug hook so the Visual-Review harness can test Hard/Expert dormant modes),
## else the persisted difficulty setting, else "normal". So a fresh/corrupt boot defaults to Normal
## (identity, byte-identical to HEAD), and a returning player boots into their last-chosen mode
## (or Normal if the save is legacy/corrupt). Reads a STRING (never a bare bool) to dodge the
## Web-export null-Variant marshalling that bit the apex tell (036); unknown values fall back to
## the persisted setting or "normal".
func _resolve_difficulty() -> Difficulty:
	var forced := _query_difficulty()
	if forced != "" and Difficulty.is_known(forced):
		return Difficulty.by_id(forced)  # web override — test the dormant modes
	var persisted := _store.load_difficulty()
	return Difficulty.by_id(persisted)

## Difficulty-mode seam (080/P4-1): read `?bra_difficulty=normal|hard|expert` off the live web
## URL, returning the mode id ("" = no override → use the persisted setting). Reads a STRING
## sentinel (never a bare bool) to dodge the Web-export null-Variant marshalling gotcha (036);
## unknown/garbage values return "" (fall back to the persisted setting).
func _query_difficulty() -> String:
	if not OS.has_feature("web"):
		return ""
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	if typeof(search) != TYPE_STRING:
		return ""
	var q := (search as String).to_lower()
	if q.contains("bra_difficulty=hard"):
		return "hard"
	if q.contains("bra_difficulty=expert"):
		return "expert"
	if q.contains("bra_difficulty=normal"):
		return "normal"
	return ""

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

## Visual-review seam (071): read `?bra_force_scratch=1` off the live web URL to pin every offer to a
## scratch feint so the brief scratch is reliably captured (see _force_scratch). Off the web export
## JavaScriptBridge.eval is a no-op, so this is false in headless/desktop and normal play is untouched.
func _query_force_scratch() -> bool:
	if not OS.has_feature("web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	return typeof(search) == TYPE_STRING and (search as String).contains("bra_force_scratch=1")

## Visual-review seam (058/P2-9): true only when the live web URL carries `?bra_force_trainer=1`.
## Pins the approach ring to a mid-approach radius at full opacity every frame so a SINGLE
## screenshot deterministically proves the ring renders (the live ring sweeps in ~0.2s per sit
## cycle — too brief for a non-deterministic burst to reliably catch, the same problem 030
## solved for the apex tell). Web-only (off desktop/headless/normal play); reads a STRING
## sentinel, never a bare bool, to dodge the Web-export null-Variant marshalling gotcha (036).
func _query_force_trainer() -> bool:
	if not OS.has_feature("web"):
		return false
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	return typeof(search) == TYPE_STRING and (search as String).contains("bra_force_trainer=1")

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
	if _trainer_marker != null:
		if _force_trainer:
			# Pin to mid-approach radius at full opacity for deterministic screenshot (058).
			_trainer_marker.set_radius_scale(0.5)
			_trainer_marker.set_opacity(1.0)
		elif _trainer != null and _session.is_open():
			var el := _session.elapsed()
			_trainer_marker.set_radius_scale(_trainer.radius_scale(el))
			_trainer_marker.set_opacity(_trainer.opacity(el))
		else:
			_trainer_marker.set_opacity(0.0)
	if _readout != null:
		if _force_tier >= 0:
			_readout.display(_force_tier as SitWindow.Tier)  # pin tier for capture (033) — web-only
		_readout.advance(delta)  # fade the last tier's flash (024g/P1-7)
	if _word_pop != null:
		_word_pop.advance(delta)  # float/fade the fired marker word (094/P5-3)
	if _learned_bar != null:
		_learned_bar.advance(delta)  # fade the setback wash (045/P2-4)
	_drive_wander(delta)   # roam the patch + place the dog at its wander spot (050/P2-8)
	_drive_confused(delta) # layer the bad-tap wobble on top of the wander base (045)
	_drive_joy(delta)      # layer the good-mark celebration bounce on top of the wander base (077)

## Drive the repeating round loop (027, P1-9): each frame SitLoop decides whether to begin
## the next sit or stand the dog back to idle. A no-op until _start_dog builds _loop, and a
## permanent idle on the CC0 dog (has_sit == false) — never a faked sit.
func _advance_loop(delta: float) -> void:
	if _menu_open:
		return  # the completion menu is up — pause offers so no trick fires behind the modal (072)
	if _loop == null or _director == null:
		return
	var sit_end := _window.sit_end if _window != null else 0.0
	match _loop.tick(delta, _director.has_trick(_current_trick), _session.elapsed(), sit_end):
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
	_director.play_trick(_current_trick)  # Sitt or Ligg — the dog performs the current trick (065)
	# The active breed's window_stability widens/tightens the timing bands (075, P3-3): the Labrador's
	# forgiving temperament gives a touch more grace. Radii compose with 073's late_bias in SitWindow.
	# Difficulty stacks on top (081, P4-2/P4-4): effective = breed_intrinsic × difficulty.window_scale.
	# Normal is identity — no change to default play (dormancy).
	# Marker-word widening stacks on top (093, P5-2): effective_window_scale() returns the active
	# word's scale when it is available (not cooling), else 1.0. Base "bra" (scale 1.0) + Normal
	# difficulty + Labrador = byte-identical to pre-093 play (all multipliers = 1.0 × identity).
	var _word_scale := _words.effective_window_scale()
	_window = _director.trick_window(_current_trick,
		_difficulty.scale_radius(_breed.perfect_radius()) * _word_scale,
		_difficulty.scale_radius(_breed.ok_radius()))
	_session.open(_window)
	_engage_face_for_sit()  # turn to face the camera so the apex reads head-on (061, P2-11)
	# Tell intensity scales with difficulty (081, P4-2): harder modes fade the tell. Clamped to
	# TELL_FLOOR so a non-zero tell never collapses to zero (ADR X-5). The tell's narrowness/speed
	# falls out for free from the already-tightened _window.ok_radius (one source of truth).
	_tell = ApexTell.from_window(_window, _difficulty.scale_tell_intensity(_motion_scale))
	# Build the approach-cue ring from the SAME window (single source of truth) — its teach
	# strength reflects the CURRENT learned level so each sit's ring fades with the bar (058).
	_trainer = TrainerRing.from_window(_window, TrainerRing.teach_strength(_progress.value, _progress.mastered))

## End the sit: close the session (taps DEAD again, no penalty between sits — P1-5), drop
## the tell so the marker goes dark, and stand the dog back down to the ambient idle so the
## loop can come round to the next sit (P1-9).
func _end_sit() -> void:
	_session.close()
	_window = null
	_tell = null
	_trainer = null  # drop the approach ring — marker goes dark next _process frame (058)
	_autotapped = false  # arm the next sit's capture mark (034 seam)
	_director.play_trick_end(_current_trick)  # stand back up through the trick's authored end clip (059/065), then idle
	_release_face()  # ease the facing back to the roam heading, then hand yaw to the wander (061)
	_resume_wander()  # come back round to roaming the patch (050)

## Begin a feint (048, P2-8): the dog visibly dips toward a sit and aborts. CRUCIALLY this
## leaves _session/_window/_tell UNTOUCHED — no scoring window opens for a feint, so the apex
## tell stays dark (P1-4 honest, the same path P2-9 will fade) and a tap during the dip flows
## through the existing _on_bra_pressed → _session.tap() → DEAD → gentle erosion + confused
## beat, with ZERO new downstream branches. Only the dog's animation differs from idle.
func _begin_feint() -> void:
	_pause_wander()  # settle so the dip reads as a deliberate fake-sit, not a stride (050)
	# A feint is sometimes the funny SCRATCH, sometimes the plain trick-dip (071, PO note 3). Both open
	# NO scoring window (a tap during either is DEAD — P2-8). Falls back to the trick-dip if the dog
	# has no scratch clip (the CC0 gate), so a scratch-less dog never fakes one.
	if _loop != null and _loop.is_scratch_feint() and _director.has_scratch():
		_director.play_scratch()                    # the funny scratch — still no markable window
	else:
		_director.play_trick_feint(_current_trick)  # feint the current trick's build-in (065)

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
	# Sky gradient (P2-10 stylization, 062): a bright clear sky-blue zenith grading down to a WARM
	# peach/cream near-horizon — the Pokémon-GO warmth the owner asked for, and a richer grade than
	# the old blue→flat-pale-yellow band. Peach means red leads green leads blue at the horizon.
	# 143 (PO father-pass-8, X-4): the old warm-peach horizon dominated the look-down camera's
	# near-horizon band, so the visible sky read a muddy grey-brown haze (PO measured (166,156,127)) —
	# no blue at all. The goal art is a bright sunny day: a clean pale-blue sky (~(184,213,240)). So the
	# horizon now reads PALE BLUE (blue leads), turning the whole visible band cool and sunny.
	sky_mat.sky_top_color = Color(0.30, 0.56, 0.90)       # clear sky-blue zenith
	sky_mat.sky_horizon_color = Color(0.72, 0.84, 0.95)   # pale-blue horizon — matches the goal-art sky sample; blue leads
	sky_mat.sky_curve = 0.2                     # gentle grade — the pale band spreads up, not banded
	# Ground half of the procedural sky (below horizon). The finite 40 m grass plane doesn't quite
	# reach the true horizon, so a thin band of this shows between the plane's far edge and the sky.
	# 143: a COOL pale haze at the horizon (was warm cream) so that thin band blends into the pale-blue
	# sky instead of cutting a brown seam under it, fading to distant grass-green below.
	sky_mat.ground_bottom_color = Color(0.46, 0.66, 0.36)   # brighter distant grass (matches the lifted lawn)
	sky_mat.ground_horizon_color = Color(0.74, 0.84, 0.88)  # cool pale haze, blends with the pale-blue sky horizon
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
	env.ambient_light_energy = 0.8   # 143: lifted 0.6 → 0.8 for a brighter sunny-day exposure (the goal reads bright, not dusk)
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

## Portrait layout constants (029). The 720×1280 logical viewport is the DESIGN base;
## with stretch=expand (063) the real frame is taller on modern phones, but these are
## anchor-relative offsets (insets from the real edges), so they hold on any portrait device.
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
## Approach-cue trainer ring (058/P2-9): seated in the clear band ABOVE the BRA button so
## the large cyan ring NEVER crosses the pill at any point in its animation (owner directive
## 2026-07-05, task 123). The fully-expanded radius is ring_radius(160, 1.0) ≈ 259.2 px, so
## the ring centre must satisfy: ring_center_y + 259.2 < BRA_OFFSET_TOP (-280), i.e.
## ring_center_y < -539.2. -580 gives a bottom edge of ≈ -320.8 (41 px clear of the button
## top) and a top edge of ≈ -839.2 (well within the 1280-px viewport). The half-width of the
## marker square is still TELL_HALF_WIDTH (160) — same SIZE constant — so the two rings share
## the same aspect; only the vertical band differs.
const RING_CENTER_Y := -580.0
const RING_OFFSET_TOP := RING_CENTER_Y - TELL_HALF_WIDTH    ## -740.0
const RING_OFFSET_BOTTOM := RING_CENTER_Y + TELL_HALF_WIDTH ## -420.0
## The coin readout (069) gets its OWN top line at the very top of the HUD. Since the always-on chip
## row is retired (072, PO note 1 — the completion menu is the chooser now), the learned bar and timing
## readout stack directly below the coin line, reclaiming the band the selector used to occupy.
const COIN_READOUT_TOP := 10.0

## The "Tricks" reopen button (072): a small persistent touch target in the top-LEFT corner (clear of
## the top-right coin readout and far from the bottom BRA band), so the player can reopen the completion
## menu between rounds to switch trick — never a dead-end waiting on a mastery.
const TRICKS_BTN_MARGIN := 20.0
const TRICKS_BTN_TOP := COIN_READOUT_TOP
const TRICKS_BTN_WIDTH := 128.0   ## 100: a touch wider so the glyph + "Triks" both fit the pill
## 185 (PO father-pass-58 X-6): the «Kennel» nav pill was pinned to a bare 96 px and Godot trimmed
## the 6-char label to «Kennel.» with an overrun ellipsis. Named for parity with TRICKS_BTN_WIDTH and
## widened to hold «Kennel» at T_HEAD with balanced side padding (no glyph, so narrower than Triks).
const KENNEL_BTN_WIDTH := 118.0
const TRICKS_BTN_HEIGHT := 44.0
## 100 (Phase 6): the drawn hamburger menu glyph on the Triks pill + the top-HUD legibility lift.
const TRICKS_GLYPH_GAP := 8       ## px between the hamburger glyph and the "Triks" label
const HAMBURGER_BAR_W := 20       ## px width of each of the three bars (baked into the icon image)
const HAMBURGER_BAR_H := 2        ## px thickness of each bar
const HAMBURGER_BAR_GAP := 4      ## px gap between bars
## A deeper drop shadow than panel()'s default (alpha .08) for the top HUD pills, so a pale PAPER
## pill lifts off the bright sun band instead of washing out (PO Phase-6 note #3).
## 125: bumped alpha 0.20 → 0.28 — extra lift for directive-5 HUD legibility after de-bloom.
const HUD_PILL_SHADOW := Color(DesignSystem.INK.r, DesignSystem.INK.g, DesignSystem.INK.b, 0.28)
## The «Triks»/«Kennel» HUD nav pills + hamburger glyph ink (176 → 200). SLATE (176's predecessor)
## then BLUE_INK both read too light in the SHIPPED render: at the small bold T_HEAD (18px Baloo)
## the thin strokes reach only ~0.60 sub-pixel coverage, so BLUE_INK's darkest core washed to
## ~2.43:1 on the PAPER pill (PO father-pass-77 measured it — analytic 4.84:1 was a mirage). 200
## points this at the deeper DS NAV_INK (#0a1628), dark enough that even the 0.60-coverage rendered
## pixel clears AA (~4.8:1 in the render-floor model) yet still blue-dominant for the goal-art blue.
## One named source so both pill labels and the glyph can never drift apart.
const HUD_NAV_INK := DesignSystem.NAV_INK
## 200: a same-ink outline that THICKENS the nav-label strokes. At 18px the thin Nunito-700 strokes
## reach only ~0.55 sub-pixel coverage in the SwiftShader/GL-Compat render, which caps the darkest
## stroke-core contrast at ~4.68:1 even for pure black — so a dark ink alone cannot clear AA with
## margin. Outlining the glyph in its own ink raises effective coverage (no change to text advance,
## so «Kennel» stays un-truncated / geometry unchanged), letting NAV_INK reach ≥4.5:1 in the actual
## render. Applied to «Triks» + «Kennel» (the hamburger bars are already full-coverage baked pixels).
const HUD_NAV_LABEL_OUTLINE := 4

## Learned bar (045, P2-4): a meter below the coin line holding the trick label + progress track.
## 097 (Phase 6): expanded to include the trick-name label row above the track itself. The label row
## is T_TITLE (26px) + a small gap, so the total band is LABEL_ROW + gap + TRACK height.
## LEARNED_BAR_HEIGHT covers the full band so READOUT_OFFSET_TOP stacks correctly below it.
const LEARNED_BAR_OFFSET_TOP := COIN_READOUT_TOP + CoinReadout.HEIGHT + 10.0  ## below the coin pill
const LEARNED_BAR_LABEL_ROW := 26.0   ## px height of the trick-name / percentage row
const LEARNED_BAR_TRACK_HEIGHT := 12.0 ## px height of the actual bar track
const LEARNED_BAR_LABEL_GAP := 4.0    ## gap between label row and track
const LEARNED_BAR_HEIGHT := LEARNED_BAR_LABEL_ROW + LEARNED_BAR_LABEL_GAP + LEARNED_BAR_TRACK_HEIGHT
const LEARNED_BAR_MARGIN_X := 48.0

## Timing readout: a band across the upper portrait area, clear of dog and button (024g). Stacked
## below the learned bar. 038 kept the flashed tier word off the centred dog's crown; the taller
## expand frame (063) leaves ample sky for the coin line + bar + readout stack above the dog.
const READOUT_OFFSET_LEFT := 24.0
const READOUT_OFFSET_RIGHT := -24.0
const READOUT_OFFSET_TOP := LEARNED_BAR_OFFSET_TOP + LEARNED_BAR_HEIGHT + 16.0
const READOUT_OFFSET_BOTTOM := READOUT_OFFSET_TOP + 124.0  ## 124 px band (unchanged height, 038)

## Word-pop band (094, P5-3): anchored to the bottom, just ABOVE the BRA button top, so the
## fired word floats up from the button into the clear lower-middle sky. Must not overlap the
## top-centre TierReadout (which is in the upper third). 8 px gap + 120 px tall band.
const WORD_POP_MARGIN_X := 24.0
const WORD_POP_BAND_HEIGHT := 120.0
const WORD_POP_OFFSET_BOTTOM := BRA_OFFSET_TOP - 8.0          ## just above the button top
const WORD_POP_OFFSET_TOP := WORD_POP_OFFSET_BOTTOM - WORD_POP_BAND_HEIGHT
## Coin readout (068, redrawn in 069/P3-D3): a small running balance tucked on its OWN top line in
## the top-right corner (COIN_READOUT_TOP), clear of the top-left Tricks button — the earned-coins
## feedback is always visible in-round, and the completion menu (072) shows the same balance in its
## header. The CoinReadout node draws its own coin disc + digits + "coins" caption, so main only
## supplies the anchor box + width.
const COIN_READOUT_MARGIN := 20.0
const COIN_READOUT_WIDTH := 170.0
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
	_camera = cam  # kept so the face-the-camera turn (061/P2-11) aims at its real position

## 143 (PO father-pass-8, X-4): the painterly grass ramp's shadow/mid/light tones. Lifted from
## the 099 values toward the goal art's bright saturated green (~(136,185,104)) so the mottled
## lawn reads sunny, not the dark olive (85,148,94) the PO measured. Named so the grass-brightness
## test can guard it directly (a regression back to the dark ramp can't read green).
## 144 (PO father-pass-9, X-4): the ROOT CAUSE of the muddy/blotchy foreground was the oversized
## contact-shadow disc washing the near lawn (see GARDEN_SHADOW_SPREAD below) — NOT the ramp. But
## while here, lift the dark end off (0.34,0.56,0.28) and narrow the shadow→light spread to Δg 0.13
## so the painterly mottle is a subtle variation, not high-contrast patches, and the whole lawn sits
## nearer the goal's bright green. Secondary polish; the test pins the dark floor + the spread.
const GRASS_TONES := [
	Color(0.52, 0.72, 0.42),       # shadowed green — lifted off mud, still green-leading/saturated
	Color(0.57, 0.78, 0.46),       # mid grass
	Color(0.62, 0.84, 0.50),       # light sunny green — near the goal-art lawn sample
]

## 144 (PO father-pass-9, X-4): the baked normal-map relief strength. Pass-8 left it at 1.3; a strong
## relief adds visible mottle at the grazing foreground angle, so dial it to a gentle 0.3 — the lawn
## keeps a whisper of micro-relief but shades evenly front-to-back (a probe with it disabled confirmed
## it was NOT the main foreground-darkening cause; the contact shadow was). Named so the test guards it.
const GRASS_RELIEF_BUMP := 0.3

## 144 (PO father-pass-9, X-4): the contact-shadow disc diameter as a multiple of the footprint.
## 101 pushed this to 1.55×, but the flat disc projects from the low camera across the whole lower
## frame and washes the foreground grass dark. 1.1× keeps a tight grounding smudge under the paws
## without spilling onto the lawn. Named so the foreground-grass evenness test can guard it.
const GARDEN_SHADOW_SPREAD := 1.1

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
	# Painterly grass (062/P2-10 stylization): a low-frequency noise with a green colour-ramp paints
	# mottled patches of deep-shadow / mid / sunny green across the plane, so the lawn reads
	# painterly rather than one flat gradient (the owner's 2026-07-01 directive). Baked to an Image
	# (NoiseTexture2D), so it renders in every GL path incl. the local software renderer. Cheap: one
	# albedo texture, no shader, no extra geometry — the plane stays flat so the dog's foot plane and
	# contact shadow are untouched (grounding safe); "shape" is tonal, not geometric (Phase-7 defers
	# real relief). GL-Compatibility-safe.
	# FBM fractal (078/Note-6): stacking octaves gives the albedo BOTH the large soft patches AND
	# a finer blade-scale grain, so the lawn reads as textured grass rather than one smooth mottle.
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.032            # large soft patches; fewer octaves keep it painterly, not noisy
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 2          # 099: dialled from 4 → 2 so the lawn reads smooth, not pixel-noise
	noise.fractal_gain = 0.45          # gentler octave falloff → softer mottle
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	# 143 (PO father-pass-8, X-4): the 099 ramp read a dark low-saturation olive under the dusk sky
	# (PO measured (85,148,94)); the goal art's lawn is a bright saturated green (~(136,185,104)). The
	# shadow/mid/light tones are lifted toward the goal so the mottled average reads bright and sunny,
	# while the narrow range (099) keeps it smooth-painterly, not patchy pixel-noise.
	ramp.colors = PackedColorArray(GRASS_TONES)
	var grass_tex := NoiseTexture2D.new()
	grass_tex.noise = noise
	grass_tex.color_ramp = ramp
	grass_tex.seamless = true          # tiles across the large plane without a visible seam
	grass_tex.width = 256
	grass_tex.height = 256
	mat.albedo_texture = grass_tex
	# A baked NORMAL map (078/Note-6): fine blade-scale ripples so the directional sun catches the
	# lawn's micro-relief and it stops reading as a flat fill — the biggest single cue that killed
	# the "cutout floating on a fill" look. Baked to an Image (headless-safe), no shader.
	var relief := FastNoiseLite.new()
	relief.noise_type = FastNoiseLite.TYPE_SIMPLEX
	relief.frequency = 0.16            # fine blade-scale bumps
	relief.fractal_type = FastNoiseLite.FRACTAL_FBM
	relief.fractal_octaves = 3
	var grass_normal := NoiseTexture2D.new()
	grass_normal.noise = relief
	grass_normal.as_normal_map = true
	grass_normal.bump_strength = GRASS_RELIEF_BUMP   # 099: 2.2→1.3; 144: →0.5 so foreground shades evenly (no grazing-angle blotches)
	grass_normal.seamless = true
	grass_normal.width = 256
	grass_normal.height = 256
	mat.normal_enabled = true
	mat.normal_texture = grass_normal
	mat.normal_scale = 1.0
	mat.uv1_scale = Vector3(3.5, 3.5, 1.0)   # 099: coarser tiling (6 → 3.5) → larger, softer painterly patches
	mat.roughness = 1.0    # 144: fully matte — kills the low-gloss sheen that over-brightened the mid-field
	mat.metallic = 0.0
	# Allow the sun's directional shading to land on it naturally.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	var ground := MeshInstance3D.new()
	ground.name = "GrassGround"
	ground.mesh = plane_mesh
	ground.material_override = mat
	ground.position = foot_center
	add_child(ground)

## 099 garden ambiance (Phase 6): the running garden read as an empty field — the PO asked it to
## match the goal training screen's LAYERED composition (a winding path to a small house, a picket
## fence across the mid-ground, corner bushes, ambient coins, a firm grounding shadow). These layers
## sit BEHIND / AROUND the centred dog so they never occlude its silhouette at the scored apex
## (face-camera contract, 061/077). All node-local transforms off the dog bounds (skinned-AABB gotcha),
## all GL-Compatibility-safe (StandardMaterial3D / baked Image, no shader, no Forward+-only feature).
## Screen mapping: camera is behind the dog (+Z) looking toward -Z, so +X = right, -Z = far/up-in-frame,
## +Z = near/bottom; the sun keys from the upper-right (_setup_light rot -30,-40).
const GARDEN_HOUSE_DIST := 12.5        ## metres ahead (-Z) — between the fence (8.5) and hedge (17), near horizon
const GARDEN_HOUSE_RIGHT := 2.3        ## metres right (+X) — upper-right of frame but ON-screen (the look-down cone is narrow)
const GARDEN_HOUSE_WALL_SIZE := Vector3(2.0, 1.05, 1.4) ## 102: cottage walls — clearly WIDER than tall (was 1.6×1.4 → read as a tower)
const GARDEN_HOUSE_ROOF_SIZE := Vector3(2.25, 0.7, 1.55) ## 102: lower, wider gable with eave overhang (was 2.0×0.85 → too tall/steep)
const GARDEN_HOUSE_WALL := Color(0.85, 0.82, 0.72)      ## 102: warm CREAM walls — off near-white so the sun doesn't blow the face out (was 0.96,0.94,0.87)
const GARDEN_HOUSE_DOOR := Color(DesignSystem.BLUE_DARK.r, DesignSystem.BLUE_DARK.g, DesignSystem.BLUE_DARK.b, 1.0)  ## 102: small blue door on the face
const GARDEN_HOUSE_WINDOW := Color(DesignSystem.BLUE_LIGHT.r, DesignSystem.BLUE_LIGHT.g, DesignSystem.BLUE_LIGHT.b, 1.0)  ## 102: small light-blue window pane
const GARDEN_PATH_NEAR_Z := 2.4        ## 101: +Z the ribbon's near end reaches — foreground, past the dog toward the bottom
const GARDEN_PATH_NEAR_X := 0.6        ## 102: +X the near end sits — BESIDE the centred dog (right), so the dog stays on grass (was 0.0 = under the dog)
const GARDEN_PATH_WIDTH_NEAR := 0.5    ## 102: SLIM near-end width — a ribbon, not the full-width dirt wedge the PO caught (was 1.0)
const GARDEN_PATH_WIDTH_FAR := 0.32    ## 102: narrower far end (narrows as it recedes to the house)
const GARDEN_PATH_TAN := Color(0.82, 0.71, 0.52)        ## medium warm tan, the goal's path colour (drawn unshaded so it reads flat + even)
const GARDEN_PATH_LIFT := 0.012        ## metres above the grass plane so the path never z-fights
const GARDEN_FENCE_DIST := 8.5         ## metres ahead (-Z) — the mid-ground line, between dog and house
const GARDEN_FENCE_HALF_SPAN := 9.0    ## metres each side of centre the fence runs
const GARDEN_FENCE_PATH_X := 0.8       ## 101: the path's X where it crosses the fence — near-centre so BOTH fence sides show
const GARDEN_FENCE_GAP_HALF := 0.8     ## 101: half-width of the gate gap — narrow, so the right fence renders (was 1.4 → ate the right)
const GARDEN_PICKET_W := 0.06          ## picket post cross-section
const GARDEN_PICKET_H := 0.55          ## picket post height
const GARDEN_PICKET_SPACING := 0.42    ## gap between pickets
const GARDEN_RAIL_H := 0.05            ## horizontal rail thickness
const GARDEN_RAIL_D := 0.04            ## rail depth
const GARDEN_RAIL_Y_LOW := 0.18        ## lower rail height off the foot plane
const GARDEN_RAIL_Y_HIGH := 0.40       ## upper rail height off the foot plane
const GARDEN_FENCE_WHITE := Color(0.95, 0.95, 0.92)     ## soft white pickets (not clinical pure white)
const GARDEN_COIN_R := 0.04            ## 142 (PO father-pass-7): ambient ground-coin radius (0.08 m disc). The PO gold-pixel-scanned the 102 R=0.12 coins at 70×69 px (~18 % of the 390-wide screen) — ~4.5× the goal art's small (~14 px) scatter, so they read as HUD orbs crowding the dog. Camera sits ~1.2 m off the dog → ~292 px/m at coin depth, so 0.08 m ≈ 23 px, landing in the goal's 20–26 px band. keep_scale stays true (GL-Compat billboard collapses edge-on otherwise) — smallness comes from the radius.
const GARDEN_COIN_LIFT := 0.02         ## metres above the grass so a coin rests, doesn't sink

## A winding light-tan PATH curving from just in front of the dog back to a small HOUSE in the
## upper-right (099, goal directive #2). The path is a flat ribbon mesh laid on the grass (built
## from a Curve3D so it genuinely winds, not a straight quad); the house is a warm box + a blue
## gable roof at its far end. Both sit above the horizon-side of the grass and read as "home in the
## distance", framing the composition without occluding the centred dog.
func _setup_path_to_house(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		return
	var c := box.get_center()
	var foot_y := box.position.y
	var y := foot_y + GARDEN_PATH_LIFT
	var house_x := c.x + GARDEN_HOUSE_RIGHT
	var house_z := c.z - GARDEN_HOUSE_DIST
	# 101/102: the path curve RUNS FROM THE FOREGROUND back to the house — a continuous winding ribbon.
	# 102 fixes the over-correction: the near end is now SLIM and offset to the RIGHT (+X) of the centred
	# dog, so it emerges beside the dog on the grass (not a full-width wedge under its feet), passes
	# through the fence gate, then sweeps right to the house door. Real perspective (slim + narrowing as
	# it recedes) with the dog left grounded on grass. Curve3D.tessellate() samples it into ribbon points.
	var curve := Curve3D.new()
	curve.add_point(Vector3(c.x + GARDEN_PATH_NEAR_X, y, c.z + GARDEN_PATH_NEAR_Z))    # slim near end, foreground — BESIDE the dog (right)
	curve.add_point(Vector3(c.x + GARDEN_PATH_NEAR_X, y, c.z - 1.8))                   # stays right of the dog as it passes it
	curve.add_point(Vector3(c.x + GARDEN_FENCE_PATH_X, y, c.z - GARDEN_FENCE_DIST))    # threads the fence gate gap
	curve.add_point(Vector3(house_x, y, house_z + 0.7))                               # ends at the house door
	var pts := curve.tessellate(4, 2.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Taper the ribbon half-width along its length: WIDE at the foreground near end (t=0) → NARROW at
	# the far house end (t=1), so the constant-tan strip reads as a receding path, not an even band.
	var near_half := GARDEN_PATH_WIDTH_NEAR * 0.5
	var far_half := GARDEN_PATH_WIDTH_FAR * 0.5
	var last := float(pts.size() - 1)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var dir := b - a
		dir.y = 0.0
		if dir.length() < 0.0001:
			continue
		dir = dir.normalized()
		var half_a := lerpf(near_half, far_half, float(i) / last)
		var half_b := lerpf(near_half, far_half, float(i + 1) / last)
		var perp := Vector3(-dir.z, 0.0, dir.x)
		var perp_a := perp * half_a
		var perp_b := perp * half_b
		var al := a - perp_a
		var ar := a + perp_a
		var bl := b - perp_b
		var br := b + perp_b
		st.set_normal(Vector3.UP)
		st.add_vertex(al)
		st.set_normal(Vector3.UP)
		st.add_vertex(ar)
		st.set_normal(Vector3.UP)
		st.add_vertex(br)
		st.set_normal(Vector3.UP)
		st.add_vertex(al)
		st.set_normal(Vector3.UP)
		st.add_vertex(br)
		st.set_normal(Vector3.UP)
		st.add_vertex(bl)
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = GARDEN_PATH_TAN
	# Unshaded: the ribbon reads as an even flat tan (like the goal's path) regardless of the sun
	# angle or triangle winding — a shaded flat strip came out dark from the grazing sun.
	path_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	path_mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # ribbon is viewed top-down — never back-face cull it
	var path := MeshInstance3D.new()
	path.name = "GardenPath"
	path.mesh = st.commit()
	path.material_override = path_mat
	path.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(path)
	_add_garden_house(Vector3(house_x, foot_y, house_z))

## The small stylized house at the far end of the path (099): a warm off-white box (walls) capped
## with a blue PrismMesh gable roof. Node-local under a "GardenHouse" Node3D anchored at its foot,
## so the walls sit ON the grass and the roof stacks above. Small in frame at 13 m — reads as a
## cottage on the horizon, the goal's "home".
func _add_garden_house(base: Vector3) -> void:
	var house := Node3D.new()
	house.name = "GardenHouse"
	house.position = base
	add_child(house)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = GARDEN_HOUSE_WALL
	wall_mat.roughness = 0.95
	wall_mat.metallic = 0.0
	var walls := MeshInstance3D.new()
	walls.name = "Walls"
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = GARDEN_HOUSE_WALL_SIZE
	walls.mesh = wall_mesh
	walls.material_override = wall_mat
	walls.position = Vector3(0.0, GARDEN_HOUSE_WALL_SIZE.y * 0.5, 0.0)
	walls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	house.add_child(walls)
	var roof_mat := StandardMaterial3D.new()
	roof_mat.albedo_color = DesignSystem.BLUE   # the goal's blue roof — coheres with the DS BRA blue
	roof_mat.roughness = 0.85
	roof_mat.metallic = 0.0
	var roof := MeshInstance3D.new()
	roof.name = "Roof"
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = GARDEN_HOUSE_ROOF_SIZE   # triangular cross-section in XY → a gable ridge
	roof.mesh = roof_mesh
	roof.material_override = roof_mat
	roof.position = Vector3(0.0, GARDEN_HOUSE_WALL_SIZE.y + GARDEN_HOUSE_ROOF_SIZE.y * 0.5, 0.0)
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	house.add_child(roof)
	# 102: a small blue DOOR + WINDOW on the face toward the camera (+Z) so the box reads as a cozy home,
	# not a blank silo. The wall box is centred at (0, wall_h/2, 0); its front face is at +wall_depth/2.
	var face_z := GARDEN_HOUSE_WALL_SIZE.z * 0.5 + 0.03   # a hair proud of the wall so it never z-fights
	var door := _house_face_detail("Door", GARDEN_HOUSE_DOOR, Vector2(0.34, 0.62),
		Vector3(-0.42, 0.31, face_z))                      # door on the ground, left of centre
	house.add_child(door)
	var window := _house_face_detail("Window", GARDEN_HOUSE_WINDOW, Vector2(0.40, 0.34),
		Vector3(0.44, 0.66, face_z))                       # window upper-right of the door
	house.add_child(window)

## A small flat detail (door/window) on the house's camera-facing wall (102): a thin BoxMesh panel,
## its own solid DS-blue material. Node-local under the GardenHouse. GL-Compatibility-safe.
func _house_face_detail(node_name: String, col: Color, size: Vector2, pos: Vector3) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.8
	mat.metallic = 0.0
	var panel := MeshInstance3D.new()
	panel.name = node_name
	var m := BoxMesh.new()
	m.size = Vector3(size.x, size.y, 0.05)
	panel.mesh = m
	panel.material_override = mat
	panel.position = pos
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return panel

## A white PICKET FENCE across the mid-ground (099): a row of thin posts + two rails, with a GAP
## where the path passes through (a gate). Reads as the goal's fence separating the near-grass from
## the path/house band. One "PicketFence" Node3D of small BoxMesh children sharing a white material —
## static scenery, node-local, GL-Compatibility-safe.
func _setup_fence_line(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		return
	var c := box.get_center()
	var foot_y := box.position.y
	var z := c.z - GARDEN_FENCE_DIST
	var fence := Node3D.new()
	fence.name = "PicketFence"
	add_child(fence)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GARDEN_FENCE_WHITE
	mat.roughness = 0.9
	mat.metallic = 0.0
	# Posts across the span, skipping the gate gap where the path crosses.
	var gap_center := c.x + GARDEN_FENCE_PATH_X
	var x := c.x - GARDEN_FENCE_HALF_SPAN
	while x <= c.x + GARDEN_FENCE_HALF_SPAN + 0.01:
		if absf(x - gap_center) > GARDEN_FENCE_GAP_HALF:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(GARDEN_PICKET_W, GARDEN_PICKET_H, GARDEN_PICKET_W)
			post.mesh = pm
			post.material_override = mat
			post.position = Vector3(x, foot_y + GARDEN_PICKET_H * 0.5, z)
			post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fence.add_child(post)
		x += GARDEN_PICKET_SPACING
	# Two horizontal rails per segment (left of the gap, right of the gap).
	_add_fence_rails(fence, mat, foot_y, z, c.x - GARDEN_FENCE_HALF_SPAN, gap_center - GARDEN_FENCE_GAP_HALF)
	_add_fence_rails(fence, mat, foot_y, z, gap_center + GARDEN_FENCE_GAP_HALF, c.x + GARDEN_FENCE_HALF_SPAN)

## Two horizontal rails spanning [x0, x1] at the fence line (099 helper).
func _add_fence_rails(parent: Node3D, mat: Material, foot_y: float, z: float, x0: float, x1: float) -> void:
	var length := x1 - x0
	if length <= 0.05:
		return
	var cx := (x0 + x1) * 0.5
	for ry in [GARDEN_RAIL_Y_LOW, GARDEN_RAIL_Y_HIGH]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(length, GARDEN_RAIL_H, GARDEN_RAIL_D)
		rail.mesh = rm
		rail.material_override = mat
		rail.position = Vector3(cx, foot_y + ry, z)
		rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(rail)

## Low rounded BUSHES framing the two bottom corners (099): squashed green spheres near the camera
## so the centred dog is framed, not floating on an empty field. Slight size/tone variation per clump
## so they read as foliage, not identical balls. One "BorderBushes" Node3D. Placed well to the sides
## (|x| >= 3.3) and low, so they never occlude the centred dog or its apex silhouette.
func _setup_border_bushes(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		return
	var c := box.get_center()
	var foot_y := box.position.y
	var bushes := Node3D.new()
	bushes.name = "BorderBushes"
	add_child(bushes)
	var dark := Color(0.18, 0.40, 0.17)   # shadowed foliage
	var light := Color(0.30, 0.53, 0.24)  # sunlit foliage
	# 101: [x, z, radius, tone] — clumps flanking the dog a couple of metres back (z ≈ -3), at |x|≈1.8-2.4.
	# The camera's horizontal FOV is narrow, so true foreground-corner bushes (|x|>1.8 up close) fall
	# off-frame; seated at mid-near depth the frustum is wide enough to show them at the left/right, low,
	# framing the dog + the path/house band. Now that the coins shrank (101) they register as the garden
	# border rather than being lost behind loud orbs. Low domes → they never occlude the dog or its apex.
	var specs := [
		[c.x - 1.75, c.z - 2.8, 0.62, 0.15],
		[c.x - 2.2, c.z - 3.6, 0.50, 0.55],
		[c.x + 1.85, c.z - 2.8, 0.60, 0.30],
		[c.x + 2.35, c.z - 3.6, 0.48, 0.60],
	]
	for s in specs:
		var r: float = s[2]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = dark.lerp(light, s[3])
		mat.roughness = 1.0
		mat.metallic = 0.0
		var bush := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		bush.mesh = sm
		bush.material_override = mat
		# Squash to a low dome and seat its bottom on the foot plane.
		bush.scale = Vector3(1.0, 0.62, 1.0)
		bush.position = Vector3(s[0], foot_y + r * 0.62, s[1])
		bush.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bushes.add_child(bush)

## Two or three ambient gold COINS on the grass near the dog (099): small BILLBOARD discs (a warm
## radial gold gradient on a camera-facing quad), the same DS gold as the HUD coin, so the garden
## carries the game's currency motif as framing juice. Billboarded because the look-down camera is
## near-horizontal — a flat ground disc would be edge-on and vanish; a billboard reads as a clean
## gold token from any angle. Ambient only — NOT collectible this task. One "GardenCoins" Node3D,
## sat just above the grass beside the dog so it never occludes the dog. GL-Compatibility-safe.
func _setup_ground_coins(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		return
	var c := box.get_center()
	var y := box.position.y + GARDEN_COIN_R + 0.04  # rest the disc just above the grass
	var coins := Node3D.new()
	coins.name = "GardenCoins"
	add_child(coins)
	# 142: two-tone — a gold coin material + a rose accent one, matching the goal art's gold + red/pink
	# scatter. Same billboard/unshaded/alpha setup, only the baked face texture differs.
	var gold_mat := _coin_material(_coin_texture())
	var rose_mat := _coin_material(_coin_texture(DesignSystem.ROSE, DesignSystem.ROSE_DARK))
	# 142: [x, z, accent] — a loose, NON-OVERLAPPING scatter FLANKING the centred dog, two per flank at
	# staggered depths. Measured via an analytic 390×844 projection: the camera sits only ~1.2 m behind
	# the dog, so the narrow portrait FOV only shows |x| < ~0.5 m at this depth — 101's coins at |x|=1.4-1.7
	# were entirely OFF-SCREEN (the PO's zero-gold scan). These sit just outside the dog silhouette
	# (|x|≈0.40-0.46), well separated in z (>=0.35 m apart, never the touching pair the PO caught), low in
	# the grass band, clear of the dog and the BRA button. One rose accent for the goal's two-tone read.
	var spots := [
		[c.x - 0.46, c.z - 0.20, false],
		[c.x - 0.40, c.z - 0.80, false],
		[c.x + 0.46, c.z - 0.55, true],
		[c.x + 0.40, c.z - 1.05, false],
	]
	for sp in spots:
		var coin := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(GARDEN_COIN_R * 2.0, GARDEN_COIN_R * 2.0)
		coin.mesh = quad
		coin.material_override = rose_mat if sp[2] else gold_mat
		coin.position = Vector3(sp[0], y, sp[1])
		coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		coins.add_child(coin)

## 142: the shared billboard material for an ambient garden coin — unshaded (self-even face, not dimmed
## by the grazing sun), alpha-transparent (the round edge IS the rim), camera-billboarded with keep_scale
## true (GL-Compat collapses the billboard edge-on otherwise; smallness comes from GARDEN_COIN_R). Only the
## baked face texture varies (gold vs rose), so the setup lives in one place.
func _coin_material(face: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = face
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

## The ambient coin's texture (099/124): a flat solid gold disc baked to an Image — opaque GOLD
## face, crisp GOLD_DARK rim ring at dist>0.86, hard alpha edge at dist>1.0. No bright blooming
## core, no soft radial falloff (owner directive 2026-07-05: coins must read as small flat gold
## coins, not glowing translucent orbs). Optional subtle upper-left glint stays opaque.
## Headless-safe (baked Image, no shader).
## 142: parametrized by face + rim so the same flat-disc bake yields both the gold coin and the rose
## accent (two-tone scatter). Defaults to the gold pair so existing callers are unchanged.
func _coin_texture(face: Color = DesignSystem.GOLD, rim: Color = DesignSystem.GOLD_DARK) -> ImageTexture:
	var d := 64
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var mid := float(d) * 0.5
	for py in d:
		for px in d:
			var dist := Vector2(float(px) - mid, float(py) - mid).length() / mid  # 0 centre → 1 edge
			var col: Color
			if dist > 1.0:
				col = Color(0, 0, 0, 0)                       # outside the disc — transparent
			elif dist > 0.86:
				col = rim                                     # crisp opaque rim ring
			else:
				# Flat solid face — no soft gradient, no near-white blooming core.
				# Subtle upper-left glint (opaque, not luminous) for a coin-face read.
				var gx := float(px) - mid
				var gy := float(py) - mid
				var glint := clampf((-gx - gy) / (mid * 1.4), 0.0, 1.0)  # upper-left direction
				col = face.lerp(rim.lerp(face, 0.6), glint * 0.18)
				col.a = 1.0
			img.set_pixel(px, py, col)
	return ImageTexture.create_from_image(img)

## Stylized hedge band at the horizon (078/Note-6): the PO found the ground meets the sky at a
## HARD cutout line with no props or depth, so the photoreal dog reads as a floating cutout. A
## wide, low hedge row seated at the far edge of the grass breaks that hard seam and gives the
## world a "there there" — readable mid/background depth. It's a single camera-facing quad with an
## AUTHORED procedural RGBA texture (a bumpy, soft-topped bushy-green silhouette baked once into an
## Image — no flat fill, no bare primitive), placed ahead of the dog toward the horizon. GL-
## Compatibility-safe: one alpha-blended StandardMaterial3D quad, no shader, no Forward+ feature.
func _setup_hedge_band(dog: Node) -> void:
	var box := _dog_bounds(dog)
	if box.size == Vector3.ZERO:
		return
	var c := box.get_center()
	var foot_y := box.position.y
	var band := QuadMesh.new()
	# Wide enough to span the frame at the horizon distance; ~3.2 m tall bushes.
	const HEDGE_WIDTH := 60.0
	const HEDGE_HEIGHT := 3.2
	const HEDGE_DIST := 17.0   # metres ahead of the dog (-Z), just inside the 40 m grass far edge
	band.size = Vector2(HEDGE_WIDTH, HEDGE_HEIGHT)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _hedge_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA   # the baked alpha IS the bumpy top
	# Softly lit so the sun tints the hedge like the rest of the garden (not a flat unshaded band),
	# but no normal map — a distant hedge reads as a stable silhouette.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var hedge := MeshInstance3D.new()
	hedge.name = "HedgeBand"
	hedge.mesh = band
	hedge.material_override = mat
	# Base of the band at the foot plane; the quad centre sits half its height up. Placed ahead
	# toward the horizon so it seats into the grass/sky seam. QuadMesh faces +Z → toward the camera.
	hedge.position = Vector3(c.x, foot_y + HEDGE_HEIGHT * 0.5, c.z - HEDGE_DIST)
	hedge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hedge)

## The hedge's texture (078): an AUTHORED procedural RGBA Image — a bushy-green body with a soft,
## BUMPY top silhouette (per-column height varied by noise, feathered so it doesn't alias) and a
## noise-mottled green so it reads as a stylized hedgerow, not a flat wall. Slightly hazed toward
## the top to sit into the warm sky horizon (atmospheric recession). Baked once at boot into an
## ImageTexture (no shader, headless-safe). This is a genuine generated asset, not a solid fill.
func _hedge_texture() -> ImageTexture:
	var w := 192
	var h := 96
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var body := FastNoiseLite.new()
	body.noise_type = FastNoiseLite.TYPE_SIMPLEX
	body.frequency = 0.05                 # soft clumps of light/dark foliage
	var top := FastNoiseLite.new()
	top.noise_type = FastNoiseLite.TYPE_SIMPLEX
	top.frequency = 0.09                  # gentle undulation of the hedge crown
	var dark := Color(0.09, 0.24, 0.11)   # shadowed foliage
	var light := Color(0.22, 0.43, 0.19)  # sunlit foliage
	var haze := Color(0.85, 0.80, 0.66)   # warm horizon haze the crown fades toward
	var feather := 4.0                    # rows of soft alpha at the crown so it doesn't alias
	for x in w:
		# Per-column crown height: y=0 is the image TOP; a lower top_row = a taller bush here.
		var bump := top.get_noise_1d(float(x)) * 0.5 + 0.5           # 0..1
		var top_row: float = lerpf(0.12, 0.5, bump) * float(h)
		for y in h:
			var vy := float(y)
			var a := clampf((vy - top_row + feather) / feather, 0.0, 1.0)
			var n := body.get_noise_2d(float(x), vy) * 0.5 + 0.5     # 0..1
			var g := dark.lerp(light, n)
			# Haze the upper crown toward the warm sky so the hedge recedes into the horizon.
			var depth := clampf(1.0 - vy / float(h), 0.0, 1.0)       # 1 at the crown, 0 at the base
			g = g.lerp(haze, depth * 0.22)
			img.set_pixel(x, y, Color(g.r, g.g, g.b, a))
	return ImageTexture.create_from_image(img)

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
	# A touch higher than the 047 disc so the larger halo stays clear of the horizon line.
	var sun_pos := Vector3(dog_center.x + 0.8, dog_center.y + 1.6, dog_center.z - 5.0)
	# A radial gradient (062/P2-10 stylization): a bright warm core → a solid golden disc body →
	# a soft transparent halo. This IS the "crisp, deliberate, haloed" sun the PO asked for — the
	# old opaque low-poly sphere read as a hard EGG with no glow in SwiftShader. Baked to an Image
	# (GradientTexture2D), so it renders in EVERY GL path including the local software renderer.
	var grad := Gradient.new()
	# 125: tightened halo (solid→transparent faster) + cooled core away from near-white.
	# Offsets: solid disc body ends at 0.45 (was 0.40) → less halo area; halo gone by 0.72
	# (was 1.0 = full quad edge) → falloff covers ~40% less sky. Core pulled from near-white
	# Color(1.0,0.99,0.90) → warm gold Color(1.0,0.93,0.70) so it reads accent not blown-out.
	grad.offsets = PackedFloat32Array([0.0, 0.30, 0.45, 0.72])
	grad.colors = PackedColorArray([
		Color(1.0, 0.93, 0.70, 1.0),   # warm gold core — not near-white (125 de-bloom)
		Color(1.0, 0.88, 0.50, 1.0),   # golden disc body — solid to here (crisp edge)
		Color(1.0, 0.82, 0.40, 0.45),  # halo begins: alpha already halved (faster fade)
		Color(1.0, 0.78, 0.35, 0.0),   # halo fades fully out at 72% radius, not full edge
	])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)   # centre of the quad
	grad_tex.fill_to = Vector2(0.5, 1.0)     # radius reaches the quad edge
	grad_tex.width = 256
	grad_tex.height = 256
	# A camera-facing quad: always a perfect round disc regardless of the look-down pitch (the
	# low-poly sphere read as an egg). 125: shrunk from 2.4×2.4 → 1.5×1.5 so the soft halo covers
	# ~40% less sky area (halo also fades out at 0.72 radius so the effective wash is far smaller).
	# Solid core (~0.30 of radius) is ~0.45 m, halo edge at 0.72×0.75 m ≈ 0.54 m radius.
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)   # 143: shrunk 1.5 → 1.2 — a soft CONTAINED sun on the brighter blue sky, not a blown white disc
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = grad_tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED   # self-luminous, not lit by the scene
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA      # the radial alpha IS the halo falloff
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED     # always face the camera → round disc
	mat.billboard_keep_scale = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var disc := MeshInstance3D.new()
	disc.name = "SunDisc"
	disc.mesh = quad
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
	# 078/Note-6: a touch wider than the bare footprint disc so the darker core lands fully under
	# the paws and the dog reads planted, not floating (the PO's "appears to float"). Position math
	# (foot plane / centre — the tested contract) is untouched; only the visual disc grows.
	# 101 widened this to 1.55×; 144 (PO father-pass-9): that flat disc, seen from the low ~1.2 m
	# camera, projected across the WHOLE lower frame and — at ~0.5 alpha black — halved the grass
	# beneath it, which is the "dark/muddy/blotchy foreground lawn" the PO measured (the brighter
	# 143 sky/grass made the wash newly obvious). Snug it back to 1.1× so the shadow stays a tight
	# smudge under the paws and the foreground grass reads as bright as the mid-field.
	var diameter := ContactShadow.radius(box) * 2.0 * GARDEN_SHADOW_SPREAD
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
	# 078/Note-6: a darker, more SOLID core (a mid stop holds the shadow together before it falls
	# off) so the dog reads planted at phone size instead of floating — the PO's grounding note.
	# 101: firmer again — the PO's Phase-6 re-review still read the seated dog's grounding as faint.
	# A darker core (0.62 → 0.72) and a stronger mid (0.34 → 0.42), pushed a touch further out (mid stop
	# 0.62 → 0.66), so more of the ellipse holds shadow before the soft rim → the dog reads planted.
	# 144 (PO father-pass-9): concentrate the shadow. 101 held a strong 0.42 alpha all the way out to
	# 66 % radius — a wide dark disc that, projected from the low camera, muddied the foreground lawn.
	# Keep the firm core (grounding intact) but fall off FAST so the disc's outer half — the part that
	# projects into the foreground — is near-transparent: alpha halves by 30 % radius and is gone by 70 %.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.30, 0.70])
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.72),   # centre: a firm dark core under the paws (grounding)
		Color(0.0, 0.0, 0.0, 0.30),   # mid: already faint by 30% radius — fast falloff
		Color(0.0, 0.0, 0.0, 0.0),    # transparent by 70% radius — no wide foreground wash
	])
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
	_camera = cam  # kept so the face-the-camera turn (061/P2-11) aims at its real position

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
	var tinted := CoatTint.apply(dog, _breed.coat_tint())  # per-breed coat recolor (076, BUST-074) — chocolate Lab = tint over the atlas; yellow Lab = identity
	print("[Bra!] dog loaded: %s (%d coat surface(s) forced opaque, %d tinted for breed '%s')" % [path, flattened, tinted, _breed.id])
	return dog

## Bring the dog to life: loop its ambient idle so it isn't a frozen rest pose
## (P1-2). On a sit-capable dog (licensed Labrador) the director also owns the
## build→apex→hold sit (024b); on the CC0 placeholder there is no Sitt clip, so we
## log the gap honestly and stay in idle — never a faked sit (see task 024b).
func _start_dog(dog: Node = null) -> void:
	if dog == null:
		dog = _dog  # re-initialize on the already-loaded dog (test seam: wiring tests call _start_dog() with no arg)
	if dog == null:
		return
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
	# The active breed's temperament drives the loop's cadence + distractibility (075, P3-3): the
	# Labrador's steady focus means slightly fewer feints, its energy sets how quick the offers come.
	# The felt experience stays inside the PO-signed Phase-2 band (small deltas — Labrador energy 1.0).
	# Difficulty stacks on top (081, P4-2/P4-4): effective = breed.feint_chance() × difficulty.feint_scale.
	# Normal is identity — no change to default play (dormancy).
	_loop.feint_chance = _difficulty.scale_feint(_breed.feint_chance())
	_loop.min_gap = _breed.min_gap()
	_loop.max_gap = _breed.max_gap()
	if _force_scratch:
		# Capture seam (071): pin every offer to a scratch feint so the brief scratch is catchable.
		# Overrides the breed's feint chance — the seam must fire every offer.
		_loop.feint_chance = 1.0
		_loop.scratch_feint_chance = 1.0
	if _director.has_trick(_current_trick):
		# Trick-capable dog (licensed Labrador, 025): the loop offers the current trick on a VARYING
		# gap (P2-8, no metronome) and sometimes feints; each real offer's apex (the score's PERFECT
		# instant) is the single source the tell is built from in _begin_sit. _process advances the clock.
		if _current_trick == TRICK_ID_SITT:
			print("[Bra!] dog can Sitt — varying the offer cadence %.1f–%.1fs, sometimes feinting (real apex from the licensed Labrador)"
				% [SitLoop.MIN_INTER_SIT_GAP, SitLoop.MAX_INTER_SIT_GAP])
		else:
			print("[Bra!] dog can perform '%s' — varying the offer cadence %.1f–%.1fs, sometimes feinting (real apex from the licensed Labrador)"
				% [_current_trick, SitLoop.MIN_INTER_SIT_GAP, SitLoop.MAX_INTER_SIT_GAP])
	else:
		# CC0 dev fallback: no sit, so the loop parks in idle and every BRA tap is DEAD
		# (does nothing, no penalty — P1-5). The button still works; it lights up the
		# moment the licensed Sitt ships (024b / ADR-0006 / 025).
		print("[Bra!] dog has no Sitt clip (CC0 dev fallback) — idle only; "
			+ "real Sitt ships with the licensed Labrador, see task 024b / ADR-0006")

## One big, thumb-friendly BRA button anchored across the bottom of the portrait
## frame (P1-5) — the single verb. It fires on release (Button's default
## ACTION_MODE_BUTTON_RELEASE = pointerup, P1-7), never a frame early.
## Garden (047/P2-10): the button floats over the grass with a subtle circular
## hit-target backdrop (073/PO note 5): a semi-transparent rounded pill so the
## shrinking trainer ring reads "press this circle" rather than "trace this path."
## The ring (TrainerRingMarker) has mouse_filter=IGNORE so every tap on or inside
## the ring lands on the button — never requires a drag/swipe.
func _setup_bra_button() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var bra := Button.new()
	bra.name = "BraButton"
	bra.text = "BRA"
	# Design-system blue button (097, Phase 6): chunky BLUE pill with a BLUE_DARK bottom-lip
	# for the 3D-pressable depth, white Baloo 2 display text, and a card drop-shadow so it
	# lifts off the grass. Replaces the translucent-white pill (073/P2-10). Tap→score logic
	# is unchanged — only the visual style is updated here.
	# 178 (X-6): the BRA hero uses the dedicated ExtraBold (wght 800) face at the bumped
	# T_DISPLAY (74) so the one hero tap reads chunky/oversized against the goal art — the
	# shared wght-600 font_display() (menu/coin/kennel/showcase) is untouched.
	bra.add_theme_font_override("font", DesignSystem.font_display_black())
	bra.add_theme_font_size_override("font_size", DesignSystem.T_DISPLAY)
	bra.add_theme_color_override("font_color",         DesignSystem.PAPER)
	bra.add_theme_color_override("font_pressed_color", DesignSystem.PAPER)
	bra.add_theme_color_override("font_hover_color",   DesignSystem.PAPER)
	# 126 (PO Phase-10, Improvement #1): the goal art's BRA button is a DEEP glossy raised pill —
	# a vertical gradient (bright top → deep bottom) over a distinct darker-blue 3D lower lip, with a
	# real drop shadow lifting it off the grass. A StyleBoxFlat can carry only one border colour, so it
	# cannot express the light-top→dark-bottom gradient; the honest match is a baked rounded-rect
	# gradient texture (BRA button only — DesignSystem.BLUE / .pill() stay untouched so the signed-off
	# completion-menu / kennel pills that consume the shared token don't move).
	var normal_style := _make_bra_pill_stylebox()
	# Pressed state: a flat BLUE_DARK pill (matching corner radius) so the button reads "pushed in".
	var pressed_style := DesignSystem.pill(DesignSystem.BLUE_DARK, BRA_PILL_RADIUS)
	# Hover: same as normal on touch devices (hover = finger hovering, not meaningful);
	# keep it identical so the style doesn't flash on desktop testing.
	var empty := StyleBoxEmpty.new()
	bra.add_theme_stylebox_override("normal",   normal_style)
	bra.add_theme_stylebox_override("hover",    normal_style)
	bra.add_theme_stylebox_override("pressed",  pressed_style)
	bra.add_theme_stylebox_override("disabled", normal_style)  # modulate dims it via BRA_LOCKED_ALPHA
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
	_setup_trainer_marker(ui)
	_setup_readout(ui)
	_setup_word_pop(ui)
	_setup_learned_bar(ui)
	_setup_coin_readout(ui)
	_setup_trick_menu(ui)
	_setup_feedback_form(ui)
	_setup_breed_showcase(ui)
	_setup_kennel_screen(ui)
	# Apply the Phase-6 design-system theme so all Control descendants (including the BRA
	# Button, learned bar, coin readout) render in the real bundled fonts (Nunito/Baloo 2).
	# CanvasLayer itself cannot hold a theme (not a Control), so we set it on the BRA Button
	# — the root Control on this layer (096, Phase 6).
	_bra_button.theme = DesignSystem.theme()

# --- BRA button raised-pill bake (126, PO Phase-10 Improvement #1) ------------------------------
## The button's content rect in design px (VIEWPORT_W 720 − 2·48 wide; the BRA band height), plus a
## transparent pad on every side into which the drop shadow bleeds. The whole canvas scales uniformly
## under the `expand` stretch, so a design-resolution bake scales to any screen without corner
## distortion — the StyleBoxTexture's expand_margins map the pad 1:1 back outside the layout rect.
const BRA_PILL_PAD := 56                                                          ## shadow/AA bleed
const BRA_PILL_RADIUS := 46.0                                                     ## rounded-pill corner
## Face gradient — the SAME palette as the completion-menu primary CTA (153): sourced from the
## DS tokens so the two dominant blue actions stay ONE component and the WCAG-AA fix can never
## drift between them (deepened so the white «BRA» label clears AA; see DesignSystem.GRAD_PILL_*).
const BRA_PILL_TOP  := DesignSystem.GRAD_PILL_TOP   ## top sheen (white ≈ 4.9:1, AA)
const BRA_PILL_BOT  := DesignSystem.GRAD_PILL_BOT   ## deep bottom
const BRA_PILL_LIP  := DesignSystem.GRAD_PILL_LIP   ## darker 3D lower lip
const BRA_PILL_LIP_H := 14.0                          ## height of the lip band
const BRA_PILL_SHADOW_DY := 14.0                      ## how far the shadow drops below the pill
const BRA_PILL_SHADOW_BLUR := 30.0                    ## shadow softness (px)
const BRA_PILL_SHADOW_MAX := 0.30                     ## shadow peak alpha over grass

## Bake the BRA button's normal StyleBox via the shared DesignSystem gradient-pill baker (130):
## a rounded-rect vertical-gradient face (bright top → deep bottom) with a darker lower lip and a
## soft drop shadow baked into the transparent pad, wrapped in a StyleBoxTexture whose
## expand_margins push the shadow outside the button's layout rect (126). The menu primary CTA
## reuses the SAME baker + the same GRAD_PILL_* palette so both dominant actions match.
func _make_bra_pill_stylebox() -> StyleBoxTexture:
	# Content size derived from the button's own offsets (VIEWPORT_W − 2·48 wide; the BRA band tall),
	# so the bake tracks the layout instead of drifting from a hard-coded literal.
	var cw := int(VIEWPORT_W - BRA_OFFSET_LEFT + BRA_OFFSET_RIGHT)   ## 624
	var ch := int(BRA_OFFSET_BOTTOM - BRA_OFFSET_TOP)                ## 192
	return DesignSystem.gradient_pill(cw, ch, BRA_PILL_RADIUS,
		BRA_PILL_TOP, BRA_PILL_BOT, BRA_PILL_LIP, BRA_PILL_PAD,
		BRA_PILL_LIP_H, BRA_PILL_SHADOW_DY, BRA_PILL_SHADOW_BLUR, BRA_PILL_SHADOW_MAX)

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

## The approach-cue trainer ring (058/P2-9), centred over the BRA button — same anchor
## math as the tell marker so both rings are concentric on the verb. Added AFTER the tell
## marker so it composites on top (later sibling = drawn last). Mouse-transparent so it
## passes every touch straight through to the button (P1-5, via TrainerRingMarker._init).
## Starts dark; _process drives it from the trainer ring during a real sit only.
func _setup_trainer_marker(ui: CanvasLayer) -> void:
	var marker := TrainerRingMarker.new()
	marker.name = "TrainerRingMarker"
	# Seated ABOVE the BRA button, not concentric with it (owner directive 2026-07-05, task 123).
	# The 320×320 square is centred on RING_CENTER_Y (-580), which sits far enough above the
	# button that the fully-expanded ring bottom (-320.8) clears the button top (-280) by ~41 px.
	# Horizontal anchoring is identical to the tell marker (centred on the viewport width).
	marker.anchor_left = 0.5
	marker.anchor_right = 0.5
	marker.anchor_top = 1.0
	marker.anchor_bottom = 1.0
	marker.offset_left = -TELL_HALF_WIDTH
	marker.offset_right = TELL_HALF_WIDTH
	marker.offset_top = RING_OFFSET_TOP
	marker.offset_bottom = RING_OFFSET_BOTTOM
	ui.add_child(marker)
	_trainer_marker = marker

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

## The marker-word burst (094, P5-3): a wide band anchored to the bottom, just above the BRA
## button, so the fired word floats up into the clear lower-middle sky on a successful mark.
## Mouse-transparent (set in WordPop._init). Starts blank; driven by _play_payoff (pop) +
## _process (advance/fade). Feed the same reduced-motion factor the tell uses.
func _setup_word_pop(ui: CanvasLayer) -> void:
	var wp := WordPop.new()
	wp.name = "WordPop"
	# Anchored to the bottom edge, centered, in a band above the BRA button.
	wp.anchor_left = 0.0
	wp.anchor_right = 1.0
	wp.anchor_top = 1.0
	wp.anchor_bottom = 1.0
	wp.offset_left = WORD_POP_MARGIN_X
	wp.offset_right = -WORD_POP_MARGIN_X
	wp.offset_top = WORD_POP_OFFSET_TOP
	wp.offset_bottom = WORD_POP_OFFSET_BOTTOM
	ui.add_child(wp)
	wp.set_motion_scale(_motion_scale)
	_word_pop = wp

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
	# Seed the trick name (097 Phase 6): bar now shows label + percentage above the track.
	_learned_bar.set_trick(_current_trick, LEARNED_BAR_LABEL_ROW, LEARNED_BAR_LABEL_GAP)
	_learned_bar.set_value(_progress.value, _progress.mastered)

## The coin readout (068/P3-D3): a small balance label in the top-right corner. Shows the coins the
## player has earned toward adopting a breed; updated whenever a trick is mastered. Mouse-transparent
## so it never eats a tap (P1-5). A dark outline keeps it legible over both bright sky and grass. The
## initial text reflects the balance already restored on boot by _load_coins (a returning player sees
## their coins immediately).
func _setup_coin_readout(ui: CanvasLayer) -> void:
	var readout := CoinReadout.new()
	readout.name = "CoinReadout"
	readout.anchor_left = 1.0
	readout.anchor_right = 1.0
	readout.anchor_top = 0.0
	readout.anchor_bottom = 0.0
	readout.offset_left = -COIN_READOUT_MARGIN - COIN_READOUT_WIDTH
	readout.offset_right = -COIN_READOUT_MARGIN
	readout.offset_top = COIN_READOUT_TOP  # its own top line, clear of the top-left Tricks button (072)
	readout.offset_bottom = COIN_READOUT_TOP + CoinReadout.HEIGHT
	ui.add_child(readout)
	_coin_readout = readout
	_refresh_coins()  # seed with the balance restored on boot (_load_coins)

## The completion menu (072, PO note 1): a modal, mounted HIDDEN over the whole HUD, that pops up when
## the active trick is mastered (and reopens from the Tricks button). Full-screen so its dimmed backdrop
## veils the game and it eats every tap behind it. `trick_chosen` routes into select_trick(); `dismissed`
## just hides it. A small persistent "Tricks" button in the top-left reopens it between rounds so a
## returning player (all mastered) or one who wants to switch is never stuck waiting for a mastery.
func _setup_trick_menu(ui: CanvasLayer) -> void:
	var menu := TrickMenu.new()
	menu.name = "TrickMenu"
	menu.anchor_right = 1.0
	menu.anchor_bottom = 1.0  # full-screen: the backdrop veils the game, the modal eats taps behind it
	menu.hide()               # starts hidden — pops on mastery / the Tricks button
	ui.add_child(menu)
	_menu = menu
	_menu.trick_chosen.connect(_on_trick_chosen)
	_menu.dismissed.connect(_on_menu_dismissed)
	_menu.breed_chosen.connect(_on_breed_chosen)       # switch to an owned breed (079/P3-4)
	_menu.breed_adopt.connect(_on_breed_adopt)         # spend coins to adopt a breed (079/P3-D3)
	_menu.feedback_requested.connect(_on_feedback_requested)  # open the feedback form (085, X-8)
	_menu.showcase_requested.connect(_on_showcase_requested)  # open the spotlit breed showcase (087, P3-4)
	_menu.word_chosen.connect(_on_word_chosen)         # swap the active marker word (092/P5-4)
	_menu.difficulty_chosen.connect(_on_difficulty_chosen)  # set the global difficulty mode (118/P4-1)

	var btn := Button.new()
	btn.name = "TricksButton"
	btn.text = "Triks"
	# Design-system white pill (097, Phase 6): PAPER background with card shadow + a BLUE_INK
	# Baloo 2 bold label (176: was SLATE, too faint). Matches the goal-screen top-left pill.
	# 100 (Phase 6): a DRAWN hamburger glyph (baked HUD_NAV_INK bars, never a "☰" font string
	# → no tofu, lesson from 089)
	# rides the button's native icon slot, left of the label, signalling "menu" like the goal.
	btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	btn.add_theme_font_size_override("font_size", DesignSystem.T_HEAD)
	btn.add_theme_color_override("font_color",         HUD_NAV_INK)  # 200: NAV_INK deep-blue-slate
	btn.add_theme_color_override("font_pressed_color", HUD_NAV_INK)
	btn.add_theme_color_override("font_hover_color",   HUD_NAV_INK)
	# 200: same-ink outline thickens the thin strokes so the dark ink clears AA in the real render.
	btn.add_theme_constant_override("outline_size", HUD_NAV_LABEL_OUTLINE)
	btn.add_theme_color_override("font_outline_color", HUD_NAV_INK)
	btn.icon = _hamburger_texture()
	btn.add_theme_constant_override("h_separation", TRICKS_GLYPH_GAP)  # space the glyph off the label
	# 100: near-opaque PAPER fill (unchanged) + a STRONGER-than-default drop shadow so the pale
	# pill lifts off the bright sun band (the PO's "washes out faint" note). panel()'s default card
	# shadow (alpha .08) is too subtle over the bright sky, so deepen it just for the top HUD pills.
	var tricks_normal := DesignSystem.panel(DesignSystem.PAPER, DesignSystem.R_PILL)
	tricks_normal.shadow_color = HUD_PILL_SHADOW
	var tricks_pressed := DesignSystem.panel(DesignSystem.CREAM, DesignSystem.R_PILL)
	tricks_pressed.shadow_color = HUD_PILL_SHADOW
	var tricks_empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal",   tricks_normal)
	btn.add_theme_stylebox_override("hover",    tricks_normal)
	btn.add_theme_stylebox_override("pressed",  tricks_pressed)
	btn.add_theme_stylebox_override("disabled", tricks_normal)
	btn.add_theme_stylebox_override("focus",    tricks_empty)
	btn.anchor_left = 0.0
	btn.anchor_right = 0.0
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = TRICKS_BTN_MARGIN
	btn.offset_top = TRICKS_BTN_TOP
	btn.offset_right = TRICKS_BTN_MARGIN + TRICKS_BTN_WIDTH
	btn.offset_bottom = TRICKS_BTN_TOP + TRICKS_BTN_HEIGHT
	btn.focus_mode = Control.FOCUS_NONE  # no keyboard focus ring on a touch target
	ui.add_child(btn)
	btn.pressed.connect(_open_trick_menu)
	_tricks_button = btn
	_publish_current_trick()  # seed the web e2e hook with the initial trick (072, kept from 066)
	_publish_menu_open()      # seed __bra_menu_open = false so a capture polls a defined value (072)
	_publish_roster()         # seed the active breed + owned roster + balance for the 079 capture

## The Triks pill's hamburger menu glyph (100): three short HUD_NAV_INK bars baked into an RGBA Image
## (never a "☰" font string — that risks tofu on the fallback font, per 089). Used as the button's
## native icon so it sits left of the "Triks" label. Headless-safe (baked Image, no shader).
func _hamburger_texture() -> ImageTexture:
	var w := HAMBURGER_BAR_W + 4
	var h := HAMBURGER_BAR_H * 3 + HAMBURGER_BAR_GAP * 2 + 4
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var x0 := 2
	var y := 2
	for _bar in 3:
		for yy in range(y, y + HAMBURGER_BAR_H):
			for xx in range(x0, x0 + HAMBURGER_BAR_W):
				img.set_pixel(xx, yy, HUD_NAV_INK)  # 176: BLUE_INK, matches the pill label
		y += HAMBURGER_BAR_H + HAMBURGER_BAR_GAP
	return ImageTexture.create_from_image(img)

## Mount the feedback form modal (085, X-8) above the trick menu on the same CanvasLayer. Hidden until
## _on_feedback_requested opens it. Signal routing: submitted → _on_feedback_submitted (→ _telem);
## cancelled → hide. Rating is shown sparingly — only after the active trick is mastered (milestone).
func _setup_feedback_form(ui: CanvasLayer) -> void:
	var form := FeedbackFormView.new()
	form.name = "FeedbackForm"
	form.anchor_right = 1.0
	form.anchor_bottom = 1.0
	form.hide()
	ui.add_child(form)
	_feedback = form
	_feedback.submitted.connect(_on_feedback_submitted)
	_feedback.cancelled.connect(func(): _feedback.hide())

## Mount the spotlit breed showcase (087, P3-4) above the menu, hidden until _on_showcase_requested.
## It does NOT dim the scene (its centre is clear) so the brightened live dog shows through. Signals:
## prev/next/focus move the spotlight (main re-tints the live rig to preview), commit switches+persists,
## dismissed closes without switching.
func _setup_breed_showcase(ui: CanvasLayer) -> void:
	var view := BreedShowcaseView.new()
	view.name = "BreedShowcase"
	view.anchor_right = 1.0
	view.anchor_bottom = 1.0
	view.hide()
	ui.add_child(view)
	_showcase = view
	_showcase.prev_requested.connect(func(): _showcase_move(_showcase_model.prev()))
	_showcase.next_requested.connect(func(): _showcase_move(_showcase_model.next()))
	_showcase.focus_requested.connect(_on_showcase_focus)
	_showcase.commit_requested.connect(_on_showcase_commit)
	_showcase.dismissed.connect(_on_showcase_dismissed)

## The "Vis frem hundene" row in TrickMenu was tapped (087): open the spotlit showcase. Hide the menu
## panel (so the dog is unobstructed), point the model at the owned roster (active breed spotlit first),
## brighten the stage, render, and show. `_menu_open` stays true so offers keep paused behind it.
func _on_showcase_requested() -> void:
	if _showcase == null:
		return
	_showcase_model.set_roster(_roster.owned, _roster.active)
	if _menu != null:
		_menu.hide()  # the showcase replaces the menu surface; the menu re-shows on Tilbake
	_set_training_hud_visible(false)  # the showcase centre is transparent — hide the chrome that would ghost through (090)
	_brighten_stage(true)
	# Pose the spotlit dog as a composed, centred, camera-facing portrait (172, PO father-pass-37):
	# stop the roam, recentre it to the patch centre, and turn to face the player — so the hero holds
	# still and reads as "shown off", not caught mid-stride or half out of frame. _close_showcase undoes
	# all three (resume the roam, release the facing) on both the commit and dismiss paths.
	_pause_wander()
	if _wander != null:
		_wander.recenter()
		if _dog != null:
			_dog.transform = _wander_base()  # snap to the recentred base so the facing computes from centre
	_engage_face_for_showcase()
	_render_showcase()
	_showcase.show()
	_publish_showcase()

## Move the spotlight to `id` (from prev/next/focus): re-tint the LIVE rig to that breed's coat so what
## the player sees IS the real coat — WITHOUT touching the roster or persisting (preview only). Then
## re-render the chrome + publish the capture hook.
func _showcase_move(id: String) -> void:
	if id == "":
		return
	if _dog != null:
		# Preview the spotlit breed's coat (not persisted) — but the ACTIVE entry restores the coat of the
		# dog actually trained, so cycling back to it never repaints a trained kennel dog (174: e.g. moving
		# back to the active «labrador» pip while training grey Nova must stay grey, not flip to cream Lab).
		var tint := _active_coat_tint() if id == _roster.active else BreedPersonality.by_id(id).coat_tint()
		CoatTint.apply(_dog, tint)
	_render_showcase()
	_publish_showcase()

func _on_showcase_focus(id: String) -> void:
	_showcase_model.focus(id)
	_showcase_move(_showcase_model.spotlit_id())

## Commit the spotlit breed (087): make it the active dog through the SAME switch+persist path a menu
## switch uses (_on_breed_chosen re-tints, re-applies levers, persists, closes the menu). Then close the
## showcase + restore the stage lighting, so training resumes as the newly-chosen dog.
func _on_showcase_commit() -> void:
	var id := _showcase_model.spotlit_id()
	_close_showcase()
	if id != "":
		_on_breed_chosen(id)  # switch active + persist; also closes the (hidden) menu + resumes offers

## Back out of the showcase without switching (087): re-tint the live rig back to the actually-active
## breed (undo any preview), close the showcase + restore lighting, and re-show the trick menu the
## player came from (offers stay paused until they dismiss the menu).
func _on_showcase_dismissed() -> void:
	if _dog != null:
		CoatTint.apply(_dog, _active_coat_tint())  # restore the actually-trained dog's coat (kennel or breed), undo any preview (174)
	_close_showcase()
	if _menu != null and _menu_open:
		_menu.show()

## Build the owned-breed entries [{id,name,tint}] (owned only — the showcase shows dogs you have) and
## hand them + the spotlit/active ids to the dumb view.
func _render_showcase() -> void:
	if _showcase == null:
		return
	var entries: Array = []
	for id in _roster.owned:
		var bp := BreedPersonality.by_id(id)
		# Name the dog the player is actually SHOWING OFF: the active entry borrows the active kennel
		# individual's name+breed («Nova» / «Border collie») when the kennel is driving training, else the
		# 173 breed→individual bridge («Bella» / «Labrador»), breed demoted to a subtitle (174, pass-39 X-4).
		var d := KennelDog.showoff_name(id, bp.display_name, id == _roster.active, _active_from_kennel, _kennel_roster.active)
		# 175: the ACTIVE entry's swatch borrows the active kennel dog's coat (grey Nova / cream Bella) so the
		# chip matches the name+breed+3D coat — every other entry keeps its own breed swatch (PO father-pass-40).
		var tint := KennelDog.showoff_swatch(bp.swatch_color(), id == _roster.active, _active_from_kennel, _kennel_roster.active)
		entries.append({"id": id, "name": d.name, "subtitle": d.subtitle, "tint": tint})
	_showcase.render(entries, _showcase_model.spotlit_id(), _roster.active)

## Hide the showcase view and restore the garden lighting (shared by commit + dismiss).
func _close_showcase() -> void:
	if _showcase != null:
		_showcase.hide()
	_set_training_hud_visible(true)  # restore the training chrome hidden on open (090)
	_brighten_stage(false)
	_release_face()   # ease the camera-facing pose back to the roam heading (172, mirrors the sit-end release)
	_resume_wander()  # hand the dog back to roaming its patch (172) — behind the menu / into resumed training
	_publish_showcase()

# ---------------------------------------------------------------------------
# Kennel grid screen (105, Phase 8 K-1/K-3 — anchor visual slice)
# ---------------------------------------------------------------------------

## Mount the kennel screen on the CanvasLayer, hidden. Also mounts the top-area
## «Kennel» pill button that opens it, positioned to the right of _tricks_button.
## Called from _setup_bra_button near the other modal setups.
func _setup_kennel_screen(ui: CanvasLayer) -> void:
	# The dumb kennel renderer — full-screen, hidden until _open_kennel().
	var ks := KennelScreen.new()
	ks.name = "KennelScreen"
	ks.anchor_right  = 1.0
	ks.anchor_bottom = 1.0
	ks.hide()
	ui.add_child(ks)
	_kennel = ks
	_kennel.closed.connect(_close_kennel)
	_kennel.dog_selected.connect(_on_kennel_dog_selected)
	_kennel.adopt_requested.connect(_on_kennel_adopt)  # K-4 adopt wiring (109)
	_kennel.train_with_requested.connect(_on_kennel_train_with)  # K-5 switch-active wiring (110)

	# The Kennel pill button: mirrors the Triks button on the top-left but sits to its right.
	# Using the same HUD-pill style as _tricks_button (097/100, Phase 6).
	var btn := Button.new()
	btn.name = "KennelButton"
	btn.text = "Kennel"
	btn.add_theme_font_override("font", DesignSystem.font_body_bold())
	btn.add_theme_font_size_override("font_size", DesignSystem.T_HEAD)
	btn.add_theme_color_override("font_color",         HUD_NAV_INK)  # 200: NAV_INK deep-blue-slate
	btn.add_theme_color_override("font_pressed_color", HUD_NAV_INK)
	btn.add_theme_color_override("font_hover_color",   HUD_NAV_INK)
	# 200: same-ink outline thickens the thin strokes so the dark ink clears AA in the real render.
	btn.add_theme_constant_override("outline_size", HUD_NAV_LABEL_OUTLINE)
	btn.add_theme_color_override("font_outline_color", HUD_NAV_INK)
	var k_normal := DesignSystem.panel(DesignSystem.PAPER, DesignSystem.R_PILL)
	k_normal.shadow_color = HUD_PILL_SHADOW
	var k_pressed := DesignSystem.panel(DesignSystem.CREAM, DesignSystem.R_PILL)
	k_pressed.shadow_color = HUD_PILL_SHADOW
	btn.add_theme_stylebox_override("normal",   k_normal)
	btn.add_theme_stylebox_override("hover",    k_normal)
	btn.add_theme_stylebox_override("pressed",  k_pressed)
	btn.add_theme_stylebox_override("disabled", k_normal)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	# Position: same top row as Triks, directly to its right.
	btn.anchor_left = 0.0
	btn.anchor_right = 0.0
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left   = TRICKS_BTN_MARGIN + TRICKS_BTN_WIDTH + 8.0
	btn.offset_top    = TRICKS_BTN_TOP
	btn.offset_right  = TRICKS_BTN_MARGIN + TRICKS_BTN_WIDTH + 8.0 + KENNEL_BTN_WIDTH
	btn.offset_bottom = TRICKS_BTN_TOP + TRICKS_BTN_HEIGHT
	btn.focus_mode = Control.FOCUS_NONE
	ui.add_child(btn)
	btn.pressed.connect(_open_kennel)
	_kennel_button = btn
	_publish_kennel_btn()  # seed the capture hook for the Visual-Review script

## Open the kennel: build rows from the current economy state, render, hide the training
## HUD (task-090 pattern so the chrome doesn't ghost through the opaque kennel surface),
## and show. The coin chip is seeded with the live balance — it stays static this slice
## (balance only changes through training mastery which is paused while the kennel is open).
func _open_kennel() -> void:
	if _kennel == null:
		return
	var rows := KennelDog.classify_kennel_dogs(_kennel_owned(), _kennel_active(), _purse.balance)
	_kennel.render(rows, _purse.balance)
	_set_training_hud_visible(false)
	_kennel.show()

## Close the kennel and restore the training HUD. Called from the closed signal and from
## the wiring test via _close_kennel().
func _close_kennel() -> void:
	if _kennel != null:
		_kennel.hide()
	_set_training_hud_visible(true)

## Web-only e2e/capture hook (105): publish the Kennel button centre (viewport px) so the
## Visual-Review capture script can land a REAL tap on it. Mirrors _publish_showcase().
func _publish_kennel_btn() -> void:
	if not OS.has_feature("web") or _kennel_button == null:
		return
	var c := _kennel_button.get_global_rect().get_center()
	JavaScriptBridge.eval("window.__bra_kennel_btn = {x: %s, y: %s};" % [c.x, c.y], true)

## Web-only capture/e2e hook (110, K-5/K-7): mirror the active kennel dog id onto window.* so a LIVE
## browser capture can deterministically prove the switch — «Tren med Nova» flips it and a reload
## restores it. Mirrors __bra_active_breed; a no-op off the web export, never read back in play.
func _publish_kennel_active() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__bra_kennel_active = '%s';" % _kennel_roster.active, true)
	JavaScriptBridge.eval("window.__bra_kennel_owned = %s;" % JSON.stringify(_kennel_roster.owned), true)

## dog_selected(id) from the kennel grid — opens the K-2 inspect modal for that dog.
## No economy/roster/save mutation: inspect only (K-4 adopt wiring lands in the next task).
func _on_kennel_dog_selected(id: String) -> void:
	_kennel.open_detail(id)

## The set of dog ids the player currently owns, in kennel terms.
## The set of owned kennel-dog ids — reads the persisted KennelRoster (109, Phase 8 K-7).
## Replaces the STARTER-only stub from the browse-only 105 slice.
func _kennel_owned() -> Array:
	return _kennel_roster.owned

## The active kennel-dog id — reads the persisted KennelRoster (109, Phase 8 K-7).
## Replaces the STARTER-only stub from the browse-only 105 slice.
func _kennel_active() -> String:
	return _kennel_roster.active

## Show/hide the training-HUD chrome as a unit (090, PO 2026-07-03 Bugfix 2). The trick menu is an opaque
## panel that covers this chrome, but the breed showcase keeps its centre transparent so the spotlit dog
## shows through — the always-on BRA button (plus its concentric ring markers, the coin readout, learned
## bar, tier readout, and Tricks reopen button) would otherwise ghost through that clear centre. None of
## these nodes self-set `.visible` (their _process/event drivers touch only `.disabled`/`.modulate`/
## `.text`), so toggling visibility here is safe + sticky. Null-guarded — a no-op before the HUD is built.
func _set_training_hud_visible(v: bool) -> void:
	for n in [_bra_button, _tell_marker, _trainer_marker, _readout, _word_pop, _learned_bar, _coin_readout, _tricks_button, _kennel_button]:
		if n != null:
			(n as CanvasItem).visible = v

## Brighten (on) / restore (off) the 3D stage so the showcased dog is spotlit, not buried in the garden
## shadow (P3-4 / PO-Improvement-2). Raises the DirectionalLight3D key energy and adds a viewer-side fill
## OmniLight (a light from the camera, so the visible side of the dog always pops); off restores the
## saved key energy exactly and frees the fill. Guarded so it is a no-op if the scene has no Sun/camera.
func _brighten_stage(on: bool) -> void:
	var sun := get_node_or_null("Sun") as DirectionalLight3D
	if on:
		if sun != null:
			if _sun_base_energy < 0.0:
				_sun_base_energy = sun.light_energy
			sun.light_energy = _sun_base_energy * SHOWCASE_LIGHT_BOOST
		if _showcase_fill == null and _camera != null:
			var fill := OmniLight3D.new()
			fill.name = "ShowcaseFill"
			fill.light_energy = SHOWCASE_FILL_ENERGY
			fill.omni_range = SHOWCASE_FILL_RANGE
			add_child(fill)
			fill.global_position = _camera.global_position  # light from the viewer — lights the seen side
			_showcase_fill = fill
	else:
		if sun != null and _sun_base_energy >= 0.0:
			sun.light_energy = _sun_base_energy
		if _showcase_fill != null:
			_showcase_fill.queue_free()
			_showcase_fill = null

## Web-only e2e/capture hook (087): mirror the showcase open-state + spotlit breed onto window.* so a
## live browser capture can wait for the showcase and prove the previewed breed re-tinted the live dog.
## Mirrors __bra_menu_open / __bra_current_trick; a no-op off the web export, never read back in play.
func _publish_showcase() -> void:
	if OS.has_feature("web"):
		var open := _showcase != null and _showcase.visible
		JavaScriptBridge.eval("window.__bra_showcase_open = %s; window.__bra_showcase_spotlit = '%s';"
			% [("true" if open else "false"), _showcase_model.spotlit_id()], true)

## The "Give feedback" row in TrickMenu was tapped (085, X-8): configure the form with the current
## game context and show it. Rating is shown when the active trick is mastered (one milestone per
## session — avoids fatigue per ADR-0007).
func _on_feedback_requested() -> void:
	if _feedback == null:
		return
	_feedback.configure(
		{"trick": _current_trick, "menu_open": _menu_open},
		_progress.mastered  # show rating only on mastery milestone (sparse — ADR-0007)
	)
	_feedback.show()

## The player submitted feedback (085, X-8): route through _telem (the ONE choke-point — grep
## confirms no other PostHog path). The form already hid itself; the trick menu stays as-is.
func _on_feedback_submitted(payload: Dictionary) -> void:
	_telem("feedback_submitted", payload)

## The trick ids the ACTIVE kennel breed may train (K-8) — the active dog's OWN list, not a global
## const, so which dog is active decides what can be trained. KennelDog.by_id resolves an empty/legacy/
## breed id to a real dog (the starter's core), so this always yields a valid list on any save. Today
## every dog shares core_tricks() == KNOWN_TRICKS, so the menu is unchanged; the list grows per breed
## the moment an owner signature clip lands (owner-gated divergence stays under the P3-2 flag).
func _active_trick_ids() -> Array:
	return KennelDog.by_id(_kennel_roster.active).trick_ids

## The tricks the loaded dog can actually perform, restricted to the ACTIVE breed's list, in that
## list's order (065/067/K-8). The menu offers exactly these as Available/Learned — never a trick the
## dog can't perform (the never-fake gate): on the CC0 placeholder this is empty, on the licensed
## Labrador it is the active breed's core (Sitt + Ligg + Legg deg).
func _selectable_tricks() -> Array:
	if _director == null:
		return []
	return _performable(_active_trick_ids(), _director)

## Pure: keep only the `wanted` ids the loaded rig can actually perform, preserving `wanted` order —
## never offers a trick the dog can't do (the never-fake gate). Static so it unit-tests without a scene.
static func _performable(wanted: Array, director) -> Array:
	var out: Array = []
	for id in wanted:
		if director != null and director.has_trick(id):
			out.append(id)
	return out

## Build the completion-menu rows: the wired tricks (Learned/Available by their own mastery) followed
## by the genuinely-absent roadmap tricks (always Locked). Order is stable so the collection reads the
## same every open. The classify split itself is the pure, unit-locked honesty gate.
func _menu_rows() -> Array:
	var all_ids: Array = []
	all_ids.append_array(KNOWN_TRICKS)
	# Progressive disclosure (127): tease just the NEXT roadmap trick, not all three future systems.
	all_ids.append_array(MenuReveal.teased_locked(ROADMAP_LOCKED_TRICKS))
	var mastered := {}
	for id in KNOWN_TRICKS:
		var p: TrickProgress = _progress_by_trick.get(id)
		mastered[id] = p != null and p.mastered
	# Mark the trick we're training now (152, X-6) so the selector shows an ACTIVE state like its
	# breed/word siblings + the kennel — instead of the current trick reading as an anonymous row.
	return TrickMenu.classify(all_ids, _selectable_tricks(), mastered, ROADMAP_LOCKED_TRICKS, _current_trick)

## Feed the current trick rows + breed rows + word rows + coin balance into the menu (called just before it shows).
func _refresh_trick_menu() -> void:
	if _menu != null:
		_menu.set_rows(_menu_rows(), _purse.balance)
		# Progressive disclosure (127, PO Phase-10 Menu #2): feed a section only once the player has
		# earned their way to it — otherwise feed [] and the dumb renderer collapses it to zero height
		# (the showcase row hides with empty breeds too). One new beat lands per mastery, never a dump.
		var mastered_count := _count_mastered_tricks()
		var breeds := _breed_rows() if MenuReveal.reveal_breeds(_purse.balance, _roster.owned.size(), BREED_ADOPT_COST) else []
		_menu.set_breeds(breeds)         # the adopt/select breeds section (079) — revealed when adoption is meaningful
		_menu.set_words(_word_rows() if MenuReveal.reveal_words(_unlocked_alt_word_count()) else [])  # marker words (092) — once the first alt word unlocks
		_menu.set_difficulty(_difficulty_rows() if MenuReveal.reveal_difficulty(mastered_count) else [])  # difficulty (118) — once the loop is understood
		_publish_breed_rows()            # publish the breed-row centres for the live e2e capture (079)

## Build the completion-menu breed rows (079): the shipped-breed catalog classified against the owned
## roster + the active breed + the coin balance + the adopt price, so each row reads Active / Switch /
## Adopt(price) / Locked(price). The swatch is each breed's honest coat colour (never a faked image).
func _breed_rows() -> Array:
	var cat: Array = []
	for entry in BreedPersonality.catalog():
		var bp := entry as BreedPersonality
		# The «Raser» active-dog marker names the dog actually trained: the active entry borrows the active
		# kennel individual's name+breed («Nova» / «Border collie») when the kennel is driving, else the 173
		# breed→individual bridge, breed as subtitle — matching the kennel + showcase (174, pass-39 X-4).
		var d := KennelDog.showoff_name(bp.id, bp.display_name, bp.id == _roster.active, _active_from_kennel, _kennel_roster.active)
		# 175: the active «Raser» row's swatch borrows the active kennel dog's coat (grey Nova) so the chip
		# agrees with the name+breed+coat; non-active rows keep their own breed swatch (PO father-pass-40 X-4).
		var tint := KennelDog.showoff_swatch(bp.swatch_color(), bp.id == _roster.active, _active_from_kennel, _kennel_roster.active)
		cat.append({"id": bp.id, "name": d.name, "subtitle": d.subtitle, "tint": tint})
	return TrickMenu.classify_breeds(cat, _roster.owned, _roster.active, _purse.balance, BREED_ADOPT_COST)

## Build the completion-menu word rows (092, P5-4): the catalog classified against the unlocked set +
## the active word id, so each row reads Active / Unlocked / Locked. Order follows the catalog.
## Extends each row with a `cooling` bool (093, P5-2) so the menu can surface the trade-off
## honestly: a stronger word that is currently on cooldown reads "Hviler" instead of "Active" so
## the player sees why the effective word fell back to "bra" this round. This is the minimal legible
## signal — the full per-round pop (P5-3) is deferred.
## How many marker words the player has unlocked BEYOND the always-available base "bra" (127). Drives
## the progressive reveal of the whole words section — it surfaces the moment the first alt word lands.
func _unlocked_alt_word_count() -> int:
	var count := 0
	for id in _words.to_dict().get("unlocked", []):
		if id != MarkerWords.BASE_ID:
			count += 1
	return count

func _word_rows() -> Array:
	var d := _words.to_dict()
	var rows := TrickMenu.classify_words(MarkerWords.CATALOG, d.get("unlocked", []), d.get("active", MarkerWords.BASE_ID))
	for row in rows:
		var id: String = (row as Dictionary).get("id", "")
		(row as Dictionary)["cooling"] = _words.is_on_cooldown(id)
		(row as Dictionary)["remaining"] = _words.cooldown_remaining(id)
	# Progressive disclosure (128, PO Phase-10 narrowed residual): tease just the NEXT locked word,
	# not all three future words — mirror MenuReveal.teased_locked on the tricks roadmap.
	return MenuReveal.teased_words(rows, TrickMenu.WordState.LOCKED)

## Build the completion-menu difficulty rows (118, P4-1): the shipped modes (Normal/Hard/Expert)
## classified against the active mode id, so the section shows one row per mode with the active one
## marked. Order follows Difficulty.catalog(). The selector is free for a normal dog; task 119 extends
## this through the same classify seam to reflect the special-dog lock.
func _difficulty_rows() -> Array:
	return TrickMenu.classify_difficulty(Difficulty.catalog(), _difficulty.id,
		_difficulty_locked(), _locked_difficulty_id())

## Open the completion menu (072): pop the modal and PAUSE offers. Any in-flight offer of the current
## trick is closed cleanly first (the dog stands up through its own end clip, never a mismatched one)
## and the loop is parked in idle, so nothing lingers behind the modal; the `_menu_open` guard in
## _advance_loop then keeps every offer from firing until the menu closes.
func _open_trick_menu() -> void:
	if _session.is_open():
		_end_sit()
	elif _loop != null and _loop.is_feinting():
		_end_feint()
	if _loop != null:
		_loop.reset_to_idle()
	_menu_open = true
	_refresh_trick_menu()
	if _menu != null:
		_menu.show()
	_publish_menu_open()

## Hide the menu and resume offers (072). Shared by a choice and a dismiss.
func _close_trick_menu() -> void:
	_menu_open = false
	if _menu != null:
		_menu.hide()
	_publish_menu_open()

## Web-only e2e/capture hook (072): mirror the menu-open state onto window.__bra_menu_open so a live
## browser capture can deterministically wait for the completion menu to pop (after an autotap masters
## the trick) before screenshotting. A no-op off the web export; a test seam only, never read back.
func _publish_menu_open() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__bra_menu_open = %s;" % ("true" if _menu_open else "false"), true)

## A performable trick was chosen from the menu (072): switch to it (select_trick repoints the whole
## scoring/bar path) and close the menu so offers resume as the new trick. select_trick ignores an
## unknown id, so a Locked row's id (which the menu never emits anyway) could never switch the trick.
func _on_trick_chosen(id: String) -> void:
	select_trick(id)
	_close_trick_menu()

## The menu was dismissed without a choice (072): just hide it and keep training the current trick.
func _on_menu_dismissed() -> void:
	_close_trick_menu()

## Adopt a breed by spending coins (079, P3-D3). Guards: a known, not-yet-owned breed only; the spend is
## atomic through the production CoinPurse (unaffordable → a no-op, no debt, breed not owned — the row
## stays Locked/priced). On success record the breed, refresh the HUD balance + the menu's breed rows,
## and persist coins + roster in the one save blob. The menu stays OPEN so the player sees the adopt land
## (the row flips to Owned/Switch) and can immediately switch to their new dog.
func _on_breed_adopt(id: String) -> void:
	if not BreedPersonality.is_known(id) or _roster.owns(id):
		return
	if not _purse.spend(BREED_ADOPT_COST):
		return  # unaffordable — no debt, breed not owned
	_roster.adopt(id)
	_telem("breed_adopted", {"breed": id})
	_refresh_coins()     # debits the HUD + republishes balance/owned for the e2e hooks (079)
	_refresh_trick_menu()
	_save_progress()

## Switch which owned breed is active (079, P3-4). set_active refuses an unowned breed (a no-op returning
## false), so an unowned id can never take over. On a real switch re-point _breed and re-apply the breed's
## coat (076) + temperament (075) to the live dog, refresh the menu (the Active badge moves), and persist
## the active breed so a returning player boots straight into their chosen dog.
func _on_breed_chosen(id: String) -> void:
	if not _roster.set_active(id):
		return  # not owned — never switch to a breed the player doesn't own
	_apply_active_breed()
	_publish_roster()
	_save_progress()
	_close_trick_menu()  # reveal the switched dog + resume training (like choosing a trick, 072)

## Swap the active marker word (092, P5-4). Mirrors _on_breed_chosen but keeps the menu OPEN so the
## player sees the Active badge move and can confirm the switch before training. The menu is never
## closed here (closing is only for trick-select, 072) — X-2 ("one verb, always") is preserved.
func _on_word_chosen(id: String) -> void:
	if not _words.set_active(id):
		return  # locked or unknown id — no-op, no state change
	_payoff.set_active_word(_words.active())
	_refresh_trick_menu()   # reflect the new ACTIVE row immediately (Active badge moves)
	_save_progress()        # persist the chosen word so a reload boots into the same selection

## Set the global difficulty mode from the menu (118, P4-1). Guards: a known mode only, and a no-op if
## it is already active (no needless re-apply / persist). On a real switch, re-apply the difficulty
## levers live to the running dog (the same calls a breed switch uses — erosion per trick + the loop's
## feint chance; the timing window + tell rebuild from _difficulty on the next offer), refresh the menu
## so the new active row highlights, and persist so a returning player boots into their chosen mode.
func _on_difficulty_chosen(id: String) -> void:
	if _difficulty_locked():
		return  # a special dog fixes the mode — the selector is a no-op (119, P4-1)
	if not Difficulty.is_known(id) or id == _chosen_difficulty.id:
		return
	_chosen_difficulty = Difficulty.by_id(id)  # remember the player's free pick (survives a special-dog lock, 119)
	_difficulty = _chosen_difficulty
	_apply_difficulty()
	_refresh_trick_menu()  # the active badge moves to the newly-chosen mode
	_save_progress()       # the blob carries the CHOSEN mode (068/080/119)

## Re-apply the current difficulty's levers to the live dog (118). Erosion scales each trick's learned
## bar; the loop's feint chance takes breed × difficulty immediately. The timing-window radii + the tell
## intensity read _difficulty in _begin_sit, so they apply on the next offer — no live rebuild needed.
## Mirrors the difficulty half of _apply_breed_personality so the two paths never drift.
func _apply_difficulty() -> void:
	for tid in _progress_by_trick:
		(_progress_by_trick[tid] as TrickProgress).set_erosion_scale(_difficulty.erosion_scale)
	if _loop != null and not _force_scratch:  # _force_scratch pins offers to a scratch (071) — don't clobber it
		_loop.feint_chance = _difficulty.scale_feint(_breed.feint_chance())

## Re-point the active breed onto the running dog (079): its coat tint (076) re-tints the coat atlas in
## place, and its four personality levers (075) re-apply — each trick's fill gains and the loop's feint
## chance + offer cadence take the new temperament immediately; the timing-window radii apply on the next
## offer (read from _breed in _begin_sit). Dog-agnostic: a coatless/CC0 dog just isn't re-tinted.
func _apply_active_breed() -> void:
	_active_from_kennel = false  # 174: a Phase-3 breed switch now owns the coat → show-off surfaces read the breed
	_apply_breed_personality(BreedPersonality.by_id(_roster.active))

## Switch which KENNEL dog is trained (110, K-5). The active kennel dog (KennelDog) maps to the SAME
## BreedPersonality lever object the Phase-3 breed switch drives (KennelDog.to_personality) — its coat
## tint (076 seam) + its four stat-driven levers (075) re-apply to the live dog through the shared path
## below. So «Tren med Nova» re-tints the shared Labrador rig to Nova's coat and gives her stats real
## bite, the honest BUST-068 stand-in — no faked new model, no parallel apply-system. Dog-agnostic: a
## coatless/CC0 dog just isn't re-tinted.
func _apply_active_kennel_dog(id: String) -> void:
	_active_from_kennel = true  # 174: the kennel now owns the coat → the show-off surfaces name this kennel individual
	_apply_breed_personality(KennelDog.by_id(id).to_personality())
	_recompute_difficulty()  # 119: a special dog forces its locked mode; a normal dog restores the player's chosen mode

## The coat tint of the dog currently ON the training rig (174): the active KENNEL individual's coat when the
## kennel is driving training, else the active BREED's coat. The showcase previews breeds by re-tinting the
## live rig, so moving back to / dismissing onto the active dog must restore THIS coat, not blindly the breed
## coat (which would repaint a trained kennel dog — e.g. turn grey Nova cream on «Tilbake»).
func _active_coat_tint() -> Color:
	return KennelDog.by_id(_kennel_roster.active).coat_tint() if _active_from_kennel else _breed.coat_tint()

## True iff the active TRAINING dog locks the global difficulty (119, P4-1). "Special" dogs
## (RARE/EPIC/SECRET) fix the challenge; the starter Bella + plain COMMON dogs stay choosable. The
## active training dog is the active KENNEL dog (the kennel is the roster the training scene loads).
func _difficulty_locked() -> bool:
	return KennelDog.by_id(_kennel_roster.active).locks_difficulty()

## The difficulty mode a special active dog pins (119). Only meaningful while _difficulty_locked().
func _locked_difficulty_id() -> String:
	return KennelDog.by_id(_kennel_roster.active).locked_difficulty_id()

## Recompute the EFFECTIVE difficulty from the lock state (119). A special active dog forces its locked
## mode; any other dog restores the player's CHOSEN mode. Re-applies the levers so the change lands live.
## Idempotent — safe to call on every kennel switch and on boot after the active dog loads.
func _recompute_difficulty() -> void:
	_difficulty = Difficulty.by_id(_locked_difficulty_id()) if _difficulty_locked() else _chosen_difficulty
	_apply_difficulty()

## Re-point the running dog onto a resolved BreedPersonality (the shared body of both the Phase-3 breed
## switch and the Phase-8 kennel switch): its coat tint (076) re-tints the coat atlas in place, and its
## four personality levers (075) re-apply — each trick's fill gains and the loop's feint chance + offer
## cadence take the new temperament immediately; the timing-window radii apply on the next offer (read
## from _breed in _begin_sit). Dog-agnostic: a coatless/CC0 dog just isn't re-tinted.
func _apply_breed_personality(bp: BreedPersonality) -> void:
	_breed = bp
	if _dog != null:
		CoatTint.apply(_dog, _breed.coat_tint())  # re-tint the coat atlas for the chosen dog (076)
	for tid in _progress_by_trick:
		var tp := _progress_by_trick[tid] as TrickProgress
		_breed.apply_gains_to(tp)  # learn_speed re-scales each bar's fill (075)
		tp.set_erosion_scale(_difficulty.erosion_scale)  # difficulty erosion re-applied on switch (081, P4-2/P4-4)
	if _loop != null and not _force_scratch:  # _force_scratch pins every offer to a scratch (071) — don't clobber it
		_loop.feint_chance = _difficulty.scale_feint(_breed.feint_chance())  # breed × difficulty (081, P4-2/P4-4)
		_loop.min_gap = _breed.min_gap()
		_loop.max_gap = _breed.max_gap()

## Pick a trick to train (P2-1; driven by the 072 completion menu): repoint _current_trick and the
## learned bar/model to THAT trick's own persisted state. Picking is a BETWEEN-rounds choice, never a
## second in-round verb — so if an offer of the OLD trick is mid-flight, close it cleanly first (the
## dog stands up through the OLD trick's own end clip, never a mismatched one) and reset the loop so the
## next offer comes round fresh as the newly-chosen trick. A no-op for an unknown id or the current
## trick. Routing is dog-agnostic (the menu is what filters to performable tricks), so it is
## scene-testable on the CC0 dog.
func select_trick(id: String) -> void:
	if not KNOWN_TRICKS.has(id) or id == _current_trick:
		return
	# Close whatever offer of the OLD trick is in flight before switching.
	if _session.is_open():
		_end_sit()                              # graceful stand-up on the OLD trick; closes the window, resumes the roam
	elif _loop != null and _loop.is_feinting():
		_end_feint()                            # the dip settles back to idle + resumes the roam
	if _loop != null:
		_loop.reset_to_idle()                   # next offer comes round fresh as the newly-chosen trick
	_current_trick = id
	_progress = _progress_by_trick[id]          # the whole scoring/erosion/bar path now reads the new trick's model
	if _learned_bar != null:
		_learned_bar.set_trick(_current_trick, LEARNED_BAR_LABEL_ROW, LEARNED_BAR_LABEL_GAP)  # 097: update label
		_learned_bar.set_value(_progress.value, _progress.mastered)
	_publish_current_trick()  # reflect the switch onto the web e2e hook (066/072)

## Web-only e2e hook (066/072): expose the trained trick id so a LIVE browser test can prove a real
## menu tap actually switches it — the menu's crux (a canvas tap → _gui_input → trick_chosen →
## select_trick). Mirrors the __bra_reaction_n / __appReady hooks; a no-op off the web export and
## harmless in normal play. This is a test seam only — the menu never reads it back.
func _publish_current_trick() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__bra_current_trick = '%s';" % _current_trick, true)

## Web-only e2e/capture hook (079): mirror the roster (active breed + owned ids) + the coin balance onto
## window.* so a LIVE browser capture can deterministically prove the collect-and-train loop — an adopt
## debits the balance and flips `__bra_owned`, a switch flips `__bra_active_breed`, and a reload restores
## both. Mirrors the __bra_current_trick / __bra_menu_open seams; a no-op off the web export, never read
## back in play. Published on boot + after every adopt/switch.
func _publish_roster() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.__bra_active_breed = '%s';" % _roster.active, true)
	JavaScriptBridge.eval("window.__bra_owned = %s;" % JSON.stringify(_roster.owned), true)
	JavaScriptBridge.eval("window.__bra_balance = %d;" % _purse.balance, true)

## Web-only e2e/capture hook (079): publish each breed row's centre (in viewport px) + its id + the
## viewport size, so the capture lands a REAL canvas tap on a specific breed row (adopt / switch) rather
## than hard-coding fragile screenshot pixels — the honest-tap proof the 072 menu capture pioneered.
## Published whenever the menu is refreshed (so the coords match the currently-drawn rows).
func _publish_breed_rows() -> void:
	if not OS.has_feature("web") or _menu == null:
		return
	var vp := get_viewport().get_visible_rect().size
	var breeds: Array = []
	for i in _menu.breed_count():
		var c := _menu.breed_row_center(i)
		breeds.append({"id": _menu.breed_id(i), "x": c.x, "y": c.y})
	JavaScriptBridge.eval("window.__bra_breed_rows = %s;" % JSON.stringify(breeds), true)
	var tricks: Array = []
	for i in _menu.row_count():
		var c := _menu.row_center(i)
		tricks.append({"id": _menu.row_id(i), "x": c.x, "y": c.y})
	JavaScriptBridge.eval("window.__bra_trick_rows = %s;" % JSON.stringify(tricks), true)
	# Publish the marker-word row centres + ids + the active word (092/P5-4) so the capture can land a
	# REAL tap on a specific word row and assert the active-word swap — the same honest-tap proof.
	var words: Array = []
	for i in _menu.word_count():
		var c := _menu.word_row_center(i)
		words.append({"id": _menu.word_id(i), "x": c.x, "y": c.y})
	JavaScriptBridge.eval("window.__bra_word_rows = %s;" % JSON.stringify(words), true)
	JavaScriptBridge.eval("window.__bra_active_word = '%s';" % _words.active(), true)
	JavaScriptBridge.eval("window.__bra_viewport = [%f, %f];" % [vp.x, vp.y], true)
	# Publish the feedback row centre so the capture can tap "Give feedback" robustly (085, X-8).
	var fc := _menu.feedback_row_center()
	JavaScriptBridge.eval("window.__bra_feedback_row = [%f, %f];" % [fc.x, fc.y], true)
	# Publish the "Vis frem hundene" showcase row centre so the capture can open the showcase (087).
	var sc := _menu.showcase_row_center()
	JavaScriptBridge.eval("window.__bra_showcase_row = [%f, %f];" % [sc.x, sc.y], true)
	# Publish the difficulty row centres + ids + the active mode (118/P4-1) so the capture can land a
	# REAL tap on a specific mode row and assert the global-difficulty switch — the same honest-tap proof.
	var diffs: Array = []
	for i in _menu.difficulty_row_count():
		var c := _menu.difficulty_row_center(i)
		diffs.append({"id": _menu.difficulty_id(i), "x": c.x, "y": c.y})
	JavaScriptBridge.eval("window.__bra_difficulty_rows = %s;" % JSON.stringify(diffs), true)
	JavaScriptBridge.eval("window.__bra_difficulty = '%s';" % _difficulty.id, true)

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
	if _grace.is_grace_active(_now()):
		return  # a stray resume-touch (120/P4-5) — ignore entirely: neither a mark nor a miss, no erosion
	if not _tap_gate.is_armed():
		return  # swallowed during the fixed lock — not scored, the gate's clock untouched (046/P2-7)
	_tap_gate.lock()  # the fixed re-arm window starts on the ACCEPTED tap only — mashing can't extend it
	var tier := _session.tap()
	_attempts += 1
	var _off := _session.apex_offset()
	_telem("bra_tapped", {
		"trick": _current_trick,
		"bucket": SitWindow.bucket(tier, _off),
		"latency_ms_from_apex": int(round(_off * 1000.0)),
		"attempt_number": _attempts
	})
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
		_telem("trick_mastered", {"trick": _current_trick})
		_play_mastery_beat()
		_purse.earn(_difficulty.mastery_reward(COIN_REWARD_MASTERY))  # difficulty scales the payout (082, P4-3); Normal = identity
		_refresh_coins()
		var mastered_count := _count_mastered_tricks()  # how many tricks are now mastered (091/P5-1)
		_words.unlock_up_to(mastered_count)             # unlock the next word(s) up to the mastered count
		_open_trick_menu()  # the active trick is learned — pop the completion menu, pause offers (072/PO note 1)
	elif not SitWindow.is_successful(tier):
		_play_confused_beat()  # a mistimed / wrong-moment tap — the dog reads confused (P2-4)
	_save_progress()  # persist after every change so the bar survives a reload (049/P2-5)

## The tricks main holds a learned bar for (065). Each gets its own persisted TrickProgress, keyed by
## id in the save map, so per-trick progress never leaks across tricks. Grows as more tricks wire (067).
const KNOWN_TRICKS := [TRICK_ID_SITT, TRICK_ID_LIGG, TRICK_ID_LEGG_DEG]

## Count how many KNOWN tricks are currently mastered (091/P5-1). Used by the just_mastered hook to
## decide which marker words to unlock: 1st mastered → dyktig, 2nd → flink, etc. Mirrors the
## mastery-counting loop in _menu_rows so there is one source of truth for "mastered count".
func _count_mastered_tricks() -> int:
	var count := 0
	for id in KNOWN_TRICKS:
		var p: TrickProgress = _progress_by_trick.get(id)
		if p != null and p.mastered:
			count += 1
	return count

## Load saved per-trick progress on boot (049/P2-5). Builds one TrickProgress per known trick, restores
## each from its own key in the save map, then points `_progress` at the current trick's model so
## _setup_learned_bar shows the returning player's filled / mastered bar immediately. First run (or a
## corrupt / wrong-version save) restores nothing → clean zeros (TrickStore degrades to {}).
func _load_progress() -> void:
	var saved := _store.load()
	for id in KNOWN_TRICKS:
		# The active breed's learn_speed scales each trick's fill gains (075, P3-3): a more trainable
		# dog fills its learned bar faster. Labrador learns a touch fast; the constants stay the baseline.
		var p := TrickProgress.new(_breed.perfect_gain(), _breed.ok_gain())
		# Difficulty erosion stacks on top (081, P4-2/P4-4): harsher difficulty drains the bar faster
		# on mistimed/wrong taps. Normal erosion_scale = 1.0 (identity — no change to default play).
		p.set_erosion_scale(_difficulty.erosion_scale)
		var entry: Variant = saved.get(id, {})
		if typeof(entry) == TYPE_DICTIONARY:
			p.restore(entry)
		_progress_by_trick[id] = p
	_progress = _progress_by_trick[_current_trick]

## Persist every trick's progress (049/P2-5). One JSON map keyed per trick to user:// — IndexedDB on
## web, no backend / account / network (X-7 offline). Saves the whole map so switching trick and saving
## never drops another trick's fill. Coins, roster, and difficulty ride the same blob (068/079/080).
func _save_progress() -> void:
	var out := {}
	for id in _progress_by_trick:
		out[id] = (_progress_by_trick[id] as TrickProgress).to_dict()
	_store.save(out, _purse.balance, _roster.to_dict(), _chosen_difficulty.id, _words.to_dict(), _kennel_roster.to_dict())  # persist the player's CHOSEN mode, not the special-dog-forced effective one (068/079/080/091/109/119)
	# Web-only e2e seam (087): mirror the active breed the save JUST wrote. Lets a capture prove a breed
	# switch was PERSISTED to the save deterministically — the reload-restore is separately proven (079),
	# but its IndexedDB flush is async/racy, so this hook is the deterministic write-side proof. No-op off
	# the web export; never read back in play.
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__bra_last_saved_active = '%s';" % _roster.active, true)
		# Same deterministic write-side proof for the ACTIVE KENNEL dog (110, K-7): a capture asserts the
		# switch was PERSISTED the instant the save is written, independent of the async/racy IndexedDB
		# flush that gates the reload-restore. No-op off web; never read back in play.
		JavaScriptBridge.eval("window.__bra_last_saved_kennel_active = '%s';" % _kennel_roster.active, true)

## Restore the saved coin balance on boot (068/P3-D3). Runs before the coin readout is built so a
## returning player sees their earned coins immediately. First run / corrupt save -> 0 (TrickStore
## degrades cleanly). Mastery restored from disk does NOT re-fire just_mastered, and the balance is
## read from disk rather than recomputed, so coins are never re-awarded on load.
func _load_coins() -> void:
	_purse.restore({"balance": _store.load_coins()})
	# Capture-harness seam (110): ?bra_coins=N grants a starting balance so the Visual-Review script can
	# adopt a kennel dog then switch to it deterministically (a fresh player has 0 coins). Web-only, only
	# GRANTS (never reduces), and only when the saved balance is below N — so it never fights a real save.
	# Mirrors the ?bra_breed= / ?bra_difficulty= dev seams (a kept capture shortcut, dormant in real play).
	var granted := _query_coins()
	if granted > _purse.balance:
		_purse.earn(granted - _purse.balance)

## Capture seam (110): read ?bra_coins=N off the live web URL, returning N (or -1 for no override). Reads
## a STRING (never a bare bool/int) to dodge the Web-export null-Variant marshalling that bit the apex
## tell (036); a malformed value returns -1 (no grant). Web-only; desktop/headless never grant.
func _query_coins() -> int:
	if not OS.has_feature("web"):
		return -1
	var search: Variant = JavaScriptBridge.eval("window.location.search || ''", true)
	if typeof(search) != TYPE_STRING:
		return -1
	var s := search as String
	var idx := s.find("bra_coins=")
	if idx < 0:
		return -1
	var tail := s.substr(idx + "bra_coins=".length())
	var digits := ""
	for ch in tail:
		if ch >= "0" and ch <= "9":
			digits += ch
		else:
			break
	return int(digits) if digits != "" else -1

## Restore the owned-breeds roster on boot (079/P3-4). Runs before the active breed is resolved so a
## returning player boots into their chosen dog with their adopted breeds. First run / corrupt / legacy
## save -> owning just the starter Labrador (TrickStore + BreedRoster both degrade cleanly), never a
## dog-less player and never a crash.
func _load_roster() -> void:
	_roster.restore(_store.load_roster())

## Restore the kennel-dog owned roster on boot (109, Phase 8 K-7). Runs before the kennel screen
## is shown so a returning player sees their adopted dogs. First run / corrupt / legacy save ->
## owning just Bella (TrickStore + KennelRoster both degrade cleanly), never a dog-less kennel
## and never a crash.
func _load_kennel_roster() -> void:
	_kennel_roster.restore(_store.load_kennel())

## Adopt a kennel dog by spending coins (109, Phase 8 K-3/K-4). Guards:
##   - In-flight: a second press while one adopt is mid-flight is swallowed (no double-spend).
##   - Affordability: price > 0 and not enough coins → K-3 gate blocks the adopt.
##   - Already-owned: KennelRoster.adopt is idempotent, but we also skip the spend if the dog
##     is already owned (the caller's owns() guard keeps this a no-op).
## On success: deducts the price, marks the dog owned, persists the whole blob, re-renders the
## kennel grid, re-opens/refreshes the modal to the owned treatment, and plays a small joyful
## beat (coin count-down via _refresh_coins + procedural bounce — reusing the 072/077 pattern).
## Pure adopt decision (109/K-3/K-4/K-6) — the single predicate _on_kennel_adopt() branches on.
## already_owned → false (no-op, no double-spend). A priced dog you can't afford (balance < price)
## → false (K-3 gate). A free dog (price 0) is ALWAYS adoptable, at any balance (K-6 easter path).
## Static so the gate unit-tests through the real seam, not a comment.
static func _can_adopt(already_owned: bool, price: int, balance: int) -> bool:
	if already_owned:
		return false
	if price > 0 and balance < price:
		return false
	return true

func _on_kennel_adopt(id: String) -> void:
	if _kennel_adopt_busy:
		return
	var price := KennelDog.by_id(id).price
	if not _can_adopt(_kennel_roster.owns(id), price, _purse.balance):
		return  # already-owned no-op OR K-3 affordability gate
	_kennel_adopt_busy = true
	_purse.spend(price)
	_kennel_roster.adopt(id)
	_save_progress()            # persist the whole blob (tricks + coins + roster + kennel)
	_refresh_coins()            # update the HUD coin readout
	# Re-render the kennel grid with the updated owned set.
	if _kennel != null:
		var rows := KennelDog.classify_kennel_dogs(_kennel_owned(), _kennel_active(), _purse.balance)
		_kennel.render(rows, _purse.balance)
		_kennel.open_detail(id)  # refresh the modal to the owned treatment
	_publish_kennel_active()    # keep the owned-set capture hook fresh after the adopt (K-4/K-6)
	# Positive feedback: joyful beat (077 pattern — a facing-preserving bounce, not a clip).
	_play_joy_beat()
	_kennel_adopt_busy = false

## Switch which dog the player trains to an owned kennel dog (110, K-5/K-7). set_active refuses an
## unowned id (a no-op returning false — the never-train-what-you-don't-own invariant), so a stray id
## can never take over. On a real switch: re-tint the coat + re-apply the dog's stat levers to the live
## dog (_apply_active_kennel_dog), persist the choice in the one save blob (so a returning player boots
## straight into this dog, K-7), publish the e2e hook, then close the kennel so the player lands back on
## the training scene with their chosen dog framed and ready — the payoff that makes adoption mean
## something.
func _on_kennel_train_with(id: String) -> void:
	if not _kennel_roster.set_active(id):
		return  # not owned — never switch to a dog the player doesn't own
	_apply_active_kennel_dog(id)
	_save_progress()            # persist the active kennel dog (K-7) in the one blob
	_publish_kennel_active()    # keep the capture/e2e hook fresh
	_close_kennel()             # reveal the switched dog + resume training

## Push the current coin balance onto the HUD readout (068/P3-D3). No-op before the readout mounts.
func _refresh_coins() -> void:
	if _coin_readout != null:
		_coin_readout.set_balance(_purse.balance)
	_publish_roster()  # keep the e2e balance + roster hooks fresh on every coin change (earn/spend, 079)

## The celebratory beat when a trick reaches mastery (045/P2-4): the same facing-preserving joyful
## bounce a PERFECT mark plays (077, PO Note 7). Procedural, so it reads as a coherent celebration
## that stays facing the player — never the rear-spinning Jump_Place_IP hop. Works on any dog (the
## bounce is not a faked clip, the same honest procedural pattern as the confused beat).
func _play_mastery_beat() -> void:
	_play_joy_beat()

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

## Begin the procedural joyful beat (077, PO Note 7): the celebration on a successful mark. _process
## drives a brief facing-preserving bounce from here (JoyBeat) and restores the dog to its rest
## transform. Replaces the rear-spinning Jump_Place_IP reaction — the dog stays on its seated hold
## (already playing) and just bounces happily. Cancels any lingering confused beat so a good mark
## never wobbles and bounces at once. No-op if the dog isn't a Node3D we can nudge.
func _play_joy_beat() -> void:
	if _dog != null:
		_confused_age = -1.0  # a successful mark is never also "confused"
		_joy_age = 0.0

## Step the procedural joyful beat (077): a damped happy bounce + gentle body waggle that KEEPS the
## dog facing the player (JoyBeat caps the yaw), composed on top of the dog's CURRENT base transform —
## its frozen seated spot while a mark's hold is up, or its wander spot — so the celebration never
## fights the seated clip and always settles EXACTLY back to rest (no drift, no framing regression).
## Dampened by the reduced-motion factor (X-5): scale 0 ⇒ no bounce. Mirrors _drive_confused exactly.
func _drive_joy(delta: float) -> void:
	if _dog == null or _joy_age < 0.0:
		return
	_joy_age += delta
	var base := _dog_base_transform()
	if _joy_age >= JoyBeat.DURATION:
		_dog.transform = base  # settle exactly back — no drift
		_joy_age = -1.0
		return
	_dog.transform = base * JoyBeat.offset(_joy_age, _motion_scale)

## Drive the ambient wander (050, P2-8): while active (between offers), advance the bounded-patch
## roam and switch the dog between its walk clip (ambling) and idle (paused at a target) — only on
## a change, so the clip isn't restarted every frame. Each frame it places the dog ROOT at its
## wander spot (frozen while a sit/feint pauses the roam) and slides the contact shadow to match,
## UNLESS the confused beat is mid-recoil — that frame _drive_confused owns the transform and
## composes its wobble off the same wander base. A no-op on a dog with no walk clip (no _wander).
func _drive_wander(delta: float) -> void:
	if _wander == null or _dog == null:
		return
	# Hold the roam IN PLACE while the dog stands up out of a sit (059), so the authored
	# `Sitting_end` reads before the amble resumes and the walk clip can't clobber it a frame
	# in. This gates only which clip shows — the next offer stays on SitLoop's own clock, so the
	# P2-8 variable cadence is untouched.
	if _wander_active and not _director.is_ending_trick(_current_trick):
		_wander.advance(delta)
		if _wander.is_moving() and not _ambling:
			_director.play_walk()   # step the legs while the root glides
			_ambling = true
			_release_resting_face()  # hand the yaw back to the travel heading (071)
		elif not _wander.is_moving() and _ambling:
			_director.play_idle()   # paused at a target — stand and look around
			_ambling = false
			_engage_resting_face()   # ease to generally face the player while paused (071, PO note 3)
	_advance_facing(delta)  # ease the face-the-camera turn / its release (061, P2-11)
	if _confused_age < 0.0 and _joy_age < 0.0:
		_dog.transform = _wander_base()  # a confused/joyful beat owns the transform that frame instead
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
## (keep the rest Y so the feet stay on the grass) and yaw the rest basis to the current yaw so the
## dog faces where it's walking (reads as roaming, not sliding) — OR, during a real trick, to the
## face-the-camera heading (061, via _dog_yaw), so the seated apex reads head-on.
func _wander_base() -> Transform3D:
	var off := _wander.position()
	var basis := _dog_rest.basis.rotated(Vector3.UP, _dog_yaw())
	return Transform3D(basis, _dog_rest.origin + Vector3(off.x, 0.0, off.y))

## The dog's yaw this frame: the face-the-camera turner while a trick is engaging / releasing (061,
## P2-11), else the wander travel heading (050). Once the release re-aligns, `_face` is dropped and
## the wander drives the yaw directly again — steady-roam feel is unchanged.
func _dog_yaw() -> float:
	if _face != null:
		return _face.heading()
	return _wander.heading()

## Engage the face-the-camera turn for a real sit (061, P2-11): cache the camera-facing target and
## build a bounded turner from the dog's current yaw that COMPLETES before the seated apex — sized so
## a turn of any magnitude finishes within FACE_APEX_FRACTION of the time-to-apex (floored), and at
## least the natural roam rate. Reduced motion (X-5) resolves near-instantly. A feint never calls
## this, so it keeps its wander heading. A no-op on a dog with no wander/root (nothing to turn).
func _engage_face_for_sit() -> void:
	if _wander == null or _dog == null:
		return
	_sit_face_heading = _camera_facing_heading()
	var start := _dog_yaw()
	var reduced := _motion_scale < 1.0  # damped tell scale ⇒ prefers-reduced-motion is active
	var speed := FACE_REDUCED_SPEED
	if not reduced:
		var turn := absf(wrapf(_sit_face_heading - start, -PI, PI))
		var apex := _window.apex if _window != null else FACE_DEFAULT_APEX
		var deadline := maxf(FACE_MIN_DEADLINE, apex * FACE_APEX_FRACTION)
		speed = maxf(FACE_ROAM_SPEED, turn / deadline)  # fast enough to beat the apex, never slower than natural
	_face = FaceTurn.new(start, _sit_face_heading, speed)
	_facing = true

## Engage the face-the-camera turn for the breed showcase (172, PO father-pass-37): the showcase poses
## the spotlit dog as a composed portrait, so — like a sit — it turns to face the player, but WITHOUT
## the sit's apex-deadline timing (there is no scoring window here). Reuses the same `_facing`/`_face`
## machinery `_advance_facing` drives, so the turn-in holds the camera heading regardless of the (now
## paused) roam, and `_release_face` on close eases it back. A no-op on a dog with no wander/root.
func _engage_face_for_showcase() -> void:
	if _wander == null or _dog == null:
		return
	_sit_face_heading = _camera_facing_heading()
	var speed := FACE_REDUCED_SPEED if _motion_scale < 1.0 else FACE_ROAM_SPEED
	_face = FaceTurn.new(_dog_yaw(), _sit_face_heading, speed)
	_facing = true

## Release the facing after the trick (061): stop holding the camera and drop to the natural roam
## turn rate. `_advance_facing` then eases `_face` back to the wander heading and, once re-aligned,
## hands the yaw back to the wander (drops `_face`). A no-op if no turn was engaged.
func _release_face() -> void:
	_facing = false
	if _face != null:
		_face.set_speed(FACE_REDUCED_SPEED if _motion_scale < 1.0 else FACE_ROAM_SPEED)

## Advance the face-the-camera turn each frame (061). While `_facing`, hold the cached camera
## target (the turn-in); after `_release_face`, retarget to the live wander heading (the eased
## turn-out) and, once re-aligned, drop `_face` so the wander drives the yaw directly again. A no-op
## while roaming (no `_face`).
func _advance_facing(delta: float) -> void:
	if _face == null:
		return
	if _facing:
		# The trick turn-IN owns the facing outright and must complete before the apex even though the
		# sit paused the roam (061) — so it always eases, regardless of _wander_active.
		_face.retarget(_sit_face_heading)
		_face.advance(delta)
		return
	# Otherwise this is the ambient resting turn (071) or the trick turn-OUT release: both belong to
	# the LIVE roam, so they ease only while the roam is active. A sit/feint/confused beat freezes the
	# roam and with it this turn, so the recoil-return invariant (045) and the frozen offer base hold.
	if not _wander_active:
		return
	if _resting_face:
		_face.retarget(_camera_facing_heading())  # paused between offers: gently face the player (071)
	else:
		_face.retarget(_wander.heading())          # moving / release: ease back to the travel heading
	_face.advance(delta)
	if not _resting_face and _face.is_facing():
		_face = null  # re-aligned with the roam — hand the yaw back to the instant wander

## Ease the PAUSED dog to generally face the player between offers (071, PO note 3 — the owner saw it
## stand rear-on, tail to the player). Reuses the 061 FaceTurn at the gentle roam rate; _advance_facing
## then holds the camera-facing heading while paused. A moving dog still faces its travel heading (reads
## as roaming, not moon-walking). A no-op while a trick owns the facing (_facing) or on a dog with no
## wander/root. Kept subtle: an eased turn, never a snap and never a rigid front-lock.
func _engage_resting_face() -> void:
	if _wander == null or _dog == null or _facing:
		return
	_resting_face = true
	var target := _camera_facing_heading()
	if _face == null:
		_face = FaceTurn.new(_dog_yaw(), target, FACE_ROAM_SPEED)
	else:
		_face.set_speed(FACE_ROAM_SPEED)
		_face.retarget(target)

## Hand the facing back to the travel heading when the dog starts ambling again (071). _advance_facing
## then eases _face out to the wander heading and drops it once re-aligned — the steady-roam feel and
## the 061 trick-facing release are both unchanged.
func _release_resting_face() -> void:
	_resting_face = false

## The yaw that faces the camera POV (061, P2-11), in the WanderField convention (heading =
## atan2(dir.x, dir.z) faces `dir`, proven by the wander Visual Review). So the dog->camera XZ
## vector's atan2 turns the dog to face the camera — model-agnostic, no hardcoded angle. Falls back
## to the current yaw if the camera or dog is missing (nothing sensible to aim at).
func _camera_facing_heading() -> float:
	if _camera == null or _dog == null:
		return _dog_yaw() if _wander != null else 0.0
	var dogp := _dog.transform.origin
	var camp := _camera.transform.origin
	var dir := Vector2(camp.x - dogp.x, camp.z - dogp.z)  # (worldX, worldZ), the WanderField convention
	if dir.length() < 1e-4:
		return _dog_yaw()
	return atan2(dir.x, dir.y)  # y holds worldZ — matches WanderField.heading = atan2(to.x, to.y)

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
##
## Marker-word fallback (093, P5-2): on a successful mark, fire_active(true) returns the
## EFFECTIVE word id — the active word itself when available, "bra" when it is cooling.
## The payoff plays that effective word's clip so the player hears "bra" when the stronger
## word is resting (never a hidden mechanic). On a MISS/DEAD fire_active(false) is called
## so no cooldown is armed/decremented — a bad round doesn't tick the clock. Base "bra"
## (scale 1.0, cooldown 0) leaves this path byte-identical to pre-093 play.
func _play_payoff(tier: SitWindow.Tier) -> void:
	var payoff := MarkPayoff.for_tier(tier)
	# Fire the active word and get the effective id (093, P5-2). succeeded=true iff the tier
	# is a real mark (PERFECT or OK); succeeded=false for MISS/DEAD (no arm, no decrement).
	var fired := _words.fire_active(payoff.is_success)
	if _payoff != null:
		# Point the payoff player at the effective word's clip for this mark, then play.
		# While the active word is cooling `fired` == "bra" and the base clip sounds.
		# Base "bra" active always returns "bra" — byte-identical stream, no regression.
		_payoff.set_active_word(fired)
		_payoff.play(payoff)
	# Pop the effective fired word on screen — shows the word that actually sounded, including the
	# "Bra!" fallback while a stronger word is cooling (makes P5-2 legible in play). A MISS/DEAD
	# (is_success=false) fires nothing: no pop, matching the silent payoff + blank TierReadout.
	if payoff.is_success and _word_pop != null:
		_word_pop.pop(_words.display_for(fired))
	if payoff.reacts() and _director != null:
		# The celebration is now a facing-preserving procedural bounce (077, PO Note 7), NOT the
		# authored Jump_Place_IP hop — that hop rotated the dog rear-to-camera and snapped through a
		# side profile (the "chaotic, unnatural" payoff the PO caught), and the manifest has no
		# wag/tail clip to swap in. The dog stays on its current trick's seated hold and bounces.
		_play_joy_beat()
		# Web-only capture/e2e signal: a counter the reaction-capture harness watches so it
		# can sync its screenshot burst to the exact frame the celebration starts (034). No-op
		# off the web export; harmless in normal play.
		if OS.has_feature("web"):
			JavaScriptBridge.eval("window.__bra_reaction_n = (window.__bra_reaction_n||0)+1;", true)

## Deterministic readiness signal for the PWA splash / e2e, mirroring the
## old web shell's window.__appReady. No-op off the web export.
func _notify_web_ready() -> void:
	if OS.has_feature("web"):
		# Publish the real render viewport size at boot so every capture's tap-coordinate conversion is
		# correct from the first tap (it was previously only set on a trick-menu refresh → UNSET for the
		# kennel flow, so captures fell back to a stale 1280 height and every tap landed too low, 110).
		var vp := get_viewport().get_visible_rect().size
		JavaScriptBridge.eval("window.__bra_viewport = [%f, %f];" % [vp.x, vp.y], true)
		JavaScriptBridge.eval("window.__appReady = true;", true)
	print("[Bra!] scaffold ready")
	# Positive telemetry gate (086, X-8/ADR-0007): print a console signal ONLY when a real project
	# token is baked in (a CI web export with POSTHOG_TOKEN injected → is_enabled() true). Locally /
	# on the CC0 build the committed token is empty → disabled → this stays silent, so verify's boot
	# leg and normal play are untouched. The deploy's browser boot check --require's this exact
	# substring, so a token that failed to bake fails the deploy closed (the live site stays stale).
	if _telemetry != null and _telemetry.is_enabled():
		print("[Bra!] telemetry enabled (anonymous PostHog capture)")

## Single choke-point for all telemetry calls in main (084, X-8). Routes every capture
## through the one _telemetry node; null-guards for headless paths that skip _ready().
## Fire-and-forget: if capture() throws nothing surfaces to gameplay (X-7).
func _telem(event: String, props := {}) -> void:
	if _telemetry != null:
		_telemetry.capture(event, props)

## Godot's web export raises NOTIFICATION_APPLICATION_PAUSED on the Page Visibility API
## "hidden" transition (tab hidden / backgrounded) and NOTIFICATION_WM_CLOSE_REQUEST on
## desktop close — the best-effort, engine-native flush point for session_end (ADR-0007).
## No JavaScriptBridge needed: the engine surfaces both as standard Godot notifications.
## Fire-and-forget: a hard tab-kill without a prior "hidden" may still drop the final
## event, which ADR-0007's fire-and-forget posture explicitly tolerates.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_emit_session_end()
	# Resume-from-background (120, P4-5): arm the tap grace so the first stray resume-touch (a
	# notification/lock delivering a phantom tap on the first frame) is swallowed, never a false mark.
	# APPLICATION_FOCUS_IN fires on mobile resume; WM_WINDOW_FOCUS_IN gives desktop/web parity. Inert
	# headless (no focus events fire), so the verify boot/test legs never arm it.
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_grace.arm(_now())

## The monotonic clock the tap grace reads (120, P4-5). Seconds since engine start — never wall-clock,
## so it is immune to a device clock change. Injected in tests via _grace directly (no real timer).
func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

## Emit session_end with a summary of the session: the last trick trained, the total
## accepted tap count, the best single-trick progress value seen, and how many tricks
## were mastered. Iterates _progress_by_trick so it is correct even if the player
## switched tricks mid-session. Safe to call with an empty map (mastered_count = 0).
func _emit_session_end() -> void:
	var best := 0.0
	var mastered := 0
	for id in _progress_by_trick:
		var p := _progress_by_trick[id] as TrickProgress
		best = maxf(best, p.value)
		if p.mastered:
			mastered += 1
	_telem("session_end", {
		"last_trick": _current_trick,
		"attempts": _attempts,
		"best_progress": best,
		"mastered_count": mastered
	})
