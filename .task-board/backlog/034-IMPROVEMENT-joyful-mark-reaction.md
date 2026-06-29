# IMPROVEMENT: 034 — The mark reads as joy, not a lone bark (P1-6)

**Status**: Backlog
**Created**: 2026-06-29
**Priority**: High — open **PO directive** (Improvements) blocking the Phase-1
Visual-Review sign-off (P1-10). Only-remaining-gap override applies (visual domain
saturated, but this is one of just two open Phase-1 PO findings).
**Labels**: visual, animation, gameplay, phase-1, po-directive, tdd
**Estimated Effort**: Small–Medium

## What it addresses (PO directive, `.docs/specs/po-review.md` → Improvements)

> **The "positive reaction" is a lone Bark and doesn't read as celebration (P1-6).**
> The licensed pack's only clip matching the reaction vocab is `Bark` … a successful
> mark fires a single bark on a dog whose mouth is already open in idle — no clear,
> joyful reaction … Playing a (standing) Bark over the seated pose also risks a pose
> pop. *Good looks like:* a reaction that reads as joy at phone size — e.g. a small
> happy bounce/hop (the pack has `Jump_Place`/`JumpAir_low`) or a clear perk-up,
> blended cleanly from the seat with no snap, PERFECT brighter than OK — confirmed in
> a capture.

## Root cause (audit 2026-06-29)

`scripts/dog_clips.gd:22`:

```gdscript
const REACTION_VOCAB := ["wag", "happy", "excit", "greet", "celebrat", "perk", "bark"]
```

`_pick_reaction()` walks the vocab in priority order and returns the first matching
clip. On the licensed Labrador the only matching leaf is `Bark`, so `reaction` resolves
to `Bark` — the lone bark the PO saw. The joyful `Jump_Place` / `JumpAir_low` clips are
**invisible to the resolver**: "jump" was deliberately excluded as generic locomotion
(so the CC0 dog's generic `Jump` can't fake a celebration), so the vocab change must be
**specific** enough to catch the licensed `Jump_Place` / `JumpAir_low` **without**
matching the CC0 `Jump`.

## Technical Approach

**Step 0 — confirm the real clip names first (don't guess).** The verified `LAB`
constant in `tests/test_dog_clips.gd` is incomplete (it lists only idle/sit/walk).
Before coding, probe the on-disk licensed glb (`assets/models/dog_licensed.glb`, present
locally, gitignored) for its actual leaf names — e.g. a one-off headless dump of
`AnimationPlayer.get_animation_list()` (or `nix develop -c godot --headless` script).
Record the **exact** joyful leaf names (expected `Jump_Place`, `JumpAir_low`) in the
task notes and use those literals. If neither exists, fall back to a perk-up clip that
does; do **not** invent a clip name.

**Step 1 — prefer a joyful bounce over the bark (vocab priority).** Insert
licensed-specific joyful terms ahead of `"bark"`, specific enough not to match the CC0
`Jump`:

**Before:**

```gdscript
const REACTION_VOCAB := ["wag", "happy", "excit", "greet", "celebrat", "perk", "bark"]
```

**After** (use the leaf names confirmed in Step 0; these match `Jump_Place` /
`JumpAir_low` but NOT a bare `Jump`):

```gdscript
## Positive-reaction leaf substrings, in priority order. A joyful bounce reads as
## celebration at phone size, so the licensed pack's hop clips rank ahead of a bare
## Bark. Terms stay reaction-SPECIFIC — "jump_place"/"jumpair", never a bare "jump" —
## so the CC0 placeholder's generic `Jump` is still NOT mistaken for a celebration
## (it resolves no reaction and stays idle; the 024f asset gate holds). (P1-6, task 034)
const REACTION_VOCAB := [
	"jump_place", "jumpair", "wag", "happy", "excit", "greet", "celebrat", "perk", "bark",
]
```

`_pick_reaction()` already walks vocab order, so no other resolver change is needed:
the licensed dog now resolves the bounce; the CC0 dog still resolves `""` (its `Jump`
leaf matches none of the specific terms); a dog that only had `Bark` would still fall
through to it.

**Step 2 — blend cleanly from the seat (no pose pop).** In `scripts/dog_director.gd`
`play_reaction()` (currently a bare `_ap.play(clips.reaction)`), use a short blend /
crossfade into the reaction from the seated pose, then queue back to the sit-loop / idle
as it does now, so the hop doesn't snap. (Render glue → Visual Review, not unit-tested.)
PERFECT-brighter-than-OK already lives in `MarkPayoff`/`PayoffPlayer`; keep that gate —
the reaction fires on a successful mark, nothing on MISS / dead tap.

### TDD steps (resolver logic)

In `tests/test_dog_clips.gd`:

1. **Red — joyful preferred over bark.** Build a synthetic licensed-style list
   containing both `"Arm_Labrador|Jump_Place"` and `"Arm_Labrador|Bark"`; assert
   `DogClips.resolve(list).reaction` ends with the joyful clip (`Jump_Place`), **not**
   `Bark`. Fails today (returns `Bark`).
2. **Red — CC0 generic Jump is NOT a reaction.** Build a CC0-style list containing a
   bare `"AnimalArmature|...|Jump"` (and no reaction-vocab clip); assert `reaction == ""`
   and `has_reaction()` is false (the asset gate holds — no faked celebration).
3. **Green** — apply the vocab change (Step 1) → both pass.
4. Keep the existing `LAB`/CC0 sit-resolution tests green. Optionally extend the
   `if present` licensed test to assert `has_reaction()` is true on the real asset once
   Step 0 confirms the joyful clip exists.

Follow `.claude/skills/tdd/SKILL.md` (red → green → refactor).

## Visual Review (the real gate)

Run `polish`, then spawn review agents on the **running local licensed web export** at
390×844: trigger a PERFECT mark and capture the post-mark frames. The dog must give a
**clearly joyful** reaction (a happy bounce/hop or clear perk-up) that reads at phone
size, **blended cleanly from the seat with no snap/pop**, and nothing must fire on a
MISS / dead tap. Findings are blocking. Save the proof frame under `.screenshots/`.

## Acceptance Criteria

- [ ] Step 0 done: the **actual** joyful leaf name(s) on `assets/models/dog_licensed.glb`
      are probed and recorded (not guessed); the vocab uses those literals.
- [ ] Failing tests written first per `tdd`: (a) joyful clip preferred over `Bark`;
      (b) CC0 generic `Jump` resolves no reaction (`reaction == ""`).
- [ ] `REACTION_VOCAB` ranks the licensed joyful bounce ahead of `bark`, with terms
      specific enough that the CC0 `Jump` is still not matched.
- [ ] Reaction blends cleanly from the seated pose (no snap), then returns to the loop.
- [ ] Audio/reaction gate intact: fires on a successful mark only; silent on MISS /
      dead tap; PERFECT brighter than OK.
- [ ] Visual Review on the running 390×844 licensed export confirms a joyful,
      pop-free reaction — with a captured proof frame in `.screenshots/`.
- [ ] `nix develop -c bash verify.sh` green (import → boot → test → export).
