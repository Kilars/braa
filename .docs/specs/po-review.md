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
   **→ Stylization DELIVERED (task 062, commit `c0ab6cd`), content re-verified good this pass** — the sky is
   now a warm blue→peach gradient, the sun is a genuine **haloed** disc (bright warm core + soft golden glow,
   round — no longer the hard flat egg), and the grass is **painterly noise-mottled** (deep/mid/sunny-green
   patches, not one flat plane), with **no** cyan horizon seam. See the P2-10 entry under "What holds up".
   **Caveat found this pass:** the stylized world renders inside a 9:16 **black letterbox** on 390×844 (a
   separate config defect, not the stylization ask) — filed under **Bugfixes**; the content stays, the box goes.
2. **Dog faces the player for tricks — new story P2-11** (added to `phase2.md`). Whenever the
   dog performs a **real** trick it turns to face the camera POV so the apex reads head-on;
   a feint keeps its wander heading. Buildable now (Sitt only); build + Visual-Review it.
   **→ DELIVERED (task 061, commit `f2f3d17`) and Visual-Review-verified good this pass** — see
   the P2-11 entry under "What holds up" below.

### PO Review — 2026-07-01

Fresh, fully independent re-play on **current HEAD (commit `88e0972` / tree at `c0ab6cd` — the 062
garden stylization, on top of 061 face-turn + 060 voice)** — my own harness
(`tools/po_phase2_pass.mjs` + `tools/po_letterbox_check.mjs`), my own eyes on every frame, my own new
captures under `.screenshots/po-p2/`. Drove the **current-HEAD local licensed bundle** (`build/web` —
the 38 MB pck that bundles the unencrypted, sit-capable Labrador; `index.pck` mtime 13:42 sits *after*
every source, `find scripts scenes assets -newer build/web/index.pck` empty, tree clean → byte-current
for gameplay, includes the 062 garden stylization) served over a local http origin and driven in
headless Chromium at 390×844 — SwiftShader == the deployed GL Compatibility renderer — and I also
drove the **live Pages site** (https://kilars.github.io/braa/) at 390×844 for the letterbox check
below. Boot is clean on every run: `__appReady` true, `dog loaded: …dog_licensed.glb (1 coat surface
forced opaque)`, `dog ambles a bounded patch between offers`, `dog can Sitt — varying the offer
cadence 0.8–2.0s, sometimes feinting`, and **zero** SCRIPT ERROR / pageerror across all runs (a
16-frame free-run living-loop burst, an 18-frame autotap sit→turn→mark→stand-up cycle, a forced-lock
capture, and a forced-trainer-ring capture — all under `.screenshots/po-p2/`).

**This pass found a real, buildable current-phase defect the prior re-verification missed: the garden
is letterboxed by black bars on the mandated 390×844 phone viewport (see Bugfixes).** The letterbox
black blends into the black montage gutters, which is how a contact-sheet-only look slides past it —
a per-row brightness scan + a magenta-bordered full frame (`.screenshots/po-p2/zoom-letterbox.png`)
make it undeniable, on **both** the local bundle and the live site. So the earlier "no buildable
current-phase directive left / blocked purely on owner" conclusion no longer holds — there is a
buildable fix to make now (**not** owner-gated).

**The garden stylization CONTENT (task 062) holds — but the world is boxed by a black letterbox (new
Bugfix above).** The owner's three stylization asks were all delivered and I re-confirmed them good in
my own fresh full-res pixels (`.screenshots/po-p2/zoom-sky.png`, `zoom-lock.png`, `sheet-free.png` /
`sheet-tap.png`):
- **Warmer sky.** The old blue→flat-pale-yellow band is now a **bright sky-blue zenith grading down to
  a warm peach/cream horizon** — the Pokémon-GO warmth asked for. Reads clean behind the dog and UI.
- **A deliberate, haloed sun.** The old **hard flat egg** is replaced by a round disc with a
  **bright near-white core → golden body → a soft transparent halo** that glows into the peach sky.
  Crisp and deliberate, and round from the look-down angle (billboarded), exactly the ask.
- **Painterly grass.** The old single flat gradient plane now carries **low-frequency mottled patches
  of deep-shadow / mid / sunny green**, so the lawn reads painterly rather than a flat fill — a tonal
  "shape" (Phase-7 still owns real relief/props). Cheap, phone-legible, dog stays the clear focus.
The earlier seam worry is gone: the grass meets the warm horizon haze **with no cyan sliver**, and
**BRA** floats over the grass with **no** opaque control band. Good stylization — but it renders inside
a 9:16 letterbox, so on a real phone the sky is capped by a black band above and the grass by a black
band below (see Bugfixes). **The stylization stays; the letterbox is the fix.**

**P2-11 "face me for the trick" (task 061) still holds this pass.** Re-confirmed on the autotap
sit-cycle (`sheet-tap.png`): the dog walks in three-quarter/side → **rotates to face the camera on its
walk** (smooth, no snap, no foot-slide) → **seated apex facing head-on** with the gold ring +
**PERFECT** → 059 stand-up → turns away and ambles on. It **completes the turn before the apex** every
cycle, and stays correctly tied to the real trick only — in wander frames the dog faces its *travel*
direction (rear/side views dot the free-run sheet), never face-locking outside a committed trick.

**Each Phase-2 story's mechanic holds up in my own live pixels** (P2-4, P2-5, P2-7, P2-8, P2-9,
P2-10-stylization, P2-11) — but P2-10 is **not** clean: the look-down world is letterboxed on the
mandated phone viewport (see Bugfixes), so there **is** a buildable current-phase directive to make
now. Phase 2 is therefore **not** blocked purely on the owner: fix the letterbox first. Separately,
the **owner-gated trick roster** (**P2-1 / P2-2 / P2-3** — see Changes) also still blocks the phase's
headline: the licensed dog ships only the Sitt, so there is no second trick to select, perform, or
polish, and "more tricks" can't be delivered without owner-supplied clips. Do **not** sign Phase 2 off.

**What holds up (verified live this pass, keep it):**
- **P2-10 — the garden (stylized content good, but letterboxed → see Bugfixes).** The *content*
  re-verified good this pass (see the dedicated paragraph above): warm blue→peach sky gradient, a
  **haloed** sun disc (core + soft golden glow, round), **painterly mottled** grass, the Labrador
  grounded by a soft contact shadow, and **"BRA"** floating over the lower grass with **no** opaque
  control band and **no** cyan horizon seam (`.screenshots/po-p2/zoom-sky.png`, and the whole
  `sheet-free.png`). It reads with real Pokémon-GO character and the dog stays the focus — **but** the
  whole world renders in a 9:16 letterbox with black bands top and bottom on 390×844
  (`.screenshots/po-p2/zoom-letterbox.png`), so the acceptance criterion "a world to play in" that
  fills the phone is **not** met yet. Not a hold — filed as a Bugfix.
- **P2-11 — face me for the trick.** Holds this pass (see the dedicated paragraph above and
  `sheet-tap.png`). Dog turns head-on before the sit apex, smooth in-character turn, completes before
  the apex, and does **not** face-lock outside real tricks.
- **P2-8 — the dog lives.** Across the 16-frame free-run (`.screenshots/po-p2/free-*.png`,
  contact-sheeted to `sheet-free.png`) the dog **wandered** the patch through many distinct headings —
  front-facing seated, rear-facing walking away, three-quarter and side profiles — on a **real walk
  gait**, facing its travel direction with **no foot-slide**, and it **stayed framed** every frame.
  Cadence is **not** a metronome, and it **completes** each sit through the 059 stand-up before ambling
  on. Boot log confirms: `dog ambles a bounded patch between offers` + `varying the offer cadence
  0.8–2.0s, sometimes feinting`. Good.
- **P2-9 — the fading timing trainer.** Caught the **bold cyan ring** live, unforced, encircling the
  BRA word as a fresh trick approaches its apex (dotted through the `sheet-free.png` sheet and confirmed
  pinned under `?bra_force_trainer=1`, `.screenshots/po-p2/train-00.png`) — a cool outlined ring,
  clearly **distinct** from the gold apex tell, riding the same `SitWindow` as the score. Its
  prominence fades with the learned bar (unit-tested `opacity = 1 − learned` envelope). Good.
- **P2-4 — the learned bar fills.** Under `?bra_autotap=1` the top meter fills **green** as PERFECTs
  land — I cropped the bar early vs late (`.screenshots/po-p2/zoom-bar3.png`): an **empty grey track**
  at the start of the cycle, **~55 % green** later, with the gold **PERFECT** readout firing in the
  clear sky. The full-gold mastered latch + the trainer ring going away at mastery were pixel-verified
  in prior passes; this run confirms the fill mechanic is intact and climbing. Good.
- **P2-7 — anti-mash freeze.** With `?bra_force_lock=1` the **"BRA"** word reads clearly **dimmed to a
  faint grey** versus the crisp white "BRA" of every unlocked frame — captured side-by-side in
  `.screenshots/po-p2/zoom-lock.png` — so the locked state is legible and static
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

- **The garden is letterboxed by black bars on real phones — the look-down world doesn't fill the
  screen (P2-10 / X-1).** *What I saw:* on the mandated **390×844** phone-portrait viewport (the
  canonical iPhone logical resolution), the whole scene renders inside a fixed **9:16** box with a
  **pure-black band across the top (~75 px) and the bottom (~64 px)** — together ~16 % of the screen.
  Measured objectively (rows 0–74 and 780–843 read mean brightness **0**; the sky only begins at row
  ~75) and shown framed in `.screenshots/po-p2/zoom-letterbox.png` (magenta = the true frame edge).
  The canvas element itself fills 390×844 (top=0), so the bars are drawn **by the engine**, and it
  reproduces **identically on the live deployed Pages site** (`letterbox-live.png`), not just locally.
  Root cause is in the committed config: `project.godot` sets `window/stretch/aspect="keep"` against a
  **720×1280 (9:16, 0.5625)** design, so any device taller than 9:16 — every modern phone (iPhone X+ ≈
  0.462, most Android ≈ 0.46) — gets letterboxed. *Why it's wrong:* **P2-10** promises a Pokémon-GO
  look-down **"world to play in"** that *replaces the flat void* and lets the dog roam; framing that
  world in black voids top and bottom undercuts the immersion and wastes ~1/6 of a phone screen, and
  **X-1** is "built for one-hand portrait phone." The stylization content the owner asked for (warm
  sky, haloed sun, painterly grass) landed well — but it's boxed. *What "good" looks like:* the garden
  **fills the full phone screen** — no black bands at 390×844 (rows 0 and 843 are garden, not black) —
  across the common portrait aspect range (~0.46–0.56). The standard mobile fix is
  `window/stretch/aspect="expand"` (or `"keep_width"`) so the sky/grass extend to the top and bottom
  edges while the dog stays centered and the BRA / learned-bar UI stay anchored; then re-verify in
  live pixels at 390×844 that no black letterbox remains. Buildable now — **not** owner-gated.
- Otherwise every run booted clean (`__appReady` true, licensed Sitt dog) with **zero** console errors;
  idle → wander → **turn to face the camera** → sit → mark → stand-up → loop, plus the green fill, the
  lock, and the trainer ring all worked inside the (letterboxed) frame.

#### Improvements (buildable now)

- (none new as an *improvement*) — the sole prior improvement directive, the **garden stylization**
  (P2-10, owner directive item 1), was **built (task 062, commit `c0ab6cd`) and its content re-verified
  good this pass** in my own fresh pixels (warmer peach sky, haloed sun, painterly mottled grass, no
  cyan seam — see "What holds up"). Pruned. The one open buildable current-phase item this pass is a
  correctness defect, not a polish improvement — the garden **letterbox** — filed under **Bugfixes**.

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

**Sign-off status:** Phase 2 stays **open** — and this pass it is **not** blocked purely on the owner.
Each Phase-2 mechanic holds in my own live pixels (P2-4 green fill climbs, P2-5 persists, P2-7 lock
dims legibly, P2-8 wander, P2-9 fading cyan trainer ring, P2-10 stylization content, P2-11 face-turn),
but I found a **buildable current-phase defect**: on the mandated 390×844 phone viewport the look-down
garden is **letterboxed** by black bands top and bottom (`window/stretch/aspect="keep"` at 720×1280),
reproduced on **both** the local bundle and the **live** site — so P2-10's "a world to play in" that
fills the phone is not met. **Fix the letterbox** (see Bugfixes) before Phase 2 can be signed off; it
**preempts** any work-ahead. Separately, the phase's headline "more tricks" stays **owner-gated** on
trick clips (P2-1/P2-2/P2-3), each new trick clearing its **own Visual Review (P2-3)** — the licensed
dog ships only the Sitt. And three things a future sign-off pass should still catch in live pixels:
the **P2-4 erosion / confused-beat** setback, the **mastery celebratory beat**, and that the
persistence flush captures the very latest marks. Do not sign off yet.

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
