class_name TrickMenu
extends Control
## The completion menu (072, Phase-3 PO note 1). The game trains ONE active trick at a time; when that
## trick is mastered this modal pops up showing the whole collection — the just-learned trick as
## Learned, the other performable tricks as Available (tap one to train it next), the earned COIN
## balance, and the genuinely-absent tricks as Locked/unavailable (greyed, never tappable, never a
## faked clip — the never-fake honesty gate, BUST-064 residual). It supersedes the always-on 066 chip
## row: picking a trick is now this between-rounds surface, not a permanent second in-round verb.
##
## Same dumb-renderer split the rest of the HUD uses (TrickSelector / CoinReadout / LearnedBar): main
## decides the rows + the balance and feeds them in via set_rows(); this node only draws the modal and
## maps a tap to a trick id. So the classify split + the row hit-map + the signals are unit-testable
## render-free (static classify / id_at / a constructed InputEvent — no framebuffer), and the routing
## INTO the game (open on mastery, pause offers, select_trick) lives in main and is scene-tested.

## A performable trick was tapped — main.select_trick() consumes it. Only Learned/Available rows emit.
signal trick_chosen(id: String)
## The menu was dismissed without switching (the close affordance or a tap on the dimmed backdrop) —
## main hides it and resumes training the CURRENT trick.
signal dismissed

## An OWNED, non-active breed row was tapped — main.select the active breed (switch which dog runs).
signal breed_chosen(id: String)
## A BUYABLE (affordable, unowned) breed row was tapped — main spends the coins + adopts it. An
## unaffordable (Locked) or already-active breed absorbs the tap and emits nothing (no debt, no switch).
signal breed_adopt(id: String)
## An UNLOCKED, non-active marker word was tapped — main.set_active + re-point the payoff clip.
## ACTIVE (already active) and LOCKED (not yet unlocked) rows absorb the tap and emit nothing.
signal word_chosen(id: String)
## The "Give feedback" row was tapped — main opens the FeedbackFormView modal over this menu.
## The menu itself stays dumb: it only emits; main holds the form and routes the submit through _telem.
signal feedback_requested

## The "Vis frem hundene" (show off my dogs) row was tapped — main opens the spotlit BreedShowcaseView
## over this menu (087, P3-4). Shown only when there are breeds; the menu stays dumb (only emits).
signal showcase_requested

## A selectable difficulty-mode row was tapped (118, P4-1) — main.set the global difficulty + re-apply
## the levers live. The active mode (already selected) and, when the active dog LOCKS difficulty (119),
## every row absorb the tap and emit nothing — the menu stays dumb (only emits, main decides).
signal difficulty_chosen(id: String)

## Each known trick's standing in the collection. LOCKED covers both the owner-gated absent tricks and
## anything the loaded dog simply can't perform (the honest CC0 read) — neither is ever trainable.
## ACTIVE = the trick currently being trained (the HUD's trick) — muted + non-tappable, absorbs its
## tap (mirrors BreedState.ACTIVE / WordState.ACTIVE + the kennel's «Trener nå», 151/152). Appended so
## the existing LEARNED/AVAILABLE/LOCKED ordinals are unchanged.
enum State { LEARNED, AVAILABLE, LOCKED, ACTIVE }

## Each breed's standing in the roster (079, P3-D3/P3-4). ACTIVE = the running dog (absorbs a tap);
## OWNED = adopted but not active (tap → switch); BUYABLE = unowned + affordable (tap → adopt, spends
## coins); LOCKED = unowned + can't-afford (absorbs a tap — priced, no debt). Only OWNED/BUYABLE emit.
enum BreedState { ACTIVE, OWNED, BUYABLE, LOCKED }

## Each marker word's standing in the player's collection (092, P5-4). ACTIVE = the word that fires
## at the mark (absorbs a tap — already firing); UNLOCKED = unlocked by mastery, not yet active
## (tap → switch the active word); LOCKED = not yet earned (greyed, absorbs a tap — no faked clip).
## Only UNLOCKED rows emit word_chosen.
enum WordState { ACTIVE, UNLOCKED, LOCKED }

## Player-facing names, keyed by the stable trick ids (the three wired tricks + the BUST-064 roadmap
## residual so the Locked rows read honestly). A new trick is a one-line add, mirroring TrickSelector.
const LABELS := {
	DogClips.TRICK_SITT: "Sitt",
	DogClips.TRICK_LIGG: "Ligg",
	DogClips.TRICK_LEGG_DEG: "Legg deg",
	"gi_labb": "Gi labb",
	"rull": "Rull",
	"snurr": "Snurr",
}

## The state badge each row shows to its right.
const BADGE := {
	State.LEARNED: "Lært",
	State.AVAILABLE: "Tilgjengelig",
	State.LOCKED: "Låst",
	State.ACTIVE: "Trener nå",   ## the trick you're training now — same wording the kennel uses (151)
}

## Layout, homed here (no scattered literals — cf. 029). Design space; the panel centres in whatever
## size main anchors (full-screen). Row/close geometry is derived from these so the hit-map and _draw
## agree on exactly one layout.
const PANEL_MARGIN_X := 28.0    ## min gutter from the screen edges to the panel
const PANEL_MAX_W := 340.0      ## the panel never grows wider than this (reads centred on a phone)
const PANEL_PAD := 20.0         ## inner padding inside the panel
const HEADER_H := 76.0          ## the coins + "Tricks" title band
const ROW_H := 58.0             ## one trick row
const ROW_GAP := 8.0            ## gutter between rows
const CLOSE_GAP := 16.0         ## gap above the close button
const CLOSE_H := 54.0           ## the "Keep training" close button
## The "Show off my dogs" row (087, P3-4) sits between the breeds section and the feedback row — it
## opens the spotlit showcase. Shown only when there are breeds (zero-height otherwise), so the
## trick-only menu (072) geometry is unchanged.
const SHOWCASE_GAP := 14.0      ## gutter above the showcase pill
const SHOWCASE_H := 48.0        ## the "Vis frem hundene" pill button height
## The "Give feedback" row sits just above the close button so it is always reachable (085, X-8).
const FEEDBACK_GAP := 10.0      ## gutter between the feedback row and the close button
const FEEDBACK_H := 48.0        ## the "Give feedback" pill button height
const RADIUS := 18.0            ## panel corner radius
## The breeds section (079): a small "Breeds" subheading + one row per shipped breed, seated between the
## trick rows and the close button. Zero-height when there are no breeds, so the trick-only geometry the
## 072 tests pin is unchanged.
const BREEDS_GAP := 18.0        ## gutter between the trick block and the breeds section
const BREED_HEADER_H := 30.0    ## the "Breeds" subheading band
const BREED_ROW_H := 54.0       ## one breed row (swatch + name + state/price)
const BREED_ROW_GAP := 8.0      ## gutter between breed rows
const SWATCH_R := 13.0          ## the honest coat-colour chip radius

## The marker words section (092, P5-4; typography 134): a distinct Baloo-2 heading + a divider rule
## + one row per catalog word, seated between the breeds section and the showcase/footer pills.
## Zero-height when no words are fed, so the trick-only + breeds-only geometry is unchanged.
const WORDS_GAP := 18.0          ## gutter above the divider rule (from the breeds section, or trick rows if no breeds)
const WORD_DIVIDER_H := 1.0      ## hairline divider rule height (134: section break before the heading)
const WORD_DIVIDER_GAP := 8.0    ## gap between the divider rule and the heading text
const WORD_HEADER_H := 38.0      ## the "Marker words" heading band — taller for the Baloo-2 display heading (was 30)
const WORD_ROW_H := 54.0         ## one word row (display text + state badge)
const WORD_ROW_GAP := 8.0        ## gutter between word rows
const WORD_ROW_INDENT := 8.0     ## extra left indent for marker-word rows (134: visually distinct from trick rows)
const WORD_PIP_R := 3.0          ## leading pip radius — small filled circle at the left of each word row (134)

## The difficulty section (118, P4-1): a small "Vanskelighet" subheading + one row per mode
## (Normal/Hard/Expert), seated between the marker-words section and the showcase/footer pills.
## Zero-height when no difficulty rows are fed, so the trick-only (072) / breeds (079) / words (092)
## geometry is all unchanged when the section is absent.
const DIFFICULTY_GAP := 18.0    ## gutter above the "Vanskelighet" subheading
const DIFFICULTY_HEADER_H := 30.0  ## the "Vanskelighet" subheading band
const DIFFICULTY_ROW_H := 54.0  ## one difficulty row (name + active/locked badge)
const DIFFICULTY_ROW_GAP := 8.0 ## gutter between difficulty rows
const DIFFICULTY_NOTE_H := 22.0  ## the locked-section reason note band (122) — reserved only when locked

## Type sizes — DS tokens (DesignSystem.T_*), not ad-hoc literals.
## TITLE_SIZE: Baloo 2 SemiBold heading (T_TITLE=26) for the "Tricks" panel title.
## NAME_SIZE: Nunito Bold row name at heading scale (T_TITLE=26 — a DS section/row heading).
## BADGE_SIZE: Baloo 2 sub-heading / badge scale (T_HEAD=18).
## HINT_SIZE: Nunito secondary caption for cost/trade sub-labels (T_SMALL=13 — ≥12px per spec).
## CLOSE_SIZE: CTA button label — one step above BADGE so the primary action reads dominant.
const TITLE_SIZE := DesignSystem.T_TITLE   ## 26 px — Baloo 2 heading (panel title)
const NAME_SIZE  := DesignSystem.T_TITLE   ## 26 px — Nunito Bold row name
const BADGE_SIZE := DesignSystem.T_HEAD    ## 18 px — badge / sub-heading
const HINT_SIZE  := DesignSystem.T_SMALL   ## 13 px — secondary caption (cost / trade hint) ≥12px
const CLOSE_SIZE := DesignSystem.T_TITLE   ## 26 px — primary CTA label

## Palette — DS tokens (098, Phase 6). SLATE-on-PAPER, BLUE primary accent, GOLD reserved for coin.
## BACKDROP: soft INK-based veil, not pure black.
const BACKDROP := Color(DesignSystem.INK.r, DesignSystem.INK.g, DesignSystem.INK.b, 0.45)
## Panel card: PAPER surface with hairline BORDER — drawn via DesignSystem.panel(PAPER, R_LG).
const PANEL_BG := DesignSystem.PAPER
const PANEL_BORDER := DesignSystem.BORDER
const TITLE_COLOR := DesignSystem.SLATE
## Row backgrounds: a light CREAM fill for active/available rows, a near-invisible tint for locked.
const ROW_BG := DesignSystem.CREAM
const ROW_BG_LOCKED := Color(DesignSystem.SLATE_SOFT.r, DesignSystem.SLATE_SOFT.g, DesignSystem.SLATE_SOFT.b, 0.08)
## Trick name colours: BLUE_INK (AA-legible blue text on light, 154) for active/learned (primary
## accent), SLATE for available, SLATE_SOFT for locked. Plain BLUE is a fill accent — on the CREAM
## row it reads ~2.9:1 and fails WCAG AA, so all blue-on-CREAM TEXT uses the deeper BLUE_INK.
const NAME_LEARNED := DesignSystem.BLUE_INK
const NAME_AVAILABLE := DesignSystem.SLATE
const NAME_LOCKED := DesignSystem.SLATE_SOFT
## Badge colours: BLUE_INK for learned/available (AA on CREAM), SLATE_SOFT for locked.
const BADGE_LEARNED := DesignSystem.BLUE_INK
const BADGE_AVAILABLE := DesignSystem.BLUE_INK
const BADGE_LOCKED := DesignSystem.SLATE_SOFT
## The ACTIVE (currently-trained) trick row (152, X-6): the 151 owned-status treatment carried into
## the trick selector so all four selection surfaces (tricks·breeds·words·kennel) read as one system.
## A muted, OPAQUE pale-BLUE wash (non-tappable — it must NOT look like a live pressable button) with a
## dark ink label + badge that clears WCAG AA on that wash (the legibility bar the loop set in 149/151).
const ROW_BG_ACTIVE := Color(0.902, 0.933, 0.988)   ## opaque pale-blue wash (CREAM lerped toward BLUE ~14%)
const ROW_ACTIVE_INK := Color("141c26")             ## the shared dark status/badge ink (== kennel C_TAG_INK)
## Coin GOLD reserved for the Buyable breed-price PIP (a real coin glyph) — never the text.
## The header balance is the shared CoinReadout pill (129); the price badge draws its own small
## gold coin disc, exactly like the kennel _make_price_chip. GOLD is intrinsically too light to
## read as TEXT on the CREAM row (~1.55:1, sub-AA), so the price WORDS/number use a dark ink.
const COIN_GOLD := DesignSystem.GOLD
## The buyable «Adopter 30» price-badge TEXT ink (162, PO father-pass-27, X-6). Was COIN_GOLD —
## gold-on-cream ~1.55:1 failed WCAG AA. SLATE #5a6b7d clears 4.78:1 on the CREAM row and is the
## SAME ink the buyable breed NAME already uses (BREED_NAME_BUYABLE), so the row reads as one.
const BADGE_PRICE_INK := DesignSystem.SLATE
## The price-badge coin pip radius + gap — small gold disc drawn before the text (kennel pattern).
const PRICE_PIP_R := 6.0
const PRICE_PIP_GAP := 5.0
## Action button colours. The primary CTA ("Fortsett treningen") is drawn with the SAME raised-blue
## gradient treatment as the BRA button (130, via DesignSystem.gradient_pill), so the two dominant
## actions read identically — not the old flat pale-BLUE pill that read as secondary. White ≥700 label.
const CLOSE_TEXT := DesignSystem.PAPER
## The CTA gradient corner radius — R_MD-scale so it matches the footer pills' rounding, baked into
## the gradient texture (the shared baker is radius-parameterized). Kept modest so the CTA reads as a
## footer button, not the hero BRA band (which uses the much larger BRA_PILL_RADIUS).
const CLOSE_GRAD_RADIUS := 16.0
## Softer shadow/lip numbers than the hero BRA button — this is a footer CTA on a paper card, so the
## raised effect is present but restrained (shorter lip, shorter/softer shadow, smaller pad).
const CLOSE_GRAD_PAD := 22
const CLOSE_GRAD_LIP_H := 8.0
const CLOSE_GRAD_SHADOW_DY := 8.0
const CLOSE_GRAD_SHADOW_BLUR := 18.0
const CLOSE_GRAD_SHADOW_MAX := 0.22
## Secondary footer pills (feedback / showcase) — demoted to a clear GHOST style so they never
## compete with the primary CTA: PAPER fill, a Bra-Blue hairline outline, Bra-Blue text.
const SECONDARY_BG := DesignSystem.PAPER          ## paper fill (was CREAM) — lighter than the CTA
const SECONDARY_TEXT := DesignSystem.BLUE_INK     ## Bra-Blue text (154: BLUE_INK, AA-legible on PAPER) — reads as a link/ghost action
const SECONDARY_OUTLINE := DesignSystem.BLUE_INK  ## deeper Bra-Blue hairline outline on the ghost pill — matches the darker label (154)
const SECONDARY_OUTLINE_W := 2.0                  ## outline thickness (px, design space)

## Section heading labels — all Norwegian (138), homed as named consts (no scattered literals).
## LABEL_TITLE: the panel title the «Triks» HUD pill opens (was «Tricks»).
## LABEL_BREEDS / LABEL_WORDS: the breeds + marker-words section subheadings (were «Breeds» / «Marker words»).
const LABEL_TITLE     := "Triks"
const LABEL_BREEDS    := "Raser"
const LABEL_WORDS     := "Markørord"

## Action button labels — all Norwegian, homed as named consts (no scattered literals).
const LABEL_SHOWCASE  := "Vis frem hundene"
const LABEL_FEEDBACK  := "Gi tilbakemelding"
const LABEL_CLOSE     := "Fortsett treningen"

## Breed-row palette + badges (079, DS restyle 098).
const BREED_BADGE := {
	BreedState.ACTIVE: "Aktiv",
	BreedState.OWNED: "Bytt",
	BreedState.BUYABLE: "Adopter",
	BreedState.LOCKED: "Låst",
}
const BREED_NAME_ACTIVE  := DesignSystem.BLUE_INK    ## the running dog — primary accent (154: BLUE_INK, AA on CREAM)
const BREED_NAME_OWNED   := DesignSystem.SLATE       ## owned, tap to switch — slate body text
const BREED_NAME_BUYABLE := DesignSystem.SLATE       ## affordable — slate body text
const BREED_NAME_LOCKED  := DesignSystem.SLATE_SOFT  ## can't afford — greyed, clearly not tappable
const BREED_SUBHEAD      := DesignSystem.SLATE_SOFT  ## the "Breeds" subheading — secondary
const SWATCH_RIM         := DesignSystem.BORDER      ## hairline rim so a pale coat chip reads on paper

## Marker-word-row palette + badges (092, DS restyle 098).
const WORD_BADGE := {
	WordState.ACTIVE:   "Aktiv",
	WordState.UNLOCKED: "Bytt",
	WordState.LOCKED:   "Låst",
}
const WORD_NAME_ACTIVE   := DesignSystem.BLUE_INK    ## the firing word — primary accent (154: BLUE_INK, AA on CREAM)
const WORD_NAME_UNLOCKED := DesignSystem.SLATE       ## switchable — slate body text
const WORD_NAME_LOCKED   := DesignSystem.SLATE_SOFT  ## not yet earned — greyed, clearly not tappable
const WORD_SUBHEAD       := DesignSystem.SLATE_SOFT  ## the "Marker words" subheading — secondary
const WORD_COST_HINT     := DesignSystem.SLATE  ## cost hint (095, P5-2) — Ink-Soft #5A6B7D, legible ≥12px (task 134)

## Difficulty-row palette + badges (118, DS tokens). Mirrors the breed/word row treatment.
const DIFF_SUBHEAD       := DesignSystem.SLATE_SOFT  ## the "Vanskelighet" subheading — secondary
const DIFF_NAME_ACTIVE   := DesignSystem.BLUE_INK    ## the selected mode — primary accent (154: BLUE_INK, AA on CREAM)
const DIFF_NAME_IDLE     := DesignSystem.SLATE       ## a selectable, non-active mode — slate body text
const DIFF_NAME_LOCKED   := DesignSystem.SLATE_SOFT  ## non-selectable (special dog locks it, 119) — greyed
const DIFF_BADGE_ACTIVE  := "Valgt"                  ## the chosen mode's badge
const DIFF_BADGE_LOCKED  := "Låst"                   ## the fixed mode on a special dog (119)
## Trade subtitle (121, P4-3): the reward/challenge trade made legible before selecting, dimmed like
## the marker-word cost hint. WORD_COST_HINT SLATE_SOFT reused so the two hint styles read identical.
const DIFF_TRADE_HINT    := WORD_COST_HINT           ## dimmed trade subtitle colour — secondary
const DIFF_TRADE_COIN_WORD    := "mynt"              ## coin word in the trade string ("×1.4 mynt · …")
const DIFF_WINDOW_TIGHT       := "smalere vindu"     ## a tightened timing window (window_scale < 1.0)
const DIFF_WINDOW_VERY_TIGHT  := "mye smalere vindu" ## a strongly tightened window (window_scale < …_MAX)
const DIFF_WINDOW_VERY_TIGHT_MAX := 0.6              ## window_scale below this reads as "mye smalere"
## The "Vanskelighet" (difficulty) subheading label — Norwegian, homed as a named const.
const LABEL_DIFFICULTY   := "Vanskelighet"
## The locked-section reason note (122): on a special dog the mode is fixed — this one-liner tells the
## player it's by design, not a bug. Shown (dimmed) only when the section is locked; homed as a const.
const DIFF_LOCKED_NOTE   := "Spesialhunder trener alltid på Hard"

## The rows main fed in (each {id, state}) + the coin balance shown in the header.
var _rows: Array = []
var _balance := 0
## The breed rows main fed in (each {id, name, tint, state, price}) — empty until the roster wires them,
## so the trick-only menu (072) is byte-for-byte unchanged when there are no breeds.
var _breeds: Array = []
## The marker-word rows main fed in (each {id, display, state}) — empty until P5-4 wires them,
## so the trick-only + breeds-only menu geometry is unchanged when no words are fed.
var _words: Array = []
## The difficulty rows main fed in (each {id, name, active, selectable, locked}) — empty until 118 wires
## them, so the trick/breeds/words-only geometry is byte-for-byte unchanged when the section is absent.
var _difficulties: Array = []

## The shared coin pill (129, X-4): the SAME CoinReadout widget the training HUD uses, hosted as a child
## in the header band so the balance reads identically on training / menu / kennel. Built lazily on the
## first draw (never in _init — headless harness gotcha: add_child in _init doesn't work). The header
## coin is no longer hand-drawn; _position_coin_readout keeps it right-anchored in the header rect.
var _coin_readout: CoinReadout = null

## Cached raised-gradient StyleBoxTexture for the primary CTA (130). Baking is a per-pixel image
## loop, so it MUST NOT run every _draw frame — we bake once and rebuild only when the CTA rect size
## changes (tracked by _cta_box_size). Rebuilt lazily in _draw via _ensure_cta_box().
var _cta_box: StyleBoxTexture = null
var _cta_box_size := Vector2.ZERO

func _init() -> void:
	# Modal: the menu eats every tap while it is up (STOP), so a tap can never fall through to the BRA
	# button or a chip behind it. main also hides/shows it; it starts hidden (main mounts it hidden).
	mouse_filter = Control.MOUSE_FILTER_STOP

## Classify each known trick for the menu (pure — the honesty split is unit-locked). `performable` are
## the ids the loaded dog can actually do; `mastered` maps id→bool; `locked` are the genuinely-absent
## roadmap ids that must ALWAYS read Locked (never trainable) regardless of anything else. `active` is
## the trick currently being trained (152): a performable, non-locked id equal to `active` reads ACTIVE,
## taking precedence over LEARNED/AVAILABLE so a mastered active trick isn't an anonymous «Lært» row.
## Default "" marks nothing active — old callers/tests are byte-for-byte unchanged.
static func classify(all_ids: Array, performable: Array, mastered: Dictionary, locked: Array, active := "") -> Array:
	var rows: Array = []
	for id in all_ids:
		var st := State.LOCKED
		if not locked.has(id) and performable.has(id):
			if id == active:
				st = State.ACTIVE
			else:
				st = State.LEARNED if mastered.get(id, false) else State.AVAILABLE
		rows.append({"id": id, "state": st})
	return rows

## Whether a state is choosable. Only LEARNED/AVAILABLE emit — a Locked trick never is (the never-fake
## gate), and the ACTIVE (currently-trained) trick absorbs its tap (152, mirrors breed/word ACTIVE).
static func is_selectable(state: int) -> bool:
	return state == State.LEARNED or state == State.AVAILABLE

## Classify each shipped breed for the menu (pure — the adopt/switch split is unit-locked). `catalog` is
## the ordered breed list (each {id, name, tint}); `owned` the adopted ids; `active` the running breed;
## `balance` the coins on hand; `price` the fixed adopt cost. Each row carries the price so the Locked /
## Buyable badge can show the cost. Order follows the catalog so the roster reads the same every open.
static func classify_breeds(catalog: Array, owned: Array, active: String, balance: int, price: int) -> Array:
	var rows: Array = []
	for entry in catalog:
		var b: Dictionary = entry
		var id: String = b.id
		var st := BreedState.LOCKED
		if id == active:
			st = BreedState.ACTIVE
		elif owned.has(id):
			st = BreedState.OWNED
		elif balance >= price:
			st = BreedState.BUYABLE
		rows.append({"id": id, "name": b.get("name", id), "tint": b.get("tint", Color(1, 1, 1)),
			"state": st, "price": price})
	return rows

## Whether a breed row is tappable: OWNED switches to it, BUYABLE adopts it. ACTIVE (already running) and
## LOCKED (unaffordable) absorb the tap — no switch, no debt.
static func breed_is_selectable(state: int) -> bool:
	return state == BreedState.OWNED or state == BreedState.BUYABLE

## Classify each catalog word for the menu (pure — the active/unlocked/locked partition is unit-locked).
## `catalog` is the ordered word list (each {id, display, …}); `unlocked` the ids the player has earned;
## `active` the id currently firing at the mark. Each row: {id, display, state}. Order follows the catalog
## so the display reads the same every open. ACTIVE (the firing word) and LOCKED absorb a tap; only an
## UNLOCKED non-active word emits word_chosen (so the player can deliberately switch — P5-4, X-2 holds).
static func classify_words(catalog: Array, unlocked: Array, active: String) -> Array:
	var rows: Array = []
	for entry in catalog:
		var e: Dictionary = entry
		var id: String = e.get("id", "")
		var display: String = e.get("display", id)
		var st := WordState.LOCKED
		if id == active and unlocked.has(id):
			st = WordState.ACTIVE
		elif unlocked.has(id):
			st = WordState.UNLOCKED
		rows.append({"id": id, "display": display, "state": st,
			"window_scale": float(e.get("window_scale", 1.0)),
			"cooldown": int(e.get("cooldown", 0))})
	return rows

## Classify each difficulty mode for the menu (118, P4-1; pure — the active split is unit-locked).
## `catalog` is the ordered mode list (Difficulty objects, Normal→Hard→Expert); `active_id` the mode
## currently in effect. Each row: {id, name, active, selectable, locked}. Order follows the catalog so
## the selector reads the same every open. Unlocked (a normal dog): every row selectable, the active id
## flagged. `locked` (a special dog, 119): every row non-selectable and `locked_id` is flagged active
## instead of `active_id` — the fixed mode reads as the chosen one while nothing is tappable.
static func classify_difficulty(catalog: Array, active_id: String, locked := false, locked_id := "") -> Array:
	var rows: Array = []
	var flagged := locked_id if locked else active_id
	for entry in catalog:
		var mode := entry as Difficulty
		rows.append({
			"id": mode.id,
			"name": mode.display_name,
			"active": mode.id == flagged,
			"selectable": not locked,
			"locked": locked,
			"reward_scale": mode.reward_scale,
			"window_scale": mode.window_scale,
		})
	return rows

## The dimmed trade subtitle for a difficulty row (121, P4-3), derived from the Difficulty model —
## the reward/challenge trade made legible at the point of choice (mirrors the marker-word cost hint,
## 095). "" for the baseline (Normal / reward_scale == 1.0) → no subtitle. Otherwise
## "×<reward> mynt · <window phrase>": the coin multiplier (trailing ".0" dropped so 2.0 reads "×2"),
## then a window-tightening phrase bucketed by how much the timing window shrinks. Pure — unit-locked.
static func difficulty_trade_label(reward_scale: float, window_scale: float) -> String:
	if is_equal_approx(reward_scale, 1.0):
		return ""
	var reward_txt: String
	if is_equal_approx(reward_scale, round(reward_scale)):
		reward_txt = "×%d" % int(round(reward_scale))
	else:
		reward_txt = ("×%.1f" % reward_scale)
	var window_txt := DIFF_WINDOW_TIGHT if window_scale >= DIFF_WINDOW_VERY_TIGHT_MAX else DIFF_WINDOW_VERY_TIGHT
	return "%s %s · %s" % [reward_txt, DIFF_TRADE_COIN_WORD, window_txt]

## Whether a difficulty row may be tapped (118/119). A locked row (special dog) is never selectable;
## the active mode is still "selectable" (tapping it is simply a no-op switch in main). Pure predicate.
static func is_difficulty_selectable(row: Dictionary) -> bool:
	return row.get("selectable", false)

## Whether the fed difficulty section is locked (122): a special dog fixes the mode, so every row is
## locked. Drives the one-line reason note that tells the player the challenge is fixed by design, not
## broken. False for a normal dog (rows selectable) or an empty/unfed section. Pure predicate.
static func difficulty_section_locked(rows: Array) -> bool:
	for r in rows:
		if (r as Dictionary).get("locked", false):
			return true
	return false

## The player-facing name for a trick id (pure). Unknown ids fall back to a capitalised id.
static func display_name(id: String) -> String:
	return LABELS.get(id, id.capitalize())

## Set the rows + the coin balance to show, and request a redraw. main rebuilds this each time it opens
## the menu (or after mastery), so the menu itself stays dumb.
func set_rows(rows: Array, balance: int) -> void:
	_rows = rows
	_balance = maxi(0, balance)
	if _coin_readout != null:
		_coin_readout.set_balance(_balance)
	queue_redraw()

## Set the breed rows to show (079) and request a redraw. Empty until the roster wires them; main rebuilds
## these (via classify_breeds) each time it opens the menu, so the menu itself stays dumb.
func set_breeds(breeds: Array) -> void:
	_breeds = breeds
	queue_redraw()

## Set the marker-word rows to show (092) and request a redraw. Empty until P5-4 wires them; main
## rebuilds these (via classify_words) each time it opens the menu, so the menu stays dumb.
func set_words(rows: Array) -> void:
	_words = rows
	queue_redraw()

## Set the difficulty rows to show (118) and request a redraw. Empty until the selector wires them; main
## rebuilds these (via classify_difficulty) each time it opens the menu, so the menu itself stays dumb.
func set_difficulty(rows: Array) -> void:
	_difficulties = rows
	queue_redraw()

func row_count() -> int:
	return _rows.size()

## The difficulty rows accessors (118) — mirror the breed/word capture accessors so the live e2e /
## Visual-Review capture can land a REAL canvas tap on a specific mode row rather than fragile pixels.
func difficulty_row_count() -> int:
	return _difficulties.size()

func difficulty_row_center(i: int) -> Vector2:
	return _difficulty_row_rect(i).get_center()

func difficulty_id(i: int) -> String:
	return (_difficulties[i] as Dictionary).id

func breed_count() -> int:
	return _breeds.size()

## The i-th breed row's centre in this Control's local (viewport) coords, and its breed id (079). The
## live e2e/Visual-Review capture reads these to land a REAL canvas tap on a specific breed row (the same
## honest-tap proof the 072 menu capture uses for trick rows), rather than hard-coding fragile pixels.
func breed_row_center(i: int) -> Vector2:
	return _breed_row_rect(i).get_center()

func breed_id(i: int) -> String:
	return (_breeds[i] as Dictionary).id

## The i-th trick row's centre + its id (079) — same purpose as the breed accessors above. The breeds
## section makes the panel taller, so the 072-era hard-coded trick-row pixels no longer land; the capture
## reads these instead so a real tap on "Ligg" / "Legg deg" is robust to the layout growing.
func row_center(i: int) -> Vector2:
	return _row_rect(i).get_center()

func row_id(i: int) -> String:
	return (_rows[i] as Dictionary).id

## The i-th marker-word row's centre + its id (092/P5-4) — same capture purpose as the breed/trick
## accessors above, so the live e2e/Visual-Review capture can land a REAL tap on a specific word row.
func word_count() -> int:
	return _words.size()

func word_row_center(i: int) -> Vector2:
	return _word_row_rect(i).get_center()

func word_id(i: int) -> String:
	return (_words[i] as Dictionary).id

## The coin balance currently shown — the render-free predicate a test reads.
func balance() -> int:
	return _balance

## The State for a trick id in the current rows, or LOCKED if it isn't present (defensive default —
## an unknown id is never trainable).
func state_of(id: String) -> int:
	for r in _rows:
		if r.id == id:
			return r.state
	return State.LOCKED

# ---- geometry (one home so _draw and the hit-map agree) -------------------------------------------

## The rows block height for the current row count.
func _rows_block_h() -> float:
	var n := _rows.size()
	if n == 0:
		return 0.0
	return n * ROW_H + (n - 1) * ROW_GAP

## The breeds block height (079): the gutter + "Breeds" subheading + one row per breed. Zero when there
## are no breeds, so the trick-only panel geometry (072) is unchanged.
func _breeds_block_h() -> float:
	var n := _breeds.size()
	if n == 0:
		return 0.0
	return BREEDS_GAP + BREED_HEADER_H + n * BREED_ROW_H + (n - 1) * BREED_ROW_GAP

## The marker words block height (092/134): the gutter + divider + divider-gap + heading + rows.
## Zero when no word rows are fed, so the trick-only panel geometry (072) and the breeds layout
## (079) are both unchanged when the section is absent.
func _words_block_h() -> float:
	var n := _words.size()
	if n == 0:
		return 0.0
	return WORDS_GAP + WORD_DIVIDER_H + WORD_DIVIDER_GAP + WORD_HEADER_H + n * WORD_ROW_H + (n - 1) * WORD_ROW_GAP

## The y where the words section (subheading) begins — just below breeds, or just below trick rows
## if there are no breeds.
func _words_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() + WORDS_GAP

## The i-th word row rect inside the panel (below the "Marker words" heading + divider).
## _words_top() is the start of the section; skip divider + divider-gap + heading to reach the first row.
func _word_row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _words_top() + WORD_DIVIDER_H + WORD_DIVIDER_GAP + WORD_HEADER_H + i * (WORD_ROW_H + WORD_ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, WORD_ROW_H)

## The word row index under a point, or -1 if none.
func _word_row_index_at(pos: Vector2) -> int:
	for i in _words.size():
		if _word_row_rect(i).has_point(pos):
			return i
	return -1

## The difficulty block height (118): the gutter + "Vanskelighet" subheading + one row per mode. Zero
## when no difficulty rows are fed, so the trick/breeds/words-only geometry is unchanged.
func _difficulty_block_h() -> float:
	var n := _difficulties.size()
	if n == 0:
		return 0.0
	return DIFFICULTY_GAP + DIFFICULTY_HEADER_H + _difficulty_note_h() \
		+ n * DIFFICULTY_ROW_H + (n - 1) * DIFFICULTY_ROW_GAP

## The locked-section reason-note band height (122): DIFFICULTY_NOTE_H only when the section is locked
## (a special dog), else 0 — so a normal-dog / unfed section's geometry is byte-identical. The note sits
## between the "Vanskelighet" subheading and the first row.
func _difficulty_note_h() -> float:
	return DIFFICULTY_NOTE_H if difficulty_section_locked(_difficulties) else 0.0

## The y where the difficulty section (subheading) begins — just below the words block (or breeds/trick
## rows if those sections are absent, since each contributes 0 height when empty).
func _difficulty_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() \
		+ _words_block_h() + DIFFICULTY_GAP

## The i-th difficulty row rect inside the panel (below the "Vanskelighet" subheading).
func _difficulty_row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _difficulty_top() + DIFFICULTY_HEADER_H + _difficulty_note_h() + i * (DIFFICULTY_ROW_H + DIFFICULTY_ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, DIFFICULTY_ROW_H)

## The difficulty row index under a point, or -1 if none.
func _difficulty_row_index_at(pos: Vector2) -> int:
	for i in _difficulties.size():
		if _difficulty_row_rect(i).has_point(pos):
			return i
	return -1

## The showcase pill's block height (087): the gutter + pill, only when there are breeds to show off.
## Zero-height with no breeds, so the trick-only panel geometry (072) is unchanged.
func _showcase_block_h() -> float:
	return (SHOWCASE_GAP + SHOWCASE_H) if not _breeds.is_empty() else 0.0

## The centred modal panel rect for the current size + row/breed/word counts.
## The showcase + feedback pills sit above the close button, so the panel grows to fit them.
func _panel_rect() -> Rect2:
	var pw := minf(size.x - 2.0 * PANEL_MARGIN_X, PANEL_MAX_W)
	var ph := PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() + _words_block_h() + _difficulty_block_h() + _showcase_block_h() + CLOSE_GAP + FEEDBACK_H + FEEDBACK_GAP + CLOSE_H + PANEL_PAD
	var px := (size.x - pw) * 0.5
	var py := (size.y - ph) * 0.5
	return Rect2(px, py, pw, ph)

## The y just below the trick + breeds + words + difficulty blocks — the top of the footer
## (showcase/feedback/close pills). Each section contributes 0 height when empty.
func _foot_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + _breeds_block_h() \
		+ _words_block_h() + _difficulty_block_h()

## The "Vis frem hundene" showcase pill rect (087) — between the breeds section and the feedback row.
## Zero-area (offscreen) when there are no breeds so it is never drawn or hit.
func _showcase_rect() -> Rect2:
	if _breeds.is_empty():
		return Rect2()
	var panel := _panel_rect()
	return Rect2(panel.position.x + PANEL_PAD, _foot_top() + SHOWCASE_GAP,
		panel.size.x - 2.0 * PANEL_PAD, SHOWCASE_H)

## The centre of the showcase row in local coords — the live e2e/capture harness taps this (087).
func showcase_row_center() -> Vector2:
	return _showcase_rect().get_center()

## The y where the breeds section (subheading) begins, just below the trick rows block.
func _breeds_top() -> float:
	var panel := _panel_rect()
	return panel.position.y + PANEL_PAD + HEADER_H + _rows_block_h() + BREEDS_GAP

## The i-th breed row rect inside the panel (below the "Breeds" subheading).
func _breed_row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _breeds_top() + BREED_HEADER_H + i * (BREED_ROW_H + BREED_ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, BREED_ROW_H)

## The breed row index under a point, or -1 if none.
func _breed_row_index_at(pos: Vector2) -> int:
	for i in _breeds.size():
		if _breed_row_rect(i).has_point(pos):
			return i
	return -1

## The i-th trick row rect inside the panel.
func _row_rect(i: int) -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := panel.position.y + PANEL_PAD + HEADER_H + i * (ROW_H + ROW_GAP)
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, ROW_H)

## The "Give feedback" pill rect, just above the close button (085, X-8). Placed at the same
## x/width as the close button so they read as a pair at the panel foot. The geometry is the
## single home for this rect — _draw and _gui_input both read it here, never hard-coded.
func _feedback_rect() -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _foot_top() + _showcase_block_h() + CLOSE_GAP
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, FEEDBACK_H)

## The centre of the "Give feedback" row in this Control's local coords — the live e2e/capture
## harness reads this to land a REAL canvas tap on the row (same honest-tap proof as row_center).
func feedback_row_center() -> Vector2:
	return _feedback_rect().get_center()

## The close ("Keep training") button rect at the panel foot, below the feedback row.
func _close_rect() -> Rect2:
	var panel := _panel_rect()
	var x := panel.position.x + PANEL_PAD
	var y := _foot_top() + _showcase_block_h() + CLOSE_GAP + FEEDBACK_H + FEEDBACK_GAP
	return Rect2(x, y, panel.size.x - 2.0 * PANEL_PAD, CLOSE_H)

## The row index under a point, or -1 if none.
func row_index_at(pos: Vector2) -> int:
	for i in _rows.size():
		if _row_rect(i).has_point(pos):
			return i
	return -1

## Map a point to the trick id of the SELECTABLE row under it, or "" (a Locked row or empty space —
## never a hit, so a Locked trick can never be chosen). The one home for the hit-map.
func id_at(pos: Vector2) -> String:
	var i := row_index_at(pos)
	if i < 0:
		return ""
	var r: Dictionary = _rows[i]
	return r.id if is_selectable(r.state) else ""

## Pick on a left-press (press-only, once per tap — mirrors the BRA button + selector hygiene). A
## selectable row → trick_chosen; the feedback row → feedback_requested; the close button or a tap
## on the dimmed backdrop → dismissed; a Locked row is absorbed (no signal — never a faked switch).
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	var i := row_index_at(pos)
	if i >= 0:
		var r: Dictionary = _rows[i]
		if is_selectable(r.state):
			trick_chosen.emit(r.id)
		return  # a Locked row is absorbed — never a dismiss, never a switch
	var bi := _breed_row_index_at(pos)
	if bi >= 0:
		var b: Dictionary = _breeds[bi]
		match b.state:
			BreedState.OWNED:   breed_chosen.emit(b.id)  # switch to an owned dog
			BreedState.BUYABLE: breed_adopt.emit(b.id)   # spend coins to adopt it
			# ACTIVE (already running) / LOCKED (can't afford) absorb the tap — no switch, no debt.
		return
	var wi := _word_row_index_at(pos)
	if wi >= 0:
		var w: Dictionary = _words[wi]
		if w.state == WordState.UNLOCKED:
			word_chosen.emit(w.id)  # switch the active marker word (non-active unlocked only)
		# ACTIVE (already firing) / LOCKED (not earned) absorb the tap — no switch, no faked clip.
		return
	var di := _difficulty_row_index_at(pos)
	if di >= 0:
		var d: Dictionary = _difficulties[di]
		if is_difficulty_selectable(d):
			difficulty_chosen.emit(d.id)  # main no-ops an already-active pick; a locked dog's rows aren't selectable
		# A locked row (special dog, 119) absorbs the tap — the mode is fixed, no switch.
		return
	if not _breeds.is_empty() and _showcase_rect().has_point(pos):
		showcase_requested.emit()
		accept_event()
		return
	if _feedback_rect().has_point(pos):
		feedback_requested.emit()
		accept_event()
		return
	if _close_rect().has_point(pos) or not _panel_rect().has_point(pos):
		dismissed.emit()

# ---- rendering ------------------------------------------------------------------------------------

## Draw text crisp on the light PAPER surface — no heavy black halo (that was for dark-navy legibility).
## On paper, text renders SLATE-on-paper; we use crisp draw_string only.
func _draw_text(font: Font, pos: Vector2, text: String, fsize: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, text, align, width, fsize, color)

## Trim `text` to at most `max_w` pixels, appending "…" when it would overflow — so a long name
## (e.g. "Chocolate Labrador") never runs under its right-aligned badge on the light DS card. Pure
## measurement + string trim; no geometry change. Returns `text` unchanged when it already fits.
func _elide(font: Font, text: String, fsize: int, max_w: float) -> String:
	if max_w <= 0.0 or font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x <= max_w:
		return text
	var ell := "…"
	var out := text
	while out.length() > 1 and font.get_string_size(out + ell, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > max_w:
		out = out.substr(0, out.length() - 1)
	return out.strip_edges(false, true) + ell

func _draw() -> void:
	var f_display   := DesignSystem.font_display()
	var f_bold      := DesignSystem.font_body_bold()
	var f_body      := DesignSystem.font_body()
	# The dimmed veil over the whole game, then the centred PAPER card.
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP, true)
	var panel := _panel_rect()
	draw_style_box(_panel_box(), panel)
	# Header: the "Tricks" title on the left (display font), the drawn coin + balance on the right.
	var hx := panel.position.x + PANEL_PAD
	var hy := panel.position.y + PANEL_PAD
	var title_baseline := hy + f_display.get_ascent(TITLE_SIZE)
	_draw_text(f_display, Vector2(hx, title_baseline), LABEL_TITLE, TITLE_SIZE, TITLE_COLOR)
	# The header balance is the SHARED CoinReadout pill (129), a child node right-anchored in the
	# header band — not a bespoke hand-draw. Built lazily here (add_child in _init is a no-op headless).
	_ensure_coin_readout()
	_position_coin_readout(panel, hy)
	# The trick rows.
	for i in _rows.size():
		_draw_row(f_bold, f_body, i)
	# The breeds section (079): a subheading + one row per shipped breed (swatch, name, state/price).
	if not _breeds.is_empty():
		var sub_baseline := _breeds_top() + f_bold.get_ascent(BADGE_SIZE)
		_draw_text(f_bold, Vector2(panel.position.x + PANEL_PAD, sub_baseline), LABEL_BREEDS,
			BADGE_SIZE, BREED_SUBHEAD)
		for i in _breeds.size():
			_draw_breed_row(f_bold, f_body, i)
	# The marker words section (092/134): a distinct Baloo-2 heading + a hairline divider rule above
	# it (matching the DS section-break treatment), then one row per catalog word (Active/Unlocked/Locked).
	# Zero-height when no words are fed, so the trick-only + breeds-only geometry (072/079) is unchanged.
	if not _words.is_empty():
		# Hairline divider rule above the heading — DS BORDER colour, full panel inner width.
		var div_y := _words_top() + WORD_DIVIDER_H * 0.5
		draw_line(
			Vector2(panel.position.x + PANEL_PAD, div_y),
			Vector2(panel.position.x + panel.size.x - PANEL_PAD, div_y),
			PANEL_BORDER, WORD_DIVIDER_H)
		# Baloo-2 display heading (heavier weight than the body-bold used for "Breeds" / "Vanskelighet").
		var word_head_baseline := _words_top() + WORD_DIVIDER_H + WORD_DIVIDER_GAP + f_display.get_ascent(TITLE_SIZE)
		_draw_text(f_display, Vector2(panel.position.x + PANEL_PAD, word_head_baseline), LABEL_WORDS,
			TITLE_SIZE, TITLE_COLOR)
		for i in _words.size():
			_draw_word_row(f_bold, f_body, i)
	# The difficulty section (118): a "Vanskelighet" subheading + one row per mode (Normal/Hard/Expert).
	# Zero-height when no rows are fed, so the trick/breeds/words geometry is unchanged when absent.
	if not _difficulties.is_empty():
		var diff_sub_baseline := _difficulty_top() + f_bold.get_ascent(BADGE_SIZE)
		_draw_text(f_bold, Vector2(panel.position.x + PANEL_PAD, diff_sub_baseline), LABEL_DIFFICULTY,
			BADGE_SIZE, DIFF_SUBHEAD)
		# On a special dog the mode is locked (119) — a dimmed one-liner tells the player WHY (122), so
		# the greyed section reads as intentional, not broken. Shown only when locked (height reserved
		# only then, so a normal dog's layout is unchanged).
		if difficulty_section_locked(_difficulties):
			var note_baseline := _difficulty_top() + DIFFICULTY_HEADER_H + f_body.get_ascent(BADGE_SIZE)
			_draw_text(f_body, Vector2(panel.position.x + PANEL_PAD, note_baseline), DIFF_LOCKED_NOTE,
				BADGE_SIZE, DIFF_TRADE_HINT)
		for i in _difficulties.size():
			_draw_difficulty_row(f_bold, f_body, i)
	# The "Vis frem hundene" showcase pill (087) — only when there are breeds. GHOST secondary pill
	# (paper fill + Bra-Blue outline + Bra-Blue text) so it reads clearly lighter than the primary CTA.
	if not _breeds.is_empty():
		var sr := _showcase_rect()
		_draw_ghost_pill(sr)
		var sb := sr.position.y + sr.size.y * 0.5 + f_bold.get_ascent(CLOSE_SIZE) * 0.5 - f_bold.get_descent(CLOSE_SIZE) * 0.5
		_draw_text(f_bold, Vector2(sr.position.x, sb), LABEL_SHOWCASE, CLOSE_SIZE,
			SECONDARY_TEXT, HORIZONTAL_ALIGNMENT_CENTER, sr.size.x)
	# The "Gi tilbakemelding" pill — GHOST secondary (demoted, 130) so it no longer competes with the
	# primary CTA below it. Always reachable above the close button (085, X-8).
	var fr := _feedback_rect()
	_draw_ghost_pill(fr)
	var fb := fr.position.y + fr.size.y * 0.5 + f_bold.get_ascent(CLOSE_SIZE) * 0.5 - f_bold.get_descent(CLOSE_SIZE) * 0.5
	_draw_text(f_bold, Vector2(fr.position.x, fb), LABEL_FEEDBACK, CLOSE_SIZE, SECONDARY_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, fr.size.x)
	# The "Fortsett treningen" close button — the PRIMARY CTA (130). Drawn with the SAME raised-blue
	# gradient treatment as the BRA button (bright top → deep bottom + darker lip + drop shadow) so it
	# reads as the dominant action; white ≥700 label. The gradient StyleBoxTexture is cached (per-pixel
	# bake, never re-run per frame — rebuilt only when the rect size changes).
	var cr := _close_rect()
	_ensure_cta_box(cr.size)
	draw_style_box(_cta_box, cr)
	var cb := cr.position.y + cr.size.y * 0.5 + f_bold.get_ascent(CLOSE_SIZE) * 0.5 - f_bold.get_descent(CLOSE_SIZE) * 0.5
	_draw_text(f_bold, Vector2(cr.position.x, cb), LABEL_CLOSE, CLOSE_SIZE, CLOSE_TEXT,
		HORIZONTAL_ALIGNMENT_CENTER, cr.size.x)

func _panel_box() -> StyleBoxFlat:
	## PAPER card with hairline BORDER + card shadow via the DS builder (098, Phase 6).
	return DesignSystem.panel(DesignSystem.PAPER, DesignSystem.R_LG)

## A GHOST secondary pill (130): PAPER fill + a Bra-Blue hairline outline, at the footer R_MD radius.
## Used for the demoted "Gi tilbakemelding" + "Vis frem hundene" pills so they read clearly lighter
## than the raised-gradient primary CTA. StyleBoxFlat is cheap to build, so no cache needed here.
func _draw_ghost_pill(rect: Rect2) -> void:
	var sb := DesignSystem.pill(SECONDARY_BG, DesignSystem.R_MD)
	sb.border_width_top    = int(SECONDARY_OUTLINE_W)
	sb.border_width_right  = int(SECONDARY_OUTLINE_W)
	sb.border_width_bottom = int(SECONDARY_OUTLINE_W)
	sb.border_width_left   = int(SECONDARY_OUTLINE_W)
	sb.border_color = SECONDARY_OUTLINE
	draw_style_box(sb, rect)

## Lazily (re)bake the primary-CTA raised-gradient StyleBoxTexture (130), reusing the shared
## DesignSystem baker + the SAME GRAD_PILL_* blue palette as the BRA button so both dominant actions
## match. PERFORMANCE: baking is a per-pixel image loop — this reuses the cache and rebuilds ONLY when
## the CTA rect size changes (the panel width tracks the screen), never every _draw frame.
func _ensure_cta_box(cta_size: Vector2) -> void:
	if _cta_box != null and _cta_box_size == cta_size:
		return
	var cw := int(round(cta_size.x))
	var ch := int(round(cta_size.y))
	_cta_box = DesignSystem.gradient_pill(cw, ch, CLOSE_GRAD_RADIUS,
		DesignSystem.GRAD_PILL_TOP, DesignSystem.GRAD_PILL_BOT, DesignSystem.GRAD_PILL_LIP,
		CLOSE_GRAD_PAD, CLOSE_GRAD_LIP_H, CLOSE_GRAD_SHADOW_DY, CLOSE_GRAD_SHADOW_BLUR,
		CLOSE_GRAD_SHADOW_MAX)
	_cta_box_size = cta_size

## Lazily build the shared CoinReadout child (129) — the SAME pill the training HUD uses, so the
## balance reads identically across surfaces. Never built in _init (add_child there is a headless
## no-op, CLAUDE.md gotcha); this runs in _draw, where the node is safely attached. Seeds the pill
## with the last balance fed via set_rows so a redraw before the next feed still shows the right number.
func _ensure_coin_readout() -> void:
	if _coin_readout != null:
		return
	var readout := CoinReadout.new()
	readout.name = "CoinReadout"
	readout.set_balance(_balance)
	add_child(readout)
	_coin_readout = readout

## Right-anchor the shared CoinReadout pill within the header band. The pill draws its own paper
## background + gold coin disc + right-aligned number, so we only give it a rect: full panel width
## (it self-right-aligns the pill to its own right edge) at the header's vertical centre.
func _position_coin_readout(panel: Rect2, top: float) -> void:
	if _coin_readout == null:
		return
	var pill_w := panel.size.x - 2.0 * PANEL_PAD
	_coin_readout.position = Vector2(panel.position.x + PANEL_PAD, top)
	_coin_readout.size = Vector2(pill_w, CoinReadout.HEIGHT)

func _draw_row(f_name: Font, f_badge: Font, i: int) -> void:
	var r: Dictionary = _rows[i]
	var rect := _row_rect(i)
	var st: int = r.state
	var locked := st == State.LOCKED
	var active := st == State.ACTIVE
	# DS pill row background: the muted pale-BLUE wash for the ACTIVE (currently-trained) trick (152),
	# CREAM for available/learned, near-invisible SLATE_SOFT tint for locked.
	var row_bg := ROW_BG_ACTIVE if active else (ROW_BG_LOCKED if locked else ROW_BG)
	draw_style_box(DesignSystem.pill(row_bg, DesignSystem.R_MD), rect)
	# Trick name, left; state badge, right. The ACTIVE row draws its label in the dark 151 status ink
	# on the muted wash (clears AA, reads as the confident current-trick row — not a live button).
	var name_col := NAME_LOCKED
	if st == State.ACTIVE:
		name_col = ROW_ACTIVE_INK
	elif st == State.LEARNED:
		name_col = NAME_LEARNED
	elif st == State.AVAILABLE:
		name_col = NAME_AVAILABLE
	var name_baseline := rect.position.y + rect.size.y * 0.5 + f_name.get_ascent(NAME_SIZE) * 0.5 - f_name.get_descent(NAME_SIZE) * 0.5
	_draw_text(f_name, Vector2(rect.position.x + 14.0, name_baseline),
		display_name(r.id), NAME_SIZE, name_col)
	var badge: String = BADGE[st]
	var badge_col := BADGE_LOCKED
	if st == State.ACTIVE:
		badge_col = ROW_ACTIVE_INK
	elif st == State.LEARNED:
		badge_col = BADGE_LEARNED
	elif st == State.AVAILABLE:
		badge_col = BADGE_AVAILABLE
	var badge_baseline := rect.position.y + rect.size.y * 0.5 + f_badge.get_ascent(BADGE_SIZE) * 0.5 - f_badge.get_descent(BADGE_SIZE) * 0.5
	_draw_text(f_badge, Vector2(rect.position.x, badge_baseline), badge, BADGE_SIZE, badge_col,
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)

## One breed row (079): the honest coat-colour swatch chip on the left, the breed name beside it, and the
## state badge on the right — with the adopt price appended for a Buyable/Locked row so the cost reads.
func _draw_breed_row(f_name: Font, f_badge: Font, i: int) -> void:
	var b: Dictionary = _breeds[i]
	var rect := _breed_row_rect(i)
	var st: int = b.state
	var locked := st == BreedState.LOCKED
	# DS pill row background: CREAM for active/available/owned, near-invisible tint for locked.
	var row_bg := ROW_BG_LOCKED if locked else ROW_BG
	draw_style_box(DesignSystem.pill(row_bg, DesignSystem.R_MD), rect)
	# The coat swatch chip — a filled disc of the real coat colour with a thin BORDER rim so a pale coat
	# still reads on the paper panel. An honest colour chip, never a faked breed image.
	var sc := Vector2(rect.position.x + 16.0 + SWATCH_R, rect.position.y + rect.size.y * 0.5)
	var chip: Color = b.get("tint", Color(1, 1, 1))
	if locked:
		chip.a = 0.4  # dim an unaffordable breed's chip so it reads clearly not-yet-yours
	draw_circle(sc, SWATCH_R + 1.0, SWATCH_RIM)
	draw_circle(sc, SWATCH_R, chip)
	# The breed name, to the right of the chip.
	var name_col := BREED_NAME_LOCKED
	if st == BreedState.ACTIVE:
		name_col = BREED_NAME_ACTIVE
	elif st == BreedState.OWNED:
		name_col = BREED_NAME_OWNED
	elif st == BreedState.BUYABLE:
		name_col = BREED_NAME_BUYABLE
	var name_x := sc.x + SWATCH_R + 12.0
	var name_baseline := rect.position.y + rect.size.y * 0.5 + f_name.get_ascent(NAME_SIZE) * 0.5 - f_name.get_descent(NAME_SIZE) * 0.5
	# The state badge, right-aligned. Buyable/Locked append the coin price so the cost reads honestly.
	var badge: String = BREED_BADGE[st]
	if st == BreedState.BUYABLE or st == BreedState.LOCKED:
		badge = "%s %d" % [badge, int(b.get("price", 0))]
	# A buyable row prefixes a small gold coin pip before its price text (162, X-6) — the "gold =
	# coin" DS signal on a real coin glyph — so reserve its width when eliding the name too.
	var show_pip := st == BreedState.BUYABLE
	var pip_reserve := (PRICE_PIP_R * 2.0 + PRICE_PIP_GAP) if show_pip else 0.0
	# Elide the name so a long breed ("Chocolate Labrador") never runs under the badge on the card.
	var badge_w := f_badge.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1, BADGE_SIZE).x
	var name_max_w := (rect.position.x + rect.size.x - 14.0 - badge_w - pip_reserve) - name_x - 10.0
	_draw_text(f_name, Vector2(name_x, name_baseline), _elide(f_name, str(b.get("name", b.id)), NAME_SIZE, name_max_w), NAME_SIZE, name_col)
	var badge_col := BREED_NAME_LOCKED
	if st == BreedState.ACTIVE:
		badge_col = BADGE_LEARNED
	elif st == BreedState.OWNED:
		badge_col = BADGE_AVAILABLE
	elif st == BreedState.BUYABLE:
		badge_col = BADGE_PRICE_INK  # 162: dark AA-legible ink (was COIN_GOLD ~1.55:1 on CREAM)
	var badge_baseline := rect.position.y + rect.size.y * 0.5 + f_badge.get_ascent(BADGE_SIZE) * 0.5 - f_badge.get_descent(BADGE_SIZE) * 0.5
	var badge_right := rect.position.x + rect.size.x - 14.0
	_draw_text(f_badge, Vector2(rect.position.x, badge_baseline), badge, BADGE_SIZE, badge_col,
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)
	# The gold coin pip, just left of the price text (kennel _make_price_chip / CoinReadout pattern):
	# gold face + darker rim, no font glyph — keeps GOLD reserved to a real coin, off the text.
	if show_pip:
		var pip_c := Vector2(badge_right - badge_w - PRICE_PIP_GAP - PRICE_PIP_R,
			rect.position.y + rect.size.y * 0.5)
		draw_circle(pip_c, PRICE_PIP_R, DesignSystem.GOLD_DARK)
		draw_circle(pip_c, PRICE_PIP_R - 1.5, COIN_GOLD)

## One marker-word row (092/093/095): the display text on the left and the state badge on the right.
## ACTIVE row highlighted BLUE (the firing word — DS primary accent); UNLOCKED SLATE (tap to switch);
## LOCKED SLATE_SOFT (not yet earned — never tappable, never a faked clip). Mirrors _draw_breed_row.
## When the ACTIVE word is on cooldown (093, P5-2) the badge reads "Hviler (n)" with the live
## remaining count (095, P5-2) so the size of the rest cost is legible.
## For any UNLOCKED or ACTIVE stronger word (cooldown > 0) a small dimmed cost hint is shown
## below the name so the player can weigh the trade-off before AND after loading (095, P5-2).
## Row dict shape: {id, display, state, cooling?, remaining?, window_scale?, cooldown?}; all
## optional keys use .get() with safe defaults so a row missing a key never errors.
func _draw_word_row(f_name: Font, f_badge: Font, i: int) -> void:
	var w: Dictionary = _words[i]
	var rect := _word_row_rect(i)
	var st: int = w.state
	var cooling: bool = w.get("cooling", false)
	var remaining: int = int(w.get("remaining", 0))
	var w_cooldown: int = int(w.get("cooldown", 0))
	var w_window_scale: float = float(w.get("window_scale", 1.0))
	var locked := st == WordState.LOCKED
	# DS pill row background: CREAM for active/unlocked, near-invisible tint for locked.
	var row_bg := ROW_BG_LOCKED if locked else ROW_BG
	draw_style_box(DesignSystem.pill(row_bg, DesignSystem.R_MD), rect)
	# Show a cost hint for any stronger word on UNLOCKED or ACTIVE rows (095, P5-2).
	# Base "bra" (cooldown == 0) shows no hint — it's the plain free default.
	# The hint is terse and dimmed (SLATE_SOFT) so it reads secondary to the name/badge.
	# Format: "+15% · hviler 2" (wider PERFECT window % · rest cost in marks).
	var show_cost_hint := w_cooldown > 0 and (st == WordState.UNLOCKED or st == WordState.ACTIVE)
	var cost_hint := ""
	if show_cost_hint:
		var pct: int = int(round((w_window_scale - 1.0) * 100.0))
		cost_hint = "+%d%% · hviler %d" % [pct, w_cooldown]
	# Leading pip — a small filled circle at the left edge of every word row so the eye separates
	# marker-word rows from trick rows at a glance (134: visual differentiation within the section).
	var pip_x := rect.position.x + WORD_ROW_INDENT + WORD_PIP_R
	var pip_y := rect.position.y + rect.size.y * 0.5
	var pip_col := WORD_NAME_ACTIVE if st == WordState.ACTIVE else (WORD_NAME_UNLOCKED if st == WordState.UNLOCKED else WORD_NAME_LOCKED)
	draw_circle(Vector2(pip_x, pip_y), WORD_PIP_R, pip_col)
	# Left offset for name text: past the pip + a small gap.
	var name_left := rect.position.x + WORD_ROW_INDENT + WORD_PIP_R * 2.0 + 6.0
	# Lay out the name: if we have a cost hint, shift the name up slightly to leave room for
	# the hint line below it, keeping everything within the row height.
	var name_mid_y := rect.position.y + rect.size.y * 0.5
	if show_cost_hint:
		name_mid_y = rect.position.y + rect.size.y * 0.5 - f_name.get_ascent(HINT_SIZE) * 0.5 - 1.0
	# The word display text (e.g. "Dyktig!"), left-aligned.
	# A cooling ACTIVE word is dimmed slightly — it IS the active choice but currently resting,
	# so it reads as "loaded but unavailable this round" rather than fully locked.
	## Cooling: BLUE_INK at 0.45 alpha — same hue as the active word ink but clearly resting.
	var name_col := WORD_NAME_LOCKED
	if st == WordState.ACTIVE:
		name_col = WORD_NAME_ACTIVE if not cooling else Color(DesignSystem.BLUE_INK.r, DesignSystem.BLUE_INK.g, DesignSystem.BLUE_INK.b, 0.45)
	elif st == WordState.UNLOCKED:
		name_col = WORD_NAME_UNLOCKED
	var name_baseline := name_mid_y + f_name.get_ascent(NAME_SIZE) * 0.5 - f_name.get_descent(NAME_SIZE) * 0.5
	_draw_text(f_name, Vector2(name_left, name_baseline),
		str(w.get("display", w.id)), NAME_SIZE, name_col)
	# Cost hint below the name (095, P5-2; 134: SLATE Ink-Soft #5A6B7D, HINT_SIZE ≥12px for legibility).
	if show_cost_hint:
		var hint_baseline := name_mid_y + f_name.get_ascent(NAME_SIZE) * 0.5 - f_name.get_descent(NAME_SIZE) * 0.5 + f_badge.get_ascent(HINT_SIZE) + 2.0
		_draw_text(f_badge, Vector2(name_left, hint_baseline),
			cost_hint, HINT_SIZE, WORD_COST_HINT)
	# The state badge, right-aligned. A cooling ACTIVE word shows "Hviler (n)" (resting, n marks
	# left) so the size of the rest cost is legible — was a bare "Hviler" before 095.
	## Cooling badge: SLATE_SOFT at 0.70 alpha — dimmed, same family as locked, distinct from active.
	var word_badge: String
	var word_badge_col := WORD_NAME_LOCKED
	if st == WordState.ACTIVE and cooling:
		word_badge = "Hviler (%d)" % remaining
		word_badge_col = Color(DesignSystem.SLATE_SOFT.r, DesignSystem.SLATE_SOFT.g, DesignSystem.SLATE_SOFT.b, 0.70)
	elif st == WordState.ACTIVE:
		word_badge = WORD_BADGE[WordState.ACTIVE]
		word_badge_col = BADGE_LEARNED
	elif st == WordState.UNLOCKED:
		word_badge = WORD_BADGE[WordState.UNLOCKED]
		word_badge_col = BADGE_AVAILABLE
	else:
		word_badge = WORD_BADGE[st]
	var word_badge_baseline := rect.position.y + rect.size.y * 0.5 + f_badge.get_ascent(BADGE_SIZE) * 0.5 - f_badge.get_descent(BADGE_SIZE) * 0.5
	_draw_text(f_badge, Vector2(rect.position.x, word_badge_baseline), word_badge, BADGE_SIZE, word_badge_col,
		HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)

## One difficulty row (118): the mode name on the left and a state badge on the right. The ACTIVE mode
## reads BLUE + "Valgt" (chosen — DS primary accent); a selectable non-active mode reads SLATE with no
## badge (tap to pick). When the row is LOCKED (special dog, 119) every row greys to SLATE_SOFT and the
## fixed mode shows "Låst" so the player understands the challenge is fixed, not broken. Mirrors
## _draw_breed_row / _draw_word_row so the section reads consistent with the rest of the menu.
func _draw_difficulty_row(f_name: Font, f_badge: Font, i: int) -> void:
	var d: Dictionary = _difficulties[i]
	var rect := _difficulty_row_rect(i)
	var is_active: bool = d.get("active", false)
	var locked: bool = d.get("locked", false)
	# DS pill row background: CREAM for a live/selectable row, near-invisible tint when the mode is
	# locked-and-not-the-fixed-one (dimmed so the fixed mode reads as the single active choice).
	var dim := locked and not is_active
	var row_bg := ROW_BG_LOCKED if dim else ROW_BG
	draw_style_box(DesignSystem.pill(row_bg, DesignSystem.R_MD), rect)
	# The dimmed trade subtitle (121, P4-3): reward × / window-tightening derived from the model.
	# "" for Normal (baseline) → no subtitle; Hard/Expert show the trade before selecting.
	var trade := difficulty_trade_label(
		float(d.get("reward_scale", 1.0)), float(d.get("window_scale", 1.0)))
	var show_trade := trade != ""
	# The mode name, left. With a trade hint, shift the name up to leave room for the hint below
	# (same treatment as the marker-word cost hint, _draw_word_row).
	var name_col := DIFF_NAME_IDLE
	if locked:
		name_col = DIFF_NAME_ACTIVE if is_active else DIFF_NAME_LOCKED
	elif is_active:
		name_col = DIFF_NAME_ACTIVE
	var name_mid_y := rect.position.y + rect.size.y * 0.5
	if show_trade:
		name_mid_y = rect.position.y + rect.size.y * 0.5 - f_name.get_ascent(HINT_SIZE) * 0.5 - 1.0
	var name_baseline := name_mid_y + f_name.get_ascent(NAME_SIZE) * 0.5 - f_name.get_descent(NAME_SIZE) * 0.5
	_draw_text(f_name, Vector2(rect.position.x + 14.0, name_baseline),
		str(d.get("name", d.id)), NAME_SIZE, name_col)
	# Trade subtitle below the name (121; 134: SLATE Ink-Soft #5A6B7D, HINT_SIZE ≥12px for legibility).
	if show_trade:
		var hint_baseline := name_mid_y + f_name.get_ascent(NAME_SIZE) * 0.5 - f_name.get_descent(NAME_SIZE) * 0.5 + f_badge.get_ascent(HINT_SIZE) + 2.0
		_draw_text(f_badge, Vector2(rect.position.x + 14.0, hint_baseline),
			trade, HINT_SIZE, DIFF_TRADE_HINT)
	# The badge, right. Locked-active → "Låst"; unlocked-active → "Valgt"; other rows show no badge.
	var badge := ""
	var badge_col := DIFF_NAME_ACTIVE
	if is_active and locked:
		badge = DIFF_BADGE_LOCKED
		badge_col = DIFF_NAME_LOCKED
	elif is_active:
		badge = DIFF_BADGE_ACTIVE
		badge_col = DIFF_NAME_ACTIVE
	if badge != "":
		var badge_baseline := rect.position.y + rect.size.y * 0.5 + f_badge.get_ascent(BADGE_SIZE) * 0.5 - f_badge.get_descent(BADGE_SIZE) * 0.5
		_draw_text(f_badge, Vector2(rect.position.x, badge_baseline), badge, BADGE_SIZE, badge_col,
			HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x - 14.0)
