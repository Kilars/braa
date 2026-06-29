# IMPROVEMENT: 034 — The mark reads as joy, not a lone bark (P1-6)

**Status**: Done (2026-06-29)
**Created**: 2026-06-29

## Step 0 findings — REAL licensed clip names (probed 2026-06-29, `dog_licensed.glb`, 113 clips)

Headless dump of `AnimationPlayer.get_animation_list()` on the on-disk licensed glb.
The task's *expected* names were close but not exact — corrected here:

- **No bare `Jump_Place`.** The in-place full hop is **`Arm_Labrador|Jump_Place_IP`**
  (`_IP` = root-motion stripped → the dog stays centered, ideal for a phone-framed
  bounce). `JumpStart_Place` / `JumpLand_Place` are decomposed pieces, not full hops.
- **`Arm_Labrador|JumpAir_low`** exists (also `JumpAir_low_F`, `JumpAir_high`, …) but
  these are only the *airborne fragment* of a decomposed jump — not a complete grounded
  hop, so they make a weaker reaction than `Jump_Place_IP`.
- Reaction chosen: **`Jump_Place_IP`** (complete in-place hop, grounded start+end).
- Vocab literals used: `"jump_place"` (matches `Jump_Place_IP` and nothing else),
  `"jumpair"` (fallback for the airborne variants). Verified neither matches the CC0
  `Jump` leaf (`"jump"` contains neither substring) → the 024f asset gate still holds.
- Blend (Step 2): `DogDirector` sets `playback_default_blend_time` so seat→hop and
  hop→rest crossfade instead of snapping (decision recorded; visual review is the gate).
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

## Results (2026-06-29)

**Resolver (TDD red→green):** `scripts/dog_clips.gd` `REACTION_VOCAB` now leads with
`"jump_place", "jumpair"` ahead of `"bark"`. On the real licensed glb the reaction
resolves to `Arm_Labrador|Jump_Place_IP` (the complete in-place hop), not `Bark`.
New tests (red first, then green): `test_reaction_prefers_a_joyful_bounce_over_a_lone_bark`,
`test_cc0_generic_jump_is_never_a_reaction`; the `if present` licensed-asset test now
asserts `reaction == Jump_Place_IP` against the on-disk asset. 114 tests, 0 failures.

**Blend (Step 2):** `scripts/dog_director.gd` sets `playback_default_blend_time = 0.2`
in `_init` so seat→hop and hop→rest crossfade (no pose pop). Render glue — visual-gated.

**Visual gate — PASS (own pixel read + independent review agent agree).** Added a
web-only deterministic capture seam `?bra_autotap=1` (mirrors the 030 `force_tell` / 033
`force_tier` seams): fires ONE real PERFECT mark as the clock enters the PERFECT band each
sit, through the real `_on_bra_pressed`, and bumps `window.__bra_reaction_n` so the capture
syncs to the hop. `tools/web_capture_reaction.mjs` drives the LOCAL licensed Web bundle
(the local "Web" pck bundles + prefers `dog_licensed.glb`) in headless Chromium and bursts
15 frames → `.screenshots/034-reaction-NN.png`. Sequence: standing idle (00) → PERFECT mark
+ rise/anticipation (01, gold "PERFECT" readout, legible) → crouch (02) → **airborne joyful
bounce (05)** → settle to seat (08) → clean return to idle (14). No snap/pop, no coat
translucency, no broken limbs; dog stays centered (in-place `_IP`) and grounded (contact
shadow holds). `tools/capture_reaction.{gd,tscn}` is the native analog (like `capture_apex`)
for GL-capable machines; native GL is unavailable in this headless loop env, so the web
path is the in-env gate.

**MISS/DEAD silent:** unchanged gate — `MarkPayoff.reacts()` keys off a successful tier
only; covered by `test_mark_payoff` / `test_payoff_wiring` (no new regression).

## Acceptance Criteria

- [x] Step 0 done: actual joyful leaf names probed (no bare `Jump_Place`; it's
      `Jump_Place_IP`; `JumpAir_low` is only the airborne fragment) and recorded above;
      vocab uses `"jump_place"`/`"jumpair"` literals.
- [x] Failing tests written first per `tdd`: (a) joyful clip preferred over `Bark`;
      (b) CC0 generic `Jump` resolves no reaction (`reaction == ""`). Confirmed red, then green.
- [x] `REACTION_VOCAB` ranks the licensed joyful bounce ahead of `bark`; `"jump_place"`/
      `"jumpair"` don't match the CC0 `Jump` leaf (`"jump"`), so the 024f asset gate holds.
- [x] Reaction blends cleanly from the seated pose (0.2s crossfade), then returns to the loop.
- [x] Audio/reaction gate intact: fires on a successful mark only; silent on MISS / dead
      tap (existing payoff gate/tests); PERFECT (gold) brighter than OK (green) — captured.
- [x] Visual Review on the running 390×844 licensed export confirms a joyful, pop-free
      reaction — proof frames in `.screenshots/034-reaction-NN.png`.
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export).
