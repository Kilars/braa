# 106 — FIX: Kennel easter-tag ★ renders as tofu (Trulte «★ Påskeegg»)

**Type:** FIX (defect in a shipped slice → **Visual Review**, plus a TDD assert on the label text)
**Phase:** 8 (Kennel — current)
**Stories:** K-6 (find the hidden dog — "reads as special, not broken").
**Depends on:** 104/105 (the classify rows + grid that render `status_label`).
**Source:** PO Review 2026-07-05, Bugfix 1.

## What this addresses

Trulte's easter-egg status tag reads **`★ Påskeegg`**, but the leading `★` (U+2605 BLACK STAR)
has **no glyph** in the kennel fonts (Baloo 2 / Nunito), so it renders as a **missing-glyph tofu
box** — exactly the "broken" look K-6 says the easter cell must NOT have, on the one cell meant to
feel magical. This is the same tofu class the project already fixed for the ◀▶ showcase chevrons
(task 089) and the coin emoji: **no tofu in any rendered string** (standing project rule,
CLAUDE.md placeholder/tofu discipline).

## Why now

- It is a visible defect in the already-reviewed grid — the PO called it out explicitly.
- Small, self-contained, zero-risk; ships a clean fix ahead of the larger spine work.

## Technical approach

The tofu comes from a literal star **character** in the label string. Two source sites carry it:

- `scripts/kennel_dog.gd:86` — `classify_kennel_dogs` builds `status_label := "★ Påskeegg"`.
- `scripts/kennel_screen.gd` — `C_STATUS_EGG` comment + `_make_tag` renders `row.status_label`
  as a plain `Label`.

**Chosen fix (089 precedent — draw the star as geometry, keep the word clean):** drop the `★`
**character** from the string and draw a small **coral star pip** as a `_draw` polygon to the left
of the word inside the tag pill — no font dependency, guaranteed to render on GL Compatibility.
The status string becomes plain **`Påskeegg`** (no leading glyph); the tag gains a leading star
mark drawn in code.

Simplest robust variant if a drawn pip is over-scoped for the pill: **drop the glyph entirely** and
render a solid **coral round pip** (a small filled circle via `_draw` / a `ColorRect` dot) before
the word — still reads as "special", still zero-tofu. Either is acceptable; **no `★` character may
survive in any rendered string.**

Do **not** "fix" it by swapping in a font that happens to carry U+2605 unless that font is already
the theme font — silently introducing a third font for one glyph is worse than drawing the mark.

### Before

```gdscript
# kennel_dog.gd:86
var status_label := "Din hund" if is_owned else ("★ Påskeegg" if is_secret else "")
```

```gdscript
# kennel_screen.gd _make_tag(): a plain Label carries whatever status_label holds,
# so "★ Påskeegg" prints the U+2605 as a tofu box in Baloo 2 / Nunito.
lbl.text = row.status_label
```

### After

```gdscript
# kennel_dog.gd — no star CHARACTER in the data; the star is a drawn mark in the view.
var status_label := "Din hund" if is_owned else ("Påskeegg" if is_secret else "")
```

```gdscript
# kennel_screen.gd _make_tag(): for the secret (easter) row, prepend a drawn coral star
# pip (a small _draw polygon / a coral ColorRect dot) before the Label — no font glyph.
# The word "Påskeegg" now renders in the theme font with zero tofu; the pip supplies the ★.
```

## Placeholder / tofu check

Grep the diff for a literal `★` (U+2605) in any string that reaches a `Label.text` — there must be
**none** after this task. The word is `Påskeegg`; the star is geometry.

## Acceptance criteria

- [ ] **TDD first:** add/extend a `tests/test_*` assert that `classify_kennel_dogs(...)` for the
      secret dog (Trulte) yields a `status_label` **containing no `★` (U+2605) character** (e.g.
      `assert(not row.status_label.contains("★"))` and that it still contains `Påskeegg`). Run it
      RED against the current `"★ Påskeegg"`, then make it pass.
- [ ] The easter tag renders the word **Påskeegg** with a **coral star pip / dot drawn in code** —
      no missing-glyph box, verified by eye on a 390×844 capture of the grid (Trulte cell).
- [ ] No literal `★` character remains in any string that reaches a rendered `Label` (grep the diff).
- [ ] Owned («Din hund») and neutral tags are unchanged.
- [ ] `nix develop -c bash verify.sh` green (import·boot·test·export).
- [ ] Visual Review PASS: Trulte's tag reads as a special coral star tag, not broken.
