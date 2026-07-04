# 098 — VISUAL: Restyle the completion menu to the Design System

**Type:** VISUAL (dumb-renderer `_draw` restyle — Visual Review gated)
**Phase:** 6 (current) — PO Review 2026-07-04, Bugfix/Change #1
**Priority:** P1 (largest UI surface; the single biggest DS gap in the phase)

## What it addresses

Spec gap (PO directive #1). Phase 6 scopes the Bra Design System to **"all aspects of
game, menu, training page visuals etc."** The training page (097) is now the light DS
aesthetic, but `scripts/trick_menu.gd` — the completion menu that pops on mastery, the
single **largest** UI surface — is still the **old dark-navy panel with a gold hairline
border, gold section labels, gold row badges**, and its three action buttons even mix
languages ("Vis frem hundene" / "Give feedback" / "Keep training"). Right next to the
now-light training page it reads as **two different apps** — a dark modal over a bright,
paper-pill garden. The DS Theme (SLATE-on-light) was never applied here.

Evidence: `.screenshots/po-p6-menu.png` (PO capture). Current palette lives in
`scripts/trick_menu.gd:118-163` (`PANEL_BG` dark navy, `PANEL_BORDER` gold, all `NAME_*` /
`BADGE_*` / `WORD_*` / `BREED_*` gold-and-white).

## Why now

Phase 6 is current and the PO explicitly named this as **not sign-off ready**. It is the
most jarring DS gap — a whole modal in the retired theme. Non-owner-gated, pure `_draw`
restyle over the existing (already unit-tested) classify/hit-map logic.

## Technical approach

`trick_menu.gd` is a **dumb renderer**: `main` decides rows + balance via `set_rows()`;
this node only `_draw`s the modal and maps a tap to an id. The classify split, the row
hit-map (`id_at` etc.), and the signals are pure and **unit-tested render-free** — this
task changes **only the pixels + the button labels**, so those tests stay green
unchanged. Consume `DesignSystem` tokens; **no new ad-hoc `Color(...)` literals** (mirror
097's rule — every colour comes from `DesignSystem`).

Map the retired palette → DS tokens (replace the `const` block at `trick_menu.gd:118-163`):

**Before** (`scripts/trick_menu.gd`):
```gdscript
const BACKDROP := Color(0.0, 0.0, 0.0, 0.55)          ## the dimmed veil over the game
const PANEL_BG := Color(0.10, 0.13, 0.18, 0.98)       ## the modal panel
const PANEL_BORDER := Color(1.0, 0.86, 0.30, 0.85)    ## the triumphant gold edge
const TITLE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const NAME_LEARNED := Color(1.0, 0.86, 0.30)          ## learned name — gold
const NAME_AVAILABLE := Color(1.0, 1.0, 1.0)          ## available name — full white
const NAME_LOCKED := Color(1.0, 1.0, 1.0, 0.32)
const BADGE_AVAILABLE := Color(0.55, 0.86, 0.62)      ## the calm learning green
...  # (BREED_* / WORD_* all gold-and-white on dark)
```
**After** (DS tokens — SLATE-on-PAPER, BLUE primary accent, GOLD reserved for the coin):
```gdscript
const BACKDROP := Color(DesignSystem.INK.r, DesignSystem.INK.g, DesignSystem.INK.b, 0.45)  ## soft ink veil, not pure black
const PANEL_BG := DesignSystem.PAPER                    ## light paper card
const PANEL_BORDER := DesignSystem.BORDER               ## hairline, not gold
const TITLE_COLOR := DesignSystem.SLATE                 ## slate heading
const NAME_LEARNED := DesignSystem.BLUE                 ## active/primary accent, not gold
const NAME_AVAILABLE := DesignSystem.SLATE              ## body text on light
const NAME_LOCKED := DesignSystem.SLATE_SOFT            ## secondary — clearly not tappable
const BADGE_AVAILABLE := DesignSystem.BLUE              ## primary accent
# GOLD stays ONLY on the coin disc/number (COIN_GOLD/COIN_RIM/NUMBER_COLOR → GOLD/GOLD_DARK/SLATE)
# active breed / active word → BLUE; locked → SLATE_SOFT; subheads → SLATE_SOFT
```

Panel surface: draw the card via `DesignSystem.panel(PAPER, R_LG)` (hairline BORDER + soft
card shadow) instead of the hand-rolled dark box + gold rect — replace `_panel_box()`'s
construction. Rows: use `DesignSystem.pill(...)` StyleBoxes for the trick / breed / word
rows (paper fill, `R_MD`) so they read as DS pills, active row filled BLUE-tint.

**Fonts:** the menu currently draws with `ThemeDB.fallback_font` (`trick_menu.gd:501`).
Switch to the DS faces: `DesignSystem.font_display()` for the "Tricks" title + coin number,
`DesignSystem.font_body_bold()` for row names / section subheads, `DesignSystem.font_body()`
for badges / cost hints. (Guard: font accessors are lazy — safe in `_draw`.) This is the
same swap 097 made on the HUD; it removes the fallback-font look that made the menu read as
a different app.

**Button-language unification** (PO: "make the three action buttons one language — Norwegian,
to match the rows"):
- **Before:** `"Vis frem hundene"` (no) / `"Give feedback"` (en) / `"Keep training"` (en)
- **After:** `"Vis frem hundene"` / `"Gi tilbakemelding"` / `"Fortsett treningen"` — all
  Norwegian. Home these as named `const`s (no scattered literals). Style the three as DS
  buttons: primary = BLUE fill "Fortsett treningen" (the dismiss/keep-training action),
  secondary = paper pills for the other two.

**Shadow / outline:** the dark-panel `SHADOW` outline behind text (`_draw_text_outlined`)
was for legibility on dark navy. On light PAPER, drop the heavy black outline (or swap to a
soft light-appropriate shadow token) so text is crisp SLATE-on-paper, not haloed.

Keep every geometry constant (`PANEL_*`, `ROW_H`, hit-map) as-is so `id_at` and the tests
stay valid — this is a **skin**, not a relayout.

## Visual Review (blocking — this is a VISUAL task, TDD-exempt for the pixels)

Spawn phone-portrait (390×844) review agents. Capture the menu on mastery via the existing
harness pattern (e.g. extend `tools/web_capture_menu.mjs` / the PO's `po_p6_drive.mjs` to
pop the completion menu and screenshot it). Verify against the DS aesthetic + the training
page beside it. Pixel proof required; orchestrator verifies the actual frame (never a
claimed one).

## Acceptance criteria

- [ ] The completion menu renders as a **light PAPER card** — `DesignSystem.panel(PAPER,
      R_LG)` surface (paper bg, hairline `BORDER`, soft card shadow), **no** dark-navy panel
      and **no** gold hairline border.
- [ ] Headings/body/badges render in the **DS fonts** (`font_display` / `font_body_bold` /
      `font_body`) and **SLATE / SLATE_SOFT** colours — not `ThemeDB.fallback_font`, not
      white-on-dark.
- [ ] **BLUE** is the active/primary accent (active trick, active word, selected/active
      breed); **GOLD** appears **only** on the coin disc + count; locked rows are
      `SLATE_SOFT` (clearly not tappable).
- [ ] Trick / breed / marker-word rows render as **DS pills** (`DesignSystem.pill`).
- [ ] The three action buttons are **one language (Norwegian)** and styled as DS buttons
      (primary BLUE "Fortsett treningen", secondary paper pills); all literals homed in
      named `const`s.
- [ ] **No new ad-hoc `Color(...)` literals** — every colour resolves from `DesignSystem`
      (grep the diff for `Color(` added lines; allow only alpha-derived tokens like the
      BACKDROP veil).
- [ ] The existing `trick_menu` classify / `id_at` / signal tests stay **green unchanged**
      (behaviour + geometry untouched — skin only). If any button-label constant is
      asserted in a test, update that test to the new Norwegian label.
- [ ] `nix develop -c bash verify.sh` → `✓ verify gate green`.
- [ ] **Visual Review PASS** (orchestrator-verified frame): menu reads as a light DS card
      that coheres with the restyled training page — no longer "two different apps".
- [ ] Placeholder check clean on the diff (no un-allowlisted stub/placeholder/TODO).
