# Tech Decisions (Open)

Technical questions parked during functional design. The **what/how-it-plays**
lives in [specs.md](specs.md); this file tracks **how we build it**. Nothing here
is final.

## 1. Architecture / Stack — DECIDED

**A PWA (web) front end with a WebGL 3D layer, wrapped for the app stores via
Capacitor. Fully client-side, no backend.**

| Layer | Choice |
|-------|--------|
| Language / build | **TypeScript**, bundled with **Vite**; **Bun** as package manager / runtime |
| 3D dog rendering + animation | **Babylon.js** (WebGL) — TS-native, code-first, built-in skeletal-animation system; renders a single skinned character on a simple backdrop |
| 2D UI (BRA marker, bars, menus, economy) | **DOM / HTML-CSS overlay** on top of the Babylon canvas |
| Store distribution | **Capacitor** wraps the same web app into native iOS/Android binaries (App Store + Play Store); the project is also an installable PWA on the open web |
| Persistence | **IndexedDB**, client-side only (see §4) |
| Backend | **None** for v1 |

**Why:** satisfies "downloadable on both stores" (Capacitor), "PWA" (it is one),
"no heavy cross-platform native" (no React Native / Flutter), "client-heavy / no
server" (IndexedDB, no backend), and "engine-grade animation without a full game
engine" (Babylon is a web-native engine, not a Unity/Godot runtime). A single
animated dog on a simple scene is well within mobile WebGL budget.

**Caveats:** profile on a real mid-range Android early; the genuine risk is the
3D dog art/animation pipeline (§2), not the architecture.

**Fallback:** if web 3D animation proves too painful in practice, **Godot 4** is
the escape hatch (small mobile exports, real 3D, free) — switch only if web
genuinely blocks, since it forfeits the PWA / instant-deploy / no-native-weight
benefits.

**Prototype first:** v1 is a "vertical slice on feel" — validate the BRA timing
with placeholder art before investing in the 3D pipeline.

## 2. Rendering — Dog Shadow Approach (DECIDED)

**Blob shadow (disc decal), not a shadow map.**

A flat semi-transparent dark disc (`MeshBuilder.CreateDisc`) at world y≈0.01 provides
the contact shadow required by D12, with zero shadow-map cost on mobile. The disc
tracks the dog's lateral x each frame (called from the render loop in `scene.ts` via
`dog.updateShadowX`), so it stays centered during confused jitter and distractor lean.
A real `ShadowGenerator` with `DirectionalLight` would look marginally sharper but adds
a non-trivial per-frame GPU cost; the blob is indistinguishable at phone size.

## 2b. Rendering — Training-Ground Backdrop (DECIDED)

**Cheap gradient backdrop via DynamicTextures + back-plane, no skybox or post-processing.**

Implemented in `src/render/backdrop.ts` (called from `scene.ts`):
- **Sky gradient**: a large back-plane quad at z=−14 with a `DynamicTexture`
  vertical gradient (pale horizon `rgb(0.76,0.89,0.98)` → richer sky-blue top
  `rgb(0.32,0.55,0.88)`). `renderingGroupId = 0` puts it behind everything; unlit
  (`disableLighting = true`) so the texture colour is direct. One extra quad draw
  call per frame; textures created once at setup.
- **Ground radial gradient**: the 10×10 ground gets a `DynamicTexture` radial
  gradient (bright vivid grass at centre → desaturated edge), focusing the eye on the
  dog and softening the ground-to-sky join. The far edge colour matches the sky
  horizon so there is no hard horizon line.
- **Corner vignette**: a flattened inside-hemisphere shell (backFaceCulling off,
  alpha=0.28) around the scene darkens corners and frames the dog without any
  post-processing pipeline.
- **Key light**: added a warm `DirectionalLight` (3/4 front, intensity 0.7) to give
  the dog crisp separation from the backdrop; the `HemisphericLight` intensity
  dropped to 0.8 as softer ambient fill. No shadow generator added.
- Per-frame cost: two extra quad draw calls (sky plane + ground) + the shell. All
  textures drawn once at init. No post-processing. Safe on mobile.

## 3. 3D-on-Mobile Cost (flagged)

Semi-realistic, breed-recognizable 3D models + per-breed signature animations is
the single biggest content/perf risk. Mitigations to evaluate:

- Start with a **small number of high-quality breeds**, not many cheap ones.
- Shared skeleton / retargeted animations across breeds where possible.
- Budget for LODs, draw-call limits, and battery/thermal on mid-range phones.
- Consider asset-store/base models early to avoid bespoke modeling per breed.

### Decision (2026-06-17): asset-store base model + shared-rig retargeting

The sourcing route is **resolved**. We will license a **rigged dog base model**
(glTF/`.glb`) with a shared canine skeleton and produce the breed roster via
**proportion morphs + per-breed coat textures on that one rig** — not bespoke
per-breed models, not AI-generated meshes, not a further-pushed procedural dog.
Rationale: predictable cost, proven pipeline, fastest route to the Pokémon-GO
look, and it is this section's own listed mitigation. Risk owners accepted the
money/license gate (the actual purchase is approved by the product owner).

Execution lives in the **[Pokémon-GO Visuals epic](../.task-board/EPIC-pokemon-go-visuals.md)**
(tasks 077–085). Key architectural choice: the migration swaps the implementation
**behind the existing `DogMesh` contract** (`src/render/dogMesh.ts`), one breed and
one phase at a time, behind a feature flag, with the procedural dog as fallback —
so the app stays shippable throughout. Vertical slice (Labrador) first, then scale.

The chosen model's link / license / format / tri count will be recorded here by
task `077` once selected and approved.

## 4. Marker Voice ("sound like Maren") (flagged)

The spec fixes the target sound: the marker voice **must sound like Maren from
_Bølle til bestevenn_** (a warm, bright, encouraging female Norwegian "bra!" with
an upward, praising lilt — see [specs.md](specs.md) → Audio). That target is not
open; only *how we source a voice that hits it* is. Open sourcing options, to
research and decide:

- **Record original voice** (the user / a friend) styled after the delivery —
  cleanest rights position, full control, manual to expand.
- **License / get permission** to use the actual voice — authentic, but requires
  outreach and likely cost/agreement.
- **Voice imitation / synth/clone of a real person** — ⚠️ **likeness & rights
  risk.** Imitating an identifiable real person's voice without consent can raise
  personality-rights/likeness issues even for a small/personal project. Treat as
  a flag, not a blocker; prefer consent-based or original-voice routes.
- **Generic TTS** — easy to scale phrases, but risks robotic delivery that
  undercuts the warm show feel.

**Recommendation:** for v1, record an **original** voice in the right *style*
(short, warm, punchy "bra!"). Revisit licensing only if the project goes public.

## 5. Persistence / Save

Single-player, local progression (coins, XP/level, unlocks, kennel, idle
timestamp for the capped trickle). Needs:

- **IndexedDB** (client-side; structured save, room to grow vs. localStorage).
- A **timestamp** for computing capped idle income on return.
- No backend required for v1. Cloud save = future, only if multi-device matters.

## 6. Content / Data-Driven Design

Breeds, tricks, and phrases are all expandable catalogs. Define them as **data**
(config/tables), not hardcoded, so new content is authored without code changes.
Tunable per entry: window width, distractor rate, learn speed, intrinsic
difficulty, rewards, phrase cooldown/effect, breed stat modifiers + signature
behaviors.

## 7. Phrase Loadout UI + Trade-off Model (from spec review)

Two phrase questions are deliberately deferred:

- **Loadout/selection UI:** spec commits to "no extra buttons" — load a phrase
  outside the round, or swipe the BRA marker to swap. Pick and prototype one;
  confirm it never competes with the timing tap.
- **Trade-off model:** with few phrases early, a strict "fire strongest on
  cooldown" rotation is harmless. Once the catalog grows, stronger phrases need a
  real upside+downside (e.g. +reward / −window) or situational specialism so
  loading is a genuine choice. Decide the model before authoring many phrases.

## 8. Tuning Targets — Audited Constant Table (iteration 11, 2026-06-14)

> **Future:** centralize all constants below into a single `src/core/tuning.ts`
> export (not done here — doc-only pass; a code refactor is a separate task).

All values are placeholders authored during initial implementation and have not
been validated by playtest. The table is the single reference for future tuning.

### 7a. Mark Deltas (`src/core/mark.ts`, `src/core/difficulty.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `NORMAL_DELTAS.PERFECT` | +8 | mark.ts | Learned-bar increase on a perfect tap | Baseline; HARD/EXPERT inherit this |
| `NORMAL_DELTAS.OK` | +3 | mark.ts | Learned-bar increase on an OK tap | |
| `NORMAL_DELTAS.MISS` | 0 | mark.ts | Bar change on a miss | No penalty; neutral |
| `NORMAL_DELTAS.FALSE_MARK` | −4 | mark.ts | Bar decrease on a false mark | HARD overrides to −8; EXPERT to −14 |
| HARD `FALSE_MARK` override | −8 | difficulty.ts | Bar penalty on false mark in HARD mode | 2× NORMAL |
| EXPERT `FALSE_MARK` override | −10 | difficulty.ts | Bar penalty on false mark in EXPERT mode | 2.5× NORMAL — **APPLIED §7n** |

### 7b. Confuse Debuff (`src/core/session.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `CONFUSE_MS` | 3000 ms | session.ts | Duration the dog is "confused" after a false mark; taps during window do nothing | Refreshes (does not stack) |

### 7c. Scheduler (`src/core/scheduler.ts`, `src/core/difficulty.ts`, `src/main.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `attemptInterval` | 2000 ms | main.ts | Gap between successive correct-attempt windows | Hardcoded in `buildSchedulerCfg()` |
| `activeSpan` | 800 ms | main.ts | How long the dog visibly holds the behavior | Hardcoded in `buildSchedulerCfg()` |
| NORMAL `windowWidth` | 400 ms | difficulty.ts | Scoring window (tap lands here → OK or PERFECT) | Centered within activeSpan |
| NORMAL `peakRadius` | 80 ms | difficulty.ts | Half-width of the PERFECT sub-band | |
| NORMAL `distractorRate` | 0.2 | difficulty.ts | Probability of a distractor between correct attempts | Gated to 0 until first mastery (onboarding) |
| HARD `windowWidth` | 280 ms | difficulty.ts | Tighter window than NORMAL 400 ms | −30% |
| HARD `peakRadius` | 50 ms | difficulty.ts | Tighter PERFECT band than NORMAL 80 ms | −37.5% |
| HARD `distractorRate` | 0.45 | difficulty.ts | Higher distractor chance than NORMAL 0.2 | +125% |
| EXPERT `windowWidth` | 160 ms | difficulty.ts | Tighter window than HARD 280 ms | −60% from NORMAL |
| EXPERT `peakRadius` | 25 ms | difficulty.ts | Tighter PERFECT band than HARD 50 ms | −69% from NORMAL |
| EXPERT `distractorRate` | 0.55 | difficulty.ts | Higher distractor chance than HARD 0.45 | +175% from NORMAL — **APPLIED §7n** |
| `TIMELINE_EVENTS` | 20 | main.ts | Events per segment before the timeline loops | Approximately 40 s per segment at 2 s interval |
| Untrain calm-gap minimum | 100 ms | scheduler.ts | Minimum gap duration to count as a markable calm window | Hard-coded inline |
| Untrain `peakRadius` (derived) | min(80, gapLen/4) ms | scheduler.ts | PERFECT sub-band for untrain attempts; adapts to gap width | |

### 7d. Difficulty Tell Intensity (`src/core/difficulty.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| NORMAL `tellIntensity` | 1.0 | difficulty.ts | Apex visual pulse strength (1 = clearest) | |
| HARD `tellIntensity` | 0.6 | difficulty.ts | Fainter pulse cue in HARD mode | −40% vs NORMAL |
| EXPERT `tellIntensity` | 0.3 | difficulty.ts | Faintest cue in EXPERT mode | −70% vs NORMAL |

### 7e. Reward Multipliers (`src/core/difficulty.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| NORMAL `rewardMultiplier` | 1.0 | difficulty.ts | Scales mastery coin + XP payout | Baseline |
| HARD `rewardMultiplier` | 1.3 | difficulty.ts | 30% bonus payout in HARD mode | **APPLIED §7n** |
| EXPERT `rewardMultiplier` | 2.5 | difficulty.ts | 150% bonus payout in EXPERT mode | |

### 7f. Tricks (`src/core/tricks.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Sitt `learnMult` | 1.0 | tricks.ts | Positive delta multiplier (PERFECT/OK); 1 = baseline | Easiest trick |
| Sitt `windowMult` | 1.0 | tricks.ts | Scales windowWidth and peakRadius | No change from mode defaults |
| Sitt `distractorBonus` | 0.0 | tricks.ts | Added to distractorRate | No extra distractors |
| Ligg `learnMult` | 0.75 | tricks.ts | 25% slower bar fill than Sitt | Medium trick |
| Ligg `windowMult` | 0.8 | tricks.ts | 20% tighter window than Sitt | |
| Ligg `distractorBonus` | 0.1 | tricks.ts | +10 pp distractor rate | |
| Legg deg `learnMult` | 0.5 | tricks.ts | 50% slower bar fill than Sitt | Hardest starter trick |
| Legg deg `windowMult` | 0.6 | tricks.ts | 40% tighter window than Sitt | |
| Legg deg `distractorBonus` | 0.2 | tricks.ts | +20 pp distractor rate | |
| Ikke hopp `learnMult` | 0.8 | tricks.ts | Slower bar fill (untrain trick) | Medium-hard untraining trick |
| Ikke hopp `windowMult` | 0.9 | tricks.ts | 10% tighter calm-gap window | |
| Ikke hopp `distractorBonus` | 0.3 | tricks.ts | +30 pp bad-habit appearance rate | |

### 7g. Breeds (`src/core/breeds.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Labrador `intrinsic` | 1.0 | breeds.ts | Difficulty multiplier applied via `composeDifficulty` | Neutral; starter breed (free) |
| Labrador `learnSpeed` | 1.0 | breeds.ts | Personality stat (informational for now) | |
| Labrador `distractibility` | 0.5 | breeds.ts | Personality stat | |
| Border Collie `intrinsic` | 1.5 | breeds.ts | Window ÷ 1.5, distractor rate × 1.5 vs baseline | Harder to train |
| Border Collie `learnSpeed` | 1.4 | breeds.ts | Personality stat | |
| Border Collie `distractibility` | 0.9 | breeds.ts | Personality stat | |
| Border Collie `adoptCost` | 200 coins | breeds.ts | Purchase price in the adopt shop | |
| Bulldog `intrinsic` | 1.3 | breeds.ts | Window ÷ 1.3, distractor rate × 1.3 vs baseline | Moderately harder |
| Bulldog `learnSpeed` | 0.7 | breeds.ts | Personality stat | |
| Bulldog `distractibility` | 0.3 | breeds.ts | Personality stat | |
| Bulldog `adoptCost` | 150 coins | breeds.ts | Purchase price in the adopt shop | |
| Husky `intrinsic` | 1.8 | breeds.ts | Window ÷ 1.8, distractor rate × 1.8 vs baseline | Most challenging breed |
| Husky `learnSpeed` | 1.1 | breeds.ts | Personality stat | |
| Husky `distractibility` | 0.95 | breeds.ts | Personality stat | |
| Husky `adoptCost` | 300 coins | breeds.ts | Purchase price in the adopt shop | |

### 7h. Economy (`src/core/economy.ts`, `src/core/game.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `MASTERY_BASE_PAYOUT.coins` | 50 | game.ts | Base coin reward on mastering a trick | Scaled by difficulty × kennel × prestige |
| `MASTERY_BASE_PAYOUT.xp` | 30 | game.ts | Base XP reward on mastering a trick | Same scaling |
| `LEVEL_THRESHOLDS[1]` | 0 XP | economy.ts | XP to reach level 1 | Starting level |
| `LEVEL_THRESHOLDS[2]` | 100 XP | economy.ts | XP to reach level 2 | ~3–4 masteries at NORMAL |
| `LEVEL_THRESHOLDS[3]` | 300 XP | economy.ts | XP to reach level 3 | +200 XP from L2 |
| `LEVEL_THRESHOLDS[4]` | 600 XP | economy.ts | XP to reach level 4 | +300 XP from L3 |
| `LEVEL_THRESHOLDS[5]` | 1000 XP | economy.ts | XP to reach level 5 | +400 XP from L4; max defined level |

### 7i. Kennel (`src/core/kennel.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Treats Pouch `cost` | 100 coins | kennel.ts | Price of the first kennel upgrade | |
| Treats Pouch `payoutMultiplier` | 1.2× | kennel.ts | Multiplies mastery payout while owned | +20% |
| Pro Clicker `cost` | 250 coins | kennel.ts | Price of second kennel upgrade | |
| Pro Clicker `payoutMultiplier` | 1.5× | kennel.ts | Multiplies mastery payout while owned | +50% |
| Training Dummy `cost` | 500 coins | kennel.ts | Price of third kennel upgrade | |
| Training Dummy `payoutMultiplier` | 2.0× | kennel.ts | Multiplies mastery payout while owned | +100% |
| `IDLE_RATE_PER_MS` | 0.001 coins/ms | kennel.ts | Coins earned per millisecond while idle (= 1 coin/second) | |
| `IDLE_CAP_COINS` | 110 coins | kennel.ts | Maximum coins claimable on return from idle | **APPLIED §7n** |

### 7j. Phrases (`src/core/phrases.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| BASE_PHRASE (`bra`) `windowBonusMs` | 0 ms | phrases.ts | Window expansion from using this phrase | Always available; no effect |
| BASE_PHRASE `rewardBonus` | 0.0 | phrases.ts | Additive reward fraction from using this phrase | |
| BASE_PHRASE `cooldownMs` | 0 ms | phrases.ts | Cooldown before phrase can fire again | No cooldown |
| FLINK_PHRASE `windowBonusMs` | 150 ms | phrases.ts | Scoring window expansion (±150 ms) | |
| FLINK_PHRASE `rewardBonus` | 0.1 | phrases.ts | +10% additive to reward | |
| FLINK_PHRASE `cooldownMs` | 8000 ms | phrases.ts | 8 s cooldown between uses | |
| FLINK_PHRASE `unlockCost` | 50 coins | phrases.ts | Shop price to unlock | |
| FLINK_PHRASE `unlockLevel` | 1 | phrases.ts | Minimum player level required | Available from level 1 |
| SUPER_PHRASE `windowBonusMs` | 250 ms | phrases.ts | ±250 ms window expansion | |
| SUPER_PHRASE `rewardBonus` | 0.2 | phrases.ts | +20% additive to reward | |
| SUPER_PHRASE `cooldownMs` | 12000 ms | phrases.ts | 12 s cooldown between uses | |
| SUPER_PHRASE `unlockCost` | 275 coins | phrases.ts | Shop price to unlock | **APPLIED §7n** |
| SUPER_PHRASE `unlockLevel` | 3 | phrases.ts | Requires player level 3 | Locks until 300 XP |

### 7k. Combo (`src/core/combo.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Combo increment formula | +1 per PERFECT/OK; 0 on MISS/FALSE | combo.ts | Combo counter per-tap | Resets on any non-hit |
| Combo multiplier formula | min(2, 1 + 0.1 × max(0, combo−1)) | combo.ts | Multiplier applied to positive learned-bar deltas | Caps at 2.0× |
| Combo cap (effective) | 2.0× at combo 11+ | combo.ts | Maximum combo bonus to learned-bar fill | Reached at combo count = 11 |

### 7l. Prestige (`src/core/prestige.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| `PRESTIGE_PER_GRADUATION` | 1 point | prestige.ts | Prestige points earned per dog graduation | |
| `prestigeMultiplier` formula | min(2.5, 1 + points × 0.1) | prestige.ts | Multiplies mastery payout coins and XP | Capped at 2.5× (15 prestige points) — **APPLIED §7n** |

### 7m. Onboarding Thresholds (`src/core/onboarding.ts`)

| Name | Value | File | What it affects | Note |
|---|---|---|---|---|
| Distractors revealed at | ≥1 mastered trick | onboarding.ts | When distractors appear in sessions | Also gates economy reveal |
| Economy revealed at | ≥1 mastered trick | onboarding.ts | When coin/XP display appears | Same threshold as distractors |
| Phrases revealed at | ≥2 mastered tricks | onboarding.ts | When phrase chip appears in HUD | |
| Kennel revealed at | ≥3 mastered tricks | onboarding.ts | When kennel shop becomes visible | |
| Difficulty revealed at | ≥3 mastered tricks | onboarding.ts | When difficulty selector appears | Same threshold as kennel |
| Untraining tricks revealed at | Never (v1) | onboarding.ts | When untrain tricks appear in trick-select | Controlled by `untrainTricksUnlocked()` predicate; always returns `false` for v1 |

### 7m-untrain. Untraining Gate — DECIDED (2026-06-17)

**Untraining is gated off for v1** per specs.md (post-v1 later addition, onboarding depth). The v1 build never surfaces untrain tricks in the trick-select, preventing onboarding confusion on a fresh player who sees "Ikke hopp" with no context.

- **Gate location:** `src/core/onboarding.ts`, `untrainTricksUnlocked(masteredCount: number)` — a pure, tested predicate.
- **Current behavior:** always returns `false` (v1: never unlock).
- **Post-v1 unlock condition:** when untraining is formally introduced, flip the condition in `untrainTricksUnlocked()` to a real threshold (e.g. `masteredCount >= N` or a flag from a deeper onboarding stage). This is a one-line, tested change.
- **Untrain mechanic code (dormant):** `untrainAttemptAt`, misbehaving visual state, scheduler untrain constants remain in the codebase (not deleted) — they are the post-v1 implementation, just not surfaced. No behavioral impact on v1 play.
- **Wire point:** `src/main.ts`, `getTricks()` — queries the gate before appending `UNTRAIN_TRICKS` to the trick list.

---

### 7n. Balance Sanity-Check (2026-06-14 audit — findings only, no code changes)

#### Mastery Reachability

With PERFECT delta = +8 and bar range 0–100, a player needs **13 perfect taps** to
reach 100 (13 × 8 = 104, capped at 100). A combo multiplier can halve this further.
At an attempt interval of 2 s, 13 perfect taps take under 30 seconds of wall time —
provided every tap is perfect. In practice (mix of OK and MISS) with NORMAL Sitt
(learnMult = 1), a realistic session converges to around 30–60 s, which is
**reasonable for a short-session mobile game**.

For Legg deg on EXPERT, however: EXPERT PERFECT delta = 8 × learnMult 0.5 = 4,
window 160 × 0.6 = 96 ms with peakRadius 25 × 0.6 = 15 ms. Reaching 100 requires
25 perfect taps in a 96 ms window (a 15 ms PERFECT band). That is near-frame-perfect
timing. **Flagged: Legg deg + EXPERT stacks two penalties (learnMult 0.5 × harder
window) without a corresponding reward multiplier bonus for the trick itself, making
this combination extremely grindy.**

#### Economy Progression vs Costs

Mastery payout at NORMAL, no upgrades, no prestige: 50 coins, 30 XP.

Kennel costs: 100, 250, 500 (total 850 coins). To buy all three, at 50 coins/mastery,
a player needs **17 masteries** (3–4 tricks × repeatable via prestige). Across 4
tricks this is roughly 4–5 graduation cycles. This is on the **grindy side** for a
mobile casual game; the Treats Pouch at 100 coins (2 masteries) is accessible, but
the Training Dummy at 500 (10 masteries) may feel very far away without HARD/EXPERT
play.

Adopt costs (200, 150, 300) are reachable in 4–6 masteries each at NORMAL. The Husky
at 300 coins is attainable in under a dozen sessions — reasonable.

Phrase costs (50, 150) are fast. FLINK at 50 coins = 1 mastery; SUPER at 150 = 3.
**These are very cheap and will be unlocked within the first two play sessions —
consider raising SUPER to 250–300 if the level-3 gate is meant to be a meaningful
filter.**

Level thresholds vs mastery XP (30 base at NORMAL): level 2 at 100 XP = ~3–4
masteries; level 3 at 300 XP = ~10 total. The SUPER phrase gate (level 3 + 150 coins)
is the most significant checkpoint, but 10 masteries is reachable in a couple of
sessions. **The level table only defines 5 levels (up to 1000 XP = ~33 NORMAL
masteries); there is no defined content beyond level 5.** Flag as a gap.

#### Difficulty EV (Expected Value Analysis)

At NORMAL (no false marks): perfect 13 taps → 50 coins.
At HARD (FALSE_MARK −8, distractors 45%, window 280 ms, mult 1.5×):
  Payout if mastered: 50 × 1.5 = 75 coins.
  Cost: tighter window + more distractors increase false-mark exposure.
  EV is positive for skilled players: the 50% payout premium more than offsets the
  penalty risk for a player landing PERFECT most of the time.

At EXPERT (FALSE_MARK −14, distractors 70%, window 160 ms, mult 2.5×):
  Payout if mastered: 50 × 2.5 = 125 coins.
  Cost: a single false mark sets the bar back 14 points (nearly two perfects). With
  70% distractor rate, false marks are frequent. A player who cannot maintain near-
  perfect accuracy on a 160 ms window will regress indefinitely. **Flagged: EXPERT
  may be EV-negative for average players — not "harder but worth it" but just
  punishing. Recommend softening EXPERT FALSE_MARK to −10 (from −14) and/or
  reducing distractorRate to 0.55 (from 0.7) as starting points.**

HARD remains the most EV-positive difficulty for the majority of players (big reward
with a manageable penalty). NORMAL and EXPERT could end up dominated: NORMAL because
HARD is strictly better for any competent player; EXPERT because the EV goes negative
for all but the most precise players. **Recommendation: tighten HARD's reward to
1.3× and relax EXPERT's false-mark penalty to −10 so there is a smooth skill
gradient rather than a cliff.**

#### Idle Cap vs Typical Session Payout

Idle rate: 1 coin/second. Idle cap: 200 coins.
Cap reached after 200 seconds (3 min 20 s) of idle time.
Typical active session at NORMAL: ~50 coins per mastery; a 10-minute session might
yield 2–3 masteries = 100–150 coins.
**The idle cap (200) slightly exceeds one medium active session (100–150 coins),
which risks making idle income feel competitive with active play, undermining the
"nudge not replacement" goal. Recommend lowering IDLE_CAP_COINS to 100–120.**

#### Combo / Prestige Runaway Check

Combo: capped at 2.0× (reached at combo count 11). No runaway risk.

Prestige: `1 + points × 0.1` — linear, **unbounded**. At 10 prestige points the
multiplier is 2.0×; at 20 points it is 3.0×; at 50 it is 6.0×. Because graduation
costs remastering all 3 STARTER_TRICKS per dog, each prestige point requires
substantial work, but the multiplier will eventually trivialize all content.
**Recommendation: cap `prestigeMultiplier` at 2.5× (25 prestige points) or switch
to a diminishing-returns formula such as `1 + log(1 + points) × 0.5`.**

#### Summary of Recommended Number Changes (iteration 11 audit; 6 of 7 APPLIED in iteration 12)

| Item | Old | New | Reason | Status |
|---|---|---|---|---|
| EXPERT `FALSE_MARK` delta | −14 | −10 | EV goes negative; too punishing vs reward | **APPLIED** |
| EXPERT `distractorRate` | 0.7 | 0.55 | Combined with tight window makes mastery near-impossible for average players | **APPLIED** |
| HARD `rewardMultiplier` | 1.5× | 1.3× | HARD currently dominates NORMAL in EV; gap should be smaller | **APPLIED** |
| `IDLE_CAP_COINS` | 200 | 110 | Cap exceeds a medium active session; undermines "nudge not replacement" | **APPLIED** |
| SUPER phrase `unlockCost` | 150 | 275 | Unlocked too quickly; level-3 gate loses meaning | **APPLIED** |
| `prestigeMultiplier` | unbounded linear | cap at 2.5× | Unbounded growth trivializes late content | **APPLIED** |
| Legg deg on EXPERT | (stacked penalty) | Exclude trick×mode combinations with effective learnMult × peakRadius &lt; 10 ms from the reward path | Near-impossible timing without trick-specific reward uplift | Deferred |

## 10. Level-Gated Unlock Ladder (Placeholder Tuning) — DECIDED

Two-step gate: **level makes content purchasable; coins purchase it** (specs.md §Economy & Progression).
`isTierUnlocked(level, requiredLevel)` is the single primitive for both phrases and breeds.

### Phrase `unlockLevel` (in `PHRASE_CATALOG`)

| Phrase | `unlockLevel` | `unlockCost` |
|--------|--------------|--------------|
| bra (base) | 1 | 0 (free) |
| flink | 1 | 50 |
| dyktig | 2 | 175 |
| super | 3 | 275 |
| kjempebra | 4 | 450 |

### Breed `requiredLevel` (in `BREED_CATALOG`)

| Breed | `requiredLevel` | `adoptCost` |
|-------|----------------|-------------|
| Labrador (starter) | 1 | 0 (given) |
| Bulldog | 2 | 150 |
| Border Collie | 3 | 200 |
| Puddel | 4 | 225 |
| Husky | 5 | 300 |

### Gate legibility — adopt panel mirrors phrase loadout (2026-06-17, task 072)

For the two-step model to *read* as designed, the player must see **which** gate
blocks them. The phrase loadout already distinguishes this via
`getLoadoutState().nextLockedIsLevelGated` (shows `Lvl N` instead of a coin price).
The adopt panel now mirrors it: `getAdoptableBreeds()` returns a display-only
`levelGated` flag (`isBreedLevelLocked(breed, level)` = `!isTierUnlocked(...)`), and a
level-locked breed renders a `Lvl N` badge + `level-locked` class + "reach level N to
unlock" aria-label instead of the coin-shortage styling. `canAdopt` stays the single
authoritative purchase gate; `levelGated` never relaxes it. This prevents a low-level
player from grinding coins pointlessly for a breed they cannot yet adopt.

## Re-Practice Payout — DECIDED (2026-06-17)

**`PRACTICE_BASE_PAYOUT = { coins: 15, xp: 0 }`** (vs `MASTERY_BASE_PAYOUT = { coins: 50, xp: 30 }`).

When a round completes on a trick the active dog had **already mastered** before the round started, `completePractice` is called instead of `completeMastery`. The same difficulty × kennel × prestige multiplier stack applies to whichever base is used.

**No XP on re-practice.** XP is the skill-gated progression currency (specs.md §Economy); granting it on re-practice would let players farm levels by grinding easy known tricks, bypassing the two-step unlock (task 069). The reduced coin payout serves as the **anti-softlock income floor** (specs.md:108–109): even when nothing new is affordable, a player can always re-practice for coins.

The `wasAlreadyMastered` flag is captured in `onSelectTrick` (before `startFreshRound` / `recordMastery` fires) so the branch at the mastery edge reads the pre-round state.

These are placeholder values for v1 — the progression feel should be validated in playtesting and adjusted via the tuning table above.

## Mark SFX — Layered Click + Clip-Fallback Policy — DECIDED (2026-06-17, task 074)

**The mark sound is two layers: a short square-wave click transient + a sine praise tone.**

Click envelope (shared across PERFECT and OK):
- `freq: 2000 Hz`, `type: 'square'`, `durationMs: 12`, `gain: 0.35`
- MISS uses the same click at `gain: 0.12` (subtle; no praise tone).
- FALSE_MARK bypasses the click entirely: `freq: 180 Hz`, `type: 'sawtooth'`, `durationMs: 90`, `gain: 0.5` — the existing low negative buzz character is preserved.

Praise tone gains (layered after the click):
- PERFECT: `gain: 0.9`, `freq: 880 Hz`, `durationMs: 140`
- OK: `gain: 0.5`, `freq: 660 Hz`, `durationMs: 120`

**Clip-fallback policy:** `MarkAudio.registerClip(cue, buffer)` registers an `AudioBuffer` keyed by result string (e.g. `'PERFECT'`). `play(result)` checks `shouldUseClip(result, clips)` — if a buffer is registered for that exact cue it plays via `playBuffer` (a thin `BufferSourceNode → GainNode → destination` chain); otherwise it synthesizes the layered `SoundSpec[]` from `markLayers()`. This makes the engine voice-ready: drop in a clip and the synth fallback is bypassed automatically, with no call-site changes.

**Voice sourcing remains the open §4 decision.** The intended clip is a Maren-style Norwegian "bra!" marker voice. Its sourcing — recorded original / licensed / TTS — carries likeness/legal weight and is not decided here. The `registerClip` path is the future hook for that asset.

## Mobile Resume Grace — DECIDED (2026-06-17, task 073)

**`RESUME_GRACE_MS = 400`** (`src/core/resumeGrace.ts`).

Spec (specs.md §Mistakes → Mobile grace) requires that taps in the brief moment
after the app resumes from background are ignored, so a notification, lock, or
fat-finger never triggers a false mark / confuse. `main.ts` stamps `resumedAt =
performance.now()` on every `visibilitychange → visible`, and `onBraTap` returns
silently (no classify / applyMark / audio / scene notify) when
`isWithinResumeGrace(now, resumedAt, RESUME_GRACE_MS)`.

**Why 400 ms:** long enough to swallow the stray tap that dismisses a notification
or wakes the screen, short enough to be invisible in normal play (well below a
deliberate reaction tap, ~250–500 ms). The window is **half-open** — a tap exactly
400 ms after resume is allowed — and `resumedAt` starts at `-Infinity` so the first
taps of a fresh session are never eaten. Placeholder value; a one-line tuning knob.

We deliberately do **not** pause the round timeline on background: the loop time base
is `performance.now()` and the scheduler loops, so swallowing the resume tap (what the
spec mandates) is sufficient. Timeline pause is out of scope.
