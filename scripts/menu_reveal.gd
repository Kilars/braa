class_name MenuReveal
extends RefCounted
## Progressive disclosure of the completion menu (127, PO Phase-10 Menu #2).
##
## The completion menu (trick_menu.gd) is a dumb renderer: every section collapses to zero height
## when main feeds it an empty array (and the "Vis frem hundene" showcase row already hides with
## empty breeds). So WHICH sections main feeds IS the disclosure. These pure predicates hold the
## reveal thresholds, staggered so one earned beat lands per mastery instead of a settings dump on
## the first open — the North-Star "single satisfying tap" stays calm and the menu grows with the
## player. No render, no state — unit-locked in tests/test_menu_reveal.gd.

## Marker-words section: reveal once the first alternate word is unlocked — the payoff of mastery #1
## ("you earned a new word!"). Before that the base "bra" is the only word; a one-row section would
## just be noise.
static func reveal_words(unlocked_alt_count: int) -> bool:
	return unlocked_alt_count >= 1

## Difficulty (Vanskelighet) section: a tuning system, not a reward — surface it once the player has
## the core loop under their belt (second mastery), so it never crowds the first reward moment.
static func reveal_difficulty(mastered_count: int) -> bool:
	return mastered_count >= 2

## Breeds section (+ its showcase row): reveal once adoption is actually MEANINGFUL — the player can
## afford the adopt cost, or already owns more than the starter dog. Naturally lands around mastery #3
## (3×10 coins = the adopt price), so it reads as the next earned beat.
static func reveal_breeds(balance: int, owned_count: int, adopt_cost: int) -> bool:
	return owned_count > 1 or balance >= adopt_cost

## Locked roadmap tricks (gi_labb/rull/snurr are never trainable): tease sparingly, not fully
## enumerated — show just the next one as a "coming soon" beat instead of dumping every future system.
static func teased_locked(all_locked: Array, max_tease := 1) -> Array:
	return all_locked.slice(0, min(max_tease, all_locked.size()))
