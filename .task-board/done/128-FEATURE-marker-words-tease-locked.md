# 128 — Marker-words section: tease locked words sparingly (not fully enumerated)

**Type:** FEATURE (menu progressive disclosure — SERIOUS/narrowed residual)
**Source:** Father Phase-10 PO pass `0003dfe` — the one open directive after 127.
**Phase:** Phase-10 finish item (X-4 quality bar), preempts Phase-10 scaffolding.

## Directive (verbatim acceptance)

> The marker-words section still fully enumerates its locked future words. Once the
> marker-words section correctly surfaces (reward for mastery #1) it lists Bra! (Active) +
> Dyktig! (Switch) **and** all three not-yet-reachable words Flink! / Super! / Kjempebra!
> as fully-enumerated Locked rows. The directive's acceptance says "locked rows are teased
> sparingly, not fully enumerated" — the tricks section honours this (`MenuReveal.teased_locked`
> caps the locked tease at 1), the marker-words section does not.
>
> **Acceptance:** apply the same sparing tease to the marker-words locked rows — show the base
> word + the earned/switchable word + at most **the single next** locked word as a "coming soon"
> beat, and hide the rest until they come within reach (mirror `MenuReveal.teased_locked`, keyed
> to the marker-word unlock ladder). Keep the section's reveal gate (appears once the first alt
> word is unlocked) as-is.

## Plan (TDD)

- New pure predicate `MenuReveal.teased_words(rows, locked_state, max_tease := 1)`: keep every
  non-locked row (Active/Switch) + at most `max_tease` locked rows, order preserved. Since the
  word catalog is ordered by the unlock ladder and unlocked words are always a prefix, the first
  kept locked row IS the next word — a single "coming soon" beat.
- Unit-lock it in `tests/test_menu_reveal.gd` (mirror the `teased_locked` tests): full-enumeration
  → tease-1; all-unlocked → unchanged; empty → empty.
- Wire in `main._word_rows()`: apply `teased_words` after `classify_words` (+ cooling/remaining),
  passing `TrickMenu.WordState.LOCKED`. Reveal gate (`reveal_words`) unchanged.

## Done when
- verify gate green (import·boot·test·export).
- Menu shows Bra!(Active) + Dyktig!(Switch) + Flink!(Locked) only — Super!/Kjempebra! hidden
  until they come within reach.
- Placeholder check clean; committed + pushed.
