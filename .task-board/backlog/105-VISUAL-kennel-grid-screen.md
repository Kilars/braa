# 105 — VISUAL: Kennel grid screen (Phase 8 K-1/K-3 — the anchor slice)

**Type:** VISUAL (pure rendering → **Visual Review**, plus a thin TDD wiring assert)
**Phase:** 8 (Kennel — current)
**Stories:** K-1 (browse the roster), K-3 (coin balance + prices always visible).
**Depends on:** 104 (`KennelDog.classify_kennel_dogs`) — the dumb-renderer rows this screen draws.

## What this addresses

There is **no kennel screen** yet. This builds the **anchor visual slice** the whole phase hangs
off: the browse grid the PO reviews to sign off the kennel aesthetic before any modal/adopt logic
layers on. It renders the 8 `KennelDog` cells from `classify_kennel_dogs(...)`, a fixed header with
the **live coin chip**, and an entry/exit path from the training scene. It is **browse only** — no
detail modal, no adopt, no economy mutation, no roster/save change (those land in follow-up K-2/K-4/
K-5 tasks). Cell tap emits a `dog_selected(id)` signal the modal task will consume.

## Why now

- Phase 8 is current; the kennel is the headline and needs a real surface to be reviewed.
- The spec calls the grid the **anchor visual slice** (phase8.md, K-1) — it unlocks PO review of the
  cool/clinical «Stålkennelen» look before modal/adopt logic is built on top of un-reviewed cells.
- Low regression risk: additive new screen, gated so the signed-off training page is unaffected until
  the player opens the kennel.

## Technical approach

**New `scripts/kennel_screen.gd`** — a `Control`-rooted screen (built in code, consistent with the
project's code-built HUD; no new `.tscn` required — instance it from `main.gd` like the showcase).
Structure per phase8.md "Godot notes":

- Root `Control` filling the portrait safe area, dimensioned for 390×844, hidden by default.
- **Header** (`HBoxContainer`, fixed): title «Kennelen» (Baloo 2, `DesignSystem.T_TITLE`) + subtitle
  «Profesjonell fasilitet · 8 plasser» (Nunito muted `SLATE_SOFT`), and a **live coin chip** on the
  right showing `CoinPurse.balance` (gold `DesignSystem.GOLD`, reuse the `CoinReadout` widget or a
  small gold pill). A back/✕ affordance returns to training.
- **Grid**: `ScrollContainer › GridContainer(columns=2)`, one **cell** instanced per row from
  `KennelDog.classify_kennel_dogs(owned, active, balance)`.
- **Palette = cool/clinical** (phase8.md): panel `#f4f6f8→#e5eaee`, cell `#ffffff`, hairline
  `#dde3e8`, steel bar `#788794` @ ~40%. Warmth ONLY in the coin chip, the dog band tints, and (later)
  the Unikt-trekk card. Use `DesignSystem` tokens where they match; add the few kennel-specific cool
  greys as **named constants** in `kennel_screen.gd` (not scattered literals — cf. task 029).

**The cell** (a reusable `PanelContainer`/`Button` fed one classify row):
- White `StyleBoxFlat`, radius 16, soft neutral shadow + 1.5px inset hairline.
- **Portrait band** (~112px): filled with the row's `band_tint`, dog render bottom-anchored. Until the
  owner supplies distinct breed models (owner-gated, BUST-068), the render is an **honest tinted
  Labrador stand-in** — do NOT fake a distinct breed silhouette. A baked `Texture2D` of the Labrador
  (or the tint band alone if no baked portrait is available this slice) is acceptable; **no bare
  primitive geometry**. If only the tint band ships this slice, note it — the per-dog baked portrait
  is a later refinement, not a stub of a claimed feature.
- **Steel bars** over the band: one reused shader (repeating vertical stripes ~2px on ~29px pitch,
  `#788794` @ ~40%, + a 2px inset steel frame). One `ShaderMaterial`, tint alpha in a uniform.
- **Status tag** top-left from `status_label`: owned «Din hund» (green `#57b85c`), secret «★ Påskeegg»
  (coral `#ff7a85`), else the neutral «N dager her» treatment (a static number is fine this slice).
- **Price chip** bottom-right from `price_label`: gold buyable / green «Din» (owned) / coral «Gratis»
  (Trulte). Rarity accent drives the chip colour (owned green, common grey, rare blue, epic gold,
  secret coral).
- **Footer**: name (Baloo 2 700) + breed (Nunito 700 muted).
- **Pressed**: gentle scale-down (K-1 affordance). Whole cell is the hit target; press emits
  `dog_selected(id)`.

**`main.gd` wiring (minimal, additive):**
- Instance the kennel screen once; open it from a modest **«Kennel» entry** in the training HUD (a
  small header/menu button) and close back to training (mirror how the showcase is shown/hidden via
  `_set_training_hud_visible(false)` on open, restore on close — task 090 pattern, so the training HUD
  doesn't bleed through).
- Feed it `KennelDog.classify_kennel_dogs(_kennel_owned(), _kennel_active(), _purse.balance)`. For this
  browse-only slice, `_kennel_owned()` returns `[KennelDog.STARTER_ID]` (Bella) and `_kennel_active()`
  returns `KennelDog.STARTER_ID` — the roster→kennel id migration that makes adopted dogs show as owned
  is deferred to the adopt task (K-4/K-5). Document this seam in the code.
- Keep the coin chip live: refresh on open (balance only changes via training mastery, already wired).

**Motion (respect X-5):** cells pop in (small scale-up + fade, lightly staggered) when the kennel
opens; honor `ReducedMotion.query()` (skip the stagger when reduced).

**TDD leg (thin wiring assert, `tests/test_kennel_screen_wiring.gd`):** the screen builds 8 cells from
a classify array; opening hides the training HUD and closing restores it; a cell press emits
`dog_selected` with the right id. (The pixel look is Visual Review, not asserted.)

## Visual Review (blocking, per X-6)

Capture at **390×844 phone-portrait** (headless Chromium via `tools/web_capture_*.mjs` pattern, real
canvas taps to open the kennel). Confirm by eye:
- Header reads «Kennelen» + subtitle, live gold coin chip right.
- 8 cells in a 2-column scrolling grid; all 8 legible at a glance (name, breed, price, status tag)
  with **no tap required to tell them apart** (K-1).
- The look is **cool/clinical**: white cells, thin steel bars over tinted bands, hairlines, no warm
  surfaces except the coin chip and the band tints.
- Bella reads owned (green «Din hund» + «Din»); Trulte reads «★ Påskeegg» coral + «Gratis»; priced
  dogs show gold price chips (K-3).
- No earlier-phase regression: the training page is byte-unchanged until the kennel is opened, and
  closing the kennel returns to it intact.
- Run the `polish` pass (alignment/spacing/typography) before declaring done.

## Acceptance criteria

- [ ] `scripts/kennel_screen.gd` renders a header (title/subtitle + live coin chip) and a
      `ScrollContainer › GridContainer(columns=2)` of 8 cells from `classify_kennel_dogs`.
- [ ] Each cell shows: tinted band + steel bars, name (Baloo 2) + breed (Nunito muted), status tag
      (owned/secret/neutral), and price chip (gold/«Din»/«Gratis») — driven by the classify row.
- [ ] Cool/clinical palette; warmth only in the coin chip + band tints; kennel greys are named
      constants, not scattered literals.
- [ ] Dog band renders an **honest** tinted Labrador stand-in (or tint band) — no bare primitive,
      no faked distinct-breed silhouette (owner-gated MODELS residual, BUST-068, left flagged).
- [ ] Entry from training opens the kennel (training HUD hidden, task-090 pattern); close returns to
      training with it intact; `dog_selected(id)` emitted on cell press.
- [ ] Cell pressed-scale affordance + staggered pop-in; `ReducedMotion` honored (X-5).
- [ ] `tests/test_kennel_screen_wiring.gd`: builds 8 cells, open hides / close restores the training
      HUD, cell press emits `dog_selected` with the right id (RED→GREEN).
- [ ] Visual Review PASS at 390×844 (screenshots kept); `polish` pass run; no earlier-phase regression.
- [ ] No modal, no adopt, no economy/roster/save mutation this slice (deferred to K-2/K-4/K-5).
- [ ] Placeholder check clean (allowlist the tint-band stand-in against the open BUST-068 residual);
      `nix develop -c bash verify.sh` green.
