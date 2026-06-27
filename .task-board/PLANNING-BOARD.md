# Planning Board — Bra! v2

Source of truth: [`.docs/specs.md`](../.docs/specs.md) (→ `specs2.md`, phased user stories).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

## Current phase

**Phase 2 — More tricks, same quality bar.** (Phase 1 signed off 2026-06-27; record in
[`.docs/tech-decisions.md`](../.docs/tech-decisions.md) §2.) A `scan-project` pass against
Phase 2 found **all six P2 stories Missing**, with one unambiguous blocker: there is **no
trick abstraction anywhere** — "Sitt" is hardcoded end to end (`sitCycle.ts`, `scene.ts`,
`dog.ts`). Every other Phase-2 story (selector, learned bar, persistence, anti-mash) needs
tricks to exist as data first, so the multi-trick model leads the batch. Same quality bar:
every new trick clears its own Visual Review before it counts as done.

## Top priorities

The Phase-2 foundation (**012**) is **done** — the trick model + seam are in. Remaining in
the batch, dependency-ordered:

1. **013 — Ligg (lie-down)** (Phase-2 core, rendering/Visual-Review). The first expansion
   trick: switch `dog.pose()` on the active trick's `poseKind` (the seam 012 added), add the
   `ligg` registry entry, and draw a distinct lower-and-settle with a clear "down" apex,
   obviously not a sit (P2-2/P2-3). The one visual task this round — saturation override
   logged in-task (P2-2 has no non-visual substitute). **Widen `TrickId` to `'sitt' | 'ligg'`
   in the same edit that appends the entry** (012 left it `'sitt'` to avoid a phantom union
   member).
2. **014 — Pick-a-trick selector** (P2-1, UI + TDD). A small one-page portrait chip selector
   that drives `scene.setTrick` (already on `SceneHandle`); pure selection state is test-first,
   chip UI gets a Visual Review. Stays one-verb — not a second gameplay action (X-2). Uses the
   `__braTricks` / `__braSetTrick` probes 012 exposed.

Deferred to the next scan round (need 013–014 first): **P2-4** learned bar → mastery,
**P2-5** persistence + pause/resume, **P2-6** light anti-mash. Domain note: visual/rendering
is saturated (4/15 recent) — this batch is mostly logic/UI, with only 013 visual by necessity.

## Recently completed

- **012 — Multi-trick model (Phase-2 foundation)** (2026-06-27). Generalized the Sitt-only
  timing brain into a `TrickDef` registry: new `src/core/trick.ts` (`TrickId`, `PoseKind`,
  `TrickDef`, `TRICKS`, `getTrick`), `scene.ts` now drives pose + scoring window + apex tell
  from an `activeTrick` (with `SceneHandle.setTrick(id)`), and `main.ts` exposes
  `__braTricks` / `__braSetTrick` probes. Sitt is **byte-identical** (regression test samples
  a full cycle against `SIT_TIMINGS`). TDD red→green; 44→49 tests. Scoped to the *seam* only —
  `dog.ts` untouched, `poseKind` carried but not switched on (that's 013). Recorded a
  discrepancy: kept `TrickId = 'sitt'` (not `'sitt' | 'ligg'`) so the union has no phantom
  member; 013 widens it with the entry. Gate green (typecheck 0 · test 49 · build clean · e2e 5).

- **011 — Phase-1 close-out sign-off (GATE / P1-10)** (2026-06-27). The hard done-gate, run
  as a single pass: `typecheck` 0 · `test` 44 · `build` no-warnings · `e2e` 5; capture
  frames regenerated; `polish` run (one safe fix — a missing BRA `:focus-visible` ring —
  applied without regressing any frame); **two independent reviewers PASS, no blocking
  findings** (cross-checked against the real `.screenshots/`); P1-0 … P1-10 walked with
  evidence. **Phase 1 closed; Phase 2 unlocked.** Full record: `tech-decisions.md` §2.

- **009 — POLISH: smooth the mid-build silhouette** (2026-06-27). Closes PO **I2** (P1-3):
  the hindquarters no longer balloon rearward at sitAmount ≈ 0.5–0.65. In `dog.ts` `pose()`
  the rump is tucked forward+down with its rearward bulge pulled in via a corrective hump
  `tuck = s*(1-s)` — zero at both s=0 and s=1, so idle and the already-clean apex are
  untouched (the rump is byte-identical at the apex by construction). Recorded a discrepancy:
  the task's illustrative snippet drove the rump *linearly* with `s`, which would have moved
  the apex — used the hump instead to honour the "don't regress the apex" constraint. Visual
  Review **2/2 PASS** on frozen build frames (0.3/0.5/0.65/0.85 + apex); no new artifacts.
  Gate green.
- **008 — Stronger mark reaction** (2026-06-27). Closes PO **I1** (NS-1 / P1-6): the
  success payoff now reads as an unmistakable celebration with audio off. Added a grounded
  `pop` squash-and-settle channel to `reaction.ts` (TDD; snappy attack, settles before the
  wag finishes, PERFECT clearly > OK, MISS flat) and mapped it in `dog.ts` to a chest puff
  + crisp chin (0.6) + ear perk + tail flurry — `root.position.y` pinned to 0 so paws stay
  on the shadow (D12). Visual Review **2/2 PASS**: head rise +9px (OK) vs +26px (PERFECT),
  shadow steps 188→208→224px (tiering, not a float), paws planted in 04/05. Gate green.
- **007 — Seated-hold vs markable window** (2026-06-27). Closed PO **C1**: every
  fully-seated instant now scores ≥ OK (the tell can't be dark while the dog looks seated).
- **006 — Phase-1 close-out gate** (2026-06-27). Verified the one-source-of-truth wiring
  in `src/main.ts` (tier → readout + audio + reaction), MISS-visible-but-silent / NONE-
  nothing, and reduced-motion damping across all cues. Visual Review found + fixed a
  blocking bug: the tier readout washed out (pale fills + soft blur) — now a crisp dark
  outline + vivid per-tier fills (gold/cyan/coral), legible over the gradient and ring
  glow. Also fixed the capture harness to pin the readout to full opacity (automated
  Chrome throttles the fade animation, masking real legibility). 2/2 final reviewers PASS.
  Gate green.
- **005 — Dog reaction on a mark** (2026-06-27). A seated perk-up (chin up, livelier tail,
  a whisper of a grounded bob — paws stay on the shadow) on OK/PERFECT, PERFECT bigger;
  none on Miss; reduced-motion dampened. Pure `reactionAt` envelope (TDD) + thin mesh
  layer in `dog.ts`; deterministic `captureReactPeak` probe for honest review frames.
- **004 — Mark payoff audio** (2026-06-27). Pure `cueForTier` decision (PERFECT brighter
  than OK; Miss/dead tap silent — no Phase-1 penalty audio) + a thin procedural WebAudio
  player (synth "Bra!" + click; real Maren voice is an owner-gated one-file swap). Boots
  green even headless (no `AudioContext` → safe no-op).

- **003 — Dog scene** (2026-06-27). Babylon dog (`src/render/{scene,backdrop,dog}.ts`) on
  the scaffold canvas: composed recognizable Labrador (neck, rounded muzzle + nose pad,
  soft drop ears, four legs, tail, blob shadow), an idle loop + a legible sit-to-apex, and
  an honest apex-tell ring driven per frame from the same `apexTime` the BRA tap scores
  against (task 002), so tell and score can't disagree. Visual Review: 2/2 independent
  phone-portrait reviewers PASS. Also fixed the capture harness to freeze the shared clock
  (pose + tell together) for honest review frames. Gate green.
- **002 — Timing & scoring core** (2026-06-27). Pure, test-first scoring brain
  (`src/core/{tuning,window,mark}.ts`): `scoreTap(window, tapTime)` →
  PERFECT/OK/MISS/NONE, a 400 ms window with an 80 ms PERFECT band centered honestly
  on the apex (P1-4), no Phase-1 penalty path (P1-0). 12 new tests; gate green.
- **001 — Project scaffolding** (2026-06-27). Runnable bun/Vite/TS skeleton; full
  verify gate green (`typecheck` · `test` · `build` · `e2e`) and `dev` serves the
  BRA shell in portrait. The app is now runnable, so the father/PO play-test pass can
  begin once Phase 1 has something to look at.
