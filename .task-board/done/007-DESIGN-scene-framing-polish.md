# DESIGN: Scene Framing & Visual Polish (placeholder → spec look)

**Status**: Backlog
**Created**: 2026-06-13
**Priority**: Low
**Labels**: design, render, visual-review, polish
**Estimated Effort**: Simple

## Context & Motivation

Findings from the iteration-2 visual review (real headless screenshots of the
playable slice). The HUD works, but the placeholder Babylon scene doesn't yet
match the spec's "Visual Presentation" (bright, Pokémon-GO styling, dog centered,
backdrop fills the portrait screen). Low priority while art is placeholder —
fold into the real dog/scene work, not before.

## Current State

Screenshot review (`/tmp/bra-initial.png`, `/tmp/bra-active.png`) showed:
- A large dark letterbox band across the top ~20% (scene clear-color "sky"); the
  green ground only starts ~1/5 down. Reads as dead space, not a bright field.
- The placeholder dog (sphere) is off-center (upper area), not centered as the
  spec wants.
- BRA button + learned bar + result flash + confused-orange state all render
  correctly — no HUD changes needed.

## Desired Outcome

The scene fills the portrait screen with a bright, readable training-ground feel;
the subject (dog) is centered in frame; the look moves toward the spec's
Pokémon-GO styling.

## Affected Components
- Modify: `src/render/scene.ts` (camera framing, clear color / sky, ground extent, lighting)
- Dependencies: none; pairs naturally with the future "real 3D dog" task

## Technical Approach
- Brighten/replace the clear color or add a sky so the top band isn't dead dark.
- Adjust camera (target/angle/FOV) so the subject is centered and the ground
  fills the lower portrait area; consider full-bleed framing.
- Re-screenshot at 390×844 to confirm (see `scripts/shoot-hud.mjs`).

## Risks & Considerations
- Placeholder art — don't gold-plate; this is a quick framing pass, real polish
  comes with the actual 3D dog/scene assets.

## Progress Log
- 2026-06-13 — Task created from iteration-2 visual review

## Acceptance Criteria
- [x] Scene has no large dead letterbox band; backdrop fills the portrait screen
- [x] Subject (placeholder dog) is centered in frame
- [x] Clear color / lighting reads bright, toward the Pokémon-GO styling
- [x] Re-screenshotted at 390×844 to confirm; HUD still renders correctly on top
- [x] `bun run build` succeeds

## Resolution (2026-06-14)

### Changes made — `src/render/scene.ts` only

**Clear color**: `Color4(0.1, 0.12, 0.18, 1)` → `Color4(0.55, 0.78, 0.95, 1)` — dark
navy replaced by bright sky blue. Eliminates the dead dark letterbox entirely; the top
band now reads as sky (a scene element, not dead space).

**Camera beta**: `Math.PI / 3` (~60°) → `1.42` (~81° from vertical) — shallower angle
means less sky in frame, horizon sits behind the sphere rather than well above it.

**Camera target**: `Vector3.Zero()` → `Vector3(0, 0.6, 0)` — targets the sphere center
(y = BASE_Y = 0.6) instead of world origin; this is what centers the dog vertically.

**Camera radius**: `6` → `4.5` — closer crop, dog fills more of the portrait canvas.

**Light intensity**: `0.9` → `1.2`; ground color: `(0.2, 0.25, 0.3)` (muddy dark) →
`(0.45, 0.55, 0.4)` (warm green fill). Removes the muddy underside shadow on the sphere.

**Ground diffuse**: `(0.3, 0.55, 0.3)` → `(0.38, 0.72, 0.38)` — vivid grass, closer to
Pokémon GO bright palette.

### Before/after screenshots
- Before: `/tmp/bra-scene-before.png` — dark navy band top ~20%, sphere off-center upper-left
- After: `/tmp/bra-scene-after.png` — bright sky-blue top, sphere centered at horizon, ground fills lower 60%, BRA button and HUD text still contrast well

### Verification
- `bun run typecheck`: 0 errors
- `bun run test`: 254/254 passed (all 20 test files)
- `bun run build`: success (dist built)
- All 5 dog visual states untouched (idle/offering/confused/happy/distractor)
