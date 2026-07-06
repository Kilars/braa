extends "res://tests/test_case.gd"
## TDD for kennel modal CTA label helper (135, K-7 CTA states). The adopt button shows
## different labels depending on affordability: when affordable, "Adopter  N mynt" in
## full Bra-Blue + white; when not, a greyed disabled token with "Har ikke råd · mangler N"
## showing the coin shortfall. This pure static helper maps price/balance/affordable → label.

func test_affordable_priced_dog_shows_adopter_label() -> void:
	## When a dog is affordable (affordable==true), the label shows "Adopter  " + price + " mynt"
	## (note the two spaces between "Adopter" and the price, matching the existing label format).
	var label: String = KennelScreen.adopt_button_label(300, 500, true)
	assert_eq(label, "Adopter  300 mynt", "affordable dog (price=300, balance=500) shows 'Adopter  300 mynt'")

func test_unaffordable_shows_shortfall_label() -> void:
	## When not affordable (affordable==false), the label shows "Har ikke råd · mangler " + shortfall.
	## Shortfall = price - balance (e.g. 300 - 0 = 300 coins short).
	var label: String = KennelScreen.adopt_button_label(300, 0, false)
	assert_eq(label, "Har ikke råd · mangler 300", "unaffordable dog (price=300, balance=0) shows shortfall of 300")

func test_unaffordable_partial_balance_shows_remaining_shortfall() -> void:
	## When the player has partial coins but still can't afford, the shortfall is price - balance.
	## E.g. price=300, balance=120 → shortfall = 300-120 = 180.
	var label: String = KennelScreen.adopt_button_label(300, 120, false)
	assert_eq(label, "Har ikke råd · mangler 180", "unaffordable partial (price=300, balance=120) shows shortfall of 180")

func test_shortfall_never_negative_guards_edge_case() -> void:
	## Guard: if price <= balance, the shortfall should never go negative. Edge case where
	## balance==price (player has exactly enough but affordable==false, defensive).
	var label: String = KennelScreen.adopt_button_label(50, 50, false)
	assert_eq(label, "Har ikke råd · mangler 0", "shortfall floors at 0 when balance==price (edge case)")
