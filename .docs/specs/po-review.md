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

### Owner directive — 2026-07-01 (larssski)

Two owner asks captured directly (not from a father play-test) — both **current-phase
(Phase 2)** work, so they **preempt** any work-ahead. Status after my 2026-07-01 re-play below:

1. **Garden — push the stylization a bit further (P2-10 improvement, buildable now).** The
   functional garden reads, but it's plain. Give it **more stylized, Pokémon-GO-style
   character** — a richer/warmer sky gradient, a more **shaped, painterly grass** (not a flat
   green plane), and a more deliberate sun — while staying clean and phone-legible with the dog
   as the clear focus. This is a **modest step now**, *not* the full Phase-7 environment-art
   pass (props / depth / heavy lighting polish still defer to **Phase 7**) — keep it cheap and
   readable. Ride a Visual-Review capture. *(Improvement, not a bug — the garden isn't broken.)*
   **→ DELIVERED (task 062, commit `c0ab6cd`) and Visual-Review-verified good this pass** — the sky is now a
   warm blue→peach gradient, the sun is a genuine **haloed** disc (bright warm core + soft golden glow, round —
   no longer the hard flat egg), and the grass is **painterly noise-mottled** (deep/mid/sunny-green patches,
   not one flat plane), with **no** cyan horizon seam. See the P2-10 entry under "What holds up" below.
2. **Dog faces the player for tricks — new story P2-11** (added to `phase2.md`). Whenever the
   dog performs a **real** trick it turns to face the camera POV so the apex reads head-on;
   a feint keeps its wander heading. Buildable now (Sitt only); build + Visual-Review it.
   **→ DELIVERED (task 061, commit `f2f3d17`) and Visual-Review-verified good this pass** — see
   the P2-11 entry under "What holds up" below.

### PO Review — 2026-07-01

Fresh, fully independent **re-verification** re-play on **current HEAD (commit `c0ab6cd` — the 062
garden stylization, on top of 061 face-turn + 060 voice)** — my own harness (`/tmp/po_capture.mjs`),
my own eyes on every frame, my own new captures (this pass under `.screenshots/po-fresh/`, distinct
from the prior pass's `po062/`). Drove the **current-HEAD local licensed bundle** (`build/web` — the
38 MB pck that bundles the unencrypted, sit-capable Labrador; `index.pck` mtime 13:27 sits *after*
every source, `find scripts scenes assets -newer build/web/index.pck` empty, tree clean → byte-current
for gameplay, includes the 062 garden stylization) served over a local http origin and driven in
headless Chromium at 390×844 — SwiftShader == the deployed GL Compatibility renderer. (Local export
over live Pages because CI lags the last gameplay commits.) Boot is clean on every run: `__appReady`
true, `dog loaded: …dog_licensed.glb (1 coat surface forced opaque)`, `dog ambles a bounded patch
between offers`, `dog can Sitt — varying the offer cadence 0.8–2.0s, sometimes feinting`, and **zero**
SCRIPT ERROR / pageerror across all runs (a 14-frame free-run living-loop burst, an 18-frame
fine-spaced autotap sit→turn→mark→stand-up cycle, a forced-lock capture, and a forced-trainer-ring
capture — all under `.screenshots/po-fresh/`).

**No genuinely new item this pass — this is a re-verification.** The one new build since my last pass,
P2-10 garden stylization (task 062), was delivered before this pass and I **re-confirmed it good** in
my own fresh full-res pixels (`.screenshots/po-fresh/zoom-sky-free03.png`, `lock-vs-unlock.png`,
`trainer-00.png`, and the `sheet-free.png` / `sheet-tap.png` contact sheets). All three things the
owner asked for hold:
- **Warmer sky.** The old blue→flat-pale-yellow band is now a **bright sky-blue zenith grading down to
  a warm peach/cream horizon** — the Pokémon-GO warmth asked for. Reads clean behind the dog and UI.
- **A deliberate, haloed sun.** The old **hard flat egg** is replaced by a round disc with a
  **bright near-white core → golden body → a soft transparent halo** that glows into the peach sky.
  Crisp and deliberate, and round from the look-down angle (billboarded), exactly the ask.
- **Painterly grass.** The old single flat gradient plane now carries **low-frequency mottled patches
  of deep-shadow / mid / sunny green**, so the lawn reads painterly rather than a flat fill — a tonal
  "shape" (Phase-7 still owns real relief/props). Cheap, phone-legible, dog stays the clear focus.
And the earlier seam worry is gone: the grass meets the warm horizon haze **with no cyan sliver**, and
**BRA** still floats over the grass with **no** opaque control band. A modest, correct Phase-2 step —
not a Phase-7 environment pass. Keep it.

**P2-11 "face me for the trick" (task 061) still holds this pass.** Re-confirmed on the autotap
sit-cycle (`sheet-tap.png`): the dog walks in three-quarter/side → **rotates to face the camera on its
walk** (smooth, no snap, no foot-slide) → **seated apex facing head-on** with the gold ring +
**PERFECT** → 059 stand-up → turns away and ambles on. It **completes the turn before the apex** every
cycle, and stays correctly tied to the real trick only — in wander frames the dog faces its *travel*
direction (rear/side views dot the free-run sheet), never face-locking outside a committed trick.

**Every *buildable* Phase-2 story is now done and holds up in my own live pixels** (P2-4, P2-5, P2-7,
P2-8, P2-9, P2-10 incl. the 062 stylization, P2-11). With the garden directive now cleared,
there is **no buildable current-phase directive left** — Phase 2 is now blocked **purely** on owner
assets + the human sign-off. The one remaining gate is the **owner-gated trick roster** (**P2-1 /
P2-2 / P2-3** — see Changes): the licensed dog still ships only the Sitt, so there is no second trick
to select, perform, or polish, and Phase 2's headline "more tricks" capability can't be delivered
without owner-supplied clips. Do **not** sign Phase 2 off.

**What holds up (verified live this pass, keep it):**
- **P2-10 — the garden (functional + now stylized).** *Stylized in 062, re-verified good this pass* (see
  the dedicated paragraph above). Warm blue→peach sky gradient, a **haloed** sun disc (core + soft
  golden glow, round), **painterly mottled** grass, the Labrador grounded by a soft contact shadow, and
  **"BRA"** floating over the lower grass with **no** opaque control band and **no** cyan horizon seam
  (`.screenshots/po-fresh/zoom-sky-free03.png`, `trainer-00.png`, and the whole `sheet-free.png`). The
  garden now reads with real Pokémon-GO character while the dog stays the clear focus.
- **P2-11 — face me for the trick.** Holds this pass (see the dedicated paragraph above and
  `sheet-tap.png`). Dog turns head-on before the sit apex, smooth in-character turn, completes before
  the apex, and does **not** face-lock outside real tricks.
- **P2-8 — the dog lives.** Across the 14-frame free-run (`.screenshots/po-fresh/free-*.png`,
  contact-sheeted to `sheet-free.png`) the dog **wandered** the patch through many distinct headings —
  front-facing seated, rear-facing walking away, three-quarter and side profiles — on a **real walk
  gait**, facing its travel direction with **no foot-slide**, and it **stayed framed** every frame.
  Cadence is **not** a metronome, and it **completes** each sit through the 059 stand-up before ambling
  on. Boot log confirms: `dog ambles a bounded patch between offers` + `varying the offer cadence
  0.8–2.0s, sometimes feinting`. Good.
- **P2-9 — the fading timing trainer.** Caught the **bold cyan ring** live, unforced, encircling the
  BRA word as a fresh trick approaches its apex (dotted through the `sheet-free.png` sheet and confirmed
  pinned under `?bra_force_trainer=1`, `.screenshots/po-fresh/trainer-00.png`) — a cool outlined ring,
  clearly **distinct** from the gold apex tell, riding the same `SitWindow` as the score. Its
  prominence fades with the learned bar (unit-tested `opacity = 1 − learned` envelope). Good.
- **P2-4 — the learned bar fills.** Under `?bra_autotap=1` the top meter fills **green** as PERFECTs
  land (the `sheet-tap.png` autotap cycle shows the green fill climbing across rows 2–3 + the gold
  **PERFECT** readout in the clear sky). The full-gold mastered latch + the trainer ring going away at
  mastery were pixel-verified in prior passes; this run confirms the fill mechanic is intact and
  climbing. Good.
- **P2-7 — anti-mash freeze.** With `?bra_force_lock=1` the **"BRA"** word reads clearly **dimmed to a
  faint grey** versus the crisp white "BRA" of every unlocked frame — captured side-by-side in
  `.screenshots/po-fresh/lock-vs-unlock.png` — so the locked state is legible and static
  (reduced-motion-safe); the fixed-350 ms re-arm is unit-tested. Good.
- **P2-5 — leave and come back.** *Not re-shot this pass* (060 voice + 061 face-turn + 062 garden touch
  neither the save path nor persistence). Carries forward from the prior same-origin reload verification: a filled
  bar came back at a substantial saved green fill after a real reload of the same browser origin — per-
  trick progress persists from `user://` (IndexedDB, no backend/account).
- *Still not cleanly pixel-verified (a sign-off-pass item, not a bug):* the **P2-4 erosion /
  confused-beat** path (red setback wash + confused recoil on a wrong-moment tap), the **mastery
  celebratory beat**, and that the **persistence flush** captures the very latest marks. All are
  unit-tested and run without crashing; the recoil/celebration flashes are brief enough that a
  strobe-sampled burst keeps missing them. A future sign-off pass should still catch them in live pixels.

#### Bugfixes

- (none) — every run booted clean (`__appReady` true, licensed Sitt dog) with **zero** console errors;
  idle → wander → **turn to face the camera** → sit → mark → stand-up → loop, plus fill, the lock, and
  the trainer ring all worked.

#### Improvements (buildable now)

- (none) — the sole prior improvement directive, the **garden stylization** (P2-10, owner directive
  item 1), was **built (task 062, commit `c0ab6cd`) and re-verified good this pass** in my own fresh
  pixels (warmer peach sky, haloed sun, painterly mottled grass, no cyan seam — see "What holds up").
  Pruned. No other buildable current-phase improvement stands: every buildable Phase-2 story holds live.

#### Changes / scope (owner-gated — the trick roster can't grow without it)

- **P2-1 / P2-2 / P2-3 need additional trick animation clips — owner-gated.** The whole point of
  Phase 2 is *more tricks at the Sitt standard*, but the licensed Labrador ships only the Sitt (+ idle
  + reaction) clips, so there is **no second trick** to select, perform, or polish — the game boots
  straight into the single-Sitt garden with no selector. *Why it's blocked:* a distinct, clean Ligg /
  Legg deg / Gi labb / Rull / Snurr animation is a licensed-asset deliverable, and the loop must
  **not** fake a sit or reuse one generic pose (CLAUDE.md). *What "good" needs:* the owner supplies the
  additional trick clips in the licensed asset; then the selector (P2-1), each trick's own distinct
  apex animation (P2-2), and its own Visual Review (P2-3) become buildable. Do **not** build a
  one-entry selector or fake a second trick. (Keep/raise the owner flag in `.task-board/FLAGS.md`.)

**Sign-off status:** Phase 2 stays open. This pass independently re-played current HEAD including the
**062 garden stylization**, which I re-verified clean and good in my own fresh pixels (warm peach sky,
haloed sun, painterly mottled grass, no cyan seam, dog stays the focus — the sole buildable directive
from my last pass is now cleared).
Every buildable Phase-2 story now holds (P2-4, P2-5, P2-7, P2-8, P2-9, P2-10, P2-11), so **there is
no buildable current-phase directive left** — Phase 2 is now blocked **purely** on the owner + the
human sign-off. The remaining gate is **owner-gated** on trick clips (P2-1/P2-2/P2-3), each new trick
clearing its **own Visual Review (P2-3)**; the licensed dog ships only the Sitt, so the phase's
headline "more tricks" capability cannot yet be delivered. Plus three things a future sign-off pass
should still catch in live pixels: the **P2-4 erosion / confused-beat** setback, the **mastery
celebratory beat**, and that the persistence flush captures the very latest marks. Do not sign off
yet, and do not invent other work — the loop may work-ahead (dormant) while it waits on the owner.

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
