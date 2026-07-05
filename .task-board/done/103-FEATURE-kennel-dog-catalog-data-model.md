# 103 — FEATURE — K-1/K-2/K-6/K-8(data) — the 8-dog kennel catalog data model

**Type:** FEATURE (game logic / data — test-first) · **Phase:** 8 (kennel) — **CURRENT**
**Stories:** K-1 (browse the roster — 8 dogs), K-2 (inspect — stats/rarity/price/trait data),
K-6 (the hidden Trulte dog), K-8 *(data half — per-breed trick list)*. The presentation
surfaces (grid, cell, detail modal) and the adopt/switch/persist WIRING are the **next**
slices — this is the pure, authoritative data foundation they all read.

## What this addresses (spec gap)

Phase 6 was signed off 2026-07-05 (`a3750fe`) → **Phase 8 (kennel) is now current.** The gap
analysis (this scan) found the Phase-3 economy/roster/persistence **spine is complete** —
`CoinPurse` (earn/can_afford/spend), `BreedRoster` (owned/active/adopt/set_active + to_dict/
restore), `TrickStore` (one `user://` save blob), `BreedPersonality` (temperament→levers +
catalog/by_id/is_known), and the adopt/switch wiring in `main.gd` all exist. What's **missing**
is the kennel's own content: the spec names **8 distinct dogs** (`phase8.md:147-159`) with
per-dog **breed / rarity / price / 4 stats / tint / unique-trait / trick-list**, but the shipped
`BreedPersonality.catalog()` holds only **2** (labrador + chocolate). No `kennel`/`Kennelen`
string exists anywhere yet.

This task ships the **8-dog catalog as a pure, tested value object** — the `Resource`-shaped
record the spec's cell/modal are "fed per dog" (`phase8.md:136`). It is the blocking dependency
for K-1 (grid) and K-2 (modal): both render this data.

## Why prioritized now (and why a NEW value object, not an in-place catalog swap)

- **Blocking foundation, dependency order.** The kennel grid (K-1) and detail modal (K-2) are
  pure presentation over this data — they can't be built until the 8-dog model exists and is
  proven. First-the-tested-model-then-wire-the-UI is the exact pattern 091 (`MarkerWords`) used
  before 092–095.
- **Test-first logic, NOT the saturated visual domain.** 7 of the last ~15 done tasks (096–102)
  were rendering — the visual/rendering domain is **saturated**. This slice is pure headless-
  testable data, so it advances the phase without piling onto the saturated domain.
- **Zero risk to the just-signed-off Phase 6.** The completion-menu Breeds section
  (`TrickMenu.classify_breeds`) and the roster both read `BreedPersonality.catalog()`. Expanding
  *that* catalog to 8 in-place would suddenly show 8 dogs (300–900 coins) in the signed-off
  completion popup — a change to a signed-off surface. Instead this task adds a **new,
  self-contained `KennelDog` catalog wired into nothing**; the roster/menu reconciliation to the
  kennel id-space happens in the **screen slice**, where the whole adopt flow changes coherently
  and the father reviews it as one Phase-8 experience. So nothing in the live build changes this
  task (the new file is consumed by the very next task — foundation, not a dead seam).

## Owner-gate notes (honest — do NOT fake, flag what's gated)

- **Distinct breed MODELS are owner-gated (BUST-068 residual).** Only one licensed rig exists
  (`assets/models/dog_licensed.glb`, the Labrador — the manifest is 139 clips all `Arm_Labrador|…`).
  The 7 new breeds (Border collie / Schäferhund / Golden / Gravhund / Spisshund / Beagle / Malchi)
  have **no** model. Per the spec Asset note + BUST-074 (the chocolate-Lab recolor), the kennel
  ships the buildable slices first — the **data model here**, and later the grid/modal rendering
  each dog as a **tinted Labrador stand-in** (the `band_tint` drives the cell band bg) — while the
  distinct silhouettes stay the open owner gate. This task carries the tint DATA; it renders
  nothing. No new flag needed — the existing **BUST-068** flag already names the missing models.
- **K-8 per-breed trick DISTINCTNESS is owner-gated (existing P3-2 flag).** All 8 dogs share the
  one Labrador rig, so all can physically perform the shared core (Sitt / Ligg / Legg deg — clips
  confirmed in the manifest). K-8 wants "no two breeds train identically" via **breed-specific**
  tricks — but the rig has **no camera-facing signature clip** (`Digging`/"Grav" was proven
  rear-to-camera / below the apex-facing bar in task 088 → open `FLAG 2026-07-03 P3-2 divergence`).
  So per the spec's own asset gate ("a breed only offers a trick its rig actually has a clean clip
  for … never faked", `phase8.md:99-101`), every dog's `trick_ids` is the **shared core** now, and
  the field becomes distinct the moment an owner signature clip lands. Building the per-dog
  `trick_ids` field + the asset-gate test is the honest infrastructure; the **distinctness** rides
  the existing P3-2 flag (do NOT re-wire Grav; do NOT fake distinct subsets to manufacture
  variety — the spec says the core is *shared*).

## Technical approach (test-first / TDD — see `.claude/skills/tdd/SKILL.md`)

### A. New `scripts/kennel_dog.gd` — one adoptable dog (pure value object)

Holds the kennel identity + economy only; **temperament/levers stay in `BreedPersonality`**
(resolved `by_id` when training needs them) so the two don't duplicate. All 8 spec rows live in
one readable `const DOGS` table (mirrors the spec table `phase8.md:147-159`), and a factory maps
each row → a `KennelDog` so the constructor stays lean (no long-parameter-list smell).

```gdscript
# scripts/kennel_dog.gd  (new)
class_name KennelDog
extends RefCounted

# Rarity drives the price-chip colour (spec palette phase8.md:117). Order = value ramp.
enum Rarity { OWNED, COMMON, RARE, EPIC, SECRET }

const STARTER_ID := "bella"   # the yellow Labrador the player owns from run 1 (spec: "Din")

var id: String
var dog_name: String     # Bella, Nova, …            (Baloo 2 in the cell footer)
var breed: String        # "Labrador retriever", …   (Nunito muted under the name)
var rarity: int          # Rarity
var price: int           # coins; 0 == gratis (Trulte)
var stats: Array         # [Læreevne, Energi, Mot, Fokus], each 1..5 (modal pips)
var unique_trait: String # the one "Unikt trekk"
var band_tint: Color     # per-dog cell-band bg tint (phase8.md:158) — NOT the coat
var trick_ids: Array     # tricks this breed can train (shared core; asset-gated)

# id, dog_name, breed, rarity, price, [stats], unique_trait, band_tint
const DOGS := [
    ["bella",  "Bella",  "Labrador retriever", Rarity.OWNED,  0,   [4,3,4,3], "Godbit-radar",              Color(0.29,0.565,0.886)],
    ["nova",   "Nova",   "Border collie",      Rarity.EPIC,   900, [5,5,4,5], "Øyet",                      Color(0.298,0.322,0.357)],
    ["balder", "Balder", "Schäferhund",        Rarity.RARE,   650, [4,4,5,4], "Vaktpost",                  Color(0.663,0.498,0.310)],
    ["sol",    "Sol",    "Golden retriever",   Rarity.RARE,   500, [4,3,4,3], "Alles venn",                Color(0.886,0.741,0.463)],
    ["pontus", "Pontus", "Gravhund",           Rarity.COMMON, 350, [2,3,4,2], "Gravemaskin",               Color(0.529,0.337,0.212)],
    ["lykke",  "Lykke",  "Spisshund",          Rarity.COMMON, 300, [3,4,3,2], "Alarmen",                   Color(0.878,0.643,0.373)],
    ["sniff",  "Sniff",  "Beagle",             Rarity.COMMON, 320, [3,4,3,2], "Nesa styrer",               Color(0.757,0.584,0.369)],
    ["trulte", "Trulte", "Malchi",             Rarity.SECRET, 0,   [3,2,1,2], "Skjelver som et aspeløv",   Color(0.902,0.863,0.796)],
]

# Every dog trains the shared core until an owner signature clip lands (K-8, P3-2 flag).
const CORE_TRICKS := [DogClips.TRICK_SITT, DogClips.TRICK_LIGG, DogClips.TRICK_LEGG_DEG]

static func catalog() -> Array           # 8 KennelDog, spec order (Bella first)
static func is_known(id: String) -> bool
static func by_id(id: String) -> KennelDog   # unknown -> the starter (never a dog-less resolve)
```

`price == 0` covers **both** Bella (owned, no price shown) and Trulte (gratis) — the rarity
disambiguates the chip treatment (OWNED «Din» vs SECRET «Gratis»), so the model needs no separate
`is_free`. `trick_ids` is `CORE_TRICKS.duplicate()` per dog (own array — no shared-array aliasing,
same reason `BreedRoster._init` sets `owned` in `_init`).

### B. Behaviors to test first (`tests/test_kennel_dog.gd`, RED → GREEN)

- **Catalog integrity:** `catalog()` returns exactly **8** dogs in spec order, first id `bella`
  == `STARTER_ID`, all ids unique, all lowercase-kebab non-empty strings.
- **Exact spec data (guards typos in the table):** for each dog assert `dog_name` / `breed` /
  `rarity` / `price` / `stats` match the spec table (`phase8.md:147-159`) — e.g. Nova is Border
  collie / EPIC / 900 / [5,5,4,5] / "Øyet"; every `stats` has length 4 with each value in 1..5.
- **Rarity mapping:** Bella OWNED, Nova EPIC, Balder+Sol RARE, Pontus+Lykke+Sniff COMMON,
  Trulte SECRET.
- **The free/owned dogs:** Bella `price == 0` & rarity OWNED; Trulte `price == 0` & rarity SECRET
  (the K-6 gratis easter dog) — and no OTHER dog has `price == 0`.
- **`is_known` / `by_id`:** every catalog id `is_known`; a ghost id (`"husky"`) is not; `by_id`
  resolves each id to the right dog and an unknown id falls back to the starter Bella.
- **K-8 asset gate (never offer a trick with no clip):** every id in every dog's `trick_ids`
  is one of `DogClips.TRICK_SITT/LIGG/LEGG_DEG` **and** — proving it's manifest-backed, not a
  bare string — resolves on the real rig: build a `DogClips.resolve(<licensed clip names>)` (load
  the licensed glb clip list the same way `test_dog_clips.gd` does, or assert against the three
  known ids) and assert `has_trick(id)` for each offered id. Assert each `trick_ids` is non-empty
  and contains the shared core.
- **Roster-shape compatibility (persistence-ready, K-7):** the 8 ids are plain lowercase strings
  suitable for the existing `BreedRoster`/`TrickStore` id list — assert `by_id(id).id == id`
  round-trips for all, so an owned-set of kennel ids stores/restores through the existing blob
  unchanged (full roster wiring is the screen slice; this proves the ids are store-safe now).

### C. No live wiring this task (guard the signed-off surfaces)

Do **not** touch `BreedPersonality.catalog()`, `BreedRoster`, `TrickMenu`, or `main.gd`. The new
file compiles + tests green and is consumed by the next slice. This keeps the signed-off Phase-6
completion menu byte-identical.

## Definition of done / Acceptance criteria

- [x] `scripts/kennel_dog.gd` `KennelDog` value object exists with the fields + `DOGS` table +
      `Rarity` enum + `core_tricks()` + `catalog()` / `is_known()` / `by_id()` / `STARTER_ID`.
- [x] **TDD:** 10 behaviors in §B in `tests/test_kennel_dog.gd`, all green — non-empty assertions,
      no hollow test (test count 561 → 571, exactly +10; the K-8 gate runs against the real resolver).
- [x] The 8-dog data matches the spec table exactly (`phase8.md:147-159`) incl. the tints
      (`phase8.md:158`) and unique traits — guarded by `test_each_dog_matches_the_spec_table_exactly`.
- [x] K-8 asset gate proven: every offered `trick_id` resolves to a real clip on the licensed rig
      (`DogClips.resolve(RIG).has_trick`); the shared core is offered; distinctness left to the owner
      signature clip (existing P3-2 flag — no new flag, no faked subsets, no Grav re-wire).
- [x] No change to `BreedPersonality` / `BreedRoster` / `TrickMenu` / `main.gd` — the diff adds only
      `scripts/kennel_dog.gd` (+.uid) and `tests/test_kennel_dog.gd` (+.uid); Phase-6 menu unaffected.
- [x] `nix develop -c bash verify.sh` green (import · boot · test · export).
- [x] Placeholder-check: only benign hits — "tinted stand-in" (a BUST-068-flag-named approach,
      allowlisted) and negations ("never fake" / "not faked"); no actual stub.

## Resolution (2026-07-05)

Shipped the pure data foundation. `scripts/kennel_dog.gd` `KennelDog` transcribes the spec's 8-dog
table (`phase8.md:147-159`) into one readable `const DOGS`, with a `_from_row` factory keeping the
constructor lean (no long-param-list smell). Identity+economy live here; temperament stays in
`BreedPersonality` (no duplication). `core_tricks()` returns a FRESH `[sitt, ligg, legg_deg]` per dog
(no shared-const aliasing) — every dog offers the manifest-backed shared core, and the K-8 asset-gate
test proves each offered id resolves on the real licensed rig via `DogClips.resolve(RIG).has_trick`.
`price == 0` covers both Bella (OWNED) and Trulte (SECRET/gratis), rarity disambiguating the chip —
no separate `is_free`. Deliberately wired into NOTHING (no roster/menu/main.gd touch) so the just-
signed-off Phase-6 completion menu is byte-identical; the grid (K-1) / modal (K-2) render this, and
the roster reconciliation to the kennel id-space + adopt/switch/persist wiring land with the screen
slice (next scan round) reviewed as one Phase-8 experience. Owner-gated residuals unchanged: distinct
breed MODELS (BUST-068) and breed-specific signature CLIPS (P3-2 flag) — both already flagged, no new
flag raised. verify green, 571/0.
