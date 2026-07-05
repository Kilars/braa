# 122 — FEATURE — Locked difficulty section states the reason, not just the fact (119 follow-up)

**Source:** PO Review 2026-07-05 (`.docs/specs/po-review.md`), Improvement #2.

## What it addresses (spec gap)

On a special dog the difficulty section correctly greys and marks Hard «Låst»
(`.screenshots/119-01-menu-locked.png`), but **nothing tells the player *why*** the challenge is
fixed — a first-timer reads it as a bug, not a design choice. The lock (119) states the fact but
not the reason.

**Good looks like:** a short one-line note on the locked section (e.g. «Spesialhunder trener alltid
på Hard») so the lock reads as intentional. Minor, but it removes the confusion.

## Why prioritized now

Second (minor) filed PO directive on the current phase (Phase 9). Small and self-contained; ships
alongside 121 to clear the sign-off directives.

## Technical approach

The "Vanskelighet" subheading is drawn once above the difficulty rows. When the section is **locked**
(a special dog — `_difficulty_locked()` in main, surfaced to the menu via the `locked` flag already
on every difficulty row from `classify_difficulty`), draw a dimmed one-line note directly under the
subheading (or under the last row), styled like the other secondary/hint text (`WORD_COST_HINT` /
`SLATE_SOFT`, `BADGE_SIZE`).

- Home the note string as a named const next to `DIFF_BADGE_LOCKED`, e.g.
  `const DIFF_LOCKED_NOTE := "Spesialhunder trener alltid på Hard"`.
- Derive "is the section locked" from the rows the menu already holds (`_difficulties` — any row
  with `locked == true`), so no new plumbing from main is needed. A pure predicate is testable:
  ```gdscript
  ## True iff the fed difficulty section is locked (a special dog fixes the mode) — drives the
  ## explanatory note. False for a normal dog (every row selectable) or an empty section.
  static func difficulty_section_locked(rows: Array) -> bool:
  ```
- Draw the note only when `difficulty_section_locked(_difficulties)` is true. Account for its height
  in the difficulty block geometry (`_difficulty_block_h` / row layout) **only when shown**, so a
  normal dog's / unfed section's layout is byte-identical (the trick/breeds/words geometry must not
  shift). Simplest: reserve the note's line height inside the existing `DIFFICULTY_HEADER_H` region
  when locked, or add a small `DIFFICULTY_NOTE_H` added to the block height only when locked.

Before (`_draw` difficulty section, around `scripts/trick_menu.gd:667`): subheading + rows only.
After: subheading + (locked ? dimmed note : nothing) + rows — the note never appears for a normal
dog.

**Do NOT** change the lock behavior, badges, or row selection; this is a presentational note only.

## Acceptance criteria

- [x] TDD: a failing test for `difficulty_section_locked` FIRST — true when any fed row is
      `locked`, false for an all-selectable (normal-dog) section and for an empty section.
- [x] Green: the predicate passes; the note const holds the Norwegian string.
- [x] `_draw` shows the dimmed one-line reason note only when the section is locked, and never for
      a normal dog or an unfed section.
- [x] Layout: a normal-dog / unfed difficulty section's geometry is unchanged (note reserves height
      only when locked); no shift to the trick/breeds/words blocks.
- [x] No regression to the 119 lock (rows still non-selectable, Hard still «Låst») or to 121's
      trade subtitles.
- [x] `verify.sh` green.
- [x] Visual Review (390×844): boot a special dog (`?bra_kennel=nova`), open the menu — the locked
      Vanskelighet section shows the reason note; a normal dog shows no note; screenshots under
      `.screenshots/122-*`.
- [x] Placeholder check clean on the diff.

## Resolution (2026-07-05)

Shipped. `difficulty_section_locked(rows)` (pure, unit-tested) reports whether any fed row is
locked (special dog). `_draw` renders a dimmed one-line note `DIFF_LOCKED_NOTE`
(«Spesialhunder trener alltid på Hard») between the "Vanskelighet" subheading and the rows, only
when the section is locked; `DIFFICULTY_NOTE_H` is reserved in `_difficulty_block_h` /
`_difficulty_row_rect` only when locked, so a normal-dog / unfed section's geometry is byte-identical.
3 TDD tests, verify green 653/0. Visual Review PASS — `.screenshots/119-01-menu-locked.png` shows the
reason note above the greyed rows on Nova (EPIC); a normal dog shows no note (`.screenshots/118-*`).
