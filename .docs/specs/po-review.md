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

Fresh, fully independent re-play on **current HEAD (commit `46930fb`, the new 059 stand-up)** — my own
harness (`/tmp/po_capture.mjs`), my own eyes on every frame. Drove the **current-HEAD local licensed
bundle** (`build/web` — the 38 MB pck that bundles the unencrypted, sit-capable Labrador; `index.pck`
carries the 05:12 mtime, matching the newest `scripts/main.gd` at 05:12, tree clean → byte-current for
gameplay, and it includes the 059 stand-up) served over a local http origin and driven in headless
Chromium at 390×844 — SwiftShader == the deployed GL Compatibility renderer. (Local export over live
Pages because CI lags the last gameplay commits.) Boot is clean on every run: `__appReady` true,
`dog loaded: …dog_licensed.glb (1 coat surface forced opaque)`, `dog ambles a bounded patch between
offers`, `dog can Sitt — varying the offer cadence 0.8–2.0s, sometimes feinting`, and **zero** SCRIPT
ERROR / pageerror across all runs (a 60-frame free-run living-loop burst, a 54-frame autotap
sit→mark→stand-up cycle, a forced-lock capture, and 28 s / 45 s / 60 s autotap fill-to-mastery sweeps).

**This pass's one genuinely new item: the 059 stand-up seam, verified clean.** The dog now plays the
authored `Sitting_end` stand-up out of every sit instead of snapping straight back to idle. Captured
the full cycle at 130 ms spacing under autotap (`.screenshots/po-tap-06…13.png`): approach (cyan ring)
→ PERFECT mark (gold) → clean **seated apex** (frame 09) → **mid-rise, front up / rear still down**
(frame 10) → **full four-legged stand** (frame 11) → ambles off as the next approach ring forms
(frames 12–13). No T-pose, no snap, no foot-slide — this is the dead seam 059 set out to fix, and it
reads as a deliberate rise. Keep it; it materially improves the living-dog feel (P2-8).

**Every *buildable* Phase-2 story is done and holds up in my own live pixels** (P2-4, P2-5, P2-7,
P2-8, P2-9, P2-10) — this pass I re-shot five from scratch (P2-4/P2-7/P2-8/P2-9/P2-10) and eyeballed
each frame; P2-5 persistence carries forward from the prior same-origin-reload verification (the 059
stand-up doesn't touch it). The **only**
thing keeping Phase 2 open is the owner-gated trick roster (**P2-1 / P2-2 / P2-3** — see Changes): the
licensed dog still ships only the Sitt, so there is no second trick to select, perform, or polish.
**There is no new buildable work this pass.** Do not sign Phase 2 off, and do not invent filler — the
loop waits on the owner for trick clips.

**What holds up (verified live this pass, keep it):**
- **P2-10 — the garden.** Present in every frame I shot this pass: a stylised blue sky band + a visible
  sun disc across the top, green grass below, the Labrador grounded by a soft contact shadow, and
  **"BRA"** floating over the lower grass with **no** opaque control band (`.screenshots/po-tap-09.png`,
  `po-tap-11.png`, and the whole `po-free-*` sheet). Good.
- **P2-8 — the dog lives.** Across the 60-frame free-run (`.screenshots/po-free-*.png`, contact-sheeted)
  the dog **wandered** the patch through many distinct headings — front-facing seated, rear-facing
  walking away, three-quarter and side profiles — on a **real walk gait**, facing its travel direction
  with **no foot-slide**, and it **stayed framed** every frame. The cadence is **not** a metronome, and
  it now **completes** each sit: sit → seated apex → the 059 stand-up (during which `_drive_wander` is
  gated on `is_standing_up()`, so the roam pauses for the rise) → ambles on. Boot log confirms the
  living behaviour: `dog ambles a bounded patch between offers` + `varying the offer cadence 0.8–2.0s,
  sometimes feinting`. Good.
- **P2-9 — the fading timing trainer.** Caught the **bold cyan ring** live, unforced, encircling the
  BRA word as a fresh trick approaches its apex (`po-tap-06.png`, `po-tap-12/13.png`, and cyan rings
  dotted through the `po-free-*` sheet) — a cool outlined ring, clearly **distinct** from the gold apex
  tell, riding the same `SitWindow` as the score. Its prominence fades with the learned bar
  (`opacity = 1 − learned value`, unit-tested envelope): at ~50 % fill the ring is dim/thin
  (`po-master-00`), and at full mastery it is **entirely gone** (`po-master60-00/01` — solid gold bar,
  no ring). Good.
- **P2-4 — the learned bar fills and masters.** Under `?bra_autotap=1` the top meter fills **green** as
  PERFECTs land and then **latches a full-width solid-gold mastered bar** with the trainer ring gone
  (P2-9). I watched the whole arc across timed sweeps: ~50 % green at 28 s (`po-master-00`), ~80 % at
  45 s (`po-master45-01`), **full gold by ~60 s** (`po-master60-00/01`). Mastery is **5 clean PERFECTs**
  (`trick_progress.gd`: `PERFECT_GAIN 0.20`, `MASTERY 1.0`; OK adds only 0.08 — PERFECT clearly nets
  more), so the wall-clock is just the by-design variable cadence + feints (P2-8) spacing those five
  apexes out, and it drifts run-to-run with feint luck. Not a metronome grind, and it reaches a
  satisfying gold end. Good. *(Note for the sign-off pass: earlier passes cited "~26 s"; my timed runs
  read ~60 s of continuous PERFECT autotap — well within the intended spread, not a regression, but
  worth confirming the mastery **celebratory beat** and the erosion/confused-beat path in live pixels.)*
- **P2-5 — leave and come back.** *Not re-shot this pass* (the 059 stand-up touches the dog loop, not
  persistence, so it's unaffected). Carries forward from the prior same-origin reload verification: a
  filled bar came back at a substantial saved green fill after a real reload of the same browser origin,
  rather than resetting to empty — per-trick progress persists from `user://` (IndexedDB, no
  backend/account). *(Caveat for the sign-off pass: the prior restore read a little lower than the
  pre-reload fill — likely the last second or two of marks hadn't flushed to IndexedDB before reload;
  a sign-off pass should confirm the flush captures the very latest marks.)*
- **P2-7 — anti-mash freeze.** With `?bra_force_lock=1` the **"BRA"** word reads clearly **dimmed to a
  faint grey** (`po-lockon-00.png`) versus the crisp white "BRA" of every unlocked frame (`po-tap-08`,
  `po-tap-09`, etc.), so the locked state is legible and static (reduced-motion-safe); the fixed-350 ms
  re-arm is unit-tested. Good.
- *Still not cleanly pixel-verified (a sign-off-pass item, not a bug):* the **P2-4 erosion /
  confused-beat** path — the red setback wash + confused recoil on a wrong-moment tap. It is
  unit-tested and prior passes drove it via blind masher taps with 0 errors (the negative-learning path
  runs and never crashes), but the ~0.45 s recoil flash is brief enough that a strobe-sampled burst
  keeps missing it. A future sign-off pass should still catch the drop + wash + recoil in live pixels.

#### Bugfixes

- (none) — every run booted clean (`__appReady` true, licensed Sitt dog) with **zero** console
  errors; idle → wander → sit → mark → loop, fill, mastery, persistence, the lock, and the trainer
  ring (including its disappearance at mastery) all worked.

#### Improvements (buildable now)

- (none) — the buildable Phase-2 stories are all built and verified good (see "What holds up"). No
  buildable Phase-2 improvement remains; the one open Phase-2 gap is owner-gated (below).
- **Garden sun reads as a flat egg-shaped blob (minor, Phase-7-leaning — NOT a Phase-2 directive).**
  A hard-edged, slightly vertical-ellipse pale-yellow disc with no halo in every SwiftShader capture
  this pass (`po-tap-09.png`, `po-master60-00.png`, and across the `po-free-*` sheet); the procedural
  sky-sun glow may add a halo on real-device GL. *Why it's minor:* P2-10 explicitly defers richer
  environment art to Phase 7, so this does **not** block Phase 2 — flagged only so the Phase-7 pass
  tightens the sun to a crisp, haloed disc.

#### Changes / scope (owner-gated — the trick roster can't grow without it)

- **P2-1 / P2-2 / P2-3 need additional trick animation clips — owner-gated, and the *sole* blocker
  for Phase 2.** The whole point of Phase 2 is *more tricks at the Sitt standard*, but the licensed
  Labrador ships only the Sitt (+ idle + reaction) clips, so there is **no second trick** to select,
  perform, or polish — the game boots straight into the single-Sitt garden with no selector.
  *Why it's blocked:* a distinct, clean Ligg / Legg deg / Gi labb / Rull / Snurr animation is a
  licensed-asset deliverable, and the loop must **not** fake a sit or reuse one generic pose
  (CLAUDE.md). *What "good" needs:* the owner supplies the additional trick clips in the licensed
  asset; then the selector (P2-1), each trick's own distinct apex animation (P2-2), and its own
  Visual Review (P2-3) become buildable. **All other Phase-2 work is complete**, so until the clips
  arrive there is nothing else to build — do **not** build a one-entry selector or fake a second
  trick. (Keep/raise the owner flag in `.task-board/FLAGS.md`.)

**Sign-off status:** Phase 2 stays open, **blocked solely on the owner**. This pass re-played
current HEAD including the **new 059 stand-up**, which I verified clean (seated → rise → stand, no
T-pose/snap/slide — a keeper for P2-8). Every buildable story (P2-4, P2-5, P2-7, P2-8, P2-9, P2-10) is
complete and holds up — garden, wandering dog that now completes each sit through the stand-up,
variable-cadence feints, fading trainer ring (gone at mastery), green fill → full-gold 5-PERFECT
mastery bar, and the anti-mash lock (P2-5 persistence carried forward, unaffected by 059). The
remaining gate is the **owner-supplied trick clips** (P2-1/P2-2/P2-3), each new trick clearing its
**own Visual Review (P2-3)**, plus three things a future sign-off pass should still catch in live
pixels: the **P2-4 erosion / confused-beat** setback, the **mastery celebratory beat**, and that the
persistence flush captures the very latest marks. **No new buildable directives this pass — do not
invent work.**

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
