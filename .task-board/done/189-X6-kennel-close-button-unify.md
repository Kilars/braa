# 189 — Unify the kennel ✕ close controls onto one shared, readable component (PO father-pass-63, X-6/X-4)

**Source:** `.docs/specs/po-review.md` — PO father-pass-63 (2026-07-08), the one buildable directive.

## Directive
The kennel has two dismiss ✕ controls styled oppositely and both below the app's touch-target standard:
- **Grid `CloseButton`** (`kennel_screen.gd:355`): dark `C_INK` glyph on a translucent light `C_CLOSE_BG` disc, `CLOSE_SIZE = 36`.
- **Modal `ModalClose`** (`kennel_screen.gd:1245`): **white** glyph on `Color(0,0,0,0.20)` disc, `CLOSE_SIZE = 36` — a dark-bg treatment applied over a **light** portrait, so it washes out on Sol's/Bella's light coats (~1.22:1-class disappearance).

The app's own nav pills are 44u (`main.gd TRICKS_BTN_HEIGHT`); both ✕ are 36u (~19–20 CSS px).

## What "good" looks like (from the PO)
One shared close-button component reused on both kennel screens: a solid, **defined** light disc with a dark `C_INK` glyph that reads on **any** band/portrait, sized to the app's **44u** standard. Keep it top-corner + unobtrusive; the glyph + disc must stay clearly present so the ✕ never vanishes over a light coat, and both kennel ✕ match.

## Plan
- Bump `CLOSE_SIZE` 36 → 44 (app control standard).
- Add opaque disc + defined steel ring so the control reads on both the light header AND a light coat (a bare light disc on a light bg would vanish — the ring defines it).
- New pure `KennelScreen.close_button_style()` returning the shared spec (size / disc / border / ink), and a `_make_close_button(name, on_pressed)` factory both call sites use → literally one component.
- TDD: assert the spec is 44u, disc opaque + light, dark-ink glyph clears AA on the disc, and both wired buttons (grid + modal) carry the identical shared stylebox/ink/size.

## Done when
- `test_kennel_close_button.gd` green, verify gate green, both ✕ reskinned, Visual Review confirms the modal ✕ reads on a light coat and matches the grid ✕.
