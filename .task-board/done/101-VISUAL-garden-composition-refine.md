# 101 — VISUAL: refine the garden composition to the goal (path perspective, coins, fence)

**Phase:** 6 (design system + training-page ambiance) — **current**
**Source:** PO Review 2026-07-04 (`.docs/specs/po-review.md`, HEAD `63ee0ea`) — the ONE remaining
directive after 098 (menu-DS) and 100 (HUD glyph) were signed as resolved & pruned. Not owner-gated.
**Type:** Visual / render-glue refinement (Visual-Review-gated) + regression-guard TDD asserts.

## Why (PO)
Task 099 added all of the goal's *elements* (hedge, house, path, fence, bushes, coins, shadow), but
three read as **broken/unfinished** at 390×844 and pull the eye — so the composition still falls short
of `.docs/specs/assets/goal-training-screen.png`. Confirmed against `.screenshots/po-p6-idle-a.png`.

## Directives (all buildable this phase)
1. **Path perspective is inverted → fix it.** Today the tan ribbon is *wide near the house (far)* and
   *narrows to a floating point at the dog's chest* (a floating triangle, not a path). Goal: a
   continuous winding ribbon **widest in the foreground** (near the viewer / BRA button, behind the
   dog) narrowing as it recedes to the house. Fix: taper the ribbon width (wide near → narrow far) and
   run the near end down **past/around the dog toward the bottom** — no mid-field point.
2. **Coins are oversized and float at shoulder height → shrink + ground them.** Today they read as big
   golden orbs hovering mid-field (`billboard_keep_scale` keeps them screen-constant 4 m back). Goal:
   **small** coins sitting **low on the grass in the lower third**, framing (not crowding) the dog.
3. **Fence is left-only → extend across the right, keep the gate gap.** The gate gap was so wide it ate
   the whole visible right side. Goal: white picket fence line across the whole mid-ground with a gate
   gap where the path passes — visible pickets on **both** sides.
4. **Minor:** firm the grounding-shadow ellipse a touch; let the corner bushes register once the coins
   shrink (move bushes to the foreground corners like the goal).

Keep everything in the DS palette (sky/grass/BLUE/GOLD). Match the layered composition + grounding, not
exact pixels.

## Plan
- Rewrite `_setup_path_to_house`: near end in the foreground (+Z, past the dog), tapered half-width
  (`GARDEN_PATH_WIDTH_NEAR` → `GARDEN_PATH_WIDTH_FAR`), fence crossing pulled near-centre so both fence
  sides show; house stays upper-right.
- Narrow `GARDEN_FENCE_GAP_HALF`, re-centre the gate on the new path crossing so left+right segments
  both render.
- Shrink `GARDEN_COIN_R`, turn off `billboard_keep_scale`, reposition coins low in the lower third to
  the sides.
- Move `_setup_border_bushes` clumps to the foreground corners.
- Nudge the contact-shadow core a touch firmer.
- TDD regression asserts in `tests/test_garden_wiring.gd`: path ribbon reaches the foreground (mesh
  AABB max-Z past the dog centre) and back toward the house; fence has pickets on **both** sides of the
  gate; coins are small (quad size below threshold) and not `billboard_keep_scale`.

## Done when
- verify gate green (import → boot → test → export).
- Visual Review at 390×844 vs the goal: path reads as a receding ribbon (wide foreground → narrow
  house, no floating point), coins small & grounded in the lower third, fence on both sides with a
  gate gap, dog stays centred + unoccluded at idle and at the mark.
- Placeholder check clean; committed + pushed; board consistent.

## Outcome (DONE)
Verify 561/0, gate green. Visual Review at 390×844 (`.screenshots/099-idle-a/b/c.png`, `099-scored.png`)
vs `goal-training-screen.png`:
- **Path — FIXED.** Rewrote the curve to run from a WIDE foreground near end (`GARDEN_PATH_NEAR_Z`,
  past the dog toward the bottom) and taper the ribbon half-width (`GARDEN_PATH_WIDTH_NEAR` 1.0 →
  `GARDEN_PATH_WIDTH_FAR` 0.55) as it recedes to the house. Reads as a real receding ribbon with grass
  margins on both sides — no floating mid-field point.
- **Fence — FIXED.** Narrowed the gate gap (`GARDEN_FENCE_GAP_HALF` 1.4 → 0.8) and pulled the crossing
  near-centre (`GARDEN_FENCE_PATH_X` 1.6 → 0.8). Pickets now render on BOTH sides with a gate gap.
- **Coins — FIXED (oversized floating orbs → small grounded coins).** Shrank `GARDEN_COIN_R` 0.24 → 0.16
  and repositioned to |x|≈1.4-1.7 beside/behind the dog so they clear the big dog silhouette. Two read
  on the left framing the dog (`099-idle-c`), one right. **GL-Compat gotcha found:** `billboard_keep_scale
  = false` collapses the billboard EDGE-ON (invisible) in the GL Compatibility renderer — it must stay
  `true`; the size cap (not keep_scale) is the anti-orb guard, so the TDD test was corrected to assert
  the small quad size.
- **Bushes / shadow — firmed.** Bushes moved to mid-near depth (z≈-3) at |x|≈1.8-2.4 where the narrow
  frustum shows them flanking the dog (they were off-frame in the extreme foreground). Contact-shadow
  core 0.62 → 0.72, wider (×1.55).
- **Camera constraint (recorded).** The camera is pitched only ~17.6° down with a narrow FOV (probe:
  eye `(0,1.79,2.48)`, forward `(0,-0.30,-0.95)`), so the goal's exact lower-third-corner coin placement
  isn't reachable without changing the framing (which would regress the dog-centring tests). Coins are
  small + grounded on the grass beside the dog — the achievable interpretation of "shrink + ground".
- TDD: 3 regression asserts added to `tests/test_garden_wiring.gd` (path reaches foreground + recedes;
  fence pickets both sides + narrow gate; coin small). Placeholder check clean.
