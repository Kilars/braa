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

## The shipped dogs, in kennel order (starter Bella first) — the single source of truth, a direct
## transcription of the spec table (phase8.md:147-159). Rows: id, name, breed, rarity, price,
## [stats], unique_trait, band_tint. Kept as a literal table so it reads like the spec and a stray
## edit fails the test_each_dog_matches_the_spec_table_exactly guard.
const DOGS := [
	["bella",  "Bella",  "Labrador retriever", Rarity.OWNED,  0,   [4, 3, 4, 3], "Godbit-radar",            Color(0.29, 0.565, 0.886)],
	["nova",   "Nova",   "Border collie",      Rarity.EPIC,   900, [5, 5, 4, 5], "Øyet",                    Color(0.298, 0.322, 0.357)],
	["balder", "Balder", "Schäferhund",        Rarity.RARE,   650, [4, 4, 5, 4], "Vaktpost",                Color(0.663, 0.498, 0.310)],
	["sol",    "Sol",    "Golden retriever",   Rarity.RARE,   500, [4, 3, 4, 3], "Alles venn",              Color(0.886, 0.741, 0.463)],
	["pontus", "Pontus", "Gravhund",           Rarity.COMMON, 350, [2, 3, 4, 2], "Gravemaskin",             Color(0.529, 0.337, 0.212)],
	["lykke",  "Lykke",  "Spisshund",          Rarity.COMMON, 300, [3, 4, 3, 2], "Alarmen",                 Color(0.878, 0.643, 0.373)],
	["sniff",  "Sniff",  "Beagle",             Rarity.COMMON, 320, [3, 4, 3, 2], "Nesa styrer",             Color(0.757, 0.584, 0.369)],
	["trulte", "Trulte", "Malchi",             Rarity.SECRET, 0,   [3, 2, 1, 2], "Skjelver som et aspeløv", Color(0.902, 0.863, 0.796)],
]

## The tricks EVERY breed can train. All 8 dogs share the one Labrador rig, so all can perform the
## PO-signed core (Sitt / Ligg / Legg deg — clips confirmed in the manifest). K-8's "no two breeds
## train identically" comes from BREED-SPECIFIC additions, which need a camera-facing signature clip
## the rig lacks (Grav/Digging plays rear-to-camera → owner-gated, open P3-2 flag) — so we never fake
## distinctness by curating subsets: the core is shared (phase8.md K-8) and the list grows per breed
## the moment an owner clip lands. Returns a FRESH array so no two dogs alias one list.
static func core_tricks() -> Array:
	return [DogClips.TRICK_SITT, DogClips.TRICK_LIGG, DogClips.TRICK_LEGG_DEG]

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
	return d
