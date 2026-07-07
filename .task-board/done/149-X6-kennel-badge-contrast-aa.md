# 149 — X-6: kennel rarity/status badges must clear WCAG AA (dark ink, keep the calm accents)

**Type:** FIX (visual legibility / X-6)
**Source:** PO father-pass-13 (`.docs/specs/po-review.md`, HEAD `3513b41`) — the one buildable directive.
**Phase:** 8 (kennel), signed off — this is X-cutting polish, no phase advance.

## What it addresses

148 shipped the rarity ladder as corner badges, but every badge uses **white label text on a
calm mid-tone accent**, and measured WCAG contrast fails AA on every tier (PO PIL samples):

| tier | fill | white-text ratio |
|------|------|------------------|
| COMMON «Vanlig» | slate `#9aa6b0` | 2.48:1 |
| OWNED «Din» | green `(87,184,92)` | 2.50:1 |
| SECRET «★ Påskeegg» | coral `#ff7a85` | 2.51:1 |
| RARE «Sjelden» | blue `#5b8fd0` | 3.34:1 |
| EPIC «Episk» | violet `#9b7bd4` | 3.40:1 |

Badge cap-height is ~10–11 px, so the applicable AA threshold is **4.5:1** — all five fail; three
fail even the 3:1 large-text floor. The same defect is present on the **price-slot status word
pills** (`_make_price_chip` else-branch: owned green «Din» / secret coral «Gratis»), which also draw
`Color.WHITE` on the same accents (2.5:1). The buyable coin price pill already uses dark `C_COIN_TEXT`
on PAPER — it is fine and untouched.

**Minor (PO, "fold in if cheap"):** on Bella's owned cell «Din» appears **twice** — top-left corner
badge **and** bottom-right price-slot pill. Every other dog carries different info in those two slots.
Only the owned dog duplicates.

## Approach — swap white → a single dark ink, keep accents EXACTLY

The clean fix the PO asked for: keep the calm accent hues, change the **label colour from white to a
dark ink** so every pill clears AA. One shared ink works for all five accents — `Color("141c26")`
(deep near-black) yields, by exact WCAG math: slate 6.9:1, green 6.9:1, coral 6.8:1, blue 5.1:1,
violet 5.1:1 — all ≥ 4.5:1 with margin. Do **NOT** change any accent constant (`C_STATUS_NEUTRAL`,
`C_RARITY_RARE`, `C_RARITY_EPIC`, `C_STATUS_OWNED`, `C_STATUS_EGG`, `C_PRICE_OWN`, `C_PRICE_FREE`) and
do **NOT** return to band fills — those are settled.

### Test-first (TDD — pure contrast math, testable)

Add a pure static WCAG helper on `KennelScreen` and a shared ink constant, then assert every
accent/ink pair clears AA. New test file `tests/test_kennel_badge_contrast.gd`:

```gdscript
# RED first — these fail until C_TAG_INK + wcag_contrast exist / are wired.
func test_tag_ink_clears_aa_on_every_badge_accent() -> void:
    var accents := [
        KennelScreen.C_STATUS_NEUTRAL, KennelScreen.C_RARITY_RARE, KennelScreen.C_RARITY_EPIC,
        KennelScreen.C_STATUS_OWNED,   KennelScreen.C_STATUS_EGG,
        KennelScreen.C_PRICE_OWN,      KennelScreen.C_PRICE_FREE,
    ]
    for a in accents:
        assert_true(KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, a) >= 4.5,
            "tag ink must clear AA 4.5:1 on accent %s" % a)

func test_wcag_contrast_matches_known_pairs() -> void:
    # white-on-slate is the failing baseline (~2.48); ink-on-slate must clear AA.
    assert_true(KennelScreen.wcag_contrast(Color.WHITE, KennelScreen.C_STATUS_NEUTRAL) < 3.0)
    assert_true(KennelScreen.wcag_contrast(KennelScreen.C_TAG_INK, KennelScreen.C_STATUS_NEUTRAL) >= 4.5)
```

`wcag_contrast` = standard relative-luminance ratio (linearize each channel: `c<=0.03928 ? c/12.92 :
pow((c+0.055)/1.055, 2.4)`, `L = 0.2126R+0.7152G+0.0722B`, ratio `(hi+0.05)/(lo+0.05)`).

### Implementation

**Before** (`_make_tag`, both label branches; `_make_price_chip` else-branch):
```gdscript
lbl.add_theme_color_override("font_color", Color.WHITE)
```
**After:**
```gdscript
lbl.add_theme_color_override("font_color", C_TAG_INK)
```
with `const C_TAG_INK := Color("141c26")  ## dark ink for status/rarity pill labels — clears WCAG AA on every calm accent (X-6, task 149)`.

**De-dup (minor):** in the grid-cell band assembly, suppress the price-slot pill for the owned dog —
its ownership is already carried by the top-left corner «Din» badge:
```gdscript
# Before: always add the chip.
# After:
if not row.owned:
    var chip := _make_price_chip(row)
    ...
```
(Secret keeps its «Gratis» pill — it differs from the «★ Påskeegg» corner badge, no duplication.)

## Acceptance criteria

- [ ] RED: `tests/test_kennel_badge_contrast.gd` written first and failing (no `C_TAG_INK` / `wcag_contrast` yet).
- [ ] `wcag_contrast` pure static helper + `C_TAG_INK = Color("141c26")` added to `KennelScreen`; GREEN.
- [ ] All three `Color.WHITE` status/rarity labels (2 in `_make_tag`, 1 in `_make_price_chip`) now draw `C_TAG_INK`.
- [ ] No accent constant changed; no band-fill reintroduced; buyable coin price pill (PAPER + `C_COIN_TEXT`) untouched.
- [ ] Owned cell no longer repeats «Din» — the bottom-right price pill is suppressed for `row.owned`; corner «Din» badge remains (all 8 cells still carry a corner badge).
- [ ] Modal echo (`_make_tag` at the modal band) inherits the dark ink automatically — verify the modal rarity badge reads.
- [ ] Visual Review: grid capture — all 8 corner badges read crisply (dark words on calm pastel pills), owned cell shows «Din» once; modal capture — rarity badge legible.
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [ ] Placeholder check clean on the diff.
