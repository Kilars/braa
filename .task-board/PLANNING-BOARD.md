# Planning Board

**Current Focus**: Iteration 25 (2026-06-21) found the backlog drained (115/116/117 all DONE) →
ran `scan-project`. The spec now carries a fresh, authoritative **PO Review — 2026-06-21** (the
father pass play-tested the imported Labrador on phone-portrait): the **v1 core loop is functional,
no P0**, and the Labrador "renders genuinely well". The review enumerates the precise remaining
spec shortfalls (5 bugfixes / 5 improvements / 3 changes). Refactor is **saturated** (105/110/114/117
= 4 of last 15) and was avoided; the scan turned the three highest-impact, well-scoped PO bugfixes/
improvements into tasks. **PO Bugfix #5 (corrupted spec line 1, `MAKE GLB REPÅLCAE PLACEHOLDER DOG`)
is NOT a task** — it requires editing `.docs/specs.md`, which is read-only for the build loop; only
the PO/father pass can fix it. Created **118/119/120**:
- **118 (HIGH, BUGFIX — core-loop signal correctness)** — **suppress the apex tell while
  disengaged.** Today `viewModel.tellStrength`/`peakProximity` ignore `disengaged` (`viewModel.ts:42-52`),
  so the gold "mark now" ring (and the on-dog apex) fire while the dog has walked off and the only
  valid action is call-back — two opposite meanings on one cue (PO Bugfix #4). One clamp in
  `toViewModel`, pure TDD. **Do first** (lowest risk, fully test-covered).
- **119 (HIGH, BUGFIX — visual/loading, D1/D14)** — **never flash the primitive placeholder dog.**
  `scene.ts` shows the capsule/sphere/cylinder dog for ~0.3–1 s before the GLB swaps in; the spec
  forbids the blob *even as a placeholder* (PO Bugfix #1). Pure `proceduralDogVisible(...)` helper
  (TDD) + hold-hidden-then-fade glue; **blocking real-screenshot Visual Review** (+300 ms no blob,
  +1000 ms real Labrador, failure path still shows procedural).
- **120 (HIGH, FEATURE — dog state-legibility, D6/D11)** — **distinct lie-down clip for the
  down-family tricks.** Sitt/Ligg/Legg deg all render the same upright sit on the imported dog
  because clip selection is trick-blind (`dogAnimationMap.ts` maps `offering`→Sitting for every
  trick); the `trickId` reaches the scene but isn't threaded to `resolveStateClip` (PO Improvement #1).
  Make imported clip selection trick-aware (prefer Lie/Lying for ligg/legg-deg/sov), pure-logic TDD +
  **blocking Visual Review**.

Remaining PO items for later scans (still spec-grounded, deliberately not picked this round to keep
the trio scoped): Bugfix #2 (stylized hand+treat asset — heavier/asset-leaning), Bugfix #3
(disengaged dog clipped at right edge), and the Improvements/Changes (kennel-upgrade descriptions,
adopt price+art, select-shell coin/level readout, brighten select scene, restyle mute toggle,
distractor-vs-disengaged distinction, recenter idle dog). **Still owner/legal/asset-gated (NOT
eligible):** the **Maren marker voice recording** (§4) and the **licensed-Labrador default-ON public
ship path** (§3i/§3j packaging).

Recommended order: **118 → 120 → 119** (logic-only first, then the two Visual-Review-gated tasks).

---

**Prior focus**: Iteration 24 (2026-06-21) found the backlog drained (112/113/114 all DONE) →
ran `scan-project`. Two analysis subagents (spec-vs-impl gap + code-quality) confirmed the **v1
core loop is intact (PASS, no P0)** and nearly everything in the spec is Implemented. The only
genuine **non-gated** v1 gaps left are narrow; the scan deliberately picked a **domain-balanced**
trio that avoids the three saturated buckets (render-visual 102/103/107/111/112=5; tuning-refactor
105/110/114=3; pure-test 101/104/113=3) and lands in **cold** domains (audio, economy-surfacing,
core-logic). Created **115/116/117**:
- **115 (MED-HIGH, FEATURE — economy/UI surfacing)** — **idle "welcome back" income on return.**
  `idleIncome` is granted invisibly at load (`main.ts:150-156`); the spec's "gentle reason to come
  back" payoff never reaches the screen. Pure `shouldShowIdleWelcome({earnedCoins, economyRevealed})`
  (TDD) gates a select-screen toast behind the economy-reveal stage. Fully screenshot-verifiable —
  **do first** (lowest risk).
- **116 (MED-HIGH, FEATURE — audio, cold since 094)** — **marker-voice clip pipeline.** Every mark
  is synth-only; the `registerClip`/`shouldUseClip`/`playBuffer` plumbing (074) is **never fed**.
  Build the owner-unblocked half: a rejection-safe `loadClip` (fetch+decodeAudioData), a pure
  phrase-keyed `voiceCue(result, phraseId?)` (TDD), wiring, + a license-clean placeholder so the
  path is proven. The **real Maren recording stays the standing owner/likeness gate (§4)** — named,
  not claimed delivered.
- **117 (MED, REFACTOR — core-logic/correctness)** — extract the **tap engagement/call-back
  decision** out of the untested `onBraTapCommit` IIFE into pure `isCallBackTap` + `tapEngagement`
  in `gameHelpers.ts` (TDD). Locks down the loop's two most edit-fragile ordering rules (call-back
  *before* classification; reward-latency *only* on PERFECT/OK+attempt) with direct unit coverage.
  Behavior-preserving; guarded by `e2e/full-loop.mjs`. **Do last** (touches the delicate tap path).

**Still owner/legal/asset-gated (NOT eligible tasks):** the **licensed-Labrador default-ON ship
path** (080 engineering-done; packaging gate §3i/§3j) and the **Maren marker voice recording** (§4 —
likeness/recording asset; task 116 builds the pipeline *around* it).

Recommended order: **115 → 116 → 117** (ascending risk).

---

**Prior focus**: Iteration 23 (2026-06-21) found the backlog drained (109/110/111 all DONE) →
ran `scan-project` → **shipped all 3 tasks + closed on-hold 098**. A spec-vs-impl gap subagent
confirmed the v1 core loop is intact and most of the spec is implemented; remaining buildable
gaps are narrow (mature project, 108 done). Two true gates stay owner/asset-bound and are **not**
eligible tasks: the **licensed-Labrador default-ON ship path** (080 engineering-done; packaging
gate §3i/§3j) and the **Maren marker voice** (§4 — a likeness/recording asset that can't be
produced autonomously; flagged as the standing escalation item).
- **112 (DONE — FEATURE)** — the intermediate **disengage beats (itch/flop/bark) now read on the
  dog**, not only the HUD pill. `DogVisual`+`beat` routing (pure, TDD, 10 tests; beats replace
  idle-lulls only, never mask `offering`), procedural poses (`dogPose.ts`) + a graded cool tint
  ramp (`scene.ts`) landing on the walk-off blue, imported-rig clip map (itch→Scratching/
  flop→Lie/bark→Bark). **This was on-hold 098's last slice → 098 is now CLOSED** (every part
  shipped procedurally; nothing was ever truly 079-gated). Real-screenshot **Visual Review = PASS**
  (`scripts/shoot-beats.mjs`; reduced-motion safe, D13). tech-decisions §"Intermediate disengage
  beats on the dog".
- **113 (DONE — TEST)** — resume round-trip integration guard: a 42% partial learned-bar now
  proven to survive the real `buildGameSave → serialize → deserialize → restoreLearnedBar` chain
  (+ fresh→0 and dog/trick-mismatch→0). 4 tests; existing code round-trips correctly (guard
  passed first run — no bug surfaced). `gameHelpers.test.ts` 46 → 50.
- **114 (DONE — REFACTOR)** — finished 110's tuning centralisation: `RESULT_FLASH_MS` moved
  hud.ts → `tuning.ts`; src/ui+src/render audited, judgement-call locals (render decay windows,
  CSS-paired timeouts, load timeout, texture size) documented kept-local. No behavior change.

Gate after iteration 23: typecheck 0 · **833 tests** · build no-warn · e2e (smoke + full-loop)
PASS. Backlog + in-progress empty; on-hold holds only the historical **077** research task.

---

**Prior focus**: Iteration 22 (2026-06-21) cleared the two lower-risk items the iteration-21
scan queued, leaving the flagship visual task for a focused pass (the iteration-17 pattern):
- **110 (DONE — REFACTOR)** — finished the §8/105 tuning centralisation. The playtest-relevant
  stragglers now live in `src/core/tuning.ts`: `NORMAL_DELTAS` (mark.ts), the engagement
  reward-latency feed + `MARK_ENGAGEMENT_DELTA` (engagement.ts), `CALL_BACK_ENGAGEMENT`
  (disengage.ts), `CONFUSE_WINDOW_MULT`/`CONFUSE_DISTRACTOR_MULT` (difficulty.ts), and
  `BASE_SCHEDULER_TIMING` (gameHelpers.ts). Each domain module imports from `tuning.ts`, thinly
  re-exporting any widely-imported name so **every test passed unchanged** (pure, behavior-
  preserving). `tuning.ts` still imports nothing from `src/core/*` (its few `Record`/`as const`
  tables write key types inline). tech-decisions §8 extended.
- **111 (DONE — QUALITY)** — hardened `importedDogMesh.ts` before the eventual flag-flip. Fixed a
  real **per-frame head-bone Y drift** (`+=` → bind-relative assign via new pure, TDD'd
  `headBoneY(bindY, lift)`; 3 tests), collapsed the dead-branch `setEmissiveMat` to one line, and
  removed the unused Phase-2 `_originalDiffuse`/`_originalEmissive` captures (+ orphaned
  `getDiffuse`). Visual Review waived per the task's own rationale (flag OFF; no-accumulation is a
  pure-math property fully covered by the helper test; no visual output changed). tech-decisions §3j.
- **109 (HIGH, QUEUED — flagship visual)** — contextual onboarding coach for the **distractor
  reveal** (specs §Onboarding staged reveal). The highest-value uncoached moment: at
  `masteredCount === 1` the dog starts offering wrong behaviors and a brand-new player gets no
  explanation of why a tap was punished. Extends task 108's proven pattern (pure gate +
  dismissible `#hud-coach` pill + reduced-motion/aria). **Left in backlog deliberately**: it has a
  *blocking* real-screenshot Visual Review and deserves a focused, screenshot-heavy iteration
  rather than being rushed at the tail of a multi-task pass (cf. iteration 17 queuing 080).

Gate after iteration 22: typecheck 0 · **808 tests** (805 → 808) · build no-warn · e2e
(smoke + full-loop) PASS. Backlog holds **109 only**; in-progress empty.

---

**Prior focus**: Iteration 20 (2026-06-21) **shipped 107 (Disengagement walk-off + call-back)** —
the flagship, and the **biggest remaining v1 gameplay gap**. Completes the 098 remainder
**procedurally on the shipping dog** (no licensed clips — the old "079-gated" deferral was
over-broad). New pure `src/core/disengage.ts` (TDD, 7 tests: `isDisengaged`/`canScoreMark`/
`callBackEngagement`→0.5=`itch`, above walk-off AND bark so it can't oscillate). At empty meter
the dog enters a distinct `disengaged` state — **back-turned** (`bodyYaw=−π/2`: rump to camera,
since the ArcRotateCamera at `alpha=−π/2` makes a 180° yaw show only the same flank), **seated**,
**cool-blue** (distinct from distractor grey), sat **off to the frame edge** (narrow footprint
once it faces into the screen → no clipping). A BRA tap now **calls the dog back** (restores
engagement, breaks combo, never scores) — branched before mark classification in `main.ts`. Faint
blue `#hud-callback-hint` pill while disengaged; first-run coach suppressed so prompts never
contradict. Reduced-motion-safe (static pose/tint/position read; D13). Real-browser Visual Review:
round 1 (independent) = FAIL (read as idle recolored) → fixed → round 2 (fresh independent) =
PASS-WITH-NITS (only nit: uniform-crouch "sit" — primitive dog has no per-leg control; non-blocking).
Decision in tech-decisions §"On-dog walk-off + call-back" (engagement section flipped PARTIAL →
COMPLETE). **specs.md untouched.** Backlog + in-progress now empty.

*Iteration 19 (2026-06-21)* shipped 106 (in-round Pause/Resume): pure `src/core/pauseClock.ts`
(TDD, 8 tests) models round time as wall clock minus paused spans; pausing freezes the dog + apex
tell and ignores taps, resume continues with no skip-ahead. 44px ⏸ button + dimmed "Paused"
overlay (reduced-motion-safe), auto-pause on background. Decision in tech-decisions §"In-Round
Pause Clock".

*Iteration 18 (2026-06-21)* closed the flagship **080** (imported Labrador: camera-facing + 113
embedded skeletal clips; verified against the real gate) then ran `scan-project`, shipping the
low-risk **108** (first-run coach) and queueing the two HIGH flagships **106 + 107**.
- **106 (DONE — 2026-06-21)** — in-round **Pause/Resume** (specs §Round States: "Pause/resume
  supported"). Pure `pauseClock` effective-time offset (TDD) freezes the round clock + a paused
  overlay (Visual Review). Touched the delicate `main.ts` round clock — handled in its own pass.
- **107 (HIGH, QUEUED — flagship)** — **Disengagement walk-off + call-back** on the *shipping
  procedural dog* (specs §Wrong-behavior beats). Completes the 098 remainder: the engagement
  meter currently only tints the HUD; this makes the dog trot off / sit back-turned at empty
  meter and adds the **tap-to-call-back** interaction. **No longer 079-gated** (procedural).
  Render+gameplay → dedicated screenshot-heavy pass.
- **108 (DONE)** — first-run **coach hint** teaching the core verb in-context (specs §Onboarding).
  Pure `shouldCoachCoreVerb` (TDD, 3 cycles); gold `#hud-coach` pill via `setCoachVisible`,
  reduced-motion-safe; runtime `hasMarkedSuccessfully` in `main.ts` shows it on the first round
  and auto-dismisses it on the first scoring mark, never for returning players. Real-screenshot
  Visual Review by an independent agent = **PASS**. Decision in tech-decisions §3k.

Gate after iteration 19: typecheck 0 · **781 tests** (767 → 781) · build no-warn · e2e
(smoke + full-loop) PASS. Backlog holds **107 only**; in-progress empty.

**Next iteration**: take **107** (the disengagement flagship — biggest remaining v1 *gameplay*
gap, gives the engagement meter real teeth; render+gameplay → dedicated screenshot-heavy pass).
Still owner/legal-gated: the **licensed-Labrador default-ON ship path** (080 is engineering-done;
the gap is packaging — §3i/§3j) and the **Maren marker voice** (§4).

---

**Prior focus**: Iteration 17 (2026-06-20) found the backlog drained → ran
`scan-project`. The PO/father review (specs.md line 1: "MAKE GLB REPLACE PLACEHOLDER DOG")
plus a fresh spec-vs-impl gap subagent confirm the **dominant remaining v1 gap is the
look** — the procedural primitive dog is still live; the real licensed Labrador is built,
textured, AES-GCM-packed and load-proven (task 103) but `renderConfig.importedDog` is OFF
for two **pure-engineering** reasons (rig faces away from camera; 113 embedded skeletal
clips unplayed). No owner/legal/asset gate remains for it. The scan created **3 tasks** —
exactly the board's own named carry-forward candidates, re-validated by gap + code-quality
subagents — and **shipped the two low-risk ones**, queueing the flagship visual task:
- **080 (HIGH, QUEUED top priority)** — epic phase 2 promoted from outline + task-103's
  recommended follow-up: face the imported Labrador to camera (base yaw on the framing
  pivot, since `applyPose` owns `root.rotation.y`) + drive idle/offering/markable-apex/
  happy/confused via the embedded `AnimationGroup`s (pure `resolveStateClip` resolver is
  TDD; playback is Visual Review), then **flip the flag iff it reads ≥ procedural** (079
  rule). Left in backlog: it's a Visual-Review-gated flagship deserving its own focused
  iteration (079 was a whole iteration), not a rushed corner of a 3-task sprint.
- **105 (DONE)** — centralize scattered tunables into `src/core/tuning.ts` (tech-decisions
  §8's standing "Future" TODO). Behavior-preserving move: `difficulty.ts` mode literals +
  `main.ts` `PANT_INTERVAL_MS`/`TIMELINE_EVENTS` now import 20 named consts from `tuning.ts`
  (imports nothing from `src/core/*` → no cycle); §8 note flipped to DONE. Zero value
  changed (each diffed against §8); all tests pass unchanged.
- **104 (DONE)** — first direct coverage of the 752-line `createHud`: 15 jsdom
  characterization tests for `renderTraining` (phrase-cooldown `--cooldown-pct` sweep,
  combo visibility/multiplier, engagement %/beat, level-gate vs coin-gate affordance +
  boundaries). Through the public handle, asserting observable DOM — no seam needed in
  `hud.ts`. Answers the standing "unit tests for hud.ts orchestration" carry-forward.

Gate after iteration 17: typecheck 0 · **744 tests** (729 → 744) · build clean · e2e
(smoke + full-loop) PASS. Backlog now holds **080 only**; in-progress empty.

**Prior focus**: Iteration 16 (2026-06-20) worked the single backlog task **102
(one-line licensed-Labrador swap seam)** and shipped it. New `src/render/dogModelSource.ts`
is the **single source of truth** for the model path: `DOG_MODEL_URL` (CC0 `/models/dog.glb`,
web default) + a pure, TDD-covered `resolveDogModelSource({allowLicensed, licensedAssetPresent})`
(4 tests; CC0 fallback never yields an empty path). `scene.ts` now calls the selector instead
of a hard-coded string (`grep`-clean — no stray model path in `src/`). The CC0 → licensed swap
is now genuinely **one line** (flip the selector inputs once the licensed glb is staged into a
license-cleared build path). Documented in **tech-decisions §3h** (swap recipe + named gate) and
cross-linked from `public/models/CREDITS.md`. `dist/models/` ships **only** `dog.glb` — no
licensed file leaks into the web bundle. **No visual change** (CC0 stays live). Full gate green:
typecheck · **715 tests** · build · e2e (smoke + full-loop). Backlog + in-progress now empty.
**Notable concurrent development:** the owner supplied `Labrador_Textures.rar` mid-iteration, so
the **texture gate is now resolved** (maps embedded in gitignored `models-build/out_anim.glb` via
`scripts/skin-dog-model.mjs`); reconciled §3h/CREDITS accordingly. The **one operative remaining
gate** for the real Labrador is now just the **web-PWA license decision** (§3b/§3d) — next scan
should treat that, plus staging the textured glb behind `allowLicensed`, as the live frontier.

**Prior focus**: Iteration 15 (2026-06-20) finished the in-progress dog-model slice:
**078 + 079 are DONE** and the imported-dog pipeline is **proven end-to-end behind the
default-off flag**. `createImportedDogMesh` renders the loaded glb through the `DogMesh`
contract; the lazy `babylon-loaders` chunk keeps the glTF loader + PBR off flag-off users
(tech-decisions §3f). Visual Review (real screenshots, `?importedDog=1`): the first pass
rendered a **sliver** — root-caused to the CC0 model being a skinned rig (`AnimalArmature
×100`) whose hierarchy/skeleton-bounds the framing stripped; **fixed** (re-parent topmost
ancestor + `refreshBoundingInfo({applySkeleton:true})`). After the fix it's a recognizable
dog but **oversized/generic → reads worse than the tuned procedural dog**, so the flag
**stays OFF** per the task's conditional (the win is the proven pipeline; real swap = 102).
Also fixed two gate breakages the snapshot left: the **build** (workbox 2 MiB precache +
chunk-size — split + raised limits) and the **e2e full-loop** (headless rAF throttles to
~3 fps so apex-by-`data-tell` always MISSed → now taps via a `nextPeak()` DEV hook + an
in-browser busy-wait; tech-decisions §3g). Full gate green: typecheck · 711 tests · build ·
e2e. **102 remains in backlog** (ready) for the next iteration.

**Iteration 14 (2026-06-20)** found the backlog drained and ran
`scan-project`. The big change since iteration 13: **the FBX→glb conversion that gated
the visuals epic is DONE** (tech-decisions §3e) and a **CC0 placeholder glb is staged at
`public/models/dog.glb`** — so the epic's phase-1 tasks are **no longer blocked**. The PO
shout on **specs.md line 1** ("MAKE GLB REPLACE PLACEHOLDER DOG") makes the imported-dog
path the unambiguous top priority. Rather than duplicate the already-detailed phase-1
tasks, the scan **reactivated 078 + 079 from on-hold → backlog** (un-parking unblocked
work — the project's #1 lesson) and added **one new task 102**:
- **078** (HIGH) — loader glue: add `@babylonjs/loaders`, lazy `loadDogModel()`, scene
  async wiring (spinner → `selectDogRenderMode` → fall back to procedural). Flag stays off.
- **079** (HIGH) — `createImportedDogMesh` behind the `DogMesh` contract + scene render-mode
  wiring + Visual Review. Flip `renderConfig.importedDog` **on only if** the imported dog
  Visual-Reviews ≥ the procedural baseline (the staged model is a generic CC0 dog, not yet
  the Labrador). Either way the pipeline is proven.
- **102** (MED) — one-line licensed-Labrador swap seam (`DOG_MODEL_URL` +
  TDD `resolveDogModelSource`) + a precisely-named owner/legal gate (missing albedo texture
  + web-PWA license). Keeps the real-asset work moving around the genuine blocker.

The only remaining gates are **owner/legal** and apply solely to the *licensed* Labrador
(texture folder + PWA-license decision) — they do **not** block 078/079/102, which build
against the safe CC0 placeholder. Then worked the backlog (see below).

---

**Prior focus**: Iteration 12 (2026-06-19) worked the single backlog task **098
(engagement meter + disengagement)**, which **depends on 079** (real Labrador clips).
Shipped the **unblocked slice**: the pure model (`src/core/engagement.ts` —
`engagement(prev,event)` reducer + `disengageBeat(level)`, 13 TDD tests) and a visible
**HUD mood meter** stacked under coins/level, colour-escalating green→red with the beat
(reduced-motion + aria, **Visual Review PASS** after two review rounds). The on-dog
beats + walk-away/call-back remain **079-gated**, so 098 moved to `on-hold` with the
remainder documented. Repaired a **pre-existing gate-blocker** en route: untracked
`dogModelLoader.test.ts` (on-hold 078 work) imported a never-implemented
`importedPoseTransforms`, breaking `tsc`; removed the dead import + orphaned fixture.
Also aligned the stats pill to the HUD's floating-inset chrome pattern (was the lone
edge-docked element — tech-decisions). Suite **646 → 662 tests**; typecheck 0 · build
clean · e2e PASS. Prior: iteration 11 shipped 095–097; iteration 10 shipped 093/094.
The **Pokémon-GO Visuals epic** remains gated on the **FBX → `.glb` conversion**
(`Labrador_FBX.rar`, tech-decisions §3c); once `public/models/dog.glb` is the real
Labrador, 078/079 (+098's remainder) + phases 080–085 are the next major block.

## Pokémon-GO Visuals epic (077–085) — FBX→glb conversion DONE; integration is next

**UNBLOCKED 2026-06-20.** The FBX → glb conversion that gated this epic is solved with a
headless, no-sudo toolchain (`node-unrar-js` to extract the RAR-7 archive that system `7z`
couldn't, then the `fbx2gltf` npm binary). The converted animated glb has the rigged mesh
(8 682 verts, 60-node skeleton) + **113 clips** — every clip 079/098 needed (Sitting/Lie/
Bark/Scratching/Digging/Trot/Turn/Idle…). Recipe + inventory in **tech-decisions §3e**;
artifacts in gitignored `models-build/`. The old "archive corrupted / no tooling" blockers
were both **false** — see the orchestration note at the bottom of this file.

**Remaining gaps are narrower and do NOT block integration:**
- *Missing texture (owner):* the FBX points at an external `Labrador_Albedo1.png` not in the
  drop → model is untextured (white). 078/079 can still wire it now with a fawn fallback
  colour and Visual-Review the silhouette/animation; photoreal skin drops in when the owner
  supplies the texture folder.
- *Web-PWA license (owner/legal, ship-time only):* pack/encrypt or native-gate the licensed
  glb before it ships on web (§3b/§3d). Does not gate local flag-off integration.

Roadmap in [`EPIC-pokemon-go-visuals.md`](EPIC-pokemon-go-visuals.md).

- **`077-RESEARCH-dog-model-sourcing`** — DONE: research, shortlist, purchase, and
  file-drop all complete (tech-decisions §3a–§3c). Remaining handoff: convert FBX → glb.
- **`078-FEATURE-gltf-load-path-and-fallback`** — pure decision core landed (TDD, 9
  tests, flag default off → app unchanged). Loader glue + scene wiring + Visual Review
  still to build (needs the converted `.glb`).
- **`079-FEATURE-imported-dogmesh-labrador`** — depends on 078. The `DogMesh` contract
  is already a clean exported seam, so it's a drop-in once the loader + glb exist.
- **`098-FEATURE-engagement-disengagement`** (on-hold) — pure model + HUD meter DELIVERED
  (iteration 12); the on-dog disengage beats + walk-away/call-back are **079-gated** (need
  the real `scratch ear`/`dig`/`bark`/`lie`/`trot`+`turn` clips). Drop-in once 079 lands.

Phases 2–6 (`080`–`085`) stay outlined in the epic; **numbers 080–085 are reserved
for those visual phases**, so new non-epic tasks start at **099**.

## Top Priorities — backlog holds **080** (queued) after iteration 17

**Next iteration: take 080** — the imported-Labrador render-readiness slice (face camera +
play the 113 embedded skeletal clips for the core states → Visual Review → flip
`renderConfig.importedDog` iff ≥ procedural). It is the PO's #1 ask and the last
pure-engineering step between the placeholder dog and the real licensed Labrador on web
(texture supplied + license decided + packed-load proven, task 103). Give it a dedicated,
screenshot-heavy pass; never fabricate a Visual Review (Subagent note below). After 080,
the next scan should re-balance the domain mix (rendering + logic are the warm buckets) and
weigh epic phases 081 (PBR look) / 082 (breed retarget). Still owner/legal-gated: the
**Maren marker voice** (§4).

## Recently Completed (iteration 17 — 2026-06-20)

- `105-REFACTOR-centralize-tunables-tuning-module` (MED) — new `src/core/tuning.ts` hosts 20
  named primitive tuning constants (NORMAL/HARD/EXPERT window/peak/distractor, FALSE_MARK
  overrides, reward mults, tell intensities) + the two app-level stragglers
  `PANT_INTERVAL_MS` / `TIMELINE_EVENTS`. `src/core/difficulty.ts` and `src/main.ts` consume
  them; the bare inline literals are gone (grep-clean). `tuning.ts` imports nothing from
  `src/core/*` (no cycle). **Behavior-preserving** — every value diffed against tech-decisions
  §8, all suites pass unchanged. §8's "Future: centralize into src/core/tuning.ts" note
  flipped to DONE. Implements the long-standing §8 refactor TODO.
- `104-TEST-hud-rendertraining-jsdom-coverage` (MED) — `src/ui/hud.test.ts`: **15 jsdom
  characterization tests** for `createHud`/`renderTraining`, the previously-untested 752-line
  HUD orchestration. Covers the phrase-cooldown `--cooldown-pct` sweep + ready/`on-cooldown`
  class, combo visibility threshold + `xN` multiplier, engagement `Math.round(*100)` fill +
  `aria-valuenow` + `data-beat`, and level-gate (`Lvl N`) vs coin-gate (`🪙N`) affordance —
  each with boundary cases. Asserts observable DOM through the public handle (refactor-proof,
  mirrors the panel tests); **no seam needed in `hud.ts`**. Characterization caught that
  `renderTraining` reads cooldown/unlock state from `callbacks.getLoadoutState()` and that
  `--cooldown-pct` is a one-decimal percent string (e.g. `"50.0%"`), not a 0–1 fraction.
  Suite 729 → **744**.

**Backlog + in-progress are now empty** (`.gitkeep` only); **078 + 079 + 102 are DONE**. The
swap seam (102) is in place, so the next iteration that finds the board drained should run
`scan-project` to replenish. The flag architecture (`renderConfig.importedDog` default off +
mandatory procedural fallback) keeps the gate green; the procedural dog always renders.

**Live frontier for the licensed Labrador (iteration 16 update):** the texture gate is now
**resolved** (owner supplied `Labrador_Textures.rar`; maps baked into gitignored
`models-build/out_anim.glb` via `scripts/skin-dog-model.mjs`). The **one operative remaining
gate** is the **web-PWA license decision** (§3b/§3d). Once that's decided, staging the textured
`labrador.glb` into a license-cleared build path + flipping the `resolveDogModelSource` inputs is
the whole swap (task 102 built the seam). A scan should weigh: **decide/stage the licensed-model
ship path** (the now-unblocked frontier), **epic phase 2 — play the glb's embedded skeletal
clips** (113 clips; reserved id **080**), **unit tests for `hud.ts` orchestration** (686-line
`createHud`, no coverage), **centralize tunables into `src/core/tuning.ts`** (§8). Still
owner/legal-gated: the **PWA license** above, the **Maren voice**.

After this epic phase-1 block lands, the **next scan** should re-balance the domain mix.
Carry-forward candidates (re-rank against fresh findings): **epic phase 2 — play the glb's
embedded skeletal clips** on the imported dog (113 clips available; reserved id **080**);
**unit tests for `hud.ts` orchestration** (panel factories got jsdom coverage in 101, but
the 686-line `createHud` orchestration has none); **centralize tunables into
`src/core/tuning.ts`** (tech-decisions §8; refactor domain is warm). Still owner/legal-gated:
the **licensed Labrador** (texture + PWA license — task 102 names it), the **Maren voice**,
and **on-dog engagement beats** (those need the *licensed* Labrador's clips; 098 remainder).

**Saturation note (iteration 13):** last-15-done now skews **feature/UI** (099 UI-interaction,
096 UI) and **test** (088, 101); quality/refactor (076/089/092/093) and logic (075/087/091/097)
remain the heaviest historical buckets. Audio (074/094) and persistence (086/090) sit at 2.
Next scan should avoid stacking more UI-interaction; a correctness/perf or content gap would
balance the mix.

## Recently Completed (iteration 16 — 2026-06-20)

- `102-FEATURE-licensed-labrador-swap-gate` (MED) — the one-line CC0 → licensed-Labrador
  swap seam. New pure `src/render/dogModelSource.ts`: `DOG_MODEL_URL` (CC0 `/models/dog.glb`,
  single source of truth) + TDD-covered `resolveDogModelSource({allowLicensed, licensedAssetPresent})`
  (4 tests; CC0 fallback never empty). `scene.ts` calls the selector — no hard-coded model path
  in `src/` (`grep`-clean). Swap recipe + named owner/legal gate in **tech-decisions §3h**,
  cross-linked from `CREDITS.md`. `dist/models/` ships only `dog.glb` (no licensed leak). No
  visual change (CC0 stays live). Reconciled §3h/CREDITS after the owner supplied
  `Labrador_Textures.rar` mid-iteration (texture gate now resolved; PWA-license is the lone
  remaining gate). Gate: typecheck 0 · **715 tests** · build clean · e2e (smoke + full-loop) PASS.

## Recently Completed (iteration 13 — 2026-06-19)

Scanned the drained backlog → replenished + shipped **099–101**. Gate after all three:
typecheck 0 · **700 tests** (662 → 700) · build clean · e2e (smoke + full-loop) PASS.

- `099-FEATURE-phrase-swipe-to-swap-bra-marker` (HIGH) — the spec's second named
  phrase-selection gesture: **swipe the BRA marker** to swap the loaded phrase
  (specs §Marker Phrases), closing tech-decisions §7's open "loadout/selection UI" item
  (now §7q). Pure `src/core/swipeGesture.ts` — `classifySwipe(dx,dy,thr=40)` (horizontal-
  dominant past-threshold = swipe; else tap) + `cycleIndex` (TDD, 10 tests). The marker is
  now **press-then-release**: `pointerdown` records the instant, the mark **commits on
  `pointerup`** only if it wasn't a swipe (a swipe calls `onSwapPhrase` and suppresses the
  mark, so swiping never fires a stray FALSE_MARK). Scoring still uses the **pointerdown**
  instant → **zero added tap latency**; e2e BRA taps now dispatch down+up and full-loop
  still masters (the precision regression guard). Faint "‹ swipe ›" hint when >1 phrase
  available + a gold swap-word flash above the marker; reduced-motion cross-fades.
  **Visual Review was genuinely blocking** — round 1 (independent agent) flagged the hint
  cramped against the bottom gesture zone + the swap word too tight/low-contrast; fixed by
  lifting `#hud-bottom` (40px + safe-area, loadout-chip calc kept in sync) and raising the
  swap word with a dark halo + richer gold; round-2 verifier = PASS. New `__forcePhrases()`
  dev hook + a `--eval` flag on `scripts/shoot.mjs`.
- `100-FEATURE-engagement-reward-latency-live-wiring` (MED) — wired the already-built
  `{kind:'reward', latencyMs}` engagement event into the live loop, completing 098's
  "slow rewards drain it" half. New pure `rewardLatencyMs(tap, apex)` (clamped ≥0, TDD);
  fired on PERFECT/OK marks only (MISS/FALSE_MARK don't double-count). **Corrects 098's
  over-broad 079 deferral** — needs only tap-vs-apex timing, no Labrador clips
  (tech-decisions §"Engagement … Reward-latency feed wired live").
- `101-TEST-ui-panel-jsdom-coverage` (MED) — added `jsdom` (dev dep) via
  `environmentMatchGlobs: [["src/ui/**","jsdom"]]` so the DOM-bearing UI layer tests under
  jsdom while the core suite stays on fast node. **24 behavior tests** through the public
  `PanelHandle` for `adoptPanel`/`kennelPanel`/`settingsPanel`/`helpPanel`/`achievementsPanel`
  (gate-legibility classes, buy/adopt/two-tap-reset flows, open/close, list re-render) —
  characterization of current behavior, asserting observable DOM not internals
  (tech-decisions §3e).

## Recently Completed (iteration 12 — 2026-06-19)

- `098-FEATURE-engagement-disengagement` (PARTIAL → on-hold) — shipped the unblocked
  "Pure first" slice + a visible HUD reflection; the on-dog beats + walk-away are
  079-gated. Pure `src/core/engagement.ts`: `engagement(prev,event)` clamped 0..1
  reducer (mark-quality + reward-latency events) and `disengageBeat(level)` →
  `engaged→itch→flop→bark→walk-off` (13 TDD tests). Live wiring in `main.ts`
  (runtime meter, not persisted — transient like `combo`; `__setEngagement` dev hook).
  New **HUD mood meter** under coins/level in a shared `#hud-stats-cluster`: fill =
  meter, colour escalates green→red with the beat, red-tinted empty track + pulse at
  walk-off, revealed at the economy stage, `role="meter"` + aria, reduced-motion handled.
  `viewModel.ts` gains `engagement`/`engagementBeat` (3 tests). **Visual Review was
  genuinely blocking** — round 1 caught a mid-screen float (→ cluster wrapper), an
  invisible track (→ lightened groove) and a colourless empty walk-off (→ red track
  tint); round 2 caught the stats pill being the lone edge-docked HUD element (→ floated
  it inset + rounded to match diff-selector/kennel/loadout/combo; tech-decisions).
  Also repaired a pre-existing gate-blocker: untracked `dogModelLoader.test.ts`
  (on-hold 078) imported a never-implemented `importedPoseTransforms` (TS2305) — removed
  the dead import + orphaned fixture. Suite **646 → 662**; typecheck 0 · build clean ·
  e2e (smoke + full-loop) PASS.

## Recently Completed (iteration 11 — 2026-06-18)

- `095-FEATURE-kennel-tier-backdrop-upgrades` — kennel level now visibly upgrades
  the training-ground backdrop in 4 tiers (specs §Kennel). Pure `backdropTier.ts`
  (`kennelTier(ids)→0-3`, `backdropTierConfig`, 19 TDD tests); `backdrop.ts` pre-
  builds bushes / agility cones / a cream jump set / a fence line once and
  `applyBackdropTier` shows/hides + green-tints the ground per tier; `scene.ts`
  exposes `setKennelUpgrades(ids)`, called by `main.ts` on bootstrap + every
  purchase (live, no rebuild). New `__setKennelUpgrades` dev/screenshot hook.
  **Visual Review was genuinely blocking** — first pass FAILED (props at negative-z
  = behind the camera; rendered black under `disableLighting`); fixed to positive-z
  lit/matte props, then an independent reviewer caught a tier-2 regression + cone
  over-dominance, fixed by keeping front bushes ahead of the deeper cones and
  shrinking/softening/cream-warming the props. Monotonic, dog framing intact.
- `096-FEATURE-stage-economy-reveal-in-hud` — onboarding fix: `applyRevealed()` now
  toggles `statsEl` on `revealed.economy`, so coins/level hide on a fresh session
  and reveal at the first payout (reveal call already re-fires post-mastery,
  `main.ts:595`). The staging contract was already tested in `onboarding.test.ts`;
  the bug was pure UI glue. Verified by screenshot + computed-style probe.
- `097-BALANCE-trick-reward-uplift-no-dominated-combos` — `trickRewardMultiplier`
  (`min(2.2, 1 + (1-learnMult) + (1-windowMult)×0.5)`; sitt 1.0× → legg-deg 1.7×)
  folded into `completeMastery`/`completePractice` via an optional `trick` param
  (omitted = 1×, backward-compat). Harder tricks now pay proportionally more, so
  none is strictly dominated (§Difficulty Modes intent; resolves the deferred
  legg-deg×EXPERT item, tech-decisions §7n). Re-practice still 0 XP (task 070).
  TDD red→green (12 tests). Suite 613 → **646**; verify + e2e green.

## Recently Completed (readability refactor, iteration 10 — 2026-06-17)

- `094-FEATURE-dog-foley-audio` — synthesised dog foley + a richer ambient bed,
  TDD-first (13 new tests; suite 613 green). Pure `foleyLayers(event)` maps
  `idle-pant | mastery-bark | false-huff` to bounded `SoundSpec[]` (gains well
  under the 0.9 praise tone); `ambientLayers()` returns three detuned low
  partials (160/163/240 Hz, ~3 Hz beat shimmer + soft fifth) and `ambientSpec()`
  now delegates to `ambientLayers()[0]`. New `MarkAudio.playFoley` (mute-aware +
  lazy) and a multi-oscillator `startAmbient`/`stopAmbient`. Triggers wired in
  `main.ts`: bark on mastery, huff on FALSE_MARK, throttled idle pant
  (`PANT_INTERVAL_MS = 7000`, gated to `dogVisualState === 'idle'`). Decision in
  tech-decisions. **Not headless-verifiable — a human on-device listen is the
  one remaining step (precedent 074).**
- `093-REFACTOR-hud-panel-split` — the 1148-line `createHud()` god-closure is
  decomposed: the five overlay panels (adopt / kennel / settings / help /
  achievements) are now self-contained `src/ui/panels/*` factories returning a
  `PanelHandle` (`{ el, open, close, update? }`). A new `createPanelManager`
  (TDD, 4 tests, DOM-agnostic) enforces one-open-at-a-time exclusivity (task 071);
  `createHud` is pure orchestration. Public return shape + `main.ts` untouched;
  panels created in the original body-append order so `hud.css`/stacking is
  unchanged. **`hud.ts` 1148 → 640 LOC.** Pixel-identity proven three ways:
  byte-level `document.body` DOM diff (all panels identical; training differs only
  in the live `data-tell` animation), MD5-identical phone-portrait screenshots
  (6/7; training = animation frame), and a Visual Review agent (PASS, no
  regression). Gate: typecheck 0 · 600 tests · build clean · e2e smoke + full-loop PASS.

## Recently Completed (non-gated correctness + quality, iteration 9 — 2026-06-17)

- `092-QUALITY-main-bootstrap-persist-helper` — the two pre-`persist()` bootstrap
  saves (idle-income grant, streak update) are unified behind a `persistBootstrap()`
  helper (uses `savedMuted` instead of `markAudio.isMuted()`), clearing the residual
  `buildGameSave({...})` duplication 089 left behind. No behaviour change.

- `091-BUGFIX-graduation-includes-breed-tricks` — closes a v1 progression
  correctness gap: graduation eligibility checked only the 3 starter tricks, so a
  Collie/Husky/Bulldog/Puddel "graduated" while its signature trick (shown as
  masterable on the select screen) was unmastered. New pure
  `graduationTrickIds(breed)` (starter set + breed signature, single-sourced off
  `tricksForBreed`) drives both `main.ts` graduation call-sites. TDD, 5 new tests.
- `090-PERF-indexeddb-connection-reuse` — `IndexedDbStorage` opened a fresh
  connection on every `load`/`save`/`clear` (dozens per session). `openDb()` now
  memoises the connection in `dbPromise`; a rejected open nulls the memo
  (retryable). TDD: spy asserts `indexedDB.open` called once across 4 ops (was 4).
- `089-QUALITY-main-ts-dead-code-consolidation` — removed dead `getPhrase`
  callback (interface + impl; `grep` clean); `getStats` reuses
  `totalMasteredCount(roster)`; new `BASE_SCHEDULER_TIMING` const single-sources
  the `2000`/`800` scheduler base shared by `main.ts` + `buildSchedulerCfg`. No
  behaviour change.

Gate after iteration 9: typecheck 0 errors · 596 tests pass · build no warnings ·
e2e (smoke + full-loop) PASS.

## Recently Completed (non-gated v1 hardening, iteration 8 — 2026-06-17)

- `086-FEATURE-round-resume-persistence` — closes the §Round States gap (partial
  learned-bar progress now persists). `GameSave` gains `activeRoundDogId` /
  `activeTrickId` / `learnedBar` (back-compat defaults); pure `restoreLearnedBar`
  (TDD) seeds the bar only on a dog+trick match; `main.ts` snapshots the live round in
  `persist()` and clears it on the mastery edge. Quit mid-round → reopen same
  dog+trick → resumes; a different round starts at 0. 12 tests.
- `087-FEATURE-phrase-tradeoff-model` — closes the §Marker Phrases trade-off gap
  (phrases were pure upside). New `Phrase.peakRadiusPenaltyMs` shrinks the PERFECT
  band, clamped to a 20 ms floor; stronger phrases trade precision for their reward
  bonus (bra/flink 0, dyktig 25, super 40, kjempebra 65 ms). Model + values recorded
  in tech-decisions §7p; the spec's "open design item" is resolved. TDD.
- `088-TEST-e2e-full-loop-coverage` — `e2e/full-loop.mjs` plays Sitt to mastery by
  apex-timed taps (polls `#hud[data-tell]`), then asserts **payout** (coins 0 → 50)
  and **return-to-select**. The heart of the loop is now guarded end-to-end. A
  DEV-only `window.__bra` read hook (tree-shaken from prod) backs the assertions.

Gate after iteration 8: typecheck 0 errors · 589 tests pass · build no warnings ·
e2e (smoke + full-loop) PASS.

## Recently Completed (audio + scope/quality, iteration 7 — 2026-06-17)

- `074-FEATURE-mark-sfx-feel` — mark SFX upgraded from a single sine bell to a
  layered **click transient (12 ms / 2000 Hz square) + per-tier praise tone**
  (PERFECT 880/140/0.9, OK 660/120/0.5, MISS click-only @0.12, FALSE_MARK 180 Hz
  sawtooth, no click); pure `markLayers` + clip-ready path (`registerClip` /
  `shouldUseClip` / guarded `playBuffer`) so the future Maren voice drops in with no
  call-site change. Voice sourcing stays open §4. TDD, 7 tests. Audio review
  (code-level) passed; human on-device listen still recommended.
- `075-FEATURE-gate-untrain-tricks-out-of-v1` — post-v1 untraining no longer leaks
  into the v1 trick-select. Pure `untrainTricksUnlocked(masteredCount)` gate (false
  for v1, documented post-v1 flip) in `onboarding.ts`, consulted by `getTricks()`;
  untrain mechanic kept dormant. TDD.
- `076-QUALITY-save-schema-dead-code-cleanup` — removed vestigial
  `GameSave.masteredTrickIds` (always `[]`/never read); `deserialize` rebuilt with
  explicit fields (legacy saves still load, back-compat test). Dropped dead imports
  (`isPhraseUnlocked`, `effectiveDistractorRate`), single-sourced `STARTER_ROSTER`,
  deleted `example.test.ts`. No behavior change. TDD.

Gate after iteration 7: typecheck 0 errors · 564 tests pass · build no warnings ·
e2e smoke PASS.

## Recently Completed (shell + mobile correctness, iteration 6 — 2026-06-17)

- `071-BUGFIX-panel-exclusivity` — panel overlays no longer stack; `open*Panel()`
  paths are mutually exclusive (verified).
- `072-FEATURE-adopt-level-gate-legibility` — level-locked breeds read as "Lvl N"
  via `isBreedLevelLocked`, distinct from coin-gating, with disabled styling.
- `073-FEATURE-mobile-resume-grace` — `RESUME_GRACE_MS = 400` + pure
  `isWithinResumeGrace`; `visibilitychange` stamps `resumedAt`; `onBraTap` swallows
  stray resume taps before any false-mark/confuse. TDD.

## Recently Completed (non-visual v1 gaps, iteration 5 — 2026-06-17)

- `068-FEATURE-confuse-debuff-mechanics` — pure `confuseDifficulty(eff)` (window &
  peakRadius ×0.6, distractorRate ×1.5 capped at 1; immutable; TDD, 9 tests) wired
  into `main.ts` `tick()` via a `prevConfused` edge guard that rebuilds
  `SCHEDULER_CFG` through `buildSchedulerCfg` (onboarding distractor gate preserved)
  + regenerates the timeline on the confuse on/off edges only. "Mashing loses" is
  now mechanically true.
- `069-FEATURE-level-gated-unlocks` — two-step gate enforced (level makes
  purchasable, coins buy). New `isPhrasePurchasable`/`nextPurchasableEntry` (phrases)
  + `Breed.requiredLevel` ladder + 4-arg `canAdopt` (breeds), both via the now-live
  `economy.isTierUnlocked`; `main.ts` purchase/adopt pass `profile.level`; HUD shows
  `Lvl N` vs coin price. TDD, 24 tests. Ladder in tech-decisions §10.
- `070-FEATURE-reduced-repractice-payout` — `PRACTICE_BASE_PAYOUT {coins:15, xp:0}`
  + `completePractice` (same multiplier stack); `main.ts` captures
  `wasAlreadyMastered` at trick-select and branches full mastery vs reduced/no-XP
  re-practice. Anti-softlock coin floor without XP-farming. TDD, 4 tests.

Gate after iteration 5: typecheck 0 errors · 537 tests pass · build no warnings ·
e2e smoke PASS.

## Recently Completed (dog loop, iteration 4 — 2026-06-16)

- `065-FEATURE-trainer-hand-reward` — trainer's hand enters frame on a mark
  (treat at the muzzle) and bigger/longer on mastery; pure `handAnim` enter/exit
  maths (TDD). Satisfies the Visual Presentation trainer's-hand req.
- `066-FEATURE-idle-look-around` — pure idle `headYaw` look-around in `dogPose`
  (occasional, bounded, reduced-motion dampened, idle-only; TDD) → `headPivot`.
  Idle dog calmly looks to both sides and returns (**D4**); screenshot-verified.
- `067-FEATURE-mastery-dog-flourish` — pure `masteryFlourish` decay module (leap +
  partial happy spin + fast wag, peak at masteredAt, mirrors `rewardPulse`; TDD)
  layered over the happy state via `scene.ts`. Dog pops bigger on mastery than a
  normal mark, then settles (**D8**); screenshot-verified. 504 tests green.

## Recently Completed (dog loop, iteration 1 — 2026-06-14)

- `056-FEATURE-dog-mesh-silhouette` — sphere → primitive dog (body/head/ears/
  snout/4 legs/tail) under one root `TransformNode`; six states preserved; new
  `src/render/dogMesh.ts`. Satisfies **D1**. (screenshot-verified)
- `057-FEATURE-dog-grounded-shadow-material` — blob contact shadow tracking
  lateral motion (**D12**), soft fur-ish material (plastic specular killed),
  eyes + nose with own materials; shadow choice documented tech-decisions §2.
- `058-FEATURE-dog-pose-states` — pure `dogPose()` (11 TDD tests) → head/tail
  pivots; per-state poses not just tint (**D4–D11**), reduced-motion dampened
  not removed (**D13**); 451 tests green.

## Recently Completed

## Recently Completed

## Recently Completed

## Recently Completed

## Recently Completed

## Recently Completed

## Orchestration note — VERIFY BLOCKERS BEFORE PARKING WORK (2026-06-20)
- **Premature blocking has cost this project the most progress.** The FBX→glb conversion
  was parked for *days* across multiple iterations on two assumptions that were **both false**
  on a second look: "the .rar is corrupted" (it wasn't — system `7z` just can't decode RAR-7
  and wrote 0-byte files) and "there's no FBX→glb tooling here" (there was — `node-unrar-js`
  + the `fbx2gltf` npm binary, both no-sudo). That single false block stalled the entire
  visuals epic (077/078/079/098).
- **Rule:** before the orchestrator marks anything `on-hold`/blocked, it must **try at least
  2–3 genuinely different approaches** and record each command + its actual error. One tool
  failing is a tool problem, not a blocker. "No X on PATH" ≠ "X is impossible" — check npm/
  WASM/prebuilt-binary routes first. Only escalate a block that survives multiple real attempts,
  and write down exactly what was tried so the next iteration doesn't re-park it blind.
- A true owner/legal gate (e.g. a missing paid asset, a licensing decision) is still a real
  block — but state precisely *what* is missing and confirm the rest of the work can proceed
  around it, rather than parking a whole epic.

## Subagent note
- NEVER fabricate a screenshot. If a headless browser fails, run `node scripts/shoot-hud.mjs`
  (it clears LD_LIBRARY_PATH) or report the failure honestly — do not synthesize a diagram.

(Backlog also: `007-DESIGN-scene-framing-polish` — low, deferred.)

## DevOps note
- Reuse ONE long-lived `bun run dev` server for screenshots (check `curl localhost:5173`,
  start only if down). Do NOT `pkill` between tasks — pkill is gated + self-matches the shell.
- **Verify with `bun run verify`** (dots wrapper, `scripts/verify.mjs`): runs typecheck →
  tests → build, prints `verify ●●●  ✓ … (N tests)` on success and the full output of only a
  failing step. Keeps subagent/loop context from filling with vitest lines + the build chunk
  table. `bun run test:verbose` for the per-test breakdown when debugging.

## Recently Completed

- `008-FEATURE-difficulty-model` — Normal/Hard/Expert effective config + scaled deltas (iter 3, TDD)
- `009-FEATURE-economy-model` — coins/XP/levels, award/spend/unlock (iter 3, TDD, triangular level table)
- `010-FEATURE-persistence` — GameSave serialize + InMemory/IndexedDB storage (iter 3, TDD, fake-indexeddb)
- `011-FEATURE-wire-meta-into-app` — live app loads save, uses difficulty, pays coins/XP on mastery, persists; HUD shows coins/level (iter 4, screenshot-verified)
- `012-FEATURE-marker-phrases` — phrases + cooldown + window/reward bonus (iter 4, TDD)
- `013-FEATURE-breeds-roster` — breed stats, `composeDifficulty`, persistent roster (iter 4, TDD)
- `014-FEATURE-apex-tell-cue` — tellStrength + gold pulse ring at peak; **timing is now playable** (iter 5, screenshot-verified)
- `015-FEATURE-dog-visual-states` — dog tints/reacts idle/offering/confused/happy (iter 5, screenshot-verified orange=confused)
- `016-FEATURE-phrases-in-loop` — `resolvePhraseMark` + FLINK loadout chip w/ cooldown sweep (iter 5, screenshot-verified)
- `017-FEATURE-idle-kennel-income` — capped idle coins + `kennelMultiplier` into payout; GameSave +kennelUpgradeIds (iter 6, TDD)
- `018-FEATURE-difficulty-selector-ui` — Normal/Hard/Expert segmented control, persisted (iter 6, screenshot-verified HARD highlight)
- `019-FEATURE-mark-audio` — per-result WebAudio SFX, lazy AudioContext (iter 6, TDD; not aurally verified headless)
- `021-FEATURE-trick-roster-select` — Sitt/Ligg/Legg deg + select/training state machine; mastery→repertoire+persist (iter 7, screenshot-verified)
- `020-FEATURE-kennel-shop-ui` — buy-upgrades panel (`canBuy` TDD) + multiplier display (iter 7, screenshot-verified)
- `022-FEATURE-onboarding-drip` — `onboardingStage` (TDD) gates selector/phrases/kennel; first-run HUD sparse (iter 7, REAL screenshot-verified)
- `023-FEATURE-trick-difficulty-profiles` — Sitt easy → Legg deg hard (learn/window/distractor mults); applied per round (iter 8, TDD)
- `024-FEATURE-visible-distractors` — grey turned-away distractor dog state vs warm offering cue; rate gated by onboarding/trick (iter 8, REAL screenshot-verified)
- `025-FEATURE-phrase-unlock-loadout` — phrase catalog + economy unlock + tap-to-cycle loadout chip (iter 8, REAL screenshot-verified)
- `026-FEATURE-adopt-dogs` — BREED_CATALOG (Collie/Bulldog/Husky) + adopt panel + roster select; active dog's breed drives difficulty (iter 9, REAL screenshot-verified)
- `027-DESIGN-hud-polish-pass` — trick label clearance, loadout chip off BRA, safe-area/consistency sweep (iter 9, before/after verified)
- `007-DESIGN-scene-framing-polish` — bright sky + grass, dog centered at horizon, letterbox gone; trick-label contrast pill (iter 9, verified)
- `028-FEATURE-combos` — combo counter (×mult, gold chip) boosts reward, breaks on miss (iter 10, TDD + forced-visible screenshot)
- `029-FEATURE-untraining` — "Ikke hopp": red jumping dog = bad habit; mark the calm (inverted) (iter 10, REAL screenshot-verified)
- `030-FEATURE-graduation-prestige` — fully-trained dog graduates → permanent prestige multiplier (iter 10, REAL screenshot-verified)
- `031-DOCS-tuning-audit` — 66 tunables tabled in tech-decisions §7 + 5 balance findings/recommendations (iter 11, no code change)
- `032-CLEANUP-consolidate-screenshot-scripts` — 11 one-offs → `shoot.mjs` (parametric) + `shoot-hud.mjs` shim (iter 11)
- `033-REFACTOR-extract-main-helpers` — 5 pure helpers → `src/app/gameHelpers.ts` (+36 tests incl. GameSave builder); main.ts 454→426 (iter 11, smoke-verified no regression)
- `034-BALANCE-apply-tuning-fixes` — 6 §7 fixes applied + tests + prestige cap 2.5× (iter 12, grep-verified)
- `035-A11Y-accessibility-sweep` — aria labels/pressed/dialog, `:focus-visible`, contrast bumps, `prefers-reduced-motion` (iter 12)
- `036-PERF-codesplit-babylon` — manualChunks split Babylon; app chunk 1MB→27KB, build warning gone (iter 12, render-verified)
- `037-FEATURE-pwa-installable` — vite-plugin-pwa: manifest + SW + real paw icons (192/512/maskable); installable (iter 13, dist-verified)
- `038-FEATURE-settings-panel` — mute/reset/stats panel; MarkAudio.muted + GameSave.muted + storage.clear() (iter 13, fixed a truncated/broken first attempt)
- `039-DOCS-readme` — project README (pitch/quick-start/tech/gameplay/structure/status), commands verified (iter 13)
- `041-TEST-e2e-smoke` — `e2e/smoke.mjs` + `bun run e2e`: select→train→mark, non-flaky (iter 14, independently run)
- `042-FEATURE-more-audio` — mastery arpeggio (C–E–G) + menu tap SFX, mute-aware (iter 14, TDD)
- `040-PERF-lazy-load-babylon` — dynamic-import scene; entry chunk 29KB / 0 Babylon refs; dog still renders (iter 14, e2e+screenshot verified)
- `043-FEATURE-loading-indicator` — `#hud-loading` spinner during the lazy-Babylon window (iter 15, screenshot-verified)
- `044-CI-github-actions` — `.github/workflows/ci.yml` (typecheck+test+build); e2e omitted-with-note; YAML-valid (iter 15)
- `045-FEATURE-breed-signature-tricks` — Rull/Ul/Sov per breed; `tricksForBreed`; breed-aware select list (iter 15, screenshot-verified)
- `046-FEATURE-mastery-celebration` — radial gold burst + 8 confetti on mastery; reduced-motion fade (iter 16, screenshot-verified)
- `048-FEATURE-help-overlay` — "?" How-to-Play dialog (apex/tap/distractor/combo/challenge) (iter 16, screenshot-verified)
- `047-DIST-capacitor-scaffolding` — `@capacitor/core+cli`, `capacitor.config.ts`, `cap:sync`, `.docs/native-build.md` (iter 16; platforms documented-only)
- `049-FEATURE-achievements` — 6 achievements + panel; `bestCombo` in GameSave (iter 17, screenshot-verified 5/6 unlocked)
- `050-CONTENT-more-phrases` — dyktig + kjempebra; catalog monotonic, §7-balanced costs (iter 17, TDD)
- `051-DESIGN-final-polish-pass` — unified panel chrome + close-button focus rings + scrollable select (iter 17, screenshot-verified)
- `052-FEATURE-daily-streak` — consecutive-day 🔥 streak + settings stat; GameSave +streak/lastPlayedYmd (iter 18, screenshot-verified)
- `053-CONTENT-one-more-breed` — Puddel breed + Snurr signature trick (iter 18, TDD)
- `054-FEATURE-ambient-audio` — 160Hz ambient pad, mute-aware, lazy ctx (iter 18, TDD)

- `001-FEATURE-project-scaffolding` — Vite+TS+Bun+Babylon+Vitest (iter 1)
- `002-FEATURE-mark-timing-model` — `classifyMark` (iter 1, TDD, 9 tests)
- `003-FEATURE-learned-bar-session-model` — learned bar/mastery/confuse (iter 1, TDD, 12 tests)
- `004-FEATURE-behavior-scheduler` — deterministic attempt/distractor timeline (iter 2, TDD, 18 tests)
- `005-FEATURE-round-controller` — headless playable round + `replaceTimeline` (iter 2, TDD)
- `006-FEATURE-bra-marker-ui` — tappable BRA marker + bar; **playable slice** (iter 2, screenshots verified)
