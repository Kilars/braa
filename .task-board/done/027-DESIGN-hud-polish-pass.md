# DESIGN: HUD Polish Pass

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: design, ui, polish, visual-review
**Estimated Effort**: Simple

## Context & Motivation

The HUD has grown a lot (bar, coins/level, difficulty selector, trick label,
BRA + tell ring, loadout chip, kennel button, select screen, kennel panel).
Accumulated minor issues need a quality pass — use the `polish` skill.

## Known issues (from prior screenshots)
- `#hud-trick-label` sits tight against the very top edge and close to the
  difficulty selector — needs breathing room / clear separation.
- The loadout chip (bottom-left) crowds the BRA button's left edge.
- General sweep: consistent margins/safe-area insets, alignment, spacing, font
  sizes, tap-target sizes, and z-order across ALL HUD elements + the select
  screen + the kennel panel.

## Affected Components
- Modify: `src/ui/hud.css` (primarily), `src/ui/hud.ts` (only if structure must change)
- Dependencies: none; Blocking: none

## Approach
- Run the **`polish`** skill mindset: alignment, spacing, consistency, interaction
  states, edge cases. Fix the two known crowding issues first, then sweep for
  consistency. Don't change behavior — visual/layout only.
- Respect `env(safe-area-inset-*)` for notch/home-bar.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- BEFORE/AFTER screenshots of the training HUD (and select screen) at 390×844.
  VIEW them; confirm the trick label has clearance, the loadout chip no longer
  crowds BRA, and spacing/alignment reads clean. Note anything still off.

## Progress Log
- 2026-06-14 — Task created (iteration 9)

## Resolution

Fixed in `src/ui/hud.css` (CSS-only, no behavior change):

1. **Trick label collision** — `#hud-trick-label` converted to `position:fixed; top:calc(8px + env(safe-area-inset-top,0px) + 48px); left:50%; transform:translateX(-50%)`. This places it ~56px below the top edge, clearly below the 8px bar + 40px diff-selector row, with a 12px gap. No collision at 390px.

2. **Loadout chip crowding** — `#hud-loadout-chip` bottom moved from `48px` to `calc(80px + 32px + 16px + env(safe-area-inset-bottom,0px))` = 128px. Accounts for BRA height (80px) + hud-bottom padding (32px) + 16px gap. Chip now sits clearly above the BRA button with visible breathing room.

3. **Consistency sweep**:
   - `#hud-diff-selector` top now uses `calc(8px + env(safe-area-inset-top,0px) + 8px)` and left uses `calc(12px + env(safe-area-inset-left,0px))`
   - `#hud-loadout-chip` left uses safe-area-inset-left
   - `#hud-kennel-btn` bottom/right changed from `bottom:28px; right:20px` to `calc(16px + env(safe-area-inset-bottom,0px)) / calc(16px + env(safe-area-inset-right,0px))` for consistent 16px margin
   - `#hud-stats` padding: 4px→5px, border-radius: 10px→12px for a slightly cleaner chip
   - `#kennel-panel-header` and `#adopt-panel-header` top-padding uses `calc(16px + env(safe-area-inset-top,0px))`
   - `#hud-select` padding now uses `calc(32px + env(safe-area-inset-*,0px))` on all sides

Before: trick label ("TEACHING: SITT") overlapped the NORMAL/HARD/EXPERT selector at top; loadout chip sat only a few px from BRA's left edge.
After: trick label sits ~12px below the diff selector row; loadout chip has ~16px gap above BRA button; all corners use consistent safe-area insets.

Screenshots: `/tmp/bra-hud-before.png`, `/tmp/bra-hud-after.png`, `/tmp/bra-select-before.png`, `/tmp/bra-select-after.png`

## Acceptance Criteria
- [x] Trick label has clear separation from the top edge and the difficulty selector
- [x] Loadout chip no longer crowds/overlaps the BRA button
- [x] Consistent margins/spacing/alignment across HUD + select + kennel panel (safe-area aware)
- [x] No behavior change; all elements still function
- [x] Before/after screenshots reviewed (real captures)
- [x] `bun run test` green (254/254); `bun run typecheck` clean (0 errors); `bun run build` succeeds
