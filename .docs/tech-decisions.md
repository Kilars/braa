# Tech decisions & sign-offs — Bra! v2

Implementation notes and gate records the build loop owns. The spec
(`specs.md` → `specs2.md`) is read-only to the loop; this file is where the
loop records how it built to the spec and the evidence behind each gate.

---

## §1 — Babylon engine ships as one large chunk (build "no-warnings")

The dog scene root-imports `@babylonjs/core` for registration safety, which pulls
the engine in as a single ~5 MB chunk. `vite.config.ts` raises
`chunkSizeWarningLimit` to 6000 so `bun run build` stays warning-free; the bundle
is cached once for offline play (X-7). Trimming it via targeted
`@babylonjs/core/...` deep imports is a tracked follow-up (task 003 notes).

---

## §2 — Phase-1 close-out sign-off (task 011 / P1-10) — 2026-06-27

**Verdict: Phase 1 is PROVABLY DONE. Phase 2 unlocked.**

Consolidated done-gate over the finished single-mark loop, run as one pass on a
phone-portrait viewport (390×844) against `_capture.spec.ts` frames in
`.screenshots/` regenerated post-punch-list. No fabricated artifacts — every claim
below ties to a real capture, test, or gate run.

### Verify gate — GREEN

| Gate | Result |
| --- | --- |
| `bun run typecheck` | 0 errors |
| `bun run test` | 44 passed (5 suites: mark, math, reaction, sitCycle, markCue) |
| `bun run build` | built clean, no warnings (`chunkSizeWarningLimit`, §1) |
| `bun run e2e` | 5 passed (smoke, scene, loop, favicon, _capture) |

### Polish pass

The `polish` skill was run over the visual surface (`src/render/*`, `src/app/shell.ts`,
`src/style.css`) at the Phase-1 MVP bar. The UI layer already carried its prior
Visual-Review fixes (layered dark-outline tier readout; vivid per-tier fills;
ring-clearing marker gap). One safe, non-regressing gap was found and fixed: the
**BRA button had no explicit keyboard focus indicator** (`border:none` + pill radius
made the UA default ring read tight/faint over the orange fill). Added a
`.bra-button:focus-visible` dark ring consistent with the existing outline language.
It does not touch any pointer/tap visual or the apex pose, so no capture frame
changed; build + e2e re-ran green after the edit. No other changes — no apex-pose
regression risk taken.

### Independent Visual Review — 2/2 PASS (blocking gate)

Two independent reviewers each read the real `.screenshots/` PNGs at phone-portrait
and ruled. Both returned **PASS, no blocking findings**. Their claims were
cross-checked against the actual images by the signing agent.

- **Reviewer A — PASS.** Dog reads as a centered, shadow-anchored Labrador (01); idle
  alive-but-calm; the I2 mid-build defect is genuinely resolved — `build-65`/`build-85`
  show the hock fold and rump drop into a seated fold, no rearward balloon; apex ring
  tell present (03); OK vs PERFECT distinct (PERFECT a bigger chin/ear lift) with paws
  planted (04 vs 05); readouts legible and color-distinct (06/07/08); reduced-motion
  tell dampened-not-removed (09); no primitive flash / T-pose / float / clip.
- **Reviewer B — PASS.** Same conclusions; specifically hunted for and confirmed the
  build-50/build-65 lumpy-haunch defect is NOT present (clean rounded fold); OK/PERFECT
  both grounded; tier words crisp in the gap above the button with no wash-out or ring
  overlap.
- **Non-blocking notes (polish backlog, did NOT re-open the gate):** the seated tail
  reads slightly stiff/stick-like at the 3/4 angle; the pure side profile (01) reads a
  touch long; the OK readout's pale-cyan is the least celebratory of the three. All
  cosmetic, within Phase-1 tolerance.

### P1 story checklist — all pass, with evidence

| Story | Verdict | Evidence |
| --- | --- | --- |
| **P1-0** Tight scope | PASS | Only the single-mark loop is built; no learned-bar/coins/levels/breeds/menus/save in `src/`. |
| **P1-1** A dog worth looking at | PASS | `01-stand.png`: centered Labrador (head/ears/snout/body/4 legs/tail), contact shadow, clean sky→green backdrop; no bare primitives. Reviewers 2/2. |
| **P1-2** Alive at rest | PASS | Idle pose centered & calm (`01`); `sitCycle` idle loop is seamless (14 tests). |
| **P1-3** Legible sit + clear apex | PASS | `build-30/50/65/85` → `03-apex` reads as one continuous fold to a clean seated apex; PO I2 (lumpy mid-build) confirmed fixed by both reviewers. |
| **P1-4** Apex tell | PASS | `03-apex.png`: cream/gold ring glow around BRA; driven per frame from the same `apexTime` the tap scores against (003) so tell ≠ score is impossible. |
| **P1-5** The BRA tap | PASS | One large pill BRA button (≥220×96px, P1 touch target); `scoreTap` → PERFECT/OK/MISS/NONE, no false-mark penalty (mark.test.ts, 12 tests). |
| **P1-6** Mark feels good | PASS | `cueForTier` audio gated (PERFECT brighter, silent on MISS/dead tap; markCue.test 5 tests); dog reaction OK vs PERFECT distinct & grounded (`04` vs `05`, PO I1 fixed). |
| **P1-7** Honest timing feedback | PASS | Tier readout lands on `pointerup` (loop.spec.ts); PERFECT/OK/MISS legible & distinct (`06/07/08`), dark-outline fills over gradient + ring. |
| **P1-8** Reduced motion respected | PASS | `09-reduced-motion-apex.png`: tell dampened not removed; CSS `prefers-reduced-motion` damps ring expand + tier pop, keeps the cue (D13). |
| **P1-9** It just works | PASS | No primitive flash / T-pose / float / clip / drift across all frames (2/2 reviewers); inline `<link rel="icon">` → no favicon 404 (favicon.spec.ts, PO B1 fixed). |
| **P1-10** Provably done | PASS | This sign-off: gate green, `polish` run, 2/2 independent reviewers PASS, game logic test-first (44 specs). |

**Signed off: 2026-06-27. Phase 1 closes; the phasing rule unlocks Phase 2.**

---

## §9 — Per-trick pose: one build axis, a `poseKind` branch, a shared ambient block (task 013)

Phase 2 ("more tricks, same quality bar") needs each trick to animate *distinctly*
(P2-2) without forking the dog rig per trick or re-tuning the feel. The pattern Ligg
established, to be reused by every later trick:

- **One 0→1 build axis drives every trick.** `sitCycle`'s eased `sitAmount` (generic to
  any static-pose trick) is the single input; `trick.ts` carries each trick's cadence +
  `poseKind`. The scene reads `activeTrick.timings` for the window/tell and passes
  `activeTrick.poseKind` to `dog.pose()`, so pose ⟷ scoring ⟷ tell can never disagree
  about which trick is active.
- **`dog.pose()` branches on `poseKind` for the *skeleton* only.** The `'sit'` branch is
  byte-identical to Phase 1 (it even resets the front legs to their planted construction
  values, so a lie→sit switch is clean). New poses add a branch; they do **not** touch the
  sit.
- **Ambient life + mark reaction stay in ONE shared block** after the branch, keyed on the
  generic build amount `a` (== sit `s` when posing the sit → byte-identical) plus a small
  set of per-pose locals the branch sets (`headPosePitch`, `tailPitch`, `wagScale`). This
  is how breathing / tail wag / chin-lift / ear-perk / grounded squash stay consistent
  across tricks for free — a new trick gets the same "feels good" reaction without
  re-implementing it.
- **Grounding is per-pose (D12).** The round blob shadow is sized for the sit's footprint;
  the lie-down's long forward footprint needed the shadow stretched in z and slid forward
  (in `scene.ts`, scaled by build amount, zero for the sit). Any future trick with a
  different footprint must do likewise or its paws read as floating.
- **The "looks-built == markable" invariant is now per-trick** (PO C1 / task 007): every
  `TrickDef` must keep `holdMs <= windowWidthMs/2`. `trick.test.ts` asserts this across
  all `TRICKS`, so a new trick with too long a hold fails the unit gate, not Visual Review.
- **Rendering tasks gate on Visual Review, not unit tests.** Ligg's first review caught
  three issues invisible to typecheck/tests (detached-looking tail under the wag, forepaws
  off the shadow, weak OK/PERFECT delta) plus a floating hind-leg blob; all fixed and
  re-confirmed SHIP by independent reviewers on real 390×844 frames.
