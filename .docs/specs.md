# Bra! — Game Specification (Functional)

> This document describes **what the game is and how it plays**. All technical
> decisions (engine, stack, architecture, persistence, asset pipeline) live in
> [CLAUDE.md](../.claude/CLAUDE.md) and [tech-decisions.md](tech-decisions.md).

## Overview

**Bra!** is a mobile-only dog-training timing game. The player acts as a dog
trainer, watching a dog from a first-person point of view and marking the exact
instant the dog performs a desired behavior by tapping a big **"BRA"** ("good"
in Norwegian) marker. Precise timing teaches the dog; sloppy timing confuses it.

The feel is inspired by the Norwegian dog-training TV show **_Bølle til
bestevenn_** ("bully to best friend"), built on marker training, where the
trainer **Maren** says **"bra"** constantly — repetitive, a little annoying, and
weirdly addictive. That satisfying marker moment is the heart of the game.

On top of the timing core sits a light grind/collection layer (in the spirit of
cookie-clicker, but gentler): mastering tricks earns currency and levels, which
unlock new breeds, tricks, and marker phrases, plus a kennel of upgrades that
makes the whole loop pay better.

- **Platform:** Mobile only, mobile-first, portrait orientation.
- **Audience:** Casual mobile players; dog lovers; fans of the show; people who
  enjoy timing/rhythm and idle-progression games.
- **Session shape:** Snackable. A meaningful push at a trick takes ~1–3 minutes;
  progress is saved and resumable at any time.

## Design Principles

- **Grounded in real training, but game-first.** The mechanics deliberately
  mirror real positive-reinforcement **marker training**: you mark the *exact
  instant* of the desired behavior, reward follows the mark, and marking the
  wrong thing genuinely confuses the dog. A player should absorb a bit of real
  intuition (timing matters; reward what you want; don't mark mistakes). Where
  realism would make the game tedious, **the game wins** — this is an addictive
  toy, not a training simulator or course.
- **One verb, deep.** The whole game is *one tap at the right moment*. Depth
  comes from reading the dog, restraint, breeds, phrases, and difficulty — never
  from adding more buttons.
- **The mark must always feel good.** Voice + SFX + reaction on every successful
  BRA; that satisfying beat is the product.

## Core Gameplay Loop

The moment-to-moment action is a **precision timing tap**. There is **one dog on
screen offering one behavior at a time** (sniff, circle, paw, lie down, sit…);
distractors are wrong behaviors that appear in this *time sequence*, not separate
on-screen targets — the player never picks a target, only *when* to mark.

1. The dog offers behaviors semi-randomly.
2. The **correct** behavior for the current trick surfaces and builds to a **peak
   instant**. A **subtle visual tell** — a soft pulse/ring/glow at the apex of
   the behavior animation — signals the moment. (Harder difficulty makes the tell
   **fainter and faster**.)
3. The player taps the **BRA** marker. Score = how close the tap lands to the peak.

```
dog: sniffs... circles... paws...
        SITT — apex pulse ◎
   miss | OK | PERFECT | OK | miss
              ^ tap BRA on the pulse
accuracy -> reward feedback -> "BRA!" voice + mark SFX
```

Tap quality tiers:

| Tier | Condition | Effect |
|------|-----------|--------|
| PERFECT | Tap on the apex pulse | Large progress, best feedback |
| OK | Tap inside the window, off-peak | Smaller progress |
| Miss | Tap just outside the window of an *active correct attempt* | No progress, no penalty |
| False mark | Tap when **no correct window is open** (idle or a distractor) | Penalty + confuse (see Mistakes) |

The Miss vs. False-mark split is what makes the one verb matter: tapping while
the dog is genuinely *attempting* the trick is forgiven (no progress only), but
spamming BRA when there's nothing to mark is punished — so mashing is a losing
strategy and patience wins.

## Training Sessions & Mastery

A **round** = one **dog** + one **trick**.

- The dog starts out not knowing the trick.
- Each well-timed BRA fills a **"learned" bar**. PERFECT fills more than OK; a
  false mark stalls or sets it back. The bar **only ever stalls — it never empties
  to a loss**: there is **no fail state**.
- When the bar reaches **100%**, the trick is **mastered** → payout (coins + XP)
  and the trick is added to that dog's repertoire.

```
SITT  [######----]  62%
PERFECT +8%   OK +3%   miss +0%   false mark -4% (Normal value; scales w/ difficulty)
100% -> "SITT mastered!" -> coins + XP
```

### Dogs & Roster

Dogs are **persistent, collected units**, not per-session loadouts:

- The player owns a **roster** of dogs (housed in the kennel).
- You pick a dog and teach it trick after trick; its **repertoire grows** over
  time, building the show's "bully → best friend" bond.
- **Switch dogs at any time.** After mastering a trick you return to the dog/trick
  select, where you continue the same dog on a new trick or swap to another.
- **Mastered tricks are re-practiceable** for a reduced payout — a guaranteed
  income floor, so a player can never soft-lock with nothing affordable left.

### Round States

- **Resumable:** a round can be left at any time; partial learned-bar progress
  **persists**.
- **Pause/resume** supported; no timer forces play.
- No win/lose beyond mastery-or-quit (see no-fail above).

### Difficulty Levers

A dog/trick's difficulty is *expressed* through these axes — not a separate
system, but how breed-intrinsic difficulty (see Breeds) and the global mode show
up in play:

- **Correct-attempt rarity** — how often the dog offers the right behavior.
- **Window width** — how tight the peak window / apex tell is.
- **Distractor rate** — how many wrong behaviors compete.
- **Learn speed** — how much each good mark advances the bar.

**Effective difficulty = global mode × breed-intrinsic difficulty.** The chosen
*trick* sets which behavior is "correct" and adds a base complexity; the breed's
personality stats are the source of the per-lever values.

A "stubborn" dog rarely offers the target, with a short window and frequent
distractors — it takes a long time before it "realizes" what you want. An easy
dog offers clear, frequent attempts with a forgiving window.

## Mistakes

Marking the wrong thing matters, as in real marker training — but the game stays
forgiving by default:

- A **false mark** (a BRA tap when no correct window is open — during idle or a
  distractor, or far outside the window) knocks the learned bar back slightly
  **and** briefly **confuses** the dog.
- **Confuse debuff (concrete):** for ~3 s the window narrows (≈ −40%) and
  distractors increase (≈ +50%), and the dog visibly jitters — the next marks are
  harder to read. It never stalls to a loss; repeated false marks **refresh**
  rather than infinitely stack the duration.
- This rewards restraint — waiting for the *right* moment — without feeling
  punishing. Because off-window taps are punished, **continuous tapping is a
  net-losing strategy**.
- The penalty **scales with global difficulty** (the −4% example is the Normal
  value; see Difficulty Modes): harder modes punish harder.
- **Mobile grace:** taps in the brief moment after the app resumes from
  background are ignored, so a notification, lock, or fat-finger never triggers a
  false mark / confuse.

### Wrong-behavior beats & disengagement

The dog sometimes offers the *wrong* thing — a temptation you must **not** mark
(marking it is a false mark). With real clips this reads as personality, scaled by
an **engagement meter**: good timing keeps the dog eager; sloppy/false marks or slow
rewards drain it and the dog gets visibly more "done with you."

- **Off-task** (mild): `scratch ear`, `dig`, sniff/`eat`, bored `flop`, the zoomies.
- **Sass**: `bark` at you, `turn` its back.
- **Disengage** (meter empty): trots to the frame edge and sits back-turned — you
  can't earn until you **call it back** (tap), costing tempo/combo. The dog returns
  and re-engages once you're rewarding well.

Escalation is graded (itch → flop → bark → walk-off), so it stays funny, never
punishing. (`pissing`/`defecation` clips exist — ultra-rare gag at most.)

## Economy & Progression

Two axes work together:

- **XP → Trainer Level.** Mastering tricks grants XP (**active play only** — the
  idle trickle is coins, never XP, so unlock-gating stays skill-driven). Rising
  levels **unlock tiers**, making that tier's breeds, tricks, and phrases
  **available to buy**. Level = steady sense of progress.
- **Coins.** Mastering tricks (and the kennel idle trickle) grant coins. Coins
  **buy the specific item** within an already-unlocked tier (breeds, tricks,
  phrases) and pay for kennel upgrades. Coins = meaningful choices.

The two steps are sequential: **level makes content purchasable; coins purchase
it.** Nothing is unlocked by level alone or coins alone.

```
master RULL (roll over) -> +50 coins, +20 XP
LEVEL 4  [XP ####----]   -> unlocks tier: "gi labb", new breed
COINS 320  -> buy: Border Collie (200) | wider-window upgrade (150)
```

## Kennel (Idle / Upgrade Layer)

The kennel is an **investment layer**, not a separate auto-training game. Coins
spent here buy facilities, equipment, and assistant trainers that:

- **Boost active-session payouts** (coin/XP multipliers, wider windows, etc.).
- Provide a **small, capped passive idle trickle** of **coins** (never XP) while
  away ("your trained dogs keep showing off") — collected on return.

Reward multipliers compose multiplicatively in one defined order:
**payout = base × difficulty-mult × kennel-mult.** The idle cap sits well below a
single active session's payout, so idling never replaces play.

The active timing game remains the **only skill engine**; the kennel makes that
engine pay better and gives a gentle reason to return. Kennel level also visibly
upgrades the on-screen training-ground backdrop.

## Marker Phrases

Beyond the base **"bra"**, the player collects alternative Norwegian marker
words (e.g. *flink*, *dyktig*, *super*, *kjempebra*). They are primarily
**flavor and voice variety** for the single BRA tap.

- The game **starts with very few phrases** (base "bra" plus perhaps one); more
  unlock slowly as you progress.
- Some phrases are **more effective** (e.g. wider window or bonus reward) and
  carry a **cooldown**, so the best one can't be spammed — the player mixes it
  with base "bra".
- **Selection without extra buttons:** a phrase is **loaded** outside the round
  (a loadout), or swapped by swiping the BRA marker itself; the round is still
  **one tap**. Base "bra" is always the default and has no cooldown.
- **Avoiding a mindless rotation:** with few phrases early, "always fire the
  strongest" is a non-issue. As the catalog grows, stronger phrases should gain a
  real **trade-off** (an upside *and* a downside — e.g. +reward but a narrower
  window) so loading one becomes a genuine choice. *(Exact trade-off model is an
  open design item — see [tech-decisions.md](tech-decisions.md).)*

## Breeds

Breeds are a core collection axis with **deep kits**, not just skins:

- Each breed is a **recognizable** dog (breed identity must read clearly).
- **Personality stats** are the source of the difficulty levers: learn speed,
  distractibility, window stability, energy.
- **Signature behaviors / tricks**: breeds bring unique behaviors or signature
  tricks of their own, giving each one a distinct feel and collection value.
- Each breed has an **intrinsic difficulty**; **effective difficulty = global
  mode × breed-intrinsic** (the chosen trick adds a base complexity on top).

Examples (illustrative, to be finalized):

| Breed | Personality | Notes |
|-------|-------------|-------|
| Labrador | Balanced, beginner-friendly | Starter breed |
| Border Collie | Fast learner, distractible | High skill ceiling |
| Bulldog | Slow but steady windows | Patience breed |
| Husky | High energy, jittery windows | Chaotic, rewarding |

## Tricks

In-game commands use their **Norwegian** names, matching the marker-word flavor.
The **first commands taught** (the starter set) are:

- **Sitt** — sit
- **Ligg** — lie down / hold the down position
- **Legg deg** (*legge seg*) — settle / lie down on the spot

Beyond the starter set, tricks range from simple to complex (e.g. *gi labb*
[shake], *rull* [roll over], *snurr* [spin], *dau* [play dead]…). Command
availability is gated by trainer level; specific commands are unlocked with
coins. Some are breed-signature (see Breeds). The full catalog expands over time.

## Difficulty Modes

Difficulty is a **single global setting** (default **Normal**; **Hard**;
**Expert**) applied to all training:

- Higher difficulty = **tighter windows, more distractors, harsher penalties, and
  a fainter/faster apex tell**.
- Higher difficulty also **raises rewards** via a coin/XP multiplier
  (**payout = base × difficulty-mult × kennel-mult**) — opting into pain pays off.
- This composes with each breed's intrinsic difficulty (**effective = global ×
  breed-intrinsic**).
- *Intent:* the reward curve should be tuned so each mode is the rational choice
  at a different skill level (no single dominant setting) — a tuning target, see
  [tech-decisions.md](tech-decisions.md).

## Visual Presentation

- **Portrait, first-person trainer POV.** The player looks down/forward at the
  dog as a trainer would.
- The **dog is the focus**: centered, clearly animated, with readable states —
  idle, each offered behavior, the markable behavior, the confused jitter, and a
  happy reward reaction. Detailed dog requirements are in [The Dog](#the-dog).
- A **trainer's hand** enters the frame for rewards and gestures (treat, pat).
- The **backdrop** is a simple training ground/park that visibly **upgrades**
  as the kennel grows.
- **Art direction:** the **visual styling explicitly references *Pokémon GO***
  — not only breed-recognizability, but the rendering *look*: clean
  stylized-realism, bright soft lighting, readable models on a simple,
  mobile-optimized scene. Semi-realistic **3D**; breeds must read clearly as
  their real breed.

## The Dog

The dog is the focal element and the game's **primary state-communication
channel** — most of what a player reads before each tap, they read off the dog,
not the UI. These requirements define what the dog must *be* and *do*; the
rendering technique (engine, mesh source, asset pipeline) is a technical
decision (see [tech-decisions.md](tech-decisions.md) / [CLAUDE.md](../.claude/CLAUDE.md)).

**Recognizability**

- **D1 — Reads as a dog.** From the trainer POV, at phone size, the dog must be
  immediately recognizable as a dog: a clear canine silhouette with a
  distinguishable head, ears, snout, body, four legs, and a tail. A featureless
  shape (a bare sphere/blob/capsule) does **not** satisfy this — not even as a
  placeholder.
- **D2 — Breed reads clearly.** Each breed must be recognizable as its real breed
  (see [Breeds](#breeds)): silhouette, proportions, coat, and coloring differ
  enough to tell a Labrador from a Border Collie from a Husky at a glance.
- **D3 — Persistent identity.** A given roster dog keeps a consistent appearance
  across rounds and sessions — it is a collected unit (see [Dogs & Roster](#dogs--roster)),
  not a per-round re-roll.

**State legibility** — the dog must visibly and *distinctly* communicate each
gameplay state. States must be tellable apart **at a glance on a phone**, not only
by a subtle color shift:

- **D4 — Idle.** With nothing being offered, the dog looks alive but calm —
  ambient motion (breathing, the odd tail wag / look-around). It is never frozen.
- **D5 — Offering (non-target).** When the dog offers a behavior that is *not* the
  current trick, it visibly performs that behavior (sniff, circle, paw…), so the
  player reads "something is happening, but not the thing I want."
- **D6 — Markable behavior + apex.** When the *correct* behavior surfaces, the dog
  performs that trick's pose and its animation **builds to a clear apex** — the
  markable instant — readable off the dog itself, reinforcing the UI apex tell.
  Per difficulty the on-dog apex gets fainter/faster (see [Difficulty Levers](#difficulty-levers)).
- **D7 — Confused.** During the confuse debuff (see [Mistakes](#mistakes)) the dog
  visibly reads as unsettled/confused (jitter, head-tilt, hesitation) for the
  debuff's duration, then settles back to idle.
- **D8 — Happy / reward.** On every successful mark, and bigger on mastery, the
  dog gives a clearly positive reaction (perk-up, bounce, tail wag). This is part
  of "the mark must always feel good" (see [Design Principles](#design-principles)).
- **D9 — Distractor.** A distractor (wrong-behavior) moment must look distinct
  from a genuine correct attempt, so a reading player can tell "don't mark this"
  from the dog — not only from memorized timing.
- **D10 — Misbehaving (untraining — a later addition).** For untraining tricks the dog
  visibly performs the bad habit (jumping, barking) so the player can mark its
  *absence* / the calm — distinct from the positive offering states.

**Motion & framing**

- **D11 — Performs the actual trick.** Trick poses must be legible as the specific
  trick (sit, lie down, roll over, spin, paw) — not one generic animation reused
  for every command. Reading the behavior is part of the skill.
- **D12 — Grounded & framed.** The dog rests on the ground (anchored by a contact
  shadow, not floating), stays centered and fully in frame in portrait, and reads
  clearly against the bright backdrop.
- **D13 — Reduced motion.** When the OS requests reduced motion
  (`prefers-reduced-motion`), jitter/bounce/shake cues are **dampened, not
  removed** — every state (D4–D10) must still be distinguishable via pose and
  tint without strong motion, for motion-sensitive players.

**Fidelity vs. legibility**

- **D14 — Reads first, and looks the part.** The *target* is the Pokémon-GO-style
  stylized-realism in [Visual Presentation](#visual-presentation), and the dog
  should reach it — not bare placeholder geometry (capsules / cylinders / spheres
  with flat materials). Above all, **D1–D2 (reads as a dog / as its breed) and
  D4–D9 (the core states) are never waivable** — a dog that doesn't read as a
  recognizable, state-communicating dog fails however it is rendered. "It animates"
  is not "it reads as a dog."

## Audio

Audio is a primary pillar — the game should *sound like the show*,
**_Bølle til bestevenn_**.

- **Marker voice (defining requirement):** the spoken **"bra"** must sound like
  **Maren from _Bølle til bestevenn_** — that is the reference, and matching it is
  non-negotiable, not a nice-to-have. Capture *her* specific delivery: a warm,
  bright, encouraging female Norwegian voice; a short, punchy, slightly clipped
  "bra!" with an upward, praising lilt; the same repetitive, sing-songy cadence
  the show is known for. If a recording or imitation does not clearly read as
  "that's the lady from the dog show," it is wrong — re-do it. This applies to the
  base "bra" first and foremost, and the same voice and delivery extend to every
  collectible phrase (each has its own line). *(Sourcing method — recorded /
  licensed / imitation / TTS — and likeness considerations are an open tech
  decision; see [tech-decisions.md](tech-decisions.md) §4. The target sound,
  Maren's delivery, is fixed here regardless of how it is sourced.)*
- **Mark SFX:** a crisp UI click sits under the voice so the mark always feels
  tactile and satisfying.
- **Dog foley:** panting, barks, happy whines, movement.
- **Ambient:** a light training-ground/park bed.

## Onboarding (First Run)

The first session teaches the one core verb — *wait for the apex, tap BRA* — on
the starter Labrador with a forgiving window and an obvious target behavior.
Systems are then **revealed in stages**, never all at once: distractors arrive
around the second trick, then the first phrase unlock, then the economy at the
first payout, with the kennel last. This avoids dumping every system right after
the first mastery (a classic casual-game churn point).

## Scope

The document above describes the game; everything in it is the target. The build
approach is to get the **core training loop genuinely fun and genuinely polished**
first — a small, finished slice that looks and plays right — then widen it with
more content. Crucially, "finished" includes the **look**: the Pokémon-GO-style
presentation in [Visual Presentation](#visual-presentation), [The Dog](#the-dog),
and [Audio](#audio) is part of the game, not a later pass.

**The game includes:**

- A **persistent roster of dogs** (starting with the Labrador), each building a
  repertoire of commands — beginning with **Sitt, Ligg, Legg deg** — via the
  command/dog select + roster shell.
- Full active loop: offer → **apex tell** → mark → learn → master → payout, with
  the **light penalty / confuse** model and the Miss vs. false-mark split.
- Base **"bra" + 1–2 phrases** with cooldown.
- **Global difficulty** setting.
- **Coins + XP + levels** with the two-step unlock model.
- The **kennel** investment / idle-upgrade layer.
- Multiple **breeds**, each visually distinct with its own personality stats.
- **Polished, Pokémon-GO-style presentation throughout** — a dog that clearly
  reads as a real dog and as its breed, centered and fully framed, with legible
  states; a bright, vivid, clean scene; finished, **opaque** UI; and mark/reward
  moments with real juice. The full bar lives in
  [Visual Presentation](#visual-presentation), [The Dog](#the-dog), and
  [Audio](#audio); visual work is closed by the **Visual Review** gate in
  [CLAUDE.md](../.claude/CLAUDE.md) — never by "it compiles / tests pass".
- The **Maren-style marker voice** (see [Audio](#audio)).

Numeric tuning (window ms, bar curve, multipliers, idle cap) stays tunable as the
game is played and balanced — see [tech-decisions.md](tech-decisions.md). The
*look*, by contrast, is not a placeholder.

**Later additions (depth, once the core game is solid):**

- **Behavior chains / combos** — chain marks (e.g. sit → stay → heel) into
  advanced tricks for reward multipliers; depth from sequencing the same one tap.
- **Untraining** — the dog has a bad habit (jumping, barking); the player marks
  its *absence* / restraint rather than a behavior. A new verb on the same tap,
  reinforcing the "bully to best friend" arc.
- **Bigger content catalogs** — more breeds, tricks, and phrases over time.
- **Higher-fidelity art at catalog scale** — bespoke high-fidelity models and
  per-breed signature animations across the full breed/trick roster.

## Non-Goals (for now)

- No landscape / tablet-optimized / desktop builds — **mobile portrait only**.
- No multiplayer or social features.
- No monetization / in-app purchases.
- Kennel is **not** a standalone auto-training game; active timing stays the
  only skill engine.
