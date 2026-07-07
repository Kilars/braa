extends "res://tests/test_case.gd"
## TDD for the kennel price/CTA coin component (146, X-4). Prices must render with the SAME coin
## component as the readout (a drawn gold coin + number), not a bare number. Two pure helpers back
## the render glue:
##   - price_shows_coin(row)  → does a grid price tag draw the coin? (buyable numeric price only)
##   - adopt_button_parts(...) → splits the adopt CTA into (prefix words, coin amount) so the modal
##     action draws [prefix][coin][amount]; amount == -1 → no coin (the free case).

# --- adopt_button_parts (modal action) ---------------------------------------

func test_affordable_priced_dog_splits_into_prefix_and_amount() -> void:
	## Affordable + priced → «Adopter» prefix + the price as a coin amount (the coin conveys the
	## unit, so the old trailing " mynt" word is dropped).
	var parts := KennelScreen.adopt_button_parts(300, 500, true)
	assert_eq(parts["prefix"], "Adopter", "affordable prefix is 'Adopter'")
	assert_eq(parts["amount"], 300, "affordable amount is the price (300)")

func test_unaffordable_splits_into_shortfall_amount() -> void:
	## Not affordable → «Har ikke råd · mangler» prefix + the shortfall (price − balance) as a coin.
	var parts := KennelScreen.adopt_button_parts(300, 0, false)
	assert_eq(parts["prefix"], "Har ikke råd · mangler", "unaffordable prefix names the shortfall")
	assert_eq(parts["amount"], 300, "unaffordable amount is the full shortfall (300)")

func test_unaffordable_partial_balance_shortfall() -> void:
	var parts := KennelScreen.adopt_button_parts(300, 120, false)
	assert_eq(parts["amount"], 180, "shortfall = price − balance (300−120 = 180)")

func test_shortfall_never_negative() -> void:
	var parts := KennelScreen.adopt_button_parts(50, 50, false)
	assert_eq(parts["amount"], 0, "shortfall floors at 0 when balance == price")

func test_free_affordable_shows_no_coin_amount() -> void:
	## A price-0 affordable dog gets no coin (amount == -1) — nothing to charge.
	var parts := KennelScreen.adopt_button_parts(0, 500, true)
	assert_eq(parts["prefix"], "Adopter", "free dog still says 'Adopter'")
	assert_eq(parts["amount"], -1, "free dog has no coin amount (-1)")

# --- price_shows_coin (grid tag) ---------------------------------------------

func test_buyable_dog_price_shows_coin() -> void:
	## A buyable dog (not owned, not secret) renders its numeric price with the coin component.
	assert_true(KennelScreen.price_shows_coin({"owned": false, "secret": false}),
		"buyable dog draws the coin on its price tag")

func test_owned_dog_price_shows_no_coin() -> void:
	## Owned shows the «Din» status word, not a price → no coin.
	assert_false(KennelScreen.price_shows_coin({"owned": true, "secret": false}),
		"owned dog («Din») is a status word, not a coin price")

func test_secret_dog_price_shows_no_coin() -> void:
	## Secret shows «Gratis» → no coin.
	assert_false(KennelScreen.price_shows_coin({"owned": false, "secret": true}),
		"secret dog («Gratis») is a status word, not a coin price")
