# 064 — BUST: the Phase-2 trick roster "owner-gate" (P2-1/P2-2/P2-3)

**Phase:** 2 (current) · **Type:** Flag-bust (research + routing only, no product code) · **Preempts work-ahead.**

## Source
`.docs/specs/po-review.md` (2026-07-01 PO pass) **asserted** the trick roster is "owner-gated on
trick clips — the licensed Labrador ships only the Sitt, so there is no second trick to select,
perform, or polish." The assertion was never raised as a `FLAGS.md` flag, so the flag-bust sweep
(Iteration step 2) would have missed it — the exact anti-pattern (behavior read as inventory) that
CLAUDE.md names for P2-1/2/3. The orchestrator raised + busted it.

## The bust (against the raw manifest — behavior ≠ inventory)
`grep -iE 'sit|lie|paw|roll|spin|beg' assets/models/dog_licensed.clips.txt` (the committed 139-line
licensed glb inventory) shows the asset already holds **three** tricks' clips, not one:
- **Sitt** → `Sitting_*` — WIRED today.
- **Ligg** (lie down) → `Lie_start / Lie_loop_1|2 / Lie_end` — **PRESENT, unwired.**
- **Legg deg** (settle) → `Lie_belly_start|loop|end` (+ `Lie_Sleep_*`) — **PRESENT, unwired.**
The app only *wires* Sitt (`DogClips.resolve()` matches only `sitting`-vocab clips), so the running
game shows one trick — but that is behavior, not inventory. Present-but-unwired clips are a **BUILD
task, not an owner-gate**. This is the P2-2 starter set verbatim ("**Sitt**, **Ligg**, **Legg deg**").

## Routing
- **Ligg** → build task **065** (this iteration): wire it as a real, distinct, markable second trick.
- **Legg deg** → build task **067** (backlog follow-up).
- **P2-1 selector** → build task **066** (backlog): a real two-/three-entry chooser once ≥2 tricks
  are wired (NOT the "one-entry selector" the PO warned against — that caution assumed one trick).

## Narrowed residual (genuinely owner-gated — clips ABSENT)
**Gi labb** (paw/shake), **Rull** (roll over), **Snurr** (spin): no matching clip in the manifest
(grep hits only `Crouch_*` / `Jump*` decoys, none a clean trick apex). These stay owner-gated until
the owner supplies clips or they are hand-authored. Flag narrowed to just these three in `FLAGS.md`.

## Outcome
Phase 2 is **not** blocked purely on the owner — a 3-trick roster (Sitt+Ligg+Legg deg) is buildable
now. Flag `FLAGS.md` 2026-07-01 stamped **busted 2026-07-01**. Research/routing only — no code here.
