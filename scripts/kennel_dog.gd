class_name KennelDog
extends RefCounted
## One adoptable dog in the kennel (103, Phase 8 K-1/K-2/K-6/K-8-data). A pure value object — the
## Resource-shaped record the kennel cell/detail-modal are "fed per dog" (phase8.md:136). It holds
## the kennel IDENTITY + ECONOMY only (name/breed/rarity/price/stats/tint/unique-trait/trick-list);
## the TEMPERAMENT→difficulty levers stay in BreedPersonality (resolved by_id when the training scene
## needs them), so the two records don't duplicate.
##
## The 8 dogs (phase8.md:147-159) all share the ONE licensed Labrador rig — until the owner supplies
## distinct breed models (owner-gated, BUST-068), the grid/modal render each as a tinted stand-in and
## band_tint drives the cell band bg (NOT the coat). This data model renders nothing; it is the
## foundation the grid (K-1) + modal (K-2) read, and the adopt/switch/persist wiring lands with them.

## Rarity drives the price-chip colour in the spec palette (phase8.md:117). Order = value ramp.
enum Rarity { OWNED, COMMON, RARE, EPIC, SECRET }

## The yellow Labrador the player owns from run 1 (spec: Bella, price «Din»). The kennel's starter.
const STARTER_ID := "bella"

var id: String
var dog_name: String     ## Bella, Nova, …            (Baloo 2 in the cell footer)
var breed: String        ## "Labrador retriever", …   (Nunito muted under the name)
var rarity: int          ## Rarity
var price: int           ## coins; 0 == free (Bella owned / Trulte gratis — rarity disambiguates)
var stats: Array         ## [Læreevne, Energi, Mot, Fokus], each 1..5 (the modal's 4 stat rows)
var unique_trait: String ## the one "Unikt trekk"
var band_tint: Color     ## per-dog cell-band bg tint (phase8.md:158) — NOT the coat colour
var trick_ids: Array     ## the tricks this breed can train (shared core; asset-gated, K-8)
var blurb: String        ## one warm Norwegian line shown in the K-2 inspect modal (108)
var traits: Array        ## 2–3 short "raseegenskaper" chip words, e.g. ["Lærevillig","Energisk"]

## The shipped dogs, in kennel order (starter Bella first) — the single source of truth, a direct
## transcription of the spec table (phase8.md:147-159). Rows: id, name, breed, rarity, price,
## [stats], unique_trait, band_tint, blurb, [traits]. Kept as a literal table so it reads like the
## spec and a stray edit fails the test_each_dog_matches_the_spec_table_exactly guard (108: the
## blurb/traits columns are also TDD-pinned via test_each_dog_has_a_blurb_and_traits).
const DOGS := [
	["bella",  "Bella",  "Labrador retriever", Rarity.OWNED,  0,   [4, 3, 4, 3], "Godbit-radar",            Color(0.29, 0.565, 0.886),
		"En varm og tålmodig hund som alltid setter pris på en godbit.",
		["Snill", "Tålmodig", "Glupen"]],
	["nova",   "Nova",   "Border collie",      Rarity.EPIC,   900, [5, 5, 4, 5], "Øyet",                    Color(0.298, 0.322, 0.357),
		"Nova brenner for å lære og gir aldri opp — perfekt for ambisiøse trenere.",
		["Lærevillig", "Energisk", "Intens"]],
	["balder", "Balder", "Schäferhund",        Rarity.RARE,   650, [4, 4, 5, 4], "Vaktpost",                Color(0.663, 0.498, 0.310),
		"Stødig og modig — Balder holder alltid øye med flokken sin.",
		["Modig", "Lojal", "Årvåken"]],
	["sol",    "Sol",    "Golden retriever",   Rarity.RARE,   500, [4, 3, 4, 3], "Alles venn",              Color(0.886, 0.741, 0.463),
		"Sol lyser opp rommet og gjør raskt venner med alle hun møter.",
		["Vennlig", "Glad", "Tillitsfull"]],
	["pontus", "Pontus", "Gravhund",           Rarity.COMMON, 350, [2, 3, 4, 2], "Gravemaskin",             Color(0.529, 0.337, 0.212),
		"Pontus følger nesa si — og nesa sier alltid «grav her».",
		["Sta", "Nysgjerrig", "Utholdende"]],
	["lykke",  "Lykke",  "Spisshund",          Rarity.COMMON, 300, [3, 4, 3, 2], "Alarmen",                 Color(0.878, 0.643, 0.373),
		"Lykke er alltid klar til å varsle — ingenting slipper forbi de spisse ørene.",
		["Vaktsom", "Livlig", "Selvstendig"]],
	["sniff",  "Sniff",  "Beagle",             Rarity.COMMON, 320, [3, 4, 3, 2], "Nesa styrer",             Color(0.757, 0.584, 0.369),
		"Der nesa peker, følger Sniff — luktesansen er hans superkraft.",
		["Sporty", "Sta", "Sosial"]],
	["trulte", "Trulte", "Malchi",             Rarity.SECRET, 0,   [3, 2, 1, 2], "Skjelver som et aspeløv", Color(0.902, 0.863, 0.796),
		"Liten, skjelvende og overraskende modig — Trulte er kennelens beste hemmelighet.",
		["Modig", "Skjelvende", "Liten"]],
]

## The tricks EVERY breed can train. All 8 dogs share the one Labrador rig, so all can perform the
## PO-signed core (Sitt / Ligg / Legg deg — clips confirmed in the manifest). K-8's "no two breeds
## train identically" comes from BREED-SPECIFIC additions, which need a camera-facing signature clip
## the rig lacks (Grav/Digging plays rear-to-camera → owner-gated, open P3-2 flag) — so we never fake
## distinctness by curating subsets: the core is shared (phase8.md K-8) and the list grows per breed
## the moment an owner clip lands. Returns a FRESH array so no two dogs alias one list.
static func core_tricks() -> Array:
	return [DogClips.TRICK_SITT, DogClips.TRICK_LIGG, DogClips.TRICK_LEGG_DEG]

## The runtime coat recolor for this dog (110, K-5 honest stand-in). All 8 dogs share the ONE
## licensed Labrador rig; a chosen dog re-tints that rig's baked coat atlas by multiplying it with
## this Color via CoatTint (the exact 076 chocolate-Lab mechanism) — a genuine per-dog variant, NOT
## a faked new model (BUST-068, already flagged). The STARTER (Bella) is the real yellow Labrador, so
## her tint is the identity Color(1,1,1) — the atlas IS her coat, left untouched. Every other dog
## re-tints toward its breed-representative band_tint (the warm browns / greys / tans the modal band
## already shows), so «Tren med Nova» loads a visibly distinct dark-grey dog, «Tren med Pontus» a
## deep-brown one, etc. Distinct per-breed MODELS stay owner-gated — the tint is the honest stand-in.
func coat_tint() -> Color:
	return Color(1, 1, 1) if id == STARTER_ID else band_tint

## The warm cream/yellow of the real licensed yellow-Labrador coat — Bella's actual coat on the
## signed-off training page. Used ONLY as her kennel-portrait modulate (below); NOT a training
## re-tint (there she rides the untouched atlas via coat_tint()'s identity).
const STARTER_PORTRAIT_TINT := Color(0.905, 0.760, 0.470)

## The COAT modulate for the 116 kennel portrait (117, PO 2026-07-05). The portrait renders the
## dog at a neutral grey coat, then modulates per breed — so this must be the dog's NATURAL coat
## hue, DECOUPLED from `band_tint` (which is the rarity/ownership BAND background, not a coat
## colour). The starter Bella sits on a BLUE owned-rarity band but is the real warm-cream yellow
## Labrador, so her portrait reads her training coat, not blue. The other 7 dogs' band hues are
## already plausible dog coats (warm browns / greys / tans), so their portrait tint = band_tint.
func portrait_tint() -> Color:
	return STARTER_PORTRAIT_TINT if id == STARTER_ID else band_tint

## Whether this dog LOCKS the global difficulty (119, P4-1 "for special dogs difficulty should be
## locked"). "Special" = a collectible/secret dog (RARE / EPIC / SECRET) — the challenge is part of
## the dog, so the player can't trade it away. The OWNED starter (Bella) and plain COMMON adoptables
## stay freely choosable. Pure predicate off the spec rarity rows (phase8.md:147-159).
func locks_difficulty() -> bool:
	return rarity == Rarity.RARE or rarity == Rarity.EPIC or rarity == Rarity.SECRET

## The player-facing Norwegian rarity badge label (148, PO father-pass-12 X-4). Owned/secret keep
## their existing words («Din» / «Påskeegg»); the three buyable rarities surface the ladder as
## «Vanlig» / «Sjelden» / «Episk» so a browsing player can read Common→Rare→Epic at a glance.
## Pure map off the enum — the grid cell + inspect modal both draw this through the SAME
## corner-badge component (no per-cell band fill).
static func rarity_label(rarity: int) -> String:
	match rarity:
		Rarity.OWNED:  return "Din"
		Rarity.COMMON: return "Vanlig"
		Rarity.RARE:   return "Sjelden"
		Rarity.EPIC:   return "Episk"
		Rarity.SECRET: return "Påskeegg"
	return ""

## The fixed difficulty mode a special dog pins (119, P4-1). A special dog is a set challenge —
## Hard — never the free Normal. The exact mode is a product knob; it must name a known Difficulty id.
func locked_difficulty_id() -> String:
	return "hard"

## Map a 1..5 stat to a difficulty-lever multiplier centred on 1.0 (stat 3 == neutral 1.0), reaching
## ±(span/2) at the extremes (stat 1 == 1-span/2, stat 5 == 1+span/2). Keeps every lever near 1.0 so a
## chosen dog stays inside the PO-signed feel band — a temperament delta, never a shake-up (cf. 075).
static func _stat_scale(stat: int, span: float) -> float:
	return 1.0 + (clampi(stat, 1, 5) - 3) * (span * 0.5)

## Map this dog's 4 stats [Læreevne, Energi, Mot, Fokus] onto the training-scene difficulty levers as a
## BreedPersonality (110, K-5 stats apply) — the same lever object the Phase-3 breed switch drives, so
## `_apply_active_kennel_dog` reuses the proven 075/079 path with no parallel system. Each stat drives
## exactly one lever: Læreevne→learn_speed (fills the learned bar faster), Energi→energy (quicker
## offers), Fokus→window_stability (a focused dog holds a steadier, more forgiving timing window), and
## Mot→distractibility *inversely* (a bold dog resists distraction → fewer feints; a timid one fidgets
## → more). The dog's coat_tint() rides along so the switch re-tints the coat too. Pure + unit-tested.
func to_personality() -> BreedPersonality:
	var s := stats if stats.size() >= 4 else [3, 3, 3, 3]
	var learn := _stat_scale(s[0], 0.30)          # Læreevne → learn_speed  (stat5 ≈ 1.15, the Lab's feel)
	var energ := _stat_scale(s[1], 0.20)          # Energi   → energy        (quicker/slower offers)
	var distract := _stat_scale(6 - int(s[2]), 0.30)  # Mot inverse → distractibility (brave = steady)
	var window := _stat_scale(s[3], 0.20)         # Fokus    → window_stability (tighter/looser timing)
	return BreedPersonality.new(id, dog_name, learn, distract, window, energ, coat_tint())

## Build the 8-dog catalog (fresh instances each call — callers may mutate freely).
static func catalog() -> Array:
	var out: Array = []
	for row in DOGS:
		out.append(_from_row(row))
	return out

## True iff `id` names a shipped kennel dog (never an unshipped / ghost id).
static func is_known(id: String) -> bool:
	for row in DOGS:
		if row[0] == id:
			return true
	return false

## Resolve a dog id to its record. An unknown id falls back to the starter Bella — never a dog-less
## resolve, so a corrupt/legacy active id still yields a real dog (mirrors BreedPersonality.by_id).
static func by_id(id: String) -> KennelDog:
	for row in DOGS:
		if row[0] == id:
			return _from_row(row)
	return _from_row(DOGS[0])

## Classify the kennel dogs for display in the grid/modal. Each row carries all state both
## the cell and the detail modal need, so neither renderer re-derives it. Takes the player's
## live economy state (owned set + active dog + balance) and returns per-dog display rows.
static func classify_kennel_dogs(owned: Array, active: String, balance: int) -> Array:
	var rows: Array = []
	for d in catalog():
		var is_owned: bool = owned.has(d.id)
		var is_secret: bool = d.rarity == Rarity.SECRET
		var affordable: bool = is_owned or d.price == 0 or balance >= d.price
		var price_label := "Din" if is_owned else ("Gratis" if is_secret else str(d.price))
		var status_label := "Din hund" if is_owned else ("Påskeegg" if is_secret else "")
		rows.append({
			"id": d.id, "name": d.dog_name, "breed": d.breed, "rarity": d.rarity,
			"price": d.price, "stats": d.stats, "unique_trait": d.unique_trait,
			"band_tint": d.band_tint, "portrait_tint": d.portrait_tint(), "trick_ids": d.trick_ids,
			"blurb": d.blurb, "traits": d.traits,
			"owned": is_owned, "active": d.id == active, "secret": is_secret,
			"affordable": affordable, "status_label": status_label, "price_label": price_label,
			"rarity_label": rarity_label(d.rarity),
		})
	return rows

## Return a Dictionary containing everything the K-2 inspect modal reads for the given dog id.
## Keys: id, name, breed, rarity, price, price_label, stats, unique_trait, trick_ids, blurb,
## traits, band_tint, secret. An unknown id falls back to the starter Bella — never a dog-less
## modal (mirrors by_id's no-dog-less-resolve contract).
static func detail_for(id: String) -> Dictionary:
	var d := by_id(id)  # unknown id already falls back to Bella via by_id
	var is_secret := d.rarity == Rarity.SECRET
	var price_label := "Din" if d.rarity == Rarity.OWNED else ("Gratis" if is_secret else str(d.price))
	return {
		"id": d.id, "name": d.dog_name, "breed": d.breed, "rarity": d.rarity,
		"price": d.price, "price_label": price_label,
		"stats": d.stats.duplicate(), "unique_trait": d.unique_trait,
		"trick_ids": d.trick_ids.duplicate(), "blurb": d.blurb,
		"traits": d.traits.duplicate(), "band_tint": d.band_tint,
		"portrait_tint": d.portrait_tint(),
		"secret": is_secret,
		"rarity_label": rarity_label(d.rarity),
	}

static func _from_row(row: Array) -> KennelDog:
	var d := KennelDog.new()
	d.id = row[0]
	d.dog_name = row[1]
	d.breed = row[2]
	d.rarity = row[3]
	d.price = row[4]
	d.stats = (row[5] as Array).duplicate()
	d.unique_trait = row[6]
	d.band_tint = row[7]
	d.trick_ids = core_tricks()
	d.blurb = row[8] if row.size() > 8 else ""
	d.traits = (row[9] as Array).duplicate() if row.size() > 9 else []
	return d
