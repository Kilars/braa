extends "res://tests/test_case.gd"
## TDD for the audible half of the payoff (024f, P1-6). MarkPayoff (test_mark_payoff)
## decides WHAT fires and how bright; PayoffPlayer is the dumb player that owns the
## AudioStreamPlayers and must (a) honour the gate — make NO sound on a MISS/DEAD — and
## (b) play PERFECT louder than OK. It ships honest synthesized placeholder cues (a
## click + a "bra" blip); the real Maren voice drops in under MarkPayoff's stable cue
## id. Asserted render-free via the player's own state, so no audio device is needed.

func _player() -> PayoffPlayer:
	var p := PayoffPlayer.new()
	# Mount it so the AudioStreamPlayers are in-tree (a real play path), then tear
	# down with queue_free in the caller — mirrors the other scene-level tests.
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(p)
	return p

func test_ships_real_placeholder_streams() -> void:
	# The cues are honest, generatable placeholders — not empty wiring. Both streams
	# must be assigned so a success genuinely makes sound (the owner's voice is a
	# later drop-in under the same cue id, not a precondition for any audio at all).
	var p := _player()
	assert_true(p.voice_stream() != null, "the voice has a (placeholder) stream assigned")
	assert_true(p.click_stream() != null, "the UI click has a stream assigned")
	p.queue_free()

func test_perfect_and_ok_play_sound() -> void:
	var p := _player()
	p.play(MarkPayoff.for_tier(SitWindow.Tier.PERFECT))
	assert_true(p.last_played, "a PERFECT mark plays the payoff sound")
	assert_eq(p.last_cue, MarkPayoff.VOICE_PERFECT, "it speaks the PERFECT cue")
	p.play(MarkPayoff.for_tier(SitWindow.Tier.OK))
	assert_true(p.last_played, "an OK mark plays the payoff sound")
	assert_eq(p.last_cue, MarkPayoff.VOICE_OK, "it speaks the OK cue")
	p.queue_free()

func test_miss_and_dead_make_no_sound() -> void:
	# The acceptance gate: a miss / dead tap is provably silent (P1-6).
	var p := _player()
	p.play(MarkPayoff.for_tier(SitWindow.Tier.MISS))
	assert_false(p.last_played, "a MISS plays no sound")
	assert_false(p.is_voicing(), "the voice player is idle after a MISS")
	p.play(MarkPayoff.for_tier(SitWindow.Tier.DEAD))
	assert_false(p.last_played, "a DEAD tap plays no sound")
	assert_false(p.is_voicing(), "the voice player is idle after a DEAD tap")
	p.queue_free()

func test_perfect_is_louder_than_ok() -> void:
	# "PERFECT sounds brighter than OK" (P1-6): a strictly higher voice level.
	var p := _player()
	p.play(MarkPayoff.for_tier(SitWindow.Tier.PERFECT))
	var perfect_db := p.voice_volume_db()
	p.play(MarkPayoff.for_tier(SitWindow.Tier.OK))
	var ok_db := p.voice_volume_db()
	assert_true(perfect_db > ok_db, "PERFECT plays louder than OK (%f > %f)" % [perfect_db, ok_db])
	p.queue_free()

func test_a_dead_tap_does_not_overwrite_the_last_cue_with_sound() -> void:
	# Defensive: a silent tap must not leave the player in a "played" state — otherwise
	# a later reader (or a re-fire) could mistake a dead tap for a mark.
	var p := _player()
	p.play(MarkPayoff.for_tier(SitWindow.Tier.PERFECT))
	assert_true(p.last_played, "PERFECT set played")
	p.play(MarkPayoff.for_tier(SitWindow.Tier.DEAD))
	assert_false(p.last_played, "a following DEAD tap clears the played flag")
	p.queue_free()
