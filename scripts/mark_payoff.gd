class_name MarkPayoff
extends RefCounted
## The payoff decision for one BRA mark (specs2.md P1-6, task 024f). Pure + testable.
##
## When the player marks the apex the reward must land — a warm "Bra!", a crisp click,
## and the dog reacting — but ONLY on a real mark. MarkPayoff is the single source of
## truth for that beat: given the scored tier (SitWindow.Tier, 024a) it decides whether
## the voice / click / dog reaction fire and how BRIGHT, and gates every cue off the one
## SitWindow.is_successful truth. So a MISS or DEAD tap is provably silent (no false
## reward, P1-6). The node layer — payoff_player.gd for the audio, the director's
## reaction for the dog — is a dumb renderer of this; all the "what fires and how loud"
## lives here, unit-tested, so the audio can never diverge from what counts as a mark.
##
## The voice cue id is STABLE per tier so the owner's real Maren "Bra!" drops in under
## the same id with zero code change — today payoff_player stands in a clearly-labelled
## synthesized placeholder blip under that id (the real voice is owner-gated).

# Stable voice cue ids — the owner's Maren clips drop in under these exact ids.
const VOICE_PERFECT := "voice_bra_perfect"
const VOICE_OK := "voice_bra_ok"
const VOICE_SILENT := ""

# Brightness per success tier (the player maps it to louder/crisper/bigger): PERFECT
# reads brighter than OK, but both are positive — a real reward, not a shrug.
const BRIGHT_PERFECT := 1.0
const BRIGHT_OK := 0.6

var tier: SitWindow.Tier
var is_success: bool   ## == SitWindow.is_successful(tier); the one gate every cue obeys
var voice_cue: String  ## stable cue id to speak, or "" when nothing should speak
var brightness: float  ## [0,1]; PERFECT brighter than OK; exactly 0 on MISS/DEAD

func _init(p_tier: SitWindow.Tier) -> void:
	tier = p_tier
	is_success = SitWindow.is_successful(p_tier)
	match p_tier:
		SitWindow.Tier.PERFECT:
			voice_cue = VOICE_PERFECT
			brightness = BRIGHT_PERFECT
		SitWindow.Tier.OK:
			voice_cue = VOICE_OK
			brightness = BRIGHT_OK
		_:
			voice_cue = VOICE_SILENT
			brightness = 0.0

## Named constructor mirroring SitWindow's builders — reads as "the payoff for tier".
static func for_tier(p_tier: SitWindow.Tier) -> MarkPayoff:
	return MarkPayoff.new(p_tier)

## Whether ANY cue fires — the single gate the voice, click and reaction all obey.
## False on MISS and DEAD, so the payoff is provably silent there (P1-6).
func plays() -> bool:
	return is_success

## Whether the dog gives its positive reaction — the same success gate as the audio,
## named for the wiring that drives the director (P1-6).
func reacts() -> bool:
	return is_success
