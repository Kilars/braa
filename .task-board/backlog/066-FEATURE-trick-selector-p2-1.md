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
- [ ] Selector built + wired to `_current_trick`; the `?bra_trick` debug reach retired or kept
      debug-only. TDD the selection→current-trick routing.
- [ ] `verify.sh` green. Visual Review passes. Placeholder check clean. Commit + push.
