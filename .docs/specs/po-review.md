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

Re-played Phase 2 on the **current-HEAD local licensed bundle** (`build/web` — the 38 MB pck that
bundles the unencrypted, sit-capable Labrador) served over http and driven in headless Chromium at
390×844 — SwiftShader == the deployed GL Compatibility renderer. I drove the **local current-HEAD
export** rather than the live Pages site because tasks **048 / 050 / 058** landed minutes ago and the
CI deploy lags; the bundle is byte-current for gameplay (the two newest commits touched only the
board + capture tools). Boot is clean: `__appReady` true, `dog loaded: …dog_licensed.glb` +
`dog can Sitt`, **zero** SCRIPT ERROR / pageerror across every run.

**The two directives from the last pass are now BUILT and verified good in live pixels** — **P2-8**
(variable cadence + feints, task 048; bounded-patch wander, task 050) and **P2-9** (fading timing
trainer, task 058). With those landed, **every *buildable* Phase-2 story is now done and holds up**
(P2-4, P2-5, P2-7, P2-8, P2-9, P2-10). The **only** thing keeping Phase 2 open is the owner-gated
trick roster (**P2-1 / P2-2 / P2-3** — see Changes): the licensed dog still ships only the Sitt, so
there is no second trick to select, perform, or polish. **There is no new buildable work this pass.**
Do not sign Phase 2 off, and do not invent filler — the loop now waits on the owner for trick clips.

**What holds up (verified live this pass, keep it):**
- **P2-10 — the garden.** Present in every frame: sky band + a visible sun across the top, green
  grass below, the Labrador grounded by a soft contact shadow, and **"BRA"** floating over the lower
  grass with **no** opaque control band (`.screenshots/po2-wander-08.png`). Good.
- **P2-8 — the dog now lives (was the #1 gap; now good).** Over a 36 s non-forced run the dog
  **wandered** the patch — its horizontal centroid roamed **x≈85↔299** across a 390-wide frame,
  walking to each edge and **turning back** so it never left frame, on a **real walk gait**: it
  **faces its travel direction** mid-stride, no foot-slide (`po2-wander-08.png` — dog at the left
  edge, facing left, mid-stride). Sits now land at **varying positions**, not dead-centre
  (`po2-wander-40.png` — a clean Sitt at the right edge). The metronome is gone: `scripts/sit_loop.gd`
  draws each idle gap **fresh from [0.8 s, 2.0 s]** and **35 %** of offers are **feints** (a
  dip-and-abort opening no markable window; the feint reuses the real sit build-in, so a sit-less dog
  can never fake one). A live ring burst found the trainer cue **dark in 45/60 frames** — i.e. dark
  between offers / during feints, consistent with no window opening on a feint. Good.
- **P2-9 — the fading timing trainer (was the #2 gap; now good).** On a brand-new trick (empty bar)
  a **bold cyan ring** appears and **shrinks onto the BRA word, landing exactly at the apex**: a live
  non-forced burst caught the **big** ring mid-approach (`058-live-25-cy5373.png`) and the **landed**
  small ring tight around BRA at the instant the dog is **fully seated at apex** (`058-live-32-cy2916.png`),
  and it reads **distinct from the gold "now" apex tell** (a separate gold halo fires the same
  instant). It **fades as the bar fills and is gone at mastery**: under autotap the ring's lower-band
  cyan averaged ~266 px while learning and **0 px once the bar latched gold**, with the dog **still
  cycling** — not frozen (`po2-fade-08.png` bar ~20 % green, ring active during sits; `po2-fade-112.png`
  full **gold** bar, **no ring**, dog mid-reaction). It rides the same `SitWindow` (present only during
  real sit approaches). Good.
- **P2-4 — the learned bar fills and masters.** The top meter fills **green** with PERFECTs and
  **latches a full gold** bar at mastery (`po2-fade-08.png` ~20 % green; `po2-fade-112.png` full
  gold); PERFECT clearly nets forward. Good.
- **P2-7 — anti-mash freeze.** Untouched by 048/050/058; the fixed-350 ms re-arm is unit-tested and
  the dim-lock seam (`?bra_force_lock=1`) was verified live last pass. Good.
- **P2-5 — leave and come back.** Per-trick progress persisted across a plain reload last pass (task
  049, `user://` IndexedDB, no backend); untouched this pass. Good.
- *Not yet pixel-verified (for the eventual sign-off pass):* the **P2-4 erosion / confused-beat**
  path — a MISS/DEAD dropping the bar, the brief red setback wash, and the dog's confused recoil.
  `?bra_autotap=1` only fires PERFECT, and the wash/wobble are ~0.45 s flashes a strobe-sampled burst
  can miss; the mechanic is unit-tested, but a sign-off pass should still catch the drop + wash +
  recoil in live pixels.

#### Bugfixes

- (none) — every run booted clean (`__appReady` true, licensed Sitt dog) with **zero** console
  errors; idle → wander → sit → mark → loop, mastery, the fade, and the trainer ring all worked.

#### Improvements (buildable now)

- (none) — **P2-8** and **P2-9**, the only two buildable Phase-2 stories outstanding last pass, are
  now built and verified good (see "What holds up"). No buildable Phase-2 improvement remains; the
  one open Phase-2 gap is owner-gated (below).
- **Garden sun reads as a flat egg-shaped blob (minor, Phase-7-leaning).** Still a hard-edged,
  slightly vertical-ellipse yellow disc with no halo in the SwiftShader capture (`po2-wander-40.png`);
  the procedural sky-sun glow may add a halo on real-device GL. *Why it's minor:* P2-10 explicitly
  defers richer environment art to Phase 7, so this does **not** block Phase 2 — flagged only so the
  Phase-7 pass tightens the sun to a crisp, haloed disc.

#### Changes / scope (owner-gated — the trick roster can't grow without it)

- **P2-1 / P2-2 / P2-3 need additional trick animation clips — owner-gated, and now the *sole*
  blocker for Phase 2.** The whole point of Phase 2 is *more tricks at the Sitt standard*, but the
  licensed Labrador ships only the Sitt (+ idle + reaction) clips, so there is **no second trick** to
  select, perform, or polish — the game boots straight into the single-Sitt garden with no selector.
  *Why it's blocked:* a distinct, clean Ligg / Legg deg / Gi labb / Rull / Snurr animation is a
  licensed-asset deliverable, and the loop must **not** fake a sit or reuse one generic pose
  (CLAUDE.md). *What "good" needs:* the owner supplies the additional trick clips in the licensed
  asset; then the selector (P2-1), each trick's own distinct apex animation (P2-2), and its own
  Visual Review (P2-3) become buildable. **All other Phase-2 work is now complete**, so until the
  clips arrive there is nothing else to build — do **not** build a one-entry selector or fake a
  second trick. (Keep/raise the owner flag in `.task-board/FLAGS.md`.)

**Sign-off status:** Phase 2 stays open, but is now **blocked solely on the owner**. Every buildable
story (P2-4, P2-5, P2-7, P2-8, P2-9, P2-10) is complete and verified good; the remaining gate is the
**owner-supplied trick clips** (P2-1/P2-2/P2-3), each new trick clearing its **own Visual Review
(P2-3)**, and a sign-off pass catching the **P2-4 erosion / confused-beat** in live pixels. **No new
buildable directives this pass — do not invent work.**

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
