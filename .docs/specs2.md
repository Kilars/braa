# Bra! — Specification v2 (User Stories, Phased)

> This is a **functional** rewrite of [specs.md](specs.md) as **user stories
> grouped into delivery phases**. It says *what the game is and how it plays*,
> sliced so each phase ships something coherent and playable. Technical decisions
> (engine, stack, asset pipeline, tuning constants) still live in
> [CLAUDE.md](../.claude/CLAUDE.md) and [tech-decisions.md](tech-decisions.md).
>
> **Phasing rule:** every phase ends on something you can *play and look at*, not
> a half-wired system. **Phase 1 is the whole bet** — the core "mark the moment"
> verb, made genuinely good, on one trick. Nothing past Phase 1 starts until
> Phase 1 passes its Visual Review and is bug-free.

---

## The North Star (one sentence)

You watch a dog, wait for the exact instant it sits, tap **BRA**, and it feels so
good — voice, sound, and the dog's reaction all landing on the beat — that you
want to do it again.

---

## Phase 1 — MVP: the perfect single mark *(the only thing that matters right now)*

**Goal:** one page. A good-looking dog does a **Sitt** (sit). Clean animation, no
bugs. You tap **BRA** at the apex, a Maren-style "Bra!" plays, and the timing
feedback is crisp and fair. This is the whole game in miniature — if this isn't
fun, nothing else matters.

**Scope guardrails for Phase 1 — explicitly OUT:** no learned bar / mastery, no
coins / XP / levels, no other tricks, no distractors, no confuse/penalty, no
breeds/roster, no kennel, no phrases, no menus, no difficulty modes, no save.
Just the loop below, polished.

### Stories

- **P1-1 — A dog worth looking at.**
  *As a player, I open the app and see a single, clearly-recognizable dog
  centered on a clean, bright scene, so the dog is the focus from the first
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
  *As a player, between sits I see the dog looking alive but calm, so it never
  feels frozen or dead.*
  Acceptance:
  - Ambient idle motion (breathing, small look-around / tail) on a loop. (D4)
  - Dog stays centered in the idle pose (no drift to the right edge). (D12,
    PO-Change-3)
  - Animation is smooth and seamless — no T-pose snap, no jitter, no popping
    between loop boundaries.

- **P1-3 — A legible sit with a clear apex.**
  *As a player, I watch the dog build into a sit and can see the exact instant it
  is fully sitting, so I know when to mark off the dog itself — not just the UI.*
  Acceptance:
  - The dog plays a **distinct sit animation** that builds to a **clear apex** —
    the fully-seated instant — readable on the dog. (D6, D11)
  - The sit pose is unmistakably a *sit* (not a generic idle).
  - Animation is clean: no foot-sliding, no clipping through the ground, no
    snapping.

- **P1-4 — The apex tell.**
  *As a player, I get a subtle, fair "now" signal at the apex, so timing is a
  skill I can read, not a guess.*
  Acceptance:
  - A subtle visual tell (soft pulse/ring/glow) fires at the apex — on the BRA
    marker and/or the dog. (Spec "subtle visual tell")
  - The tell is honest: it marks the *actual* scoring peak, not slightly
    before/after it.
  - The tell never fires when there's nothing to mark (in Phase 1, the dog is
    always either idle or sitting; the tell appears only on the sit apex).

- **P1-5 — The BRA tap.**
  *As a player, I tap one big BRA marker to mark the moment, so the whole game is
  one satisfying verb.*
  Acceptance:
  - One large, thumb-friendly **BRA** button, reachable in portrait. (One verb)
  - Tap scores by closeness to the apex: **PERFECT** (on the apex band),
    **OK** (inside the window, off-peak), **Miss** (just outside an active sit's
    window — no penalty). (Tap tiers)
  - In Phase 1 there is no false-mark penalty yet (no confuse system) — a tap with
    no window open simply does nothing.

- **P1-6 — The mark feels good (sound + reaction).**
  *As a player, every successful BRA gives me voice + sound + a dog reaction on
  the beat, so the mark is the payoff.*
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
  *As a player, I instantly see how good my tap was, so I learn the timing.*
  Acceptance:
  - Clear on-screen tier feedback per tap: **PERFECT / OK / MISS**.
  - Feedback is immediate (lands on `pointerup`, never a frame late) and never
    contradicts the audio.

- **P1-8 — Reduced motion respected.**
  *As a motion-sensitive player, with `prefers-reduced-motion` on I still get
  every cue, just calmer, so the game stays playable and readable.*
  Acceptance:
  - Idle / apex / reaction cues are **dampened, not removed** — the sit, the apex,
    and the happy reaction are all still distinguishable by pose. (D13)

- **P1-9 — It just works (no bugs).**
  *As a player, the one page never glitches, so the core feels finished.*
  Acceptance:
  - No primitive-blob flash, no T-pose, no floating/clipping dog, no off-center
    drift, no stuck animation state, no audio that fires on the wrong event.
  - The loop (idle → sit → apex tell → tap → reaction → back to idle) repeats
    indefinitely without degrading.

### Phase 1 "Done" gate

Phase 1 is done **only** when, on a real phone-portrait viewport (e.g. 390×844):

1. All P1 stories pass their acceptance criteria.
2. The **`polish`** skill has been run on the visual work.
3. **Independent review agents** have looked at the running app and confirmed the
   dog reads, the sit + apex are legible, the mark feels good, and there are no
   visual bugs (per the Visual Review gate in [CLAUDE.md](../.claude/CLAUDE.md)).
4. Game-logic (timing/scoring, apex windowing) is covered **test-first** per the
   `tdd` requirement.

"It compiles / tests pass" is **not** done for Phase 1.

---

## Phase 2 — More tricks, same quality bar

**Goal:** the player can **select and teach more tricks**, each rendered to the
**exact same standard as the Phase-1 Sitt** — clean, distinct animation, legible
apex, no bugs. Breadth of tricks, zero drop in polish.

This phase also lands the supporting *round* mechanics the first extra trick needs
to be meaningful (a learned bar to fill, mastery, resumable progress) — but the
headline deliverable is **more good tricks**.

### Stories

- **P2-1 — Pick a trick.** *As a player, I can choose which trick to train from a
  small, clear selector,* staying in the one-page, portrait, one-verb feel — the
  selector is not a second gameplay verb.
- **P2-2 — Each trick has its own clean, distinct animation.** *As a player, every
  trick visibly performs the **specific** behavior with a clear apex* — never one
  generic pose reused. Starter set: **Sitt**, **Ligg** (lie down), **Legg deg**
  (settle), then expand (e.g. **Gi labb** [shake], **Rull** [roll over], **Snurr**
  [spin]). The lie-down tricks must read as **down**, clearly different from sit.
  (D6, D11, PO-Improvement-1)
- **P2-3 — Same Phase-1 polish gate per trick.** *As a player, every new trick is
  as bug-free and satisfying as Sitt* — no foot-sliding, clipping, snapping, or
  T-pose; smooth loops; honest apex tell; the mark feels good. **Each trick passes
  its own Visual Review** before it counts as done.
- **P2-4 — Learned bar + mastery.** *As a player, well-timed BRAs fill a "learned"
  bar; 100% masters the trick with a celebratory beat,* then it's re-practiceable.
  PERFECT fills more than OK; the bar only ever stalls — **no fail state**.
  (Training Sessions, Mastery)
- **P2-5 — Resumable + pause.** *As a player, I can leave/pause and return with my
  per-trick progress intact* (introduces IndexedDB save). (Round States)

> **Mistakes/confuse, distractors, mobile-grace** (the old "restraint" depth) ride
> along here as the bar gains stakes, but are **secondary** to nailing more clean
> tricks. Keep them light until the trick roster feels good.

---

## Phase 3 — Dog breeds (races), each with its own tricks  *(needs further spec)*

**Goal:** the player can **select different dog breeds**, each a recognizable real
breed with its **own set of tricks / signature behaviors** and its own feel.

> **⚠️ This phase is deliberately under-specified and must be detailed before
> build.** The open design calls are listed below — resolve them (with the owner
> where flagged) before slicing work.

### Stories (provisional)

- **P3-1 — Choose a breed.** *As a player, I can pick which dog I'm training,* and
  it reads **clearly as that real breed** at phone size — silhouette, proportions,
  coat, color. (D2)
- **P3-2 — Breeds bring different tricks.** *As a player, different breeds open
  different / signature tricks,* so collecting breeds is also collecting moves.
- **P3-3 — Breeds feel different to train.** *As a player, each breed's personality
  changes how it trains* (learn speed, distractibility, window stability, energy).
  (Breeds)
- **P3-4 — Persistent, showcased roster.** *As a player, my dogs persist across
  sessions and are shown off** (bright/spotlit on select, not buried in shadow).
  (D3, PO-Improvement-2)

### Open questions to resolve (own this before building)

- **Which breeds ship first?** The licensed pack covers **Labrador, Border Collie,
  French Bulldog, Husky** (no Poodle). Proposed starter set = those four.
- **Universal vs. signature tricks.** Which tricks does *every* breed know vs. which
  are breed-exclusive? Proposed: a shared core (Sitt/Ligg/Legg deg) + 1–2 signature
  tricks per breed.
- **How are breeds acquired?** Free select of all, or unlocked/adopted via
  progression? This is the first point that **may require an economy** (coins /
  level gate). Decide whether Phase 3 pulls economy forward or ships with all
  breeds free.
- **Per-breed animation cost.** Each breed × each of its tricks needs a clean clip
  at Phase-1 quality. Confirm the rig/clip coverage per breed before committing the
  trick list (the pack ships shared clips, but signature tricks may not exist).

---

## Phase 4 — Difficulty

**Goal:** the player can **change difficulty**, trading challenge for reward.

- **P4-1 — Global difficulty setting.** *As a player, I can set Normal / Hard /
  Expert,* applied to all training. (Difficulty Modes)
- **P4-2 — Difficulty changes the read.** Higher = **tighter window, fainter &
  faster apex tell, more distractors, harsher false-mark penalty.** (Difficulty)
- **P4-3 — Pain pays.** Higher difficulty **raises rewards** so each mode is the
  rational choice at a different skill level. (Difficulty)
- **P4-4 — Composes with breed.** Effective difficulty = global mode × breed
  intrinsic. (Breeds)

---

## Phase 5 — Better marker words (collectible "bra" phrases)

**Goal:** the player **unlocks alternative, more-effective Norwegian marker words**
— *dyktig, flink, super, kjempebra* — beyond the base **bra**.

- **P5-1 — Unlock new phrases.** *As a player, I progressively unlock new marker
  words,* each with its own voiced line in the Maren delivery. (Phrases, Audio)
- **P5-2 — Stronger words, real trade-off.** *As a player, better words are more
  effective (wider window / bonus) but carry a **cooldown / downside**,* so I mix
  them with base "bra" instead of spamming one. Base "bra" is always the default,
  no cooldown. (Phrases)
- **P5-3 — They pop up on screen.** *As a player, the marker word visibly **pops /
  floats on screen** on a successful mark* (big, juicy, on-beat) — reinforcing the
  praise moment and showing which word fired. *(Visual treatment open — a floating
  word burst from the BRA button is the working idea.)*
- **P5-4 — Loadout without a second verb.** *As a player, I load/swap the active
  word outside the tap* (chip cycle or swipe the BRA marker) — the round stays one
  tap. (Phrases)

---

## Phase 6 — Shaping (steps) + Play mode  *(the learning-technique phase — needs further spec)*

**Goal:** teach tricks the way **real marker training** does — by **shaping in
steps** (successive approximation) — and add a **chaotic free Play mode** (toys,
praise, petting) that **bonds the dog and significantly boosts learning**. This is
the phase that turns "tap the apex" into "train a dog."

### 6a — Shaping / steps

- **P6-1 — Tricks taught in steps.** *As a player, a complex trick is broken into
  **markable sub-steps** I master in order,* mirroring real shaping. Example —
  **Legg deg**: step 1 = **step onto the bed/mat** (not lying down yet), step 2 =
  lower the front, step 3 = full settle. Each step is its own behavior with its own
  apex and learned bar; mastering a step unlocks the next.
- **P6-2 — Scenarios / props.** *As a player, steps can introduce a **prop /
  scenario*** the behavior references — e.g. a **dog bed/mat** for *Legg deg*, a
  cone, a target. The scene gains the object for that trick.

#### Open questions to resolve (own before building)

- **Do the intermittent steps need their own animations?** Almost certainly **yes**
  — each step is a distinct pose/motion (e.g. *stepping onto a bed* is locomotion,
  not the final down). Movement must be **clean** (no foot-slide/clip); confirm the
  rig has — or can get — clips for each step, or design steps around clips we have.
  This is the main cost/risk of the phase.
- **All tricks, or only some?** Proposed: **only some.** Positional/compound tricks
  (Legg deg, Rull, Dau) earn real steps; atomic tricks (Sitt, Snurr) stay
  single-step. Shaping should feel earned, not bolted onto everything. **Owner call.**
- **How granular?** 2–3 steps max per trick to start, so it teaches the idea
  without dragging. Tunable.

### 6b — Play mode (engagement → faster learning)

- **P6-3 — Go chaotic with the dog.** *As a player, I can enter a free **Play mode**
  and interact loosely* — **throw toys, pet, praise ("flink gutt!"), tug, pet
  "aggressively"** — many tappable things at once, deliberately the *opposite* of
  the precise single-tap training. It should feel joyful and a little unhinged.
- **P6-4 — Play builds bond, bond boosts learning.** *As a player, playing raises
  the dog's **engagement/bond**, which **significantly speeds up** subsequent
  training* (faster learned-bar fill / better mood). Play is the carrot that makes
  the disciplined training pay off — and models the real "build the relationship
  first" technique.

#### Open questions to resolve

- **How does Play feed learning?** A persistent bond/engagement stat that
  multiplies learn-speed? A temporary buff after a play session? Proposed: a
  **bond meter** that decays slowly and grants a learn-speed multiplier — play to
  top it up. **Needs tuning + owner steer.**
- **Animation scope.** Play multiplies the clip count (fetch, tug, roll, get-pet,
  zoomies). Confirm coverage; reuse existing pack clips where possible.

---

## Beyond Phase 6 (parked — preserved from the full vision, not yet scheduled)

These were in the original spec and remain the long-term target; slot them once the
six phases above feel great:

- **Economy depth & kennel idle/upgrade layer** (coins/XP/levels as the substrate
  for unlocks, a capped idle trickle, backdrop upgrades). *Note: Phases 3 & 5
  ("unlock"/"adopt") may pull a* light *economy forward — decide per phase.*
- **Behavior chains / combos** (sit → stay → heel) for multipliers.
- **Untraining** — mark the *absence* of a bad habit (a new verb, same tap). (D10)
- **The real Maren marker voice** (owner/likeness-gated drop-in) and **bespoke
  per-breed signature animation at catalog scale.**

---

## Cross-cutting requirements (apply to every phase)

- **Mobile portrait only.** No landscape/tablet/desktop. (Non-Goals)
- **One verb.** Depth never comes from more buttons. (Design Principles)
- **The mark must always feel good.** Voice + SFX + dog reaction on every
  successful BRA. (Design Principles)
- **Reads first, looks the part.** Pokémon-GO stylized-realism; D1–D2 and D4–D9
  are never waivable. (D14)
- **Reduced motion** dampens, never removes, every state cue. (D13)
- **Visual Review gate** closes every visual task; **TDD** gates every piece of
  game logic. (CLAUDE.md)
- **No backend, client-only, IndexedDB save.** (tech-decisions.md)

## Non-Goals (unchanged)

No landscape/desktop, no multiplayer/social, no monetization/IAP, kennel is not a
standalone auto-game.
