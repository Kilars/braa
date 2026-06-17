# DESIGN: Final Polish Pass (panel consistency)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: design, ui, polish, visual-review
**Estimated Effort**: Simple

## Context & Motivation

Many panels now exist (kennel, adopt, settings, help, achievements) plus the select
screen + training HUD. A final consistency pass with the `polish` skill mindset:
uniform panel chrome, spacing, button styling, safe-area — so it all feels cohesive.

## Affected Components
- Modify: `src/ui/hud.css` (primarily), `src/ui/hud.ts` only if a structural tweak is needed
- Dependencies: none; Blocking: none

## Approach (CSS-first; no behavior change)
- Audit ALL panels for consistency: header (title + ✕) style, padding, max-width, row spacing, button radii/colors, the dialog backdrop opacity, safe-area insets. Unify any drift (e.g. one panel uses different padding or a different close-button style).
- Check the SELECT screen now that it carries roster row + ⚙ + 🏆/? + many trick buttons + adopt/kennel/graduate/prestige — ensure spacing/scroll is sane on a 390×844 screen (does everything fit, or is a scroll needed? add overflow-y:auto to the select column if it can overflow with 4-5 tricks + buttons).
- Don't change behavior; CSS/markup polish only.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Screenshot the SELECT screen + 2 panels (e.g. kennel + settings) at 390×844; VIEW them; confirm consistent chrome + nothing clipped/overlapping/overflowing. Note anything still off.

## Progress Log
- 2026-06-14 — Task created (iteration 17)

## Resolution

**Completed 2026-06-14**

### Consistency fixes applied to `src/ui/hud.css`

1. **Panel header borders unified**: All five panels (kennel, adopt, settings, help, achievements) previously used different accent-colored header dividers (blue, amber, green, yellow, white). All now use `rgba(255, 255, 255, 0.1)` — one consistent neutral separator. Panel identity is preserved by button/trigger colors, not the divider.

2. **Focus-visible close button coverage**: `#settings-panel-close`, `#help-panel-close`, and `#achievements-panel-close` were missing from the circular close-button focus rule. Added them alongside adopt and kennel to ensure keyboard-nav outline is correct on all close buttons.

3. **Select screen overflow handling**: Changed `#hud-select` from `justify-content: center` (no scroll) to `justify-content: flex-start` with `overflow-y: auto`. Top padding increased to `68px` to clear the fixed ⚙/?  corner buttons (40px + 12px gap + 16px safe offset); bottom padding set to `80px` to clear the fixed Kennel button. At 390×844 the current 4-trick layout has ~300px of empty space below; 5-6 tricks will scroll gracefully. Gap tightened from 24px to 20px between select screen items.

### Screenshot results (real, captured at 390×844)

- **`/tmp/bra-polish-select.png`**: Select screen shows ? (top-left) and ⚙ (top-right) corner buttons not overlapping content. Dog name "Rex", roster chip, 4 trick buttons (Sitt, Ligg, Legg deg, Ikke hopp), and "+ Adopt Dog" button all visible with adequate spacing. Large empty region below confirms no overflow.

- **`/tmp/bra-polish-kennel.png`**: Kennel panel (forced open — button is gated in fresh state). Header shows "Kennel Upgrades" + multiplier + ✕. Three upgrade rows (Treats Pouch 100, Pro Clicker 250, Training Dummy 500) with BUY buttons. The select screen faintly visible through the 0.97-opacity background is expected behavior. Header border now matches all other panels.

- **`/tmp/bra-polish-settings.png`**: Settings panel fully visible. Header "Settings" + ✕, Mute audio toggle, Achievements button, Reset progress, stats grid (Prestige/Coins/Level/Tricks mastered). Header border consistent with other panels. Clean layout, no clipping.

### Verification
- `bun run typecheck`: **0 errors**
- `bun run test`: **409 passed (24 files)**
- `bun run build`: **success** (dist/assets/index-*.css 29.43 kB)
- `bun run e2e`: **E2E SMOKE PASS**

## Acceptance Criteria
- [x] Panel chrome (header/close/padding/backdrop/radii) consistent across kennel/adopt/settings/help/achievements
- [x] Select screen fits / scrolls cleanly with all its buttons at 390×844 (no clipping/overlap)
- [x] No behavior change; screenshots reviewed (real)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
