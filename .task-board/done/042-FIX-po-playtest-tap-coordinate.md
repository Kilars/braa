# 042 — FIX: PO live-playtest harness clicks the wrong BRA tap coordinate

**Type:** FIX (committed harness tool — not gameplay code)
**Phase:** 1 (verification harness; supports P1-5/P1-6 sign-off)
**Source:** PO review pass 2026-06-30 (`.docs/specs/po-review.md`). The PO explicitly
directs: *"clicks aimed low at the button band's bottom edge (y≈745 — still hard-coded in
`tools/po_live_playtest.mjs:75`) register 0 marks; the active hit area is the ring/word
centre, ~y670, so any tap-harness must aim centre — **fix that committed line**."*

## Problem

`tools/po_live_playtest.mjs:75` performs the "real BRA taps" sweep at:

```js
await page.mouse.click(195, 745);      // BRA button centre at 390x844 portrait
```

`y=745` is near the **bottom edge** of the BRA button band, not its centre, and the comment
mislabels it as "centre." A blind tap sweep there reports **0 successful marks**, which reads
like the game's scoring is broken when it is actually the harness aiming at the wrong spot.

## Ground truth (from the game's own constants, `scripts/main.gd`)

The BRA button is anchored to the bottom edge with `offset_top = BRA_OFFSET_TOP (-280)` and
`offset_bottom = BRA_OFFSET_BOTTOM (-88)`. At a 390×844 portrait viewport the band spans
**y = 564 … 756**, so its centre is **y = 660** (`BRA_CENTER_Y = (-280 + -88)/2 = -184`
→ `844 − 184 = 660`). The apex tell ring and the "BRA" word are concentric on the same
centre. The PO's eyeballed "~y670" is this same ring/word centre (the 10 px is within noise).

## Definition of done

- Line 75 clicks the BRA **ring/word centre** (`y ≈ 670`, the PO-validated value), not the
  bottom edge; the misleading "centre" comment is corrected to say what the coordinate is.
- `x=195` (horizontal centre of 390) is unchanged — only the `y` was wrong.
- Verify gate green (`nix develop -c bash verify.sh`). NOTE: `verify.sh` does **not** run
  this harness (it runs import·boot·test·export on the CC0 dog), so this change cannot break
  the gate; it also is not covered by it. Verification of the coordinate itself rests on the
  PO having already **empirically proven** that real Playwright clicks at `(195, 670)` land
  **7 successful marks** on the live site this same pass — the fix adopts that proven value.
- Placeholder-check the diff (no stub/TODO introduced).

## Scope notes

- **Coordinate only, per the PO's explicit directive.** The PO pinned the 0-marks on the
  *aim*, not the cadence. The existing `waitForTimeout(170)` already "walks the window"
  (170 ms ∤ 1200 ms sit loop → it drifts across the window over the 90-tap sweep), so it is
  left unchanged — changing it would be scope creep beyond the directive.
- This is harness/test tooling driven by a live browser (Playwright), not unit-testable
  gameplay logic → TDD-exempt (per the mother prompt: pure render/3D/asset/harness glue is
  exempt; the coordinate is validated by the PO's live run, not a unit test).
