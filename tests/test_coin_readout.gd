extends "res://tests/test_case.gd"
## The coin readout (069, Phase-3 P3-D3). CoinReadout is the dumb on-screen balance widget that
## replaces the 068 emoji Label. Two pure seams are locked here (the drawn coin + placement are
## Visual Review): the balance→text mapping shows ASCII digits and NEVER the 🪙 tofu emoji, and the
## widget sits on its own top line so it can never collide with the HUD stacked below it.
##
## No framebuffer needed — the text is read off the pure static balance_text(), and the non-overlap
## is a pure arithmetic invariant over main.gd's layout constants (read via preload, no scene boot).

const MainScript := preload("res://scripts/main.gd")

func test_balance_text_is_ascii_digits_never_the_tofu_emoji() -> void:
	# Bug 1: the 068 readout drew "%d 🪙" and the 🪙 (U+1FA99) had no glyph -> a tofu box. The
	# balance text must be plain digits and must never contain that emoji again.
	assert_eq(CoinReadout.balance_text(0), "0", "zero balance reads as '0'")
	assert_eq(CoinReadout.balance_text(10), "10", "ten reads as '10'")
	assert_eq(CoinReadout.balance_text(999), "999", "large balance reads as its digits")
	assert_false(CoinReadout.balance_text(10).contains("🪙"),
		"balance text never contains the 🪙 tofu emoji (U+1FA99)")

func test_negative_balance_never_shown():
	# The purse never goes negative; the readout floors a stray negative at 0 rather than "-1".
	assert_eq(CoinReadout.balance_text(-5), "0", "a negative balance reads as '0', never '-5'")

func test_set_balance_clamps_and_reads_back() -> void:
	var r := CoinReadout.new()
	r.set_balance(12)
	assert_eq(r.balance(), 12, "set_balance stores the balance")
	r.set_balance(-3)
	assert_eq(r.balance(), 0, "set_balance floors a negative at 0")
	r.free()

func test_coin_line_sits_clear_of_the_hud_below() -> void:
	# The coin readout keeps its OWN top line: its foot must end above the learned bar that stacks
	# below it, so the balance never collides with the HUD beneath. (072 retired the always-on chip
	# row that used to sit here; the learned bar now anchors directly under the coin line.)
	var coin_foot: float = MainScript.COIN_READOUT_TOP + CoinReadout.HEIGHT
	assert_true(coin_foot <= MainScript.LEARNED_BAR_OFFSET_TOP,
		"coin readout foot (%.1f) is above the learned bar top (%.1f) — no overlap"
			% [coin_foot, MainScript.LEARNED_BAR_OFFSET_TOP])
