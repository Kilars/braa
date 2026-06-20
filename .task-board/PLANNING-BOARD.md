# Planning Board

**Current Focus**: Iteration 13 (2026-06-19) found the backlog drained and ran
`scan-project` to replenish **three unblocked, non-epic tasks** (ids **099–101**;
080–085 stay reserved for the visuals epic). Picks deliberately avoid the saturated
quality/refactor (×4) and logic (×4) domains from the last 15 done, and steer clear of
the FBX→glb-gated visuals epic: **099** (HIGH) closes a named v1 spec gap — *swipe the
BRA marker to swap phrase* (specs §Marker Phrases; tech-decisions §7 still lists the
selection UI as open); **100** (MED) wires the already-built reward-latency event into
the live engagement meter, completing the "slow rewards drain it" half of 098 — and
carves it out of 098's over-broad 079 deferral (it needs only tap-vs-apex timing, no
clips); **101** (MED) adds a jsdom test env + unit coverage for the five untested panel
factories (`adoptPanel`/`kennelPanel`/… have none — env is node-only today). Then worked
the backlog (see below).

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

## Pokémon-GO Visuals epic (077–085) — needs FBX→glb conversion, then build

No longer owner-blocked: the owner purchased + dropped the Labrador
(`Labrador_FBX.rar` at repo root; manifest in tech-decisions §3c). The remaining
gate is the **FBX → glb conversion** — the bought FBX must be converted and staged at
`public/models/dog.glb`, replacing the CC0 placeholder. Roadmap in
[`EPIC-pokemon-go-visuals.md`](EPIC-pokemon-go-visuals.md).

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

## Top Priorities — next scan round (backlog drained again)

**Backlog and in-progress are both empty** — iteration 13 shipped all three replenished
tasks (099–101, below). The next iteration MUST run `scan-project` to replenish 3 fresh
tasks (new ids start at **102**; 080–085 stay reserved for the epic).

The Pokémon-GO Visuals epic still needs the FBX → glb conversion (tech-decisions §3c)
before 078/079/098-remainder can build against the real model — none of 099–101 touched it.

Carry-forward candidates for the next scan (re-rank against fresh findings): **unit tests
for `hud.ts` orchestration** (the panel factories now have jsdom coverage from 101, but the
686-line `createHud` orchestration does not); **centralize tunables into `src/core/tuning.ts`**
(tech-decisions §8 "Future" note — but refactor domain is now warm); **`main.ts` is 760 LOC**
and could shed more pure helpers. Still excluded: extend-levels-beyond-L5 (no content),
Maren voice (owner-gated asset), and the on-dog engagement beats / walk-away (079-gated).

**Saturation note (iteration 13):** last-15-done now skews **feature/UI** (099 UI-interaction,
096 UI) and **test** (088, 101); quality/refactor (076/089/092/093) and logic (075/087/091/097)
remain the heaviest historical buckets. Audio (074/094) and persistence (086/090) sit at 2.
Next scan should avoid stacking more UI-interaction; a correctness/perf or content gap would
balance the mix.

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
