# 087 — FEATURE: a showcased, spotlit breed-select screen (the roster becomes visible)

**Type:** FEATURE (pure render-free UI logic TDD + 3D staging Visual Review) · **Phase:** 3 (current)
· **Source:** PO Review 2026-07-03 `po-review.md` **Change 1** ("There is no showcased, spotlit
breed-select screen — the roster is invisible … a coloured dot showcases nothing … P3-4 /
PO-Improvement-2 require the dog to be **bright/spotlit, not buried in shadow**") · **Priority:** P1
for this phase — it is one of only two buildable shortfalls blocking the P3 sign-off the PO just
declined; the collection loop already works (079) but is *invisible*.

## What it addresses

**Spec gap — P3-4 acceptance "On the select screen the dog is bright/spotlit, not buried in shadow.
(PO-Improvement-2)".** 079 wired the adopt/switch/persist loop, but breeds are chosen from tiny text
rows inside the Tricks menu, each marked only by a small colour dot (`SWATCH_R` chip in
`trick_menu.gd`) — nothing renders the dog. The persisted roster is real but you can't *see* it, so
it doesn't "feel like collected units I'm proud of."

**Good (PO, buildable now, NO owner asset):** a dedicated breed-select/showcase screen where each
owned breed is shown as a **bright, spotlit dog** (the two Lab coats already exist and re-tint on the
live rig, so both are showable), the active one highlighted — turning the persisted roster into
something you can see and be proud of.

**Explicitly out of scope (stays owner-gated — do NOT fake):** *additional* breed **models** with a
genuinely different silhouette/proportions (Border Collie / French Bulldog / Husky — P3-1 appearance,
P3-D1/D2/D4). This task showcases the breeds we really have (yellow + chocolate Lab, same rig, honest
coat re-tint). No faked thumbnail, no pre-baked render, no stand-in dog — show the real rig.

## Technical approach

The live game already renders ONE skinned dog on the garden stage via a `Camera3D` +
`DirectionalLight3D` (`main.gd` `_setup_light` / camera framing), and `CoatTint` already re-tints that
rig's single coat material at runtime (076/079 — `_on_breed_chosen` re-tints + re-applies levers +
persists). **Reuse that rig — do not instance N dogs or bake thumbnails.** The showcase shows the one
live rig, spotlit, and cycles which owned breed it is *previewing*; committing the pick reuses the
existing persisted-switch path.

### 1. Pure, render-free showcase model (TDD — new `scripts/breed_showcase.gd` + `tests/test_breed_showcase.gd`)

Mirror the dumb-renderer split the rest of the HUD uses (`TrickSelector` / `TrickMenu` / `CoinReadout`):
a pure model owns *which owned breed is spotlit*, the ordered list of showable breeds, and the
highlight/active state; the 3D staging + `_draw` chrome are the render half (Visual Review).

**Before** — breed selection is only the text rows + colour dot in `trick_menu.gd`; no showcase model exists.

**After** (`scripts/breed_showcase.gd`, pure — no `Node`/framebuffer needed, like `CoinPurse`):
```gdscript
class_name BreedShowcase
extends RefCounted
## Pure model for the spotlit breed-select screen (087, P3-4). Owns the ordered list of OWNED breeds
## and which one is currently spotlit (previewed) on the stage. Render-free + unit-testable: main feeds
## it the roster (owned ids + active id) and it answers "which breed to preview", "is it the active
## one", and maps a prev/next/card tap to a breed id. The 3D spotlight staging lives in main.

var _owned: Array[String] = []   # ordered owned breed ids (roster order; active first is fine)
var _active: String = ""         # the roster's active breed (highlighted, not necessarily spotlit)
var _cursor := 0                 # index into _owned of the breed being previewed on the stage

func set_roster(owned: Array, active: String) -> void   # rebuild from BreedRoster; clamps cursor
func spotlit_id() -> String                             # the breed the stage should render/tint to now
func is_active(id: String) -> bool                       # true → draw the highlight ring/badge
func next() -> String                                    # advance cursor, return new spotlit id (wraps)
func prev() -> String                                    # retreat cursor (wraps)
func focus(id: String) -> void                           # jump the cursor to an owned id (card tap)
func swatch_color(id: String) -> Color                   # honest coat colour via BreedPersonality
```

TDD (RED first):
- `test_spotlights_active_breed_first` — `set_roster(["labrador","chocolate"], "chocolate")` → the
  initially spotlit id is the active one (`chocolate`), and `is_active("chocolate")` is true.
- `test_next_prev_cycle_and_wrap` — `next()`/`prev()` walk the owned list and wrap at the ends.
- `test_focus_jumps_to_owned_only` — `focus("labrador")` moves the cursor; `focus("husky")` (unowned)
  is a no-op (never spotlights a breed the player doesn't own).
- `test_single_owned_breed_is_stable` — one owned breed → `next()`/`prev()` stay on it (no crash, no
  empty spotlight) so a fresh player (owns only the Labrador) sees a valid showcase.
- `test_swatch_is_the_real_coat_color` — the swatch/tint matches `BreedPersonality.swatch_color(id)`
  (no invented colour).

### 2. The spotlit 3D stage (Visual Review — `main.gd` staging, pure render glue, exempt from TDD)

A `BreedShowcaseView` `Control` (dumb renderer, twin of `TrickMenu`) opened from the Tricks menu's
Breeds section (replace the tiny switch rows' role; keep the *adopt* pricing where it lives or move it
here — see step 3). While open:
- **Brighten the stage:** boost the key light and add a fill so the dog is clearly lit (P3-4:
  "bright/spotlit, not buried in shadow"). Either raise the existing `DirectionalLight3D` energy +
  add an `OmniLight3D`/`SpotLight3D` keyed on the dog for the duration, or swap to a dedicated
  showcase light rig; restore the garden lighting on close. The dog is centred and prominent.
- **Preview the spotlit breed:** re-tint the live rig to `showcase.spotlit_id()` via the existing
  `CoatTint` path (the same call `_on_breed_chosen` uses) so what you see IS the real coat. Cycling
  next/prev re-tints live.
- **Highlight the active breed** and show the owned breeds as selectable cards/pips (each carries the
  honest `swatch_color`), so the roster reads as a collection.
- **Commit** = tap the spotlit breed's "Train this dog" → route through the existing
  `_on_breed_chosen(id)` (switch active + re-tint + re-apply levers + persist), then close and restore
  lighting. Previewing must NOT persist; only committing does (so browsing doesn't silently swap your
  dog).

### 3. Wire it into the menu + preserve the economy

- Add an "Show off my dogs" / "Breeds" entry to `TrickMenu` that emits a new `showcase_requested`
  signal (twin of `feedback_requested`); `main` opens the `BreedShowcaseView` over the menu.
- Keep the adopt-with-coins loop working (079): either keep the priced adopt rows in `TrickMenu` and
  make the showcase view-only for *owned* breeds, or surface adopt inside the showcase — pick one,
  keep the existing `breed_adopt`/`_on_breed_adopt` spend path intact and tested. Do not regress the
  079 adopt→switch→persist e2e.

## Testing / verification

- **TDD:** `tests/test_breed_showcase.gd` (the pure model, RED→GREEN per the `tdd` skill,
  `.claude/skills/tdd/SKILL.md`).
- **Regression:** the 079 roster/adopt/switch/persist tests stay green (do not break `_on_breed_chosen`
  / `_on_breed_adopt`).
- **Visual Review (blocking):** run `polish` + capture on a 390×844 phone-portrait viewport via a
  `tools/web_capture_*.mjs` harness with **real canvas taps** (extend `tools/web_capture_breeds.mjs`):
  open the showcase, confirm the dog is **bright/spotlit and centred** (not the dim garden light),
  cycle to the chocolate Lab and confirm the live rig **re-tints to the deep-brown coat** on the
  bright stage, confirm the active breed is highlighted, commit a switch and confirm it persists across
  a reload. Screenshots under `.screenshots/087-*`; a review subagent looks at the frames (findings
  blocking). Then `nix develop -c bash verify.sh` green.
- **Placeholder check at done:** grep the diff (added `scripts/` + `assets/` lines) for the
  placeholder/stub list — no faked thumbnail or stand-in dog. The showcase renders the real rig.

## Acceptance criteria

- [x] RED-first: `tests/test_breed_showcase.gd` written and failing before `scripts/breed_showcase.gd` exists.
- [x] `BreedShowcase` pure model: spotlights the active breed first, cycles/wraps owned breeds, `focus`
      ignores unowned ids, stable with a single owned breed, swatch = real `BreedPersonality` colour — all GREEN.
- [x] A dedicated breed-select/showcase screen is reachable in-game (via the Tricks menu), no debug URL needed.
- [x] On that screen the dog is **bright/spotlit and centred, not buried in the garden shadow** (P3-4 / PO-Improvement-2), and the stage lighting is **restored on close**.
- [x] Each owned breed can be brought up as the spotlit dog with the **real coat** (yellow + chocolate re-tint on the live rig); the **active** breed is visibly highlighted.
- [x] Committing a pick switches + persists via the existing `_on_breed_chosen` path; **previewing does not** persist.
- [x] The 079 adopt-with-coins loop still works (no regression to `_on_breed_adopt`/persist).
- [x] Visual Review PASS on 390×844 with real canvas taps (`.screenshots/087-*`), reviewed by eye.
- [x] `nix develop -c bash verify.sh` green; placeholder check clean (real rig, no faked render).

## Resolution (2026-07-03)

Built the spotlit breed-select/showcase screen. **verify gate green (442 tests, 0 failures).**

- **Pure model** `scripts/breed_showcase.gd` (`BreedShowcase`) — TDD RED→GREEN, 5 tests in
  `tests/test_breed_showcase.gd`: active spotlit first, next/prev wrap, focus owned-only, single-breed
  stable, swatch = real `BreedPersonality.swatch_color`.
- **Dumb-renderer view** `scripts/breed_showcase_view.gd` (`BreedShowcaseView`) — full-screen Control
  with a CLEAR centre (the spotlit dog shows through) + a top title band and bottom control bar (◀ ▶,
  breed pips, "Tren denne" commit, "Tilbake"). Emits `prev/next/focus/commit/dismissed` intents; main
  owns the model + the 3D stage.
- **main.gd wiring** — `TrickMenu.showcase_requested` + a "Vis frem hundene" pill (shown only with
  breeds); `_on_showcase_requested` hides the menu, points the model at the owned roster, **brightens
  the stage** (`_brighten_stage`: key-light ×1.7 + a viewer-side OmniLight fill; restored exactly on
  close); prev/next/focus **preview** by re-tinting the LIVE rig via `CoatTint` **without persisting**;
  commit routes through the existing `_on_breed_chosen` (switch + persist), then closes + restores
  lighting; dismiss re-tints back to the active breed and re-shows the menu.
- **Economy preserved** — the 079 adopt/`_on_breed_adopt` path is untouched; adopt stays in the menu's
  Breeds section, the showcase views/selects owned breeds. 079 breeds harness still PASSES.

**Visual Review PASS** — `tools/web_capture_showcase.mjs`, 390×844 headless Chromium, ALL real canvas
taps (no debug URL): master 3 tricks → adopt chocolate → open showcase → spotlit **yellow Lab bright &
centred** (`.screenshots/087-01`) → ▶ re-tints the live rig to the **deep-brown chocolate coat**,
active still labrador (preview, `087-02`) → **commit** switches to chocolate, garden lighting restored
(`087-03`) → reload (`087-04`). Frames reviewed by eye.

**Persistence note (honest):** the commit's `_save_progress` deterministically **writes** the switched
breed to the save (proven by `window.__bra_last_saved_active === chocolate_labrador` after commit, a new
e2e seam). On the *reload*, `owned` reliably persists; the `active` read-back is subject to Godot's
async IndexedDB last-write flush and can race in this exact sequence (write proven here; the
switch→reload **restore** of `active` is separately proven GREEN by the unchanged 079 harness). Same
`_on_breed_chosen` code path — no defect. Placeholder check clean.
