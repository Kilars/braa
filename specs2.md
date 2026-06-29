# Bra! — Specification v2 (User Stories, Phased)

> This is a **functional** rewrite of [specs.md](https://github.com/Kilars/braa/blob/deprecated-game/.docs/specs.md) as **user stories
> grouped into delivery phases**. It says *what the game is and how it plays*,
> sliced so each phase ships something coherent and playable. Technical decisions
> (engine, stack, asset pipeline) live in the [ADRs](adr/).
> The concrete **content** these stories operate on — which breeds, tricks, and
> scenarios exist — lives in [content-catalog.md](https://github.com/Kilars/braa/blob/deprecated-game/.docs/content-catalog.md); stories
> here reference its IDs.
>
> **Format:** every item is a user story —
> *As a [role], I want [capability], so that [benefit]* — with acceptance
> criteria. Feature stories use the **player** role; decisions that can't be
> defaulted use a **product-owner** role; constraints that apply everywhere use a
> player role too (see Cross-cutting).
>
> **Phasing rule:** every phase ends on something you can *play and look at*, not
> a half-wired system. **Phase 1 is the whole bet** — the core "mark the moment"
> verb, made genuinely good, on one trick. Nothing past Phase 1 starts until
> Phase 1 passes its Visual Review and is bug-free.

---

## North Star

- **NS-1 — The one good moment.**
  *As a player, I want to watch a dog, wait for the exact instant it sits, and tap
  **BRA** to a payoff of voice + sound + the dog's reaction all landing on the
  beat, so that I immediately want to do it again.*
  Acceptance:
  - Every later story serves this moment; anything that doesn't is out of scope.

---

## Phase 1 — MVP: the perfect single mark *(the only thing that matters right now)*

**Goal:** one page. A good-looking dog does a **Sitt** (sit), cleanly animated and
bug-free; you tap **BRA** at the apex, a Maren-style "Bra!" plays, and the timing
feedback is crisp and fair.

- **P1-0 — Tight scope.**
  *As the product owner, I want Phase 1 to contain nothing but the polished single
  mark, so that we prove the core feel before building anything on top.*
  Acceptance:
  - Explicitly OUT: learned bar / mastery, coins / XP / levels, other tricks,
    distractors, confuse / penalty, breeds / roster, kennel, phrases, menus,
    difficulty modes, save. Just the loop below, polished.

- **P1-1 — A dog worth looking at.**
  *As a player, I want to open the app to a single, clearly-recognizable dog
  centered on a clean, bright scene, so that the dog is the focus from the first
  second.*
  Acceptance:
  - One dog, centered and fully in frame in portrait, anchored by a contact
    shadow (not floating). (D1, D12)
  - Reads immediately as a real dog — clear silhouette: head, ears, snout, body,
    four legs, tail. **No bare primitive geometry** (capsule/sphere/cylinder),
    *not even for a frame on load* — hold hidden / neutral until the model is
    ready, then fade in. (D1, D14, PO-Bugfix-1)
  - Bright, clean, Pokémon-GO-style backdrop; the dog reads clearly against it.
  - No second "primitive placeholder" dog ever appears.

- **P1-2 — Alive at rest (idle).**
  *As a player, I want the dog to look alive but calm between sits, so that it
  never feels frozen or dead.*
  Acceptance:
  - Ambient idle motion (breathing, small look-around / tail) on a loop. (D4)
  - Dog stays centered in the idle pose (no drift to the right edge). (D12,
    PO-Change-3)
  - Animation is smooth and seamless — no T-pose snap, no jitter, no popping
    between loop boundaries.

- **P1-3 — A legible sit with a clear apex.**
  *As a player, I want to watch the dog build into a sit and see the exact instant
  it is fully sitting, so that I can mark off the dog itself — not just the UI.*
  Acceptance:
  - The dog plays a **distinct sit animation** that builds to a **clear apex** —
    the fully-seated instant — readable on the dog. (D6, D11)
  - The sit pose is unmistakably a *sit* (not a generic idle).
  - Animation is clean: no foot-sliding, no clipping through the ground, no
    snapping.

- **P1-4 — The apex tell.**
  *As a player, I want a subtle, fair "now" signal at the apex, so that timing is
  a skill I can read, not a guess.*
  Acceptance:
  - A subtle visual tell (soft pulse/ring/glow) fires at the apex — on the BRA
    marker and/or the dog. (Spec "subtle visual tell")
  - The tell is honest: it marks the *actual* scoring peak, not slightly
    before/after it.
  - The tell never fires when there's nothing to mark (in Phase 1, the dog is
    always either idle or sitting; the tell appears only on the sit apex).

- **P1-5 — The BRA tap.**
  *As a player, I want one big BRA marker to mark the moment, so that the whole
  game is one satisfying verb.*
  Acceptance:
  - One large, thumb-friendly **BRA** button, reachable in portrait. (One verb)
  - Tap scores by closeness to the apex: **PERFECT** (on the apex band),
    **OK** (inside the window, off-peak), **Miss** (just outside an active sit's
    window — no penalty). (Tap tiers)
  - In Phase 1 there is no false-mark penalty yet (no confuse system) — a tap with
    no window open simply does nothing.

- **P1-6 — The mark feels good (sound + reaction).**
  *As a player, I want every successful BRA to give me voice + sound + a dog
  reaction on the beat, so that the mark is the payoff.*
  Acceptance:
  - A warm, Maren-style spoken **"Bra!"** plays on a successful mark (placeholder
    TTS acceptable for Phase 1; real Maren voice is the later owner-gated drop-in
    under the same cue). (Audio)
  - A crisp UI click sits under the voice. (Mark SFX)
  - PERFECT sounds/feels brighter than OK.
  - The dog gives a clearly positive reaction (perk-up / bounce / tail wag) on a
    successful mark. (D8)
  - Audio is gated correctly: nothing plays on a Miss / dead tap.

- **P1-7 — Honest timing feedback.**
  *As a player, I want to instantly see how good my tap was, so that I learn the
  timing.*
  Acceptance:
  - Clear on-screen tier feedback per tap: **PERFECT / OK / MISS**.
  - Feedback is immediate (lands on `pointerup`, never a frame late) and never
    contradicts the audio.

- **P1-8 — Reduced motion respected.**
  *As a motion-sensitive player, I want every cue to still come through (just
  calmer) with `prefers-reduced-motion` on, so that the game stays playable and
  readable for me.*
  Acceptance:
  - Idle / apex / reaction cues are **dampened, not removed** — the sit, the apex,
    and the happy reaction are all still distinguishable by pose. (D13)

- **P1-9 — It just works (no bugs).**
  *As a player, I want the one page to never glitch, so that the core feels
  finished.*
  Acceptance:
  - No primitive-blob flash, no T-pose, no floating/clipping dog, no off-center
    drift, no stuck animation state, no audio that fires on the wrong event.
  - The loop (idle → sit → apex tell → tap → reaction → back to idle) repeats
    indefinitely without degrading.

- **P1-10 — Phase 1 is provably done.**
  *As the product owner, I want a hard done-gate, so that "it compiles" can't be
  mistaken for "it's good."*
  Acceptance — on a real phone-portrait viewport (e.g. 390×844):
  1. All P1 stories pass their acceptance criteria.
  2. The **`polish`** skill has been run on the visual work.
  3. **Independent review agents** confirm on the running app that the dog reads,
     the sit + apex are legible, the mark feels good, and there are no visual bugs
     (Visual Review gate in [CLAUDE.md](https://github.com/Kilars/braa/blob/deprecated-game/.claude/CLAUDE.md)).
  4. Game logic (timing/scoring, apex windowing) is covered **test-first** per the
     `tdd` requirement.

---

## Phase 2 — More tricks, same quality bar

**Goal:** the player can select and teach **more tricks**, each at the **exact
Phase-1 Sitt standard**. Breadth of tricks, zero drop in polish.

- **P2-1 — Pick a trick.**
  *As a player, I want to choose which trick to train from a small, clear
  selector, so that I can grow a dog's repertoire without the game becoming
  busy.*
  Acceptance:
  - Selector stays one-page, portrait, one-verb — it is **not** a second gameplay
    verb during the round.

- **P2-2 — Each trick has its own clean, distinct animation.**
  *As a player, I want every trick to visibly perform its **specific** behavior
  with a clear apex, so that reading the behavior is part of the skill.*
  Acceptance:
  - Never one generic pose reused. Starter set: **Sitt**, **Ligg** (lie down),
    **Legg deg** (settle), then expand (e.g. **Gi labb** [shake], **Rull** [roll
    over], **Snurr** [spin]).
  - The lie-down tricks read as **down**, clearly different from sit. (D6, D11,
    PO-Improvement-1)

- **P2-3 — Same polish gate per trick.**
  *As a player, I want every new trick to be as bug-free and satisfying as Sitt,
  so that quality never drops as the roster grows.*
  Acceptance:
  - No foot-sliding, clipping, snapping, or T-pose; smooth loops; honest apex
    tell; the mark feels good.
  - **Each trick passes its own Visual Review** before it counts as done.

- **P2-4 — Feel the dog learning.**
  *As a player, I want well-timed BRAs to fill a "learned" bar that reaches
  mastery, so that training a trick has a beginning, middle, and a satisfying
  end.*
  Acceptance:
  - PERFECT fills more than OK; the bar only ever stalls — **no fail state**.
  - 100% masters the trick with a celebratory beat; mastered tricks are
    re-practiceable. (Training Sessions, Mastery)

- **P2-5 — Leave and come back.**
  *As a player, I want to pause or quit and return with my per-trick progress
  intact, so that the game is snackable.*
  Acceptance:
  - Per-trick learned progress persists (introduces IndexedDB save).
  - Pause/resume supported; no timer forces play. (Round States)

- **P2-6 — Mashing should lose (light, secondary).**
  *As a player, I want tapping with nothing to mark to be gently discouraged, so
  that patience beats spamming even before full difficulty exists.*
  Acceptance:
  - Light false-mark/confuse + distractors ride along as the bar gains stakes, but
    stay **secondary** to nailing clean tricks — keep minimal until the roster
    feels good. (Mistakes — fuller treatment folded into Phase 4.)

---

## Phase 3 — Dog breeds (races), each with its own tricks  *(needs further spec)*

**Goal:** the player can select different real **breeds**, each with its **own
tricks / signature behaviors** and its own feel.

> ⚠️ Provisional. The owner-decision stories below must be resolved before this
> phase is sliced for build.

### Player stories (provisional)

- **P3-1 — Choose a breed.**
  *As a player, I want to pick which dog I'm training, so that I can collect and
  train different breeds.*
  Acceptance:
  - The dog reads **clearly as that real breed** at phone size — silhouette,
    proportions, coat, color. (D2)

- **P3-2 — Breeds bring different tricks.**
  *As a player, I want different breeds to open different / signature tricks, so
  that collecting breeds is also collecting moves.*
  Acceptance:
  - Each breed exposes a trick list that is not identical to every other breed's.

- **P3-3 — Breeds feel different to train.**
  *As a player, I want each breed's personality to change how it trains, so that
  breeds are deep kits, not skins.*
  Acceptance:
  - Personality drives the difficulty levers (learn speed, distractibility,
    window stability, energy). (Breeds)

- **P3-4 — Persistent, showcased roster.**
  *As a player, I want my dogs to persist across sessions and be shown off, so
  that they feel like collected units I'm proud of.*
  Acceptance:
  - A dog keeps a consistent appearance across rounds/sessions. (D3)
  - On the select screen the dog is bright/spotlit, not buried in shadow.
    (PO-Improvement-2)

### Owner-decision stories (resolve before building)

- **P3-D1 — Which breeds ship first.**
  *As the product owner, I want to fix the launch breed set, so that art and trick
  lists are bounded.*
  Acceptance:
  - Decision recorded. Proposed default: the four the licensed pack covers —
    **Labrador, Border Collie, French Bulldog, Husky** (no Poodle).

- **P3-D2 — Universal vs. signature tricks.**
  *As the product owner, I want to decide which tricks every breed knows vs. which
  are breed-exclusive, so that the trick catalog is scoped per breed.*
  Acceptance:
  - Decision recorded. Proposed default: shared core (Sitt/Ligg/Legg deg) + 1–2
    signature tricks per breed.

- **P3-D3 — How breeds are acquired. ✅ DECIDED: unlock via a light economy.**
  *As a player, I want to unlock/adopt new breeds with earned currency, so that
  collecting dogs is a goal I work toward.*
  Acceptance:
  - **Decision (owner):** breeds **unlock via a light economy** — not free-select.
  - Phase 3 therefore **pulls a light economy forward**: master tricks → earn
    coins (and a level gate where it fits the two-step "level unlocks, coins buy"
    model); spend to adopt a breed.
  - Keep it light — only as much economy as adopting breeds needs; the full
    economy/kennel depth stays parked (B-1).
  - The adopt UI shows the coin price + a clear locked state and a breed thumbnail
    so the collection axis is visible. (PO-Improvement-4)

- **P3-D4 — Per-breed animation coverage.**
  *As the product owner, I want to confirm each breed has clean clips for its
  trick list before committing it, so that we never promise a trick the rig can't
  perform.*
  Acceptance:
  - Clip coverage confirmed per breed × trick at Phase-1 quality before the list
    is locked (the pack ships shared clips, but signature tricks may not exist).

---

## Phase 4 — Difficulty

**Goal:** the player can change difficulty, trading challenge for reward.

- **P4-1 — Choose how hard.**
  *As a player, I want to set Normal / Hard / Expert, so that the game matches my
  skill.*
  Acceptance:
  - A single global setting applied to all training. (Difficulty Modes)

- **P4-2 — Higher difficulty changes the read.**
  *As a player, I want harder modes to genuinely demand more, so that difficulty
  is real, not cosmetic.*
  Acceptance:
  - Higher = tighter window, fainter & faster apex tell, more distractors, and a
    harsher false-mark penalty (the fuller Mistakes/confuse model lands here).
    (Difficulty, Mistakes, D7, D9)

- **P4-3 — Pain pays.**
  *As a player, I want harder modes to reward more, so that opting into difficulty
  is worth it.*
  Acceptance:
  - Higher difficulty raises rewards so each mode is the rational choice at a
    different skill level. (Difficulty)

- **P4-4 — Stacks with the breed.**
  *As a player, I want difficulty to combine with the breed's nature, so that a
  stubborn breed on Expert is the real wall.*
  Acceptance:
  - Effective difficulty = global mode × breed intrinsic. (Breeds)

- **P4-5 — Background grace.**
  *As a player, I want taps right after the app resumes from background to be
  ignored, so that a notification or lock never causes a false mark.* (Mistakes)

---

## Phase 5 — Better marker words (collectible "bra" phrases)

**Goal:** the player unlocks alternative, more-effective Norwegian marker words —
*dyktig, flink, super, kjempebra* — beyond base **bra**.

- **P5-1 — Unlock new words.**
  *As a player, I want to progressively unlock new marker words, so that the
  praise has variety and collection value.*
  Acceptance:
  - Each new word has its own voiced line in the Maren delivery. (Phrases, Audio)

- **P5-2 — Stronger words, real trade-off.**
  *As a player, I want better words to be more effective but constrained, so that
  loading one is a genuine choice, not an obvious upgrade.*
  Acceptance:
  - Stronger = wider window / bonus, but with a **cooldown / downside**; base
    "bra" is always the default with no cooldown. (Phrases)

- **P5-3 — The word pops on screen.**
  *As a player, I want the marker word to visibly pop / float on screen on a
  successful mark, so that the praise lands harder and I can see which word
  fired.*
  Acceptance:
  - Big, juicy, on-beat word burst (working idea: floats up from the BRA button).
    *Visual treatment open.*

- **P5-4 — Load without a second verb.**
  *As a player, I want to load/swap the active word outside the tap, so that the
  round stays one tap.*
  Acceptance:
  - Selection via chip cycle or swipe the BRA marker — never an extra in-round
    button. (Phrases)

---

## Phase 6 — Play mode  *(the learning-technique phase — needs further spec)*

**Goal:** add a **chaotic free Play mode** (toys, praise, petting) that **bonds
the dog and significantly boosts learning**. This turns "tap the apex" into "train
a dog."

> ⚠️ Provisional. The owner-decision stories below must be resolved before build.

### 6a — Shaping / steps  🚩 FLAGGED FOR LATER (owner: defer)

> **Decision (owner): shaping of tricks is deferred — flagged for later, not in
> this phase.** Captured here so the design isn't lost; do **not** build it as
> part of Phase 6. Revisit after Play mode (6b) lands. (Also parked: see B-5.)

- **P6-1 — Teach a trick in steps.** *(deferred)*
  *As a player, I want a complex trick broken into markable sub-steps I master in
  order, so that I learn (and the dog "learns") it the real, gradual way.*
  Acceptance:
  - Example — **Legg deg**: step 1 = **step onto the bed/mat** (not lying down
    yet), step 2 = lower the front, step 3 = full settle.
  - Each step is its own behavior with its own apex and learned bar; mastering a
    step unlocks the next.

- **P6-2 — Steps can use props / scenarios.** *(deferred)*
  *As a player, I want steps to introduce a prop the behavior references, so that
  shaping feels concrete and the scene evolves with the trick.*
  Acceptance:
  - E.g. a **dog bed/mat** for *Legg deg*, a cone, a target; the scene gains the
    object for that trick.

#### Owner-decision stories *(deferred with shaping — resolve when un-parked)*

- **P6-D1 — Do steps need their own animations?**
  *As the product owner, I want the per-step animation cost confirmed, so that we
  don't commit to shaping the rig can't render cleanly.*
  Acceptance:
  - Likely **yes** — each step is a distinct pose/motion (stepping onto a bed is
    locomotion, not the final down); movement must be clean (no foot-slide/clip).
  - Confirm the rig has — or can get — clips per step, or design steps around
    clips we have. This is the phase's main cost/risk.

- **P6-D2 — All tricks, or only some?**
  *As the product owner, I want to decide which tricks get steps, so that shaping
  feels earned, not bolted onto everything.*
  Acceptance:
  - Decision recorded. Proposed default: **only some** — positional/compound
    tricks (Legg deg, Rull, Dau) earn steps; atomic tricks (Sitt, Snurr) stay
    single-step.

- **P6-D3 — How granular?**
  *As the product owner, I want a step-count ceiling, so that shaping teaches the
  idea without dragging.*
  Acceptance:
  - Proposed default: 2–3 steps max per trick to start. Tunable.

### 6b — Play mode (engagement → faster learning)

- **P6-3 — Go chaotic with the dog.**
  *As a player, I want a free Play mode where I interact loosely, so that I get
  joyful, unstructured time with my dog as a counterpoint to precise training.*
  Acceptance:
  - Throw toys, pet, praise ("flink gutt!"), tug, pet "aggressively" — many
    tappable things at once, deliberately the opposite of the single-tap training.
  - Reads as joyful and a little unhinged.

- **P6-4 — Play builds bond; bond boosts learning.**
  *As a player, I want playing to significantly speed up later training, so that
  building the relationship pays off (as in real training).*
  Acceptance:
  - Play raises the dog's engagement/bond, which increases learn-speed / mood on
    subsequent training.

#### Owner-decision stories (resolve before building)

- **P6-D4 — How Play feeds learning.**
  *As the product owner, I want the play→learning mechanic defined and tuned, so
  that Play is a meaningful carrot, not a token.*
  Acceptance:
  - Decision recorded. Proposed default: a **bond meter** that decays slowly and
    grants a learn-speed multiplier — play to top it up. Needs tuning.

- **P6-D5 — Play animation scope.**
  *As the product owner, I want the Play clip set bounded, so that the animation
  cost is known.*
  Acceptance:
  - Confirm coverage (fetch, tug, roll, get-pet, zoomies); reuse existing pack
    clips where possible.

---

## Phase 7 — Training-page visual enhancement (juice & ambiance)

**Goal:** lift the **training page** above its Phase-1 baseline — a more alive,
beautiful, satisfying scene. Phase 1 makes it *clean and bug-free*; Phase 7 makes
it *gorgeous*. This is pure enhancement: it must never regress the legibility,
performance, or reduced-motion guarantees of the core loop.

> **Constraint (all stories):** stays within the mobile rendering budget (cheap backdrop, blob shadow, no
> heavy post-processing) and honors
> `prefers-reduced-motion` (X-5): every enhancement dampens, never removes
> readability or a state cue.

- **P7-1 — Juicier "Bra" wording.**
  *As a player, I want the marker word itself to look and move beautifully when it
  fires, so that the praise moment is a visual treat, not just text.*
  Acceptance:
  - On-brand typography/styling for the word; a satisfying entrance (pop/scale,
    gentle float, fade) on each successful mark, brighter on PERFECT than OK.
  - Reinforces — does not clutter — the apex/score read; never blocks the dog.
  - Builds on P5-3 (the word *pop*); P5-3 introduces it, P7-1 polishes the feel.

- **P7-2 — Buttery animation smoothness.**
  *As a player, I want every transition between dog states to blend smoothly, so
  that the dog never snaps or pops between poses.*
  Acceptance:
  - Animation blending/cross-fade between idle ↔ offer ↔ trick ↔ apex ↔ reaction;
    eased timing, no hard cuts, no T-pose, no foot-slide.
  - Holds a steady frame rate on a mid-range phone; degrades gracefully, never
    janks the mark.

- **P7-3 — Lifelike dog movement.**
  *As a player, I want the dog to move with weight and personality, so that it
  feels like a real animal, not a clip player.*
  Acceptance:
  - Richer ambient/secondary motion (breathing, weight shift, ear/tail flicks,
    look-around, blink) layered over the base loops.
  - Movement reads natural (grounded contact, no float/slide); stays centered and
    framed (D12); dampened under reduced motion but still alive.

- **P7-4 — Dynamic sun / changing light.**
  *As a player, I want the scene's lighting to shift over time (sun moving,
  warm→cool, soft day cycle), so that the training ground feels alive and the page
  stays fresh across sessions.*
  Acceptance:
  - A subtle, cheap time-of-day / sun shift (light direction + color, sky tint,
    shadow warmth) — no per-frame shadow-map cost; reuse the gradient-backdrop
    approach.
  - Lighting never hurts the dog's read or breed legibility at any point in the
    cycle (D2, D14); keeps the bright, clean Pokémon-GO feel.

- **P7-5 — Living ambiance.**
  *As a player, I want gentle life in the scene around the dog, so that the
  training ground feels like a real place.*
  Acceptance:
  - Cheap ambient touches (subtle grass/foliage sway, occasional drifting
    particle/butterfly, soft cloud drift) — peripheral, never competing with the
    dog or the apex tell.
  - All ambiance pauses/calms under reduced motion; zero impact on tap timing.

- **P7-6 — Mark juice.**
  *As a player, I want a successful mark to feel physically satisfying on screen,
  so that "the mark always feels good" reaches its visual ceiling.*
  Acceptance:
  - Tasteful feedback on PERFECT (e.g. a soft burst/sparkle/ring, a tiny camera
    or dog pop), scaled down for OK, none on Miss.
  - Restrained — enhances the beat, never seizure-y; fully reduced-motion-safe.

- **P7-7 — No regression.**
  *As the product owner, I want Phase 7 gated by the same Visual Review + perf
  bar, so that "prettier" never costs us legibility, frame rate, or accessibility.*
  Acceptance:
  - Independent Visual Review on a 390×844 portrait viewport confirms the scene is
    more beautiful *and* every Phase-1 read/perf/reduced-motion guarantee still
    holds. (CLAUDE.md Visual Review gate)

---

## Beyond the phases (parked — preserved from the full vision, not yet scheduled)

Long-term target; slot once the phases above feel great.

- **B-1 — Economy & kennel depth.**
  *As a player, I want coins/XP/levels and a kennel idle/upgrade layer, so that
  unlocks, a capped idle trickle, and an upgrading backdrop give a gentle reason
  to return.*
  *(Note: Phases 3 & 5 may pull a* light *economy forward — decide per phase.)*

- **B-2 — Behavior chains / combos.**
  *As a player, I want to chain marks (sit → stay → heel) into advanced tricks, so
  that depth grows from sequencing the same one tap.*

- **B-3 — Untraining.**
  *As a player, I want to mark the **absence** of a bad habit, so that I get a new
  verb on the same tap and the "bully → best friend" arc. (D10)*

- **B-4 — Catalog-scale fidelity.**
  *As a player, I want the real Maren marker voice and bespoke per-breed signature
  animation at scale, so that the finished game fully sounds and looks like the
  show.* *(Owner/likeness-gated.)*

- **B-5 — Shaping / steps (deferred from Phase 6).**
  *As a player, I want complex tricks taught in markable steps with props/
  scenarios, so that training mirrors real successive-approximation technique.*
  *(Owner: flagged for later. Full design lives in Phase 6 §6a; revisit after Play
  mode lands.)*

---

## Cross-cutting (apply to every phase)

- **X-1 — Portrait phone only.**
  *As a player, I want the game built for one-hand portrait phone use, so that it
  fits how I actually play.* (No landscape/tablet/desktop.)

- **X-2 — One verb, always.**
  *As a player, I want depth to come from reading the dog, not from more buttons,
  so that the game stays a single satisfying tap.* (Design Principles)

- **X-3 — The mark always feels good.**
  *As a player, I want voice + SFX + dog reaction on every successful BRA, so that
  the payoff never gets stale.* (Design Principles)

- **X-4 — Reads first, looks the part.**
  *As a player, I want Pokémon-GO stylized-realism throughout, so that the dog
  always reads as a real dog and as its breed.* (D1–D2 and D4–D9 never waivable;
  D14)

- **X-5 — Reduced motion, never less information.**
  *As a motion-sensitive player, I want motion cues dampened but never removed, so
  that every state stays distinguishable for me.* (D13)

- **X-6 — Quality gates hold.**
  *As the product owner, I want every visual task closed by Visual Review and
  every piece of game logic gated by TDD, so that "it compiles / tests pass" is
  never mistaken for done.* (CLAUDE.md)

- **X-7 — Fully offline-capable.**
  *As a player, I want the whole game to run with no network after the first load
  — e.g. on a plane — with progress saved locally and no account or server, so
  that it just works anywhere.*
  Acceptance:
  - After first load, every phase is fully playable with the network off
    (airplane mode): no request blocks gameplay.
  - All assets (engine/WASM, model, audio) are cached on first load; saves are
    local (Godot `user://`, IndexedDB-backed on web). No backend.
  - *How* this is achieved rides on the engine/PWA decision (ADR-0001).

---

## Non-Goals (scope boundaries, not stories)

No landscape/desktop builds; no multiplayer/social; no monetization/IAP; the
kennel is **not** a standalone auto-training game (active timing stays the only
skill engine).

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the app, prunes what is now fixed, and
> lists concrete, buildable directives. The build loop turns these into tasks; this
> section is the only thing the PO pass touches.

### PO Review — 2026-06-28

Drove the **real Godot Web/PWA build** (local export of the licensed Labrador, served
over http) in a headless browser at 390×844, reading the live console for scored tiers
and analysing ~220 captured frames pixel-by-pixel. **Phase 1 is NOT done — it has open
visual defects, the most serious being that the apex tell never renders. Do not advance
to Phase 2; reopen Phase-1 work below.**

> Pruned the prior `2026-06-27` note: it described the **deprecated Babylon build**, not
> this one — it cited a CSS `--apex` variable and certified Phase-2 features (Ligg chip
> row, learned bar, IndexedDB persistence, pause/▶) that **do not exist** in the current
> Godot `main.gd`. None of Phase 2 is built; Phase 1 is the whole current scope.

**What holds up (re-verified live, keep it):**
- **Scoring is honest end to end.** 60 real BRA taps scored PERFECT / OK / MISS / DEAD;
  the bands match spec (PERFECT apex±80 ms, OK apex±200 ms), and a tap with no window
  open does nothing (P1-5/P1-7 logic). Console tiers never contradicted the readout.
- **The dog reads & the sit is legible.** Centered Labrador on a clean bright backdrop;
  the sit builds as one continuous fold to a clearly seated apex; head-top swings ~272 px
  between stand and seat, so the build→apex is readable on the dog (P1-1/P1-3).
- **The loop repeats** idle → sit → idle indefinitely with no console errors and no
  degradation across many cycles (P1-9).

#### Bugfixes

- **The apex tell never renders (P1-4 — blocker).** Across ~220 frames spanning many
  full sit cycles (apexes confirmed by the 272 px head-swing *and* by live PERFECT/OK
  scores), the warm-gold halo+ring (`ApexTellMarker`) **never appears** on or around the
  BRA marker: zero gold on the ring's left/right/bottom arcs in any frame, zero saturated
  gold anywhere near the marker. The same detector readily flags the dog's own tan paws,
  so the absence is real, not a capture gap. *Why it's wrong:* P1-4 is the core "now"
  cue — without it timing is a blind guess, not a readable skill, and the marker stays a
  dead gray slab through every apex. The unit tests pass (the `ApexTell` curve and
  `set_intensity` are correct) — this is a tests-green / pixels-wrong gap, exactly what
  the Visual Review gate exists to catch. *Good looks like:* on the running 390×844 web
  build a soft warm pulse is **clearly visible** ringing the BRA marker, building to a
  peak exactly at the seated apex and dark in idle — proven by a captured apex frame
  showing the gold ring. Suspects to check on the real canvas: `self_modulate` vs
  `modulate` on a custom `_draw`, the marker drawing *under* the opaque `Button`
  (z-order), or the marker rect not getting a size. Fix must be confirmed in pixels.

- **The dog floats — no contact shadow (P1-1).** In every pose (idle, build, seat,
  stand) the paws end against flat blue with nothing beneath, and the front paws dangle
  over the top of the BRA button. The `DirectionalLight3D` is created with shadows off
  and there is no blob/decal. *Why it's wrong:* P1-1 explicitly requires the dog
  "anchored by a contact shadow (not floating)"; floating breaks the grounded read and
  the Pokémon-GO look. *Good looks like:* a soft contact shadow under the feet (cheap
  blob decal or a ground plane catching the sun), present at idle and tracking the sit,
  so the dog clearly sits/stands *on* something.

- **Translucent "shell" artifacts on the dog body (P1-1 / P1-9).** Magnified, the
  Labrador shows semi-transparent ghost panels — a vertical see-through strip down the
  chest/belly and curved translucent surfaces across both flanks/haunches — present in
  every pose, idle and seated. They are geometric and consistent (not render noise),
  i.e. a model/material issue: a coat/fur shell (or duplicated mesh) importing as
  alpha-blended/two-sided instead of opaque. *Why it's wrong:* P1-1 wants a clean
  real-dog silhouette and P1-9 "no bugs"; the see-through flaps make the dog look broken.
  *Good looks like:* a solid, opaque coat with no see-through panels at any pose — set
  the offending surface(s) to opaque / cull backfaces (or drop the duplicate shell) in
  the import, confirmed by a magnified capture.

#### Improvements

- **Tier readout is too low-contrast to read (P1-7).** The PERFECT/OK/MISS word flashes
  at full opacity in the upper third, but OK (pale green) and especially MISS (light
  grey, `0.72`) sit at almost the same luminance as the bright-blue sky and are barely
  legible — "MISS" nearly disappears. It's a contrast problem, not opacity (captured
  well within the 0.6 s hold). *Good looks like:* a dark outline / drop-shadow (or
  higher-contrast fills) so every tier pops against the bright backdrop, PERFECT still
  the brightest — each word crisply readable at 390×844.

- **The "positive reaction" is a lone Bark and doesn't read as celebration (P1-6).**
  The licensed pack's only clip matching the reaction vocab is `Bark` (no
  wag/happy/excited/perk clip exists in the Labrador set), so a successful mark fires a
  single bark on a dog whose mouth is already open in idle — I could read no clear,
  joyful reaction in the post-mark frames; the dog just continued its stand/sit loop.
  Playing a (standing) Bark over the seated pose also risks a pose pop. *Good looks
  like:* a reaction that reads as joy at phone size — e.g. a small happy bounce/hop
  (the pack has `Jump_Place`/`JumpAir_low`) or a clear perk-up, blended cleanly from the
  seat with no snap, PERFECT brighter than OK — confirmed in a capture.

*Scope note: audio can't be heard in the headless harness, so the "Bra!" voice/SFX is
judged only as wired + gated (silent on MISS / dead tap) — worth an on-device listen
before final sign-off.*
