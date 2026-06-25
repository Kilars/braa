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

## Phase 2 — The learning loop (one dog, real progression)

**Goal:** turn the single mark into a *round* you can finish.

- **P2-1 — Learned bar.** *As a player, each well-timed BRA fills a "learned" bar
  so I feel the dog learning.* PERFECT fills more than OK; the bar only ever
  stalls, **never** empties — no fail state. (Training Sessions)
- **P2-2 — Mastery + a reason to repeat.** *As a player, filling the bar to 100%
  masters Sitt with a clear celebratory beat,* then I can practice it again.
  (Mastery)
- **P2-3 — Resumable round.** *As a player, I can leave and return with my
  learned-bar progress intact* (introduces save — IndexedDB). (Round States)
- **P2-4 — More starter tricks.** *As a player, I can teach **Ligg** and **Legg
  deg**, each with its own clearly-distinct down pose* (not the same sit reused).
  (D11, PO-Improvement-1)
- **P2-5 — Pause/resume.** No timer forces play. (Round States)

---

## Phase 3 — Mistakes & restraint (the verb gets depth)

- **P3-1 — False mark vs. miss.** *As a player, tapping BRA when no window is open
  is punished (small bar setback), while tapping during a genuine attempt is
  forgiven,* so mashing loses and patience wins. (Mistakes, Tap tiers)
- **P3-2 — Confuse debuff.** *As a player, a false mark briefly confuses the dog
  (narrower window, more distractors, visible jitter) for ~3s,* refreshing rather
  than stacking. (Mistakes, D7)
- **P3-3 — Distractors.** *As a player, the dog sometimes offers the **wrong**
  behavior I must NOT mark, visibly distinct from a real attempt.* (Core loop, D9)
- **P3-4 — Mobile grace.** *As a player, taps right after the app resumes from
  background are ignored,* so notifications never cause a false mark. (Mistakes)

---

## Phase 4 — Economy & progression

- **P4-1 — Coins + XP on mastery.** (Economy)
- **P4-2 — Trainer levels unlock tiers; coins buy the item** (two-step model).
  (Economy)
- **P4-3 — Persistent coin + level readout** on the shell. (PO-Change/Improvement-5)
- **P4-4 — Staged onboarding** reveals each system in turn, never all at once.
  (Onboarding)

---

## Phase 5 — Collection: breeds & roster

- **P5-1 — Persistent roster** of dogs housed in a kennel/select shell. (Roster)
- **P5-2 — Multiple recognizable breeds**, each reading clearly as its real breed,
  with personality stats driving difficulty levers. (Breeds, D2)
- **P5-3 — Adopt panel** with coin price + locked state ("Reach Lv 3") + breed
  thumbnail. (PO-Improvement-4)
- **P5-4 — Showcased dog on select** — brightened/spotlit, not buried in shadow.
  (PO-Improvement-2)
- **P5-5 — Switch dogs anytime**; each dog's repertoire grows. (Roster)

---

## Phase 6 — Kennel (idle / upgrade layer)

- **P6-1 — Buy facilities/equipment** that boost active payouts and add a small,
  capped idle coin trickle (never XP). (Kennel)
- **P6-2 — Upgrades state their concrete effect** (e.g. "+10% coins", "wider mark
  window"). (PO-Improvement-3)
- **P6-3 — Backdrop visibly upgrades** with kennel tier. (Kennel)

---

## Phase 7 — Marker phrases & difficulty modes

- **P7-1 — Collectible Norwegian marker phrases** (flink, dyktig, super…), voice
  variety for the one tap; base "bra" always default, no cooldown. (Phrases)
- **P7-2 — Loadout selection** (chip cycle or swipe the BRA marker), never an
  extra in-round button; stronger phrases carry a trade-off + cooldown. (Phrases)
- **P7-3 — Global difficulty** (Normal / Hard / Expert): tighter windows, more
  distractors, harsher penalties, fainter/faster tell, higher rewards. (Difficulty
  Modes)
- **P7-4 — Engagement meter & disengagement** — off-task → sass → walk-off + call
  back; disengaged state visually distinct from a distractor and fully in frame.
  (Wrong-behavior beats, PO-Bugfix-3, PO-Change-2)

---

## Phase 8 — Later depth (only once the core is solid)

- **P8-1 — Behavior chains / combos** (sit → stay → heel) for multipliers.
- **P8-2 — Untraining** — mark the *absence* of a bad habit (a new verb, same tap).
  (D10)
- **P8-3 — Bigger catalogs** — more breeds, tricks, phrases.
- **P8-4 — Higher-fidelity art at catalog scale** — the real Maren voice, bespoke
  per-breed signature animations, the licensed-model swap on the default build.

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
