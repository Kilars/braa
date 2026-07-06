# 129 — VISUAL — One shared CoinReadout across training, menu, and kennel

**Source:** PO Review 2026-07-06, directive **#8 [HIGH]** (cross-screen consistency).
**Phase:** current-phase X-4 quality (preempts the Phase-10 owner-gate).

## What it addresses

One datum (the coin balance) is rendered by **three different components**:
- **Training** — a white ~44px `CoinReadout` pill (drawn coin + number). This is the canonical one.
- **Completion menu** — `trick_menu.gd` draws its OWN bare GOLD disc + number in the header band
  (`HEADER_H`, palette line ~148), not the pill.
- **Kennel** — `kennel_screen.gd:375` `_coin_label.text = "%d mynter"` — a flat filled yellow disc
  with the word "mynter", a wholly different shape.

The PO wants **one shared `CoinReadout` pill** (~44px, drawn coin + right-aligned number, same
radius/padding) used verbatim on all three surfaces so the balance reads identically everywhere.

## Technical approach

`scripts/coin_readout.gd` already IS the canonical widget (white DS PAPER pill, drawn gold coin
disc, SLATE Baloo-2 number, `set_balance()` / `balance_text()`). The work is to route the menu and
kennel through it instead of their bespoke coin draws.

**Kennel** (`kennel_screen.gd`): replace the `_coin_label` "%d mynter" Label with a `CoinReadout`
instance in the header, fed via `set_balance(_balance)`.

Before:
```gdscript
_coin_label.text = "%d mynter" % _balance
```
After (sketch — instance a CoinReadout in the header, size it ~44px, right-anchor it):
```gdscript
_coin_readout.set_balance(_balance)   # shared CoinReadout, replaces the flat "%d mynter" disc
```

**Menu** (`trick_menu.gd`): the header band currently hand-draws a GOLD coin disc + number in
`_draw()`. Replace that hand-draw with a child `CoinReadout` node positioned in the header
(dropping the local `Coin:` palette draw + its constants only where they exist solely for the
header coin — keep any coin-glyph constants still used by breed/word price rows). Feed it via
`set_balance(rows_balance)` when the menu is populated.

Keep `CoinReadout`'s existing look untouched (it is the target); only its *host sites* change.
If the kennel/menu need the pill on a coloured background, rely on `CoinReadout`'s existing
paper pill + shadow (it already lifts off bright bands — see the 100/097 notes in the file).

## Test / review

- This is render glue (dumb-renderer already unit-covered via `balance_text`). No new logic
  branch → **Visual Review**, not TDD. If any non-trivial mapping is added, unit-lock it.
- Re-capture training / menu / kennel and confirm the coin widget is byte-shape-identical on all
  three (same pill radius, coin disc, number alignment).

## Acceptance criteria

- [x] Kennel header shows the shared `CoinReadout` pill (no more flat "%d mynter" disc).
- [x] Completion menu header shows the shared `CoinReadout` pill (no bespoke hand-drawn coin).
- [x] Training coin readout unchanged (it is the canonical target).
- [x] All three render the same pill shape/radius/padding + drawn coin + right-aligned number.
- [x] `CoinReadout`'s own appearance is untouched; no new scattered `Color(...)` coin literals.
- [x] Visual Review PASS on training, menu, kennel captures (phone-portrait 390×844).
      (`072-menu-open.png`: menu header shows the shared white coin pill + gold disc + "10",
      matching the training HUD top-right pill; `105-kennel-01-grid.png`: kennel header shows
      the same pill + "0". One datum, one shape on all three.)
- [x] verify gate green (import·boot·test·export); placeholder check clean.

## Resolution / Progress (2026-07-06)

Routed the completion menu + kennel through the shared `scripts/coin_readout.gd` `CoinReadout`
pill; training was already the canonical host and is untouched.

- **`scripts/trick_menu.gd`** — removed the header coin hand-draw (`_draw_coins()` + its
  header-only consts `COIN_R`/`COIN_RIM`/`NUMBER_COLOR`/`NUMBER_SIZE`). Added a lazily-built
  `_coin_readout: CoinReadout` child (`_ensure_coin_readout` in `_draw`, never `_init` —
  headless add_child gotcha), right-anchored in the header via `_position_coin_readout`, fed via
  `set_balance` from `set_rows`. Kept `COIN_GOLD` (still used by the Buyable breed-price badge).
- **`scripts/kennel_screen.gd`** — replaced the gold `coin_pill` PanelContainer + `_coin_label`
  Label ("%d mynter" / "0 🪙" — the U+1FA99 tofu emoji is gone) with a `CoinReadout` node in the
  header row, fed via `set_balance(_balance)` in `_build_header` + `_refresh`. Removed the now-dead
  `C_COIN_BG` const (kept `C_COIN_TEXT`, still used by the price chip).
- **`tests/test_kennel_screen_wiring.gd`** — the balance test now finds the `CoinReadout` by class
  and asserts `readout.balance() == 42` (was: a `CoinLabel` text-contains check).
- `coin_readout.gd` was NOT modified — configured purely via size/position (it self-right-aligns
  its pill within the given rect), so all three surfaces share identical pill/coin/number.
- verify gate green, 668 tests / 0 failures (the JSON parse errors are the intentional
  corrupt-blob decode tests). No new `Color(...)` coin literals.
- Capture tooling for Visual Review: `tools/web_capture_menu.mjs` (menu) and
  `tools/web_capture_kennel.mjs` (kennel).
