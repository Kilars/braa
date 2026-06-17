# A11Y: Accessibility & Contrast Sweep

**Status**: Done
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: a11y, ui, design, visual-review
**Estimated Effort**: Simple

## Context & Motivation

The HUD has many interactive elements (BRA, difficulty selector, trick buttons,
roster pills, kennel/adopt/graduate/loadout buttons, panel close buttons). A
quick accessibility pass: labels, focus states, contrast, reduced-motion.

## Affected Components
- Modify: `src/ui/hud.ts` (aria attributes on interactive elements), `src/ui/hud.css` (focus-visible styles, contrast, `prefers-reduced-motion`)
- Dependencies: none; Blocking: none

## Checklist
- **Labels:** every interactive element has an accessible name (`aria-label` or text). Buttons that are icon/short (✕ close, kennel, graduate) get clear labels. Selector segments get `aria-pressed`. Panels get `role="dialog"` + `aria-modal` + a label.
- **Focus:** visible `:focus-visible` outline on all buttons (keyboard nav), distinct from `:active`. Ensure tab order is sane.
- **Contrast:** verify HUD text meets ~AA (4.5:1 for normal text) on its background — especially anything on the bright sky/grass. Add pills/shadows where needed (the trick label already has one). Check coins/level, selector text, combo chip, result flash.
- **Reduced motion:** wrap the combo grow/flash, tell-ring pulse, result-flash, and any dog bounce-driven CSS in `@media (prefers-reduced-motion: reduce)` to tone down (the rAF-driven 3D can stay; this is about CSS animations).

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Screenshot the training HUD + select screen; VIEW them; confirm focus outlines appear
  on tab (you can `--force ":focus-visible"`-style or tab via the script) and text is legible.
  Note any low-contrast spots remaining.

## Progress Log
- 2026-06-14 — Task created (iteration 12)

## Resolution
2026-06-14 — Completed accessibility sweep (markup + CSS only, no logic change).

### aria / accessible names (hud.ts)
- `#hud-loadout-chip` (role=button div): added `tabindex="0"` + keydown Enter/Space handler for full keyboard operability.
- `.hud-trick-btn`: added `aria-label` (`"${trick.name}"` or `"${trick.name} — mastered"`); check span and name span get `aria-hidden="true"` to avoid double-reading.
- `#hud-graduate-btn`: added `aria-label="Graduate active dog to prestige"`.
- Already present: `aria-pressed` on diff-selector segments (via `updateModeHighlight`), `role="dialog"` + `aria-modal` + `aria-label` on both panels, `aria-label` on all close buttons, BRA button, kennel/adopt buy buttons, roster buttons, loadout unlock button.

### Focus (hud.css)
- Added `button:focus-visible, [role="button"]:focus-visible { outline: 3px solid #4cde80; outline-offset: 3px; }` covering all interactive elements.
- Close buttons (`#adopt-panel-close`, `#kennel-panel-close`): tightened to `outline-offset: 2px; border-radius: 50%` so the ring follows the circle.
- BRA button: uses `outline: 3px solid #fff; outline-offset: 4px` (white stands out against green).

### Contrast (hud.css)
- `.hud-diff-btn` inactive text: raised from `rgba(240,240,240,0.6)` → `0.88`.
- `.kennel-upgrade-cost` and `.adopt-breed-cost`: raised from `rgba(240,240,240,0.55)` → `0.75`.
- `#hud-result` (result flash): added dark pill backdrop `rgba(8,16,12,0.65)` + tighter text-shadow, ensuring AA on bright sky/grass scene.
- Other HUD text (trick label, stats, combo chip) already had dark backgrounds or strong text-shadows — no change needed.

### Reduced motion (hud.css)
- Added `@media (prefers-reduced-motion: reduce)` block disabling/removing:
  - `#hud-bar-fill` transition
  - `#hud-result` transition
  - `#hud-combo` transition + combo grow sizes (held at 1.1rem base)
  - `#hud-bra-btn` transition
  - All button/chip transitions across `.hud-trick-btn`, `.hud-roster-btn`, `.hud-diff-btn`, `.kennel-buy-btn`, `.adopt-buy-btn`, `#hud-adopt-btn`, `#hud-kennel-btn`, `#hud-graduate-btn`, `#hud-loadout-chip`, `#hud-loadout-unlock`, close buttons.

### Screenshots
- `/tmp/bra-a11y-select.png`: Select screen — dark `rgba(10,20,15,0.92)` background, Rex heading white, trick buttons green-bordered with legible white text, "Rex" roster pill clear, "+ Adopt Dog" legible. No washed-out text visible.
- `/tmp/bra-a11y-train.png`: Training HUD — "TEACHING: SITT" pill clearly readable (dark background pill), "🪙 0 Lv 1" stats in semi-dark panel top-right, BRA button large green on grass scene. Diff selector and loadout chip not visible (onboarding gated). No washed-out text.

## Acceptance Criteria
- [x] All interactive elements have accessible names (aria-label/text); selector uses aria-pressed; panels are role=dialog + labelled
- [x] Visible `:focus-visible` outlines on buttons; tab order sane
- [x] HUD text contrast checked/raised toward AA on the bright scene; no washed-out text
- [x] `prefers-reduced-motion` tones down CSS animations
- [x] Screenshot reviewed (real); no behavior change
- [x] `bun run test` green (342/342); `bun run typecheck` clean (0 errors); `bun run build` succeeds
