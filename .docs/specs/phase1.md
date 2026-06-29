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
  - A warm, Maren-style spoken **"Bra!"** plays on a successful mark. A *genuinely
    spoken* word is required even before the real recording — synthesize one (e.g.
    offline TTS) rather than substituting an abstract tone/beep. The warm **human**
    Maren voice is the owner-gated drop-in under the same stable cue id; if it can't
    be produced, that gap is **flagged** (`.task-board/FLAGS.md`), never silently
    stubbed. (Audio, PO-Directive 2026-06-29)
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
