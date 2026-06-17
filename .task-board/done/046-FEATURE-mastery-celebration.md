# FEATURE: Mastery Celebration Effect

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: ui, juice, visual-review
**Estimated Effort**: Simple

## Context & Motivation

Mastering a trick currently shows a brief "MASTERED!" banner + the audio jingle (042).
Add a celebratory VISUAL burst (confetti / radial flash) so the payoff feels good —
"the mark must always feel good" extended to the mastery moment.

## Affected Components
- Modify: `src/ui/hud.ts`/`hud.css` (a celebration element — e.g. a CSS confetti burst or a radial gold flash overlay), exposing a `celebrate()` fn from `createHud`
- Modify: `src/main.ts` (call `celebrate()` on the mastered false→true transition, alongside the existing banner + `playMastery()`)
- Dependencies: 030/042; Blocking: none

## Approach
- Keep it CSS-only (no new deps): either a handful of absolutely-positioned confetti
  divs animated outward/falling on a one-shot keyframe, or a radial gold flash that
  scales + fades once. Trigger by adding a class / re-inserting the nodes; auto-clean
  after the animation (~1s).
- Respect `prefers-reduced-motion`: reduce to a simple fade (no flying particles).
- pointer-events:none; must not block the return-to-select.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- The effect is transient. Force it for a screenshot (e.g. `--force` the celebration element visible, or trigger via a seeded near-mastery + a tap). Capture /tmp/bra-celebrate.png; VIEW it; confirm the burst renders over the scene without breaking layout. Report honestly if you can only force it.

## Progress Log
- 2026-06-14 — Task created (iteration 16)

## Resolution

**Effect**: CSS-only `#hud-celebrate` overlay (z-index 50, pointer-events:none) containing:
- `#hud-celebrate-flash` — radial gold/white gradient circle, animated via `hud-flash-burst` keyframes (scale 0.2→6 over 0.85 s, fades out)
- 8 `.hud-confetti` dots (yellow, green, red, blue repeating) animated via `hud-confetti-fly` keyframes using `calc(cos/sin(--angle) * 180px)` to fly outward in all 8 cardinal/diagonal directions over 0.95 s

**Trigger**: `celebrate()` exported from `createHud`, called in `main.ts` at the `!prevMastered && currentlyMastered` transition (alongside `markAudio.playMastery()` and before `showSelect()`). Element is appended to `<body>` and removed after 1 100 ms via `setTimeout`.

**Reduced-motion**: `@media (prefers-reduced-motion: reduce)` overrides both keyframe animations — flash becomes `hud-flash-fade` (plain opacity 0.9→0, no scaling), confetti becomes `hud-confetti-fade` (fade in place, no translation). No flying particles.

**Screenshot**: `/tmp/bra-celebrate.png` — force-injected via `--poll` JS + `--force` CSS (element is transient in production). Shows a large radial gold burst centred on the training scene with 8 coloured dots arranged at the perimeter. "TEACHING: SITT" pill and BRA button visible; layout undisturbed.

**Verification results**:
- `bun run typecheck`: 0 errors (tsc --noEmit, clean exit)
- `bun run test`: 368/368 passed (23 test files)
- `bun run build`: clean, dist produced (1 580 KiB precache)
- `bun run e2e`: E2E SMOKE PASS

## Acceptance Criteria
- [x] A celebration burst (CSS, no deps) fires on mastery alongside the banner + jingle
- [x] Auto-cleans (~1s); pointer-events:none; doesn't block return-to-select
- [x] `prefers-reduced-motion` reduces it to a simple fade
- [x] Screenshot reviewed (real, even if forced visible)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
