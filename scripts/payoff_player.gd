class_name PayoffPlayer
extends Node
## The audible half of the mark payoff (specs2.md P1-6, task 024f). A dumb player:
## MarkPayoff (the pure decision) says WHAT fires and how bright; this node owns the
## AudioStreamPlayers and just plays the click + voice at the chosen loudness, and ONLY
## when the payoff plays() — so a MISS/DEAD mark makes no sound (the gate lives in
## MarkPayoff, proven in test_mark_payoff; this node honours it in test_payoff_player).
##
## The cues are honest, generatable PLACEHOLDERS synthesized in code — a crisp UI click
## and a short warm "bra" blip — not a real recording. The owner's Maren "Bra!" is an
## asset drop-in under MarkPayoff's stable voice cue id; until it lands the blip stands
## in, clearly labelled. PERFECT plays louder (and a touch higher) than OK so it reads
## brighter, mapped straight off MarkPayoff.brightness — this node adds no policy of its
## own, which keeps the "fair / brighter-on-PERFECT" contract testable in one place.
##
## NOTE the same asset gate as the rest of Phase 1: a success only fires on a real mark,
## and on the deployed CC0 dog (no Sitt) every tap is DEAD, so this is silent on the live
## site until 025/ADR-0006 ships the sit-capable Labrador — exactly like the tell (024d)
## and the taps (024e). The cues are exercised here by the tests and by any sit-capable dog.

const MIX_RATE := 22050  ## placeholder cues are low-fi by design — they're stand-ins

# Voice level: PERFECT (brightness 1) at full; OK a few dB down. Brighter == louder.
const VOICE_BASE_DB := 0.0
const VOICE_RANGE_DB := 10.0
# The click sits just under the voice and tracks the same brightness.
const CLICK_BASE_DB := -4.0
const CLICK_RANGE_DB := 6.0

var _voice: AudioStreamPlayer
var _click: AudioStreamPlayer

# Render-free introspection of the last play() — the tests assert the gate through
# these without needing an audio device (mirrors ApexTellMarker.is_showing).
var last_played: bool = false   ## did the most recent play() actually fire sound
var last_cue: String = ""       ## the voice cue id of the most recent play()
var last_brightness: float = 0.0

func _init() -> void:
	# Build the players + their cues now, but DON'T parent them yet: children added
	# during _init never receive ENTER_TREE, so they'd be un-playable. They're attached
	# lazily on the first real play(), when this node is fully in the tree (see below).
	_voice = AudioStreamPlayer.new()
	_voice.name = "Voice"
	_voice.stream = _voice_blip()
	_click = AudioStreamPlayer.new()
	_click.name = "Click"
	_click.stream = _click_blip()

## Play the reward for a scored mark. Silent unless MarkPayoff.plays() (a successful
## mark), so a MISS/DEAD tap provably makes no sound (P1-6). Loudness and pitch come
## straight from MarkPayoff.brightness: PERFECT louder + a touch higher than OK.
func play(payoff: MarkPayoff) -> void:
	last_cue = payoff.voice_cue
	last_brightness = payoff.brightness
	if not payoff.plays():
		last_played = false
		return
	last_played = true
	_ensure_attached()
	var b := payoff.brightness
	# Set the policy (loudness/pitch) unconditionally — it's what the unit tests read —
	# but only sound when the players are actually in a running tree. In the headless
	# test harness the tree isn't running, so play() there would just error; the cue
	# physically sounds in production (and on any sit-capable dog), where they're in-tree.
	_voice.volume_db = VOICE_BASE_DB - VOICE_RANGE_DB * (1.0 - b)
	_voice.pitch_scale = 0.94 + 0.12 * b
	_click.volume_db = CLICK_BASE_DB - CLICK_RANGE_DB * (1.0 - b)
	if _voice.is_inside_tree():
		_voice.play()
	if _click.is_inside_tree():
		_click.play()

## Parent the audio players the first time a real cue fires, when this node is fully
## in the tree (AudioStreamPlayer.play() requires tree membership, and children added
## back in _init never get ENTER_TREE). A no-op once attached, so it stays cheap.
func _ensure_attached() -> void:
	if _voice.get_parent() == null and is_inside_tree():
		add_child(_voice)
		add_child(_click)

## The voice player's current level — tests assert PERFECT plays louder than OK.
func voice_volume_db() -> float:
	return _voice.volume_db

## True while the voice cue is sounding — tests assert it stays idle on a MISS/DEAD.
func is_voicing() -> bool:
	return _voice.playing

func voice_stream() -> AudioStream:
	return _voice.stream

func click_stream() -> AudioStream:
	return _click.stream

## A short, warm "bra" placeholder: a quick low syllable settling a touch higher.
## Clearly a stand-in, not a real voice — it plays under MarkPayoff's stable cue id
## so the owner's Maren clip is a drop-in replacement with no code change.
func _voice_blip() -> AudioStreamWAV:
	return _synth([
		{ "freq": 300.0, "until": 0.10 },
		{ "freq": 370.0, "until": 0.34 },
	], 0.34)

## A crisp, very short UI click — a high blip with a fast decay, "under the voice".
func _click_blip() -> AudioStreamWAV:
	return _synth([{ "freq": 1100.0, "until": 0.05 }], 0.05)

## Synthesize a mono 16-bit placeholder cue from a list of {freq, until} segments
## (freq held until the given time). Phase is accumulated across segments so there's
## no click at a frequency change; an attack + exponential-decay envelope shapes it
## into a friendly blip with clean edges. Real audio, generated — not a faked asset.
func _synth(segments: Array, total_secs: float) -> AudioStreamWAV:
	var n := int(total_secs * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / MIX_RATE
		phase += TAU * _freq_at(segments, t) / MIX_RATE
		var env := minf(1.0, t * 120.0) * exp(-t * 5.0)
		var s := sin(phase) * env * 0.85
		bytes.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	wav.data = bytes
	return wav

func _freq_at(segments: Array, t: float) -> float:
	for seg in segments:
		if t < seg.until:
			return seg.freq
	return segments[segments.size() - 1].freq
