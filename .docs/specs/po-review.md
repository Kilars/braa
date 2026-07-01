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

### PO Review — 2026-07-01 (HEAD `a6cab96` / task 063 — letterbox fix)

Fresh, fully independent re-play on **current HEAD `a6cab96`** — task 063 flips
`window/stretch/aspect` from `keep` → `expand`, on top of 062 garden stylization / 061 face-turn /
060 voice. My own eyes on every frame; new captures under `.screenshots/po-p2-063/`. Drove the
**current-HEAD local licensed bundle** (`build/web` — the 38 MB pck that bundles the unencrypted,
sit-capable Labrador; `index.pck` mtime 14:06 sits *after* the `project.godot` edit at 14:05 and so
bakes in the 063 stretch change; tree clean, only a non-runtime clips-inventory `.txt` is newer)
served over a local http origin in headless Chromium at 390×844 — SwiftShader == the deployed GL
Compatibility renderer — **and** the **live Pages site** (https://kilars.github.io/braa/) at
390×844. Boot is clean on every run: `__appReady` true, `dog loaded: …dog_licensed.glb (1 coat
surface forced opaque)`, `dog ambles a bounded patch between offers`, `dog can Sitt — varying the
offer cadence 0.8–2.0s, sometimes feinting`, and **zero** SCRIPT ERROR / pageerror across all four
scenarios (a 16-frame free-run living-loop burst, an 18-frame autotap sit→turn→mark→stand-up cycle,
a forced-lock capture, and a forced-trainer-ring capture — all under `.screenshots/po-p2-063/`).

**The prior pass's sole buildable defect — the garden letterbox (P2-10 / X-1) — is FIXED (task
063).** On the mandated 390×844 phone viewport the look-down garden now **fills the whole screen,
no black bands top or bottom.** Objective per-row brightness scan (`tools/po_letterbox_verify.mjs`,
the same measurement that caught it): **local** row 0 = 183.5 (bright sky), row 843 = 80.7 (grass);
**live** row 0 = 183.5, row 843 = 82.1 — both far above the ~0 a pure-black band read last pass
(rows 0–74 and 780–843 previously read mean 0). Confirmed in my own pixels on **both** builds
(`.screenshots/po-p2-063/letterbox-fixed-local.png`, `letterbox-live.png`): the warm sky-blue→peach
gradient now reaches the **top edge** with the haloed sun up top, the painterly grass fills to the
**bottom edge** under **"BRA"**, the dog stays centered, and the learned bar + BRA UI re-anchor to
the new edges. The `stretch=expand` fix **propagated to the live deployed site too**, not just the
local bundle. Pruned from Bugfixes.

**Every Phase-2 mechanic still holds on the 063 build — no regressions from the stretch flip.** A
`keep → expand` change is exactly the kind that can shear UI anchoring or dog framing; it didn't.
Re-verified in my own live pixels (`.screenshots/po-p2-063/sheet-free.png`, `sheet-tap.png`,
`bar-progress.png`, `lock-compare.png`):

- **P2-10 — the garden, now filling the phone.** The stylized *content* re-confirms good — warm
  blue→peach sky, a **haloed** sun disc (bright core → golden body → soft transparent halo, round
  from the look-down angle), **painterly mottled** grass (deep-shadow / mid / sunny-green patches,
  not a flat fill), the Labrador grounded by a soft contact shadow, **"BRA"** over the lower grass
  with **no** opaque control band and **no** cyan horizon seam — **and** it now renders edge-to-edge
  on 390×844 with the dog the clear focus. Real Pokémon-GO character; the black voids are gone.
- **P2-11 — face me for the trick.** On the autotap cycle (`sheet-tap.png`) the dog walks in
  three-quarter/side → **rotates to face the camera on its walk** (smooth, no snap, no foot-slide) →
  **seated apex facing head-on** with the cyan approach ring + **PERFECT** in clear sky → 059
  stand-up → turns away and ambles on. It **completes the turn before the apex** every cycle, and
  stays tied to the real trick only — in wander frames the dog faces its *travel* direction (rear /
  side views across `sheet-free.png`), never face-locking outside a committed trick.
- **P2-8 — the dog lives.** Across the 16-frame free-run (`sheet-free.png`) the dog **wandered** the
  patch through many distinct headings — rear-facing walking away, three-quarter and side profiles,
  front-facing seated — on a **real walk gait**, facing its travel direction with **no foot-slide**,
  staying **framed** every frame. Cadence is **not** a metronome, and each sit **completes** through
  the 059 stand-up. Boot log confirms `dog ambles a bounded patch` + `varying the offer cadence
  0.8–2.0s, sometimes feinting`. Good.
- **P2-9 — the fading timing trainer.** Caught the **bold cyan ring** live, unforced, encircling the
  BRA word as a fresh trick approaches its apex (`sheet-tap.png` frames 2/7 and dotted through
  `sheet-free.png`) — a cool outlined ring, clearly **distinct** from the gold apex tell, riding the
  same `SitWindow` as the score; its prominence fades with the learned bar (unit-tested
  `opacity = 1 − learned` envelope). Good.
- **P2-4 — the learned bar fills.** Under `?bra_autotap=1` the top meter goes from an **empty grey
  track** early to **~40 % green** later as PERFECTs land — cropped side-by-side in
  `.screenshots/po-p2-063/bar-progress.png` — with the gold **PERFECT** readout firing in the clear
  sky. The fill mechanic is intact and climbing. Good.
- **P2-7 — anti-mash freeze.** With `?bra_force_lock=1` the **"BRA"** word reads clearly **dimmed to
  a faint grey** versus the crisp white "BRA" of every unlocked frame — side-by-side in
  `.screenshots/po-p2-063/lock-compare.png` — so the locked state is legible and static
  (reduced-motion-safe); the fixed-350 ms re-arm is unit-tested. Good.
- **P2-5 — leave and come back.** *Not re-shot this pass* — 063 is a stretch-config-only change and
  touched neither the save path nor persistence. Carries forward from the prior same-origin reload
  verification: a filled bar came back at a substantial saved green fill after a real reload of the
  same browser origin — per-trick progress persists from `user://` (IndexedDB, no backend/account).
- *Still not cleanly pixel-verified (a sign-off-pass item, not a bug):* the **P2-4 erosion /
  confused-beat** path (red setback wash + confused recoil on a wrong-moment tap), the **mastery
  celebratory beat**, and that the **persistence flush** captures the very latest marks. All are
  unit-tested and run without crashing; the recoil/celebration flashes are brief enough that a
  strobe-sampled burst keeps missing them. A future sign-off pass should still catch them in live pixels.

#### Bugfixes

- (none) — the prior pass's one buildable current-phase defect, the **garden letterbox (P2-10 /
  X-1)**, was **fixed by task 063** (`window/stretch/aspect="keep" → "expand"`) and re-verified gone
  this pass by objective row-scan **and** live pixels on **both** the local bundle and the live Pages
  site (see the letterbox paragraph above). Pruned. Every run otherwise booted clean (`__appReady`
  true, licensed Sitt dog) with **zero** console errors; idle → wander → **turn to face the camera**
  → sit → mark → stand-up → loop, plus the green fill, the lock, and the trainer ring all worked and
  now fill the full phone frame.

#### Improvements (buildable now)

- (none) — the two prior current-phase directives are both delivered and re-verified good: the
  **garden stylization** (P2-10 owner ask, task 062 — warmer peach sky, haloed sun, painterly
  mottled grass, no cyan seam) and the **face-turn** (P2-11, task 061). With the letterbox
  correctness defect now fixed (063), **no buildable current-phase work remains** — the phase is
  blocked purely on the owner (see Changes).

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

**Sign-off status:** Phase 2 stays **open** — but with task 063 landing, it is now **blocked purely
on the owner** again. Every buildable Phase-2 mechanic holds in my own live pixels with **zero
regressions** (P2-4 green fill climbs, P2-5 persists, P2-7 lock dims legibly, P2-8 wander, P2-9
fading cyan trainer ring, P2-10 stylized garden **now filling the phone**, P2-11 face-turn), and the
one buildable defect from last pass — the garden **letterbox** — is **fixed** on **both** the local
bundle and the **live** site (objective row-scan: row 0 = 183.5 sky, row 843 ≈ 81 grass; no black
band). What remains is the phase's headline — **"more tricks at the Sitt standard"** — which is
**owner-gated on trick clips** (P2-1 / P2-2 / P2-3): the licensed Labrador ships only the Sitt, so
there is no second trick to select (P2-1), perform with its own distinct apex (P2-2), or clear its
own Visual Review (P2-3). Do **not** build a one-entry selector or fake a second trick. And three
acceptance details a future sign-off pass must still catch in live pixels once the phase is signable:
the **P2-4 erosion / confused-beat** setback, the **mastery celebratory beat**, and that the
persistence flush captures the very latest marks. **Do not sign off yet.** (With no buildable
current-phase work left, this restores the "blocked purely on owner" state that re-authorizes
**work-ahead** per `index.md` — subordinate, dormant, preempted by any current-phase reopen.)

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
