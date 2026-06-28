# Planning Board — Bra! v2

Source of truth: [`specs2.md`](../specs2.md) (phased user stories) and the ADRs in
[`adr/`](../adr/).

> **Phasing rule (from the spec):** Phase 1 is the whole bet. Nothing past Phase 1
> starts until Phase 1 passes its Visual Review and is bug-free.

## Status — trust-nothing reconcile (2026-06-28)

`main` was reset to a clean single Godot root commit (Babylon gone). A source-level,
trust-nothing audit of the committed Phase-1 tree then found the board was over-claiming.
Reconciled below. Two findings dominate:

### ⛔ Blocker 1 — the Phase-1 core loop is DORMANT on the live site
The shipped CC0 dog (`assets/models/dog.glb`) has **no Sitt clip** (and no reaction clip).
So at runtime: the sit never opens → every BRA tap scores **DEAD** → no score, no apex
tell, no payoff (silent), no dog reaction. **A player cannot experience Phase 1 on the
deployed site today** — they see a centered, idling dog and a BRA button that does nothing
audible/visible. The sit/tell/tap/payoff code is real and unit-correct but **dormant**.

**The fix is small — the sit asset already exists and the code already supports it.** The
bought licensed Labrador (`models-build/out_anim.glb`, 113 clips incl.
`Arm_Labrador|Sitting_start / loop / end`) is on disk; `DogClips.resolve()` already matches
those names, so `has_sit()` would be true and the loop would light up the moment the loader
points at it. **025 = wire + ship the Labrador**, not acquire one. The only owner-gated
piece is shipping it to the **public** Pages site without leaking the license (ADR-0006
encrypted pack → one CI secret/key, set once). Local review needs no secret.

### ⛔ Blocker 2 — the verify gate is partly lying (026)
The headless test runner reports `all green / exit 0` **even when a test throws a runtime
SCRIPT ERROR mid-method** (an aborted method records zero failures). Right now
`scripts/main.gd:123` (`get_visible_rect()` on a null headless viewport) crashes
`test_bra_button` and `test_payoff_wiring`, which therefore **never run their asserts** yet
read green. Until **026** fixes this, "verify gate green" is not trustworthy and the loop
is building on a gate that can't catch a broken scene.

### Per-system audit result
| System (card) | Code | Tests | Live on CC0 dog? | Board |
|---|---|---|---|---|
| scoring math `SitWindow`/`SitSession` (024a) | real | real, pure | n/a (logic) | **done** |
| idle loop (024c) | real | ok | **LIVE** | in-progress (needs visual review) |
| camera framing `DogFraming` | real | real, pure | **LIVE** | (part of 021/024) |
| sit (024b) | real | — | dormant | **on-hold → 025** |
| apex tell (024d) | real | real, pure | dormant | **on-hold → 025** |
| BRA tap (024e) | real | **hollow** (026) | tap always DEAD | **on-hold → 025** |
| payoff (024f) | real, synth WAV (not Maren voice) | real | silent | **on-hold → 025** |
| readout P1-7 (024g) | **MISSING** (only `print()`) | — | none | backlog |
| reduced-motion P1-8 (024g) | **MISSING** (dead seam, no caller) | — | none | backlog |

> Note: `scripts/main.gd` comments claiming "the readout (024g) consumes `marked`" are
> **false/aspirational** — no UI consumer exists. Clean up with 024g.

## Current phase

**Phase 1 — the perfect single mark** (specs2.md §Phase 1). The logic is largely built and
correct; the phase is gated on a sit-capable dog (025) and an honest gate (026).

## Before restarting the autonomous loop — DO THESE FIRST
1. **026** — fix the lying test gate (runtime errors must fail; guard `main.gd:123`).
   Otherwise every loop iteration trusts a gate that can read green on a crash.
2. **025** — wire in the **already-bought** Labrador (`models-build/out_anim.glb` has
   `Sitting_start/loop/end`; the code already resolves them). Point the loader at it, import
   it, and ship it to public Pages without leaking the license (ADR-0006 encrypted pack —
   one CI secret, set once by the owner). Local proof needs no secret. Until 024b/d/e/f run
   on this dog, they stay parked and Phase-1 live review is impossible. NB: if pointed at the
   visual slices with no real sit clip, the loop will fake a sit — but the real one IS here.

## In progress
- **024** — Phase 1 epic (stays open until the P1-10 done-gate passes).
- **024c** — idle loop: LIVE + real; needs a live **visual review** to close (P1-2).

## On-hold (code written + committed, blocked on 025 — do NOT rebuild, do NOT mark done)
- **024b** — the sit (P1-3) — dormant on CC0.
- **024d** — the apex tell (P1-4) — dormant (sit never opens).
- **024e** — BRA tap + scoring (P1-5) — every tap DEAD live; button tests hollow (026).
- **024f** — payoff voice/SFX/reaction (P1-6) — silent live; audio is synth placeholder,
  not the Maren voice.

## Backlog (in priority order)
- **026** — BUG: verify gate swallows SCRIPT ERRORs (gate integrity). **HIGH — first.**
- **025** — wire + ship the **already-bought** Labrador (`out_anim.glb`, has the sit). Code
  already resolves its clips; load it + import it + ship via ADR-0006 encrypted pack (one CI
  secret = the only owner-gated bit). The Phase-1 unblocker — small, mostly code.
- **024g** — honest on-screen timing readout (P1-7) + reduced-motion wiring (P1-8). Both
  currently MISSING; also delete the false `marked`-consumer comments in `main.gd`.

## Done (verified)
- **024a** — apex-band / scoring-window math (`SitWindow`/`SitSession`), test-first,
  source-audit confirmed real (mutation-tested).
- **023** — bun/Babylon toolchain removed; verify gate is Godot headless
  (`nix develop -c bash verify.sh`: import · boot · test · export).
- **022** — CI exports Godot Web/PWA to Pages (export-gated, nix-pinned).
- **021** — Godot 4 scaffold; boots headless with the dog loaded + centered (real framing).
