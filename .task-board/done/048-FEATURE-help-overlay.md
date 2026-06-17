# FEATURE: How-to-Play Help Overlay

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: ui, ux, onboarding, visual-review
**Estimated Effort**: Simple

## Context & Motivation

Onboarding (022) gates systems progressively but never EXPLAINS the verb. A small
"?" help overlay gives players the rules at a glance: wait for the apex pulse, tap
BRA, don't mark distractors, build combos.

## Affected Components
- Modify: `src/ui/hud.ts`/`hud.css` (a "?" button + a help panel), `src/main.ts` (wire open/close; optionally auto-open once on very first run then never again — persist a `seenHelp` flag, OR keep it purely manual to avoid touching the save schema)
- Dependencies: none; Blocking: none

## Content (concise, skimmable, a few lines)
- **Watch the dog.** When it does the trick and a gold ring pulses around BRA, that's the moment.
- **Tap BRA on the pulse.** Closer to the peak = better; fills the learn bar to 100% = mastered.
- **Don't tap the wrong thing.** A grey, turned-away dog is a distractor — marking it confuses your pup.
- **Chain it.** Consecutive good marks build a combo for bonus rewards.
- (Optional) one line on Hard/Expert + adopting breeds + graduating for prestige.

## Approach
- A "?" button (a corner of the SELECT screen and/or training HUD — no overlap with ⚙ settings, kennel, etc.). Opens a `role="dialog"` panel with the bullet list + a ✕/Got it close.
- Keep it manual (button-triggered). If auto-opening on first run, persist a flag — but simplest is manual-only; pick one and note it.
- Respect a11y (aria, focus) consistent with the other panels.

## Visual Review (required — reuse the running dev server; do NOT pkill; never fake a screenshot)
- Open the help panel (click "?") and screenshot to /tmp/bra-help.png; VIEW it; confirm the text reads clearly, no overlap, closes fine.

## Progress Log
- 2026-06-14 — Task created (iteration 16)

## Resolution

**Button placement:** A circular "?" button (`#hud-help-btn`, `aria-label="How to play"`) is fixed to the top-left corner (`top: 16px + safe-area-inset-top`, `left: 16px + safe-area-inset-left`, `z-index: 22`). The settings ⚙ button sits at the top-right — no overlap. Both are 40×40px circular buttons matching the same style.

**Panel markup:** `#help-panel` is `role="dialog"`, `aria-modal="true"`, `aria-label="How to play"`. Full-screen dark overlay (z-index 30) matching the kennel/adopt/settings panel pattern. Header has title "How to Play" + ✕ close button. Body has a `<ul>` with 5 bullet items (each with `<strong>` lead phrase), then a green "Got it!" close button. Both ✕ and "Got it!" call `closeHelpPanel()`.

**Content:**
- Watch the dog. / Tap BRA on the pulse. / Don't tap the wrong thing. / Chain it. / Pick your challenge.

**Verification results:**
- `bun run typecheck`: 0 errors
- `bun run test`: 368 passed (23 test files)
- `bun run build`: clean build, dist emitted
- `bun run e2e`: E2E SMOKE PASS

**Screenshot:** `/tmp/bra-help.png` — panel visible, all 5 bullets readable with green bullet dots, bold lead phrases, "Got it!" green button, ✕ in header, dark overlay. Select screen content visible but dimmed behind. No overlap with any HUD element (panel is full-screen modal at z-index 30).

## Acceptance Criteria
- [x] A "?" button opens a help panel explaining the core verb (apex/tap/distractor/combo)
- [x] Panel is a labelled dialog, closes cleanly, no overlap with other HUD buttons
- [x] Screenshot reviewed (real)
- [x] `bun run test` green; `bun run typecheck` 0; `bun run build` ok; `bun run e2e` PASS
