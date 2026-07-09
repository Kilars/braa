# 195 — POLISH: drop the marker-word decorative pip + indent (flush row-name alignment)

**Source:** PO Review 2026-07-09 (father pass 69), one buildable X-6 directive.
Phase 6/design-system polish arc (X-6 cross-cutting: "same component rendered the same
across the surface").

## Directive (verbatim intent)

The four completion-menu selection sections now agree on heading typography (193),
current-vs-switchable badges (194) and pale-pill row washes — **except** the marker-word
(«Markørord») rows still draw a decorative leading pip («•») + an extra indent (134's
pre-unification "make words distinct" leftover). That pushes the word name's left edge
~6 px right of the flush trick/difficulty names (which start at `rect.x + 14.0`) and
leaves «Markørord» as the lone section with a purely-decorative bullet.

## What good looks like

- Drop `WORD_ROW_INDENT` + the decorative word pip so marker-word row names start flush at
  the same `+14.0` inset as the trick (`_draw_row`) and difficulty (`_draw_difficulty_row`)
  names. Route all three through one shared `NAME_INSET`.
- Keep the **meaningful breed coat swatch** untouched (it's a real colour signal, not decoration).
- Keep the 170 colour decisions untouched — geometry/decoration change only, don't re-couple ink.
- Keep the word name/badge tokens («Bytt»/«Aktiv»/«Låst») and the dimmed cost subtitle as-is.

Net: all four sections share one row-name left edge; no section carries a decorative-only bullet.

## Plan

1. (RED) test: word/difficulty row name inset == trick row inset (14.0), not the old 20.0.
2. (GREEN) add `const NAME_INSET := 14.0` + `row_name_left()`; repoint trick/diff/word names;
   remove pip draw + `WORD_ROW_INDENT`/`WORD_PIP_R`/`WORD_PIP_ACTIVE`.
3. verify.sh green; visual capture of the menu.

## DoD
- verify gate green; TDD test passes; no decorative pip on word rows; breed swatch intact.
