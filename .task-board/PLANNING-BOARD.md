# Planning Board

**Current Focus**: **Pokémon-GO Visuals epic** kicked off (2026-06-17). v1
gameplay is complete + playable (564 tests, P0 PASS); the one unstarted pillar is
**D14 — "looks the part."** Owner picked the sourcing route (**asset-store base
model + shared-rig retargeting**, tech-decisions §3). Roadmap +
task series live in [`EPIC-pokemon-go-visuals.md`](EPIC-pokemon-go-visuals.md).

## Top Priorities — Pokémon-GO Visuals epic (077–085)

Backlog now holds the first batch (Phase 0–1). Work them in order; 078/079 are
blocked until 077 stages a real `.glb`.

- **`077-RESEARCH-dog-model-sourcing`** — **ready now.** Shortlist 2–3 rigged dog
  base models (format/license/tris/rig), recommend one, escalate the purchase to
  the owner (money/likeness gate). Unblocks everything.
- **`078-FEATURE-gltf-load-path-and-fallback`** — async glTF load + pure
  `selectDogRenderMode` + procedural fallback, flag default off. *(blocked on 077)*
- **`079-FEATURE-imported-dogmesh-labrador`** — imported Labrador behind the
  `DogMesh` contract, flag-gated, Visual-Review proving slice. *(blocked on 077+078)*

Phases 2–6 (`080`–`085`: skeletal anim, PBR look, breed retarget, signature anims +
backdrop, perf/ship gate) are outlined in the epic and promoted to full task files
as each phase begins.

Other deferred non-visual findings (own tasks, lower impact than the epic): **dog
foley** (panting/barks/whines) absent + ambient is a synth drone not a real bed;
**E2E coverage** stops at bar-progress (never exercises mastery → payout → return);
more dead exports; `hud.ts` > 1100 lines (split candidate).

Other verified findings deferred to next scan (lower impact): **dog foley** (panting/
barks/whines) entirely absent + ambient is a synthesized drone, not a real bed (audio,
own task); **D14 fidelity** — primitive Babylon meshes, not Pokémon-GO stylized-realism
(visual, large, saturated-domain — needs model sourcing); **E2E coverage** — smoke test
stops at bar-progress, never exercises mastery → payout → return-to-select; more dead
exports (`round.markAt`/`isMastered`, `roster.repertoire`, audio internals, payout
constants, deprecated `getPhrase` callback); `hud.ts` > 1100 lines (split candidate).

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
