## Phase Sign-off

> **Permanent, append-only — never pruned.** One line per phase the PO has play-tested
> **clean** on the real running build (its Visual Review gate, e.g. P1-10, passed). This is
> the explicit done-gate: the build loop reads it to know which phase is current — the
> **current phase is the lowest-numbered `phaseN.md` NOT listed here**. A phase is *not*
> advanced just because its code compiles and tests are green; it advances only when it
> appears below. (List empty ⇒ current phase is Phase 1.)

- **Phase 1 — SIGNED OFF 2026-06-30 (owner, larssski).** Played the live deployed build
  (https://kilars.github.io/braa/) at 390×844: licensed Labrador loads (no primitive flash),
  centered + shadow-grounded, idle → sit → clear seated apex → honest apex tell → BRA tap →
  joyful reaction → loop, all P1 stories (P1-0…P1-9) pass, logic is test-first, verify green.
  Accepted **as complete as best as possible**: the two residual gaps are owner-gated polish,
  not core-loop defects, and ship with honest stand-ins — the genuinely-spoken espeak "Bra!"
  (warm human Maren recording drops in under the same cue id, no code change) and the coat
  UV/tangent seam (a licensed-asset re-export, tracked as an open flag). Both remain open
  flags for the owner to close later; neither blocks the core mark. **Phase 2 is now current.**

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-07-01

First **Phase-2** play-test pass. Drove the **LIVE deployed Pages site**
(https://kilars.github.io/braa/) at 390×844 in headless Chromium (SwiftShader == the deployed
GL Compatibility renderer). Boot log confirms the licensed Sitt build is live: `dog loaded:
res://assets/models/dog_licensed.glb (1 coat surface(s) forced opaque)` and `dog can Sitt`.
Exercised the garden, the learned bar (fill → mastery via `?bra_autotap=1`), the anti-mash
lock (`?bra_force_lock=1`), and persistence (fill, then a plain reload on the same origin).
**Zero** SCRIPT ERROR / pageerror across every run.

**Phase 2 is roughly half-built — NOT signed off.** Four stories are built and verified good
(keep): **P2-4** learned bar, **P2-5** persistence, **P2-7** anti-mash, **P2-10** garden.
Five stories are missing or stationary: **P2-1** trick selector, **P2-2** distinct trick
animations, **P2-3** per-trick polish, **P2-8** the living dog, **P2-9** fading timing
trainer. Directives below. Do not sign Phase 2 off.

**What holds up (verified live this pass, keep it):**
- **P2-10 — the garden.** A real look-down Pokémon-GO view: a sky band across the top ~25% of
  the frame with a visible sun, green grass below, the Labrador centred and grounded by a soft
  contact shadow **on** the grass, and the **"BRA"** verb floating over the lower grass with
  **no** opaque control band (`.screenshots/po2-garden-idle.png`). Replaces the old flat
  blue void. Good.
- **P2-4 — the learned bar fills and masters.** A thin meter in the top sky fills **green**
  with each PERFECT (`po2-bar-1-t4000.png` ≈ 20% after one mark; `po2-bar-4-t16000.png` ≈ 60%
  after three) and latches a **full gold** bar at mastery (`po2-mastery.png` — full gold bar,
  dog caught mid-Sitt). PERFECT clearly nets forward. Good.
- **P2-5 — leave and come back.** Filled the bar to ~60% green under autotap, then reloaded
  the **plain** site on the same origin; the bar restored to ~60% green from the local save
  (`po2-persist-reload.png`). Per-trick progress survives a reload (X-7 offline, `user://`
  IndexedDB, no backend). Good.
- **P2-7 — anti-mash freeze.** `?bra_force_lock=1` pins the BRA word visibly **dimmed**
  (`po2-lock.png`) vs. the bright idle "BRA" (`po2-garden-idle.png`) — a clear static dim,
  legible without motion (X-5). The fixed-350 ms re-arm behaviour is unit-tested. Good.
- *Not yet pixel-verified this pass (for the eventual sign-off pass):* the P2-4
  **erosion / confused-beat** path — a MISS/DEAD dropping the bar, the brief red setback wash,
  and the dog's confused recoil. `?bra_autotap=1` only fires PERFECT, and the wash/wobble are
  ~0.45 s flashes a strobe-sampled burst can miss; the mechanic is unit-tested, but a sign-off
  pass should still catch the drop + wash + recoil in live pixels.

#### Bugfixes

- (none) — the build ran clean: idle → sit → mark → loop, mastery, and persistence all worked
  with **zero** console errors across every run this pass.

#### Improvements (buildable now)

- **P2-8 — the dog has no life and the cadence is a fixed metronome.** Across a 45 s run the
  dog never left dead-centre and trick offers came on a constant rhythm — one markable sit
  roughly every ~6–7 s, the idle gap a fixed 1.2 s (`scripts/sit_loop.gd`
  `DEFAULT_INTER_SIT_GAP`). *Why it falls short:* P2-8 wants a dog that **wanders** the bounded
  grass patch (turning back at the edges, camera fixed), offers tricks on a **varying** gap so
  there is no metronome to game, and sometimes **feints** (starts a sit then aborts — only a
  completed Sitt has a markable apex). None of that is present today: the dog is stationary,
  the gap is constant, and there are no feints. *Good looks like:* the dog roams and turns at
  the patch edges, the gap between offers varies, and a feint/ambient moment opens no scoring
  window — tapping it is a wrong-moment tap that erodes the bar (→ P2-4). (Task 048 is already
  queued for variable cadence + feints; the wander rides the garden, P2-10.)
- **P2-9 — no fading timing trainer.** With an empty bar (a brand-new trick) the player gets
  no "now" teaching cue beyond the brief apex ring already at the button. *Why it falls short:*
  P2-9 wants a bold approach cue — a ring that **shrinks onto the BRA button and lands exactly
  at the apex** ("tap when it lands") — shown while the trick is new, **fading as the learned
  bar fills** and **gone at mastery**, and riding the same `SitWindow` so it stays dark during
  feints/ambient. Not present. *Good looks like:* a shrinking approach-ring that lands on the
  apex for a new trick and visibly fades to nothing by the time the bar is full.
- **Garden sun reads as a flat egg-shaped blob (minor, Phase-7-leaning).** In the SwiftShader
  capture the sun is a hard-edged, slightly vertical-ellipse yellow disc with no halo
  (`po2-garden-idle.png`); the explicit sphere renders in all GL paths, and the procedural
  sky-sun glow may add a halo on real-device GL. *Why it's minor:* P2-10 explicitly defers
  richer environment art to Phase 7, so this does **not** block Phase 2 — flagging it so the
  Phase-7 pass tightens the sun to a crisp, haloed disc.

#### Changes / scope (owner-gated — the trick roster can't grow without it)

- **P2-1 / P2-2 / P2-3 need additional trick animation clips — owner-gated.** The whole point
  of Phase 2 is *more tricks at the Sitt standard*, but the licensed Labrador ships only the
  Sitt (+ idle + reaction) clips, so there is **no second trick** to select, perform, or
  polish — the game boots straight into the single-Sitt garden with no selector. *Why it's
  blocked:* a distinct, clean Ligg / Legg deg / Gi labb / Rull / Snurr animation is a
  licensed-asset deliverable, and the loop must **not** fake a sit or reuse one generic pose
  (CLAUDE.md). *What "good" needs:* the owner supplies the additional trick clips in the
  licensed asset; then the selector (P2-1), each trick's own distinct apex animation (P2-2),
  and its own Visual Review (P2-3) become buildable. Until then the only buildable Phase-2 work
  is **P2-8** and **P2-9** above — do **not** build a one-entry selector or fake a second
  trick. (Keep/raise the owner flag in `.task-board/FLAGS.md`.)

**Sign-off status:** Phase 2 stays open. Build **P2-8** and **P2-9**; the trick-roster stories
(P2-1/P2-2/P2-3) wait on owner-supplied animation clips. Do not sign Phase 2 off until all ten
stories pass, each new trick clears its own Visual Review (P2-3), and a pass catches the P2-4
erosion / confused-beat in live pixels.

---

## Forward PO Directives (captured 2026-06-29)

> Owner design decisions captured ahead of their phase. **These are not current-phase
> play-test notes**, and the build loop should **not** action the Phase-2/4 items until
> that phase is current — they are already formalized into the phase specs cited below.
> Listed here only for provenance: what the PO asked for, and when. (The father pass owns
> the two sections above and leaves this one alone.)

### 2026-06-29 — grilled feature set (→ Phase 2 / Phase 4)

1. **Anti-mash freeze on BRA.** After every tap, lock BRA ~350 ms, swallow taps during the
   lock, don't reset the timer. → **P2-7**.
2. **A living dog: wander + variable rhythm + feints.** The dog roams a bounded patch on no
   fixed cadence and sometimes fakes a sit; only a real, completed Sitt is markable. → **P2-8**
   (rides the garden, P2-10).
3. **Negative learning.** Wrong-timing / wrong-moment taps **remove** learning — gentle by
   default, erodible, floors at 0, mastery is a safe checkpoint; a bad tap shows a confused
   beat. → **amends P2-4**; harshness scales in **P4-2**.
4. **A fading timing trainer.** A bold approach-ring "now" cue for a new trick that fades with
   the learned bar and is gone at mastery; honest (rides `SitWindow`), dark during feints.
   → **P2-9**.
5. **The garden.** Look-down Pokémon-GO view — sky + sun above, grass below, BRA floating over
   the grass; fixed camera, dog roams a bounded patch. Functional garden in Phase 2 (it enables
   the wandering); environment art polish deferred to **Phase 7**. → **P2-10**.

### 2026-06-29 — the voice is not "placeholder-acceptable" (current phase, P1-6)

The synthesized **sine-tone beep** was not an honest attempt at a spoken "Bra!". A *genuinely
spoken* word is now required for Phase 1 (P1-6 amended): an offline-TTS stand-in (`espeak-ng`
"Bra!", `assets/audio/bra_tts_placeholder.wav`) ships until the warm **human** Maren recording —
which is **owner-gated** — is supplied. The owner gap is an **open flag** (`.task-board/FLAGS.md`);
the wiring is **task 035**. This is current-phase work (not parked under "Forward").
