# 066 — FEATURE: trick selector (P2-1 "Pick a trick")

**Phase:** 2 (current) · **Type:** Feature · Routed from BUST-064. Depends on **065** (≥2 tricks wired).

## Source
P2-1: "choose which trick to train from a small, clear selector … not a second gameplay verb during
the round." With Ligg wired (065) and Legg deg coming (067), a real two-/three-entry chooser is now
buildable. The PO's "do **not** build a one-entry selector" caution was premised on there being only
one trick (the behavior≠inventory error BUST-064 refuted) — it does not block a genuine multi-trick
chooser.

## Scope
- One-page, portrait, one-verb selector to pick the current trick (Sitt / Ligg / …) between rounds.
- Replaces the `?bra_trick=` debug reach 065 ships with a real UI chooser; sets `_current_trick`.
- Each entry shows its own persisted learned/mastery state (per-trick store already keyed).
- Visual Review at 390×844: clear, uncluttered, doesn't intrude on the round.

## Done when
- [x] Selector built + wired to `_current_trick`; the `?bra_trick` debug reach retired as the
      player-facing chooser but **kept web-only + off-by-default** as the capture-harness initial
      trick. TDD the selection→current-trick routing.
- [x] `verify.sh` green. Visual Review passes. Placeholder check clean. Commit + push.

## What landed
- **`scripts/trick_selector.gd`** (new `TrickSelector` Control) — a small one-page chip row pinned in
  the top HUD, one chip per performable trick (Sitt / Ligg / Legg deg). Dumb-renderer split like
  LearnedBar/TierReadout: main feeds entries + the current id; the node draws chips (current one gold-
  bordered), shows **each trick's own** learned-fraction pip + mastered-gold state (P2-1 "each entry
  shows its own state"), and maps a tap x→chip id via `id_at()`, emitting `trick_selected` on press.
  It is **not** a second in-round verb — it sits in the clear sky far above the BRA button.
- **`scripts/main.gd`** — mounts the selector (`_setup_selector`), populates it from
  `_selectable_tricks()` (only tricks `_director.has_trick()` — empty on the idle-only CC0 dog, never
  a faked trick) via `_refresh_selector()`, and routes `trick_selected → select_trick(id)`:
  repoints `_current_trick` + `_progress` (+ the learned bar) to that trick's own persisted model,
  closing any open offer of the OLD trick cleanly first (stands up on the OLD trick's own end clip)
  and `SitLoop.reset_to_idle()` so the next offer comes round fresh as the new trick. The top HUD
  stack (selector → learned bar → readout) is now derived from the selector's foot; the readout word
  still clears the dog's crown (038, re-verified in pixels below).
- **`scripts/sit_loop.gd`** — new `reset_to_idle()` (parks IDLE + draws a fresh gap) so a mid-offer
  switch never stalls the loop.
- **TDD:** `test_trick_selector.gd` (8: id→name map, x→chip hit-map, press-only signal, per-chip
  learned state) + `test_trick_selector_wiring.gd` (6: scene mount, roster = performable-only,
  select→current+progress+bar routing, same/unknown-id no-ops, highlight tracks the switch) +
  `SitLoop.reset_to_idle` regression in `test_sit_loop.gd`. 273 tests green.
- **Visual Review @ 390×844 (local licensed bundle):** `.screenshots/066-*` — the chip row reads
  cleanly (Sitt highlighted default; `?bra_trick=ligg` highlights Ligg, proving the highlight tracks
  `_current_trick`); pip no longer strikes the labels; forced-PERFECT readout still clears the crown.
- **Live e2e (`tools/web_selector_switch.mjs`):** a REAL headless-Chromium canvas tap on the middle
  chip flipped the trained trick `sitt → ligg` (via the web-only `window.__bra_current_trick` hook) —
  the selector's crux (canvas tap → `_gui_input` → `select_trick`) proven end-to-end, not self-certified.
