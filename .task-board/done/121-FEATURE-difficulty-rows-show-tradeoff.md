# 121 — FEATURE — Difficulty rows show the reward/challenge trade inline (P4-1/P4-3)

**Source:** PO Review 2026-07-05 (`.docs/specs/po-review.md`), Improvement #1 — the sole
blocker to Phase 9 sign-off.

## What it addresses (spec gap)

Phase 9's premise is *"trading challenge for reward"* (phase9 goal) and **P4-3** — *"each mode
is the rational choice at a different skill level."* The `Difficulty` model backs a real trade
(Hard = ×1.4 coins / ×0.72 window, Expert = ×2.0 coins / ×0.5 window — `difficulty.gd`), but the
completion-menu difficulty rows (118) carry only a «Valgt»/«Låst» badge and **nothing else**
(`.screenshots/118-01-menu-normal.png`). A player picking Expert gets **zero** signal that it
doubles the payout and halves the timing window, so they can't make the trade knowingly and have
no reason to leave Normal — the feature is inert to their decision.

This is the exact standard the PO required for marker words before Phase 5 sign-off (P5-2 / task
095: each word shows its cost/rest **before** loading, e.g. «+15% · hviler 2»).

## Why prioritized now

It is the single filed PO directive blocking the current-phase (Phase 9) sign-off — top of the
idle ladder (current-phase buildable work). Mechanically small: the word-row pattern already
exists to mirror.

## Technical approach (TDD — test-first)

The renderer is a dumb view; the trade string must be **derived from the `Difficulty` model** and
carried through `classify_difficulty`, exactly as `classify_words` carries `window_scale`/`cooldown`
for the word cost hint. Then `_draw_difficulty_row` renders a dimmed subtitle below the name,
reusing the `_draw_word_row` cost-hint treatment (`WORD_COST_HINT` colour, `BADGE_SIZE`, the
shift-name-up-to-make-room layout).

**Trade string derivation (pure, from the model).** Normal = baseline → **no** subtitle. Hard /
Expert show reward × and window tightening derived from `reward_scale` and `window_scale`:
- Hard: reward_scale 1.4, window_scale 0.72 → e.g. «×1.4 mynt · smalere vindu»
- Expert: reward_scale 2.0, window_scale 0.5 → e.g. «×2 mynt · mye smalere vindu»

Format from the numbers (do NOT hardcode per-mode strings): a `mynt` multiplier from
`reward_scale` (drop a trailing `.0`, e.g. `×2` not `×2.0`; keep `×1.4`), plus a window phrase
bucketed by how much `window_scale` tightens (e.g. `< 0.85` → «smalere vindu», `< 0.6` → «mye
smalere vindu»). Home the thresholds/labels as named consts next to `DIFF_*`.

### `classify_difficulty` — carry the model numbers (pure)

Before (`scripts/trick_menu.gd:284`):
```gdscript
rows.append({
    "id": d.id, "name": d.display_name,
    "active": d.id == flagged,
    "selectable": not locked,
    "locked": locked})
```
After — carry `reward_scale` + `window_scale` so the view can render the trade (mirror how
`classify_words` carries `window_scale`/`cooldown`):
```gdscript
rows.append({
    "id": d.id, "name": d.display_name,
    "active": d.id == flagged,
    "selectable": not locked,
    "locked": locked,
    "reward_scale": d.reward_scale,
    "window_scale": d.window_scale})
```

### A pure trade-label helper (unit-tested)

Add a static pure function, e.g.:
```gdscript
## The dimmed trade subtitle for a difficulty row, derived from the model. "" for the baseline
## (Normal / reward_scale == 1.0) → no subtitle. Otherwise "×<reward> mynt · <window phrase>".
static func difficulty_trade_label(reward_scale: float, window_scale: float) -> String:
```
Test it directly (no framebuffer): Normal (1.0, 1.0) → `""`; Hard (1.4, 0.72) → contains `×1.4`
+ `mynt` + a `smalere` window phrase; Expert (2.0, 0.5) → `×2` (no `.0`) + the stronger window
phrase. This is the TDD core.

### `_draw_difficulty_row` — render the subtitle

Mirror `_draw_word_row`'s cost-hint block (`scripts/trick_menu.gd:804-834`): compute the label
via `difficulty_trade_label(...)`; when non-empty, shift the name-baseline up and draw the label
below at `BADGE_SIZE` in `WORD_COST_HINT` (reuse it, or an aliased `DIFF_TRADE_HINT`). `DIFFICULTY_ROW_H`
(54.0) already matches the word row height that fits name + hint, so geometry is unchanged.

**Do NOT** change selection/lock behavior, the badge logic, or the difficulty section layout math
— subtitle only. Locked rows may still show the trade (they read greyed via the dim treatment);
keep it consistent with how a locked word row still shows its state.

## Acceptance criteria

- [x] TDD: a failing test for `difficulty_trade_label` FIRST — Normal → `""`, Hard → `×1.4` + `mynt`
      + a `smalere` window phrase, Expert → `×2` (no trailing `.0`) + the stronger window phrase.
- [x] TDD: a failing test that `classify_difficulty` rows carry `reward_scale` + `window_scale`
      for every mode (and still carry the existing id/name/active/selectable/locked keys).
- [x] Green: both tests pass; the trade label is derived from the `Difficulty` model, not hardcoded
      per-mode literals.
- [x] `_draw_difficulty_row` renders the dimmed trade subtitle below the name for Hard/Expert and
      nothing for Normal, reusing the word-row cost-hint treatment (colour/size/layout).
- [x] No regression to selection, the special-dog lock (119), badges, or section geometry.
- [x] `verify.sh` green (import → boot → test → export).
- [x] Visual Review (390×844, real canvas taps): open the completion menu, the Vanskelighet rows
      show Normal (no subtitle) / Hard / Expert each with their trade legible before selecting;
      screenshot saved under `.screenshots/121-*`.
- [x] Placeholder check clean on the diff.

## Resolution (2026-07-05)

Shipped. `difficulty_trade_label(reward_scale, window_scale)` (pure, unit-tested) derives the
dimmed trade subtitle from the `Difficulty` model — "" for Normal, «×1.4 mynt · smalere vindu»
for Hard, «×2 mynt · mye smalere vindu» for Expert (trailing `.0` dropped; window phrase bucketed
by `DIFF_WINDOW_VERY_TIGHT_MAX`). `classify_difficulty` now carries `reward_scale`/`window_scale`
per row; `_draw_difficulty_row` renders the subtitle below the name reusing the `_draw_word_row`
cost-hint layout + `WORD_COST_HINT` colour (aliased `DIFF_TRADE_HINT`). 5 TDD tests
(test_difficulty_menu.gd), verify green 650/0. Visual Review PASS — `.screenshots/118-02-menu-hard.png`
shows the three rows with their trades legible before selecting, matching the marker-word row style.
