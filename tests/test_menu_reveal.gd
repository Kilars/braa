extends "res://tests/test_case.gd"
## Progressive disclosure of the completion menu (127, PO Phase-10 Menu #2 — "reveal it as a story,
## not all at once"). MenuReveal holds the pure reveal predicates: which sections main FEEDS into the
## dumb menu renderer, staggered so one new beat lands per mastery instead of a settings dump on the
## first open. The renderer already collapses an unfed section to zero height (and the showcase row
## hides with empty breeds), so gating the feed IS the disclosure — these pin the thresholds
## render-free. The wiring INTO main (feed [] until revealed) is proven by the fresh-player boot.

# ---- marker words: reveal once the first alternate word is unlocked (payoff of mastery #1) ----

func test_words_hidden_before_first_alt_word() -> void:
	assert_false(MenuReveal.reveal_words(0), "no alternate word unlocked → words section stays hidden")

func test_words_revealed_at_first_alt_word() -> void:
	assert_true(MenuReveal.reveal_words(1), "first alternate word unlocked → words section reveals")
	assert_true(MenuReveal.reveal_words(4), "still revealed once more words unlock")

# ---- difficulty: a tuning system, surfaced once the loop is understood (mastery #2), not on #1 ----

func test_difficulty_hidden_on_first_reward() -> void:
	assert_false(MenuReveal.reveal_difficulty(0), "brand new → difficulty hidden")
	assert_false(MenuReveal.reveal_difficulty(1), "first mastery reward stays calm — difficulty still hidden")

func test_difficulty_revealed_after_two_masteries() -> void:
	assert_true(MenuReveal.reveal_difficulty(2), "second mastery surfaces the difficulty selector")
	assert_true(MenuReveal.reveal_difficulty(3), "still revealed deeper in")

# ---- breeds: reveal once adoption is actually meaningful (can afford, or already owns > 1) ----

func test_breeds_hidden_until_affordable() -> void:
	assert_false(MenuReveal.reveal_breeds(0, 1, 30), "0 coins, one dog → adoption not yet meaningful")
	assert_false(MenuReveal.reveal_breeds(29, 1, 30), "just short of the price → still hidden")

func test_breeds_revealed_when_affordable() -> void:
	assert_true(MenuReveal.reveal_breeds(30, 1, 30), "can afford the adopt cost → breeds reveals")

func test_breeds_revealed_when_owns_more_than_one() -> void:
	assert_true(MenuReveal.reveal_breeds(0, 2, 30), "already owns a second dog → breeds stays revealed even when broke")

# ---- locked roadmap tricks: tease sparingly, not fully enumerated ----

func test_teased_locked_shows_exactly_one() -> void:
	var teased := MenuReveal.teased_locked(["gi_labb", "rull", "snurr"])
	assert_eq(teased.size(), 1, "tease exactly one future trick, not all three")
	assert_eq(teased[0], "gi_labb", "the FIRST roadmap trick is the one teased (order preserved)")

func test_teased_locked_never_exceeds_list() -> void:
	assert_eq(MenuReveal.teased_locked([]).size(), 0, "nothing to tease from an empty roadmap")
	assert_eq(MenuReveal.teased_locked(["only"]).size(), 1, "a single-entry roadmap teases that one")
