# FEATURE: Kennel Upgrade Shop UI

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Medium
**Labels**: ui, economy, integration, visual-review
**Estimated Effort**: Medium

## Context & Motivation

`kennel.ts` (017) has `KENNEL_UPGRADES` + `kennelMultiplier`, and the payout uses
it — but there's no way to BUY an upgrade, so the multiplier is always 1 in-game.
Add a shop panel that spends coins to buy upgrades, closing the earn→spend→boost loop.

## Current State

`GameSave.kennelUpgradeIds` exists; `economy.spend` exists; payout already factors
`kennelMultiplier(ownedIds)`. No shop UI.

## Affected Components
- Modify: `src/ui/hud.ts`/`hud.css` (a "Kennel" button + a panel listing upgrades), `src/main.ts` (open/close panel; buy = `spend` coins, append id to `kennelUpgradeIds`, persist, re-render)
- (Optional) `src/core/kennel.ts` helper `canBuy(ownedIds, upgrade, coins)` (pure, TDD) to keep buy-eligibility logic testable
- Dependencies: `kennel.ts`, `economy.ts`, `save.ts`; Blocking: 017

## Technical Approach
- A "Kennel" button (place clear of existing HUD: bar/top, coins top-right, selector top-left, BRA/tell bottom-center, FLINK bottom-left). Opens a modal/panel listing each upgrade: name, cost, owned/affordable state. Buy → `spend(profile, cost)` (guard null), push id, persist, close or refresh.
- If adding `canBuy`, TDD it: false if already owned, false if unaffordable, true otherwise.

## Visual Review (required — reuse the running dev server; do NOT pkill)
- `curl -s localhost:5173` (start only if down). Screenshot via `scripts/shoot-hud.mjs`;
  to show the panel, add a tiny click-the-Kennel-button screenshot. VIEW the PNG; confirm
  the panel renders, buy states are clear, nothing overlaps. Note findings.

## Progress Log
- 2026-06-14 — Task created (iteration 7)

## Resolution

### Wiring
- Added `canBuy(ownedIds, upgrade, coins): boolean` pure helper to `src/core/kennel.ts` (false if owned, false if coins < cost, true otherwise). 6 TDD tests added to `src/core/kennel.test.ts`.
- Added `KENNEL_UPGRADES`, `kennelMultiplier`, `canBuy` imports to `src/ui/hud.ts`; `spend` and `KENNEL_UPGRADES` to `src/main.ts`.
- `HudCallbacks` extended with `getKennelState()` and `onBuyUpgrade(upgradeId)`.
- Kennel button (`#hud-kennel-btn`) placed on the select screen as a fixed bottom-right pill. Does not appear during training (select screen is hidden then).
- Kennel panel (`#kennel-panel`, `role=dialog`) is a full-screen dark overlay (z-index 30) listing all 3 upgrades. Header shows title + `×N.NN` multiplier + close button. Each upgrade row shows name, cost/owned label, and a Buy button.
- Buy states: `owned` (gold check, disabled), `affordable` (green Buy button, active), `too-expensive` (muted, disabled).
- Buy handler: `spend(profile, cost)` guards null, appends id to `kennelUpgradeIds`, calls `persist()`, refreshes panel in-place.
- Panel refreshes on open and after each purchase.

### Panel DOM/Layout
- `#kennel-panel` full-screen flex column, z-index 30, very dark semi-opaque background
- `#kennel-panel-header`: flex row with title, multiplier chip, close button
- `#kennel-panel-list`: vertical list of `.kennel-upgrade-row` items, each a flex row with `.kennel-upgrade-info` (name + cost) and `.kennel-buy-btn`
- Three CSS state classes on rows: `owned`, `affordable`, `too-expensive`

### Screenshot Result
Panel rendered correctly. Fresh save (0 coins): all 3 upgrades show `too-expensive` with disabled Buy buttons. Multiplier reads ×1.00. Kennel button visible at bottom-right of select screen. No overlap with trick list, dog name, or other HUD elements. Screenshots at `/tmp/bra-select-with-kennel-btn.png` and `/tmp/bra-kennel.png`.

## Acceptance Criteria
- [x] A Kennel button opens a panel listing `KENNEL_UPGRADES` with cost + owned/affordable state
- [x] Buying spends coins (guarded), adds the id to `kennelUpgradeIds`, persists, and raises the effective multiplier
- [x] Can't buy if unaffordable or already owned (TDD `canBuy` if added)
- [x] Panel doesn't overlap other HUD elements; closes cleanly
- [x] Screenshot reviewed
- [x] `bun run test` green (192 tests); `bun run typecheck` clean; `bun run build` succeeds
