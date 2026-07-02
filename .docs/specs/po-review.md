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

- **Phase 2 — Visual Review passed 2026-07-01 (PO, father pass).** Played the current HEAD
  (`7a3f12f`) on a 390×844 phone-portrait viewport — both the local licensed bundle (`build/web`,
  the 38 MB pck rebuilt 17:26, after the 066 commit at 17:21) served over http in headless Chromium
  (SwiftShader == the deployed GL Compatibility renderer) **and** the **live Pages site**
  (https://kilars.github.io/braa/). Zero console errors on every run. The prior pass's sole blocker
  — "the roster is owner-gated, there is no second trick" — was a **behavior≠inventory error**: the
  licensed Labrador already held **Ligg** (`Lie_*`) and **Legg deg** (`Lie_belly_*`), and they are now
  wired as real, distinct tricks (065 / 067) behind a live **trick selector** (066), so the phase's
  headline — *more tricks at the Sitt standard* — is genuinely delivered. Verified in my own pixels:
  **P2-1** a top chip row (Sitt · Ligg · Legg deg), tapping a chip repoints the trick, the gold
  highlight + per-trick learned pip follow, live on **both** builds; **P2-2 / P2-3** three visibly
  **distinct** apex poses (Sitt = upright seated chest-high; Ligg = low sphinx lie; Legg deg = flatter
  belly-settle, forelegs sprawled), each reading as its behaviour, each turning to face the camera at a
  PERFECT apex (P2-11), no T-pose / foot-slide / snap, honest apex tell; **P2-4** PERFECT climbs the
  bar → full-**gold mastery latch**, a mistimed tap **erodes** it (bar visibly drops ~40 %→30 % with a
  brief **red setback wash** + the dog's confused beat), floors at 0, no hard-fail; **P2-5** the
  mastered bar (the very latest marks) **persists** across a same-origin reload, per-trick isolated;
  **P2-7** anti-mash lock swallows taps; **P2-8** the dog wanders varied headings on a 0.8–2.0 s
  feinting cadence; **P2-9** the fading cyan approach ring lands on the apex, distinct from the gold
  tell; **P2-10** the garden fills the phone, sun + sky + painterly grass, BRA over the grass, no
  letterbox / cyan seam. Re-checked **Phase 1** on the same build — the Sitt core loop
  (idle → wander → face-camera → seated apex → tell → PERFECT → joyful reaction → loop) is intact, no
  regression. Accepted **as complete as best as possible**: the residuals are owner-gated, not core
  defects, and ship honest — the **expansion** tricks *Gi labb / Rull / Snurr* have **no** clip in the
  licensed asset (manifest-busted; a standing owner flag, and the P2-2 starter set Sitt/Ligg/Legg deg
  *is* complete), and the Phase-1 human "Bra!" voice (Piper stand-in) + coat UV/tangent seam remain
  open flags. None blocks the core mark. **Phase 3 is now current.**

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-07-01

Played the current HEAD (`ae6b0d9`, the 068 coin economy) on the local licensed bundle
(`build/web`, rebuilt 21:45 by a green verify) served over http in headless Chromium
(SwiftShader == the deployed GL Compatibility renderer) at **390×844**. Zero console errors
across a `?bra_autotap=1` mastery run **and** a reload run (boot log: licensed Labrador loads,
"can Sitt"). I verified the **one owner-decided Phase-3 slice that's live** — the P3-D3 coin
economy core — **in my own pixels:** the top-right readout boots at **0**, driving marks to
master a trick pays out (readout ticks **0 → 10**), and the balance **survives a same-origin
reload** (still **10** after re-boot) — earn + persist both hold, offline (X-7). Phase 1/2 are
intact on the same build (garden fills the phone, dog loads with no primitive flash, three-chip
selector present, Sitt/Ligg/Legg-deg loop marks cleanly).

**But Phase 3's headline — pick, collect, and train *different breeds* — is not in the running
game at all** (one breed, the Labrador; no breed choice, no roster, nowhere to spend a coin),
and the single live Phase-3 surface (the coin readout) has two rough edges. **Not signing off.**

**Bugfixes**

1. **The coin icon renders as a broken-glyph "tofu" box.** The readout draws the number
   followed by the 🪙 emoji (U+1FA99), but the label's font has no glyph for it, so it comes out
   as a hollow patterned box beside the digit — visible at both `0` and `10`
   (`/tmp/po-p3/00-boot-coin.png`, `t24-coin.png`). *Why it's wrong:* a missing-glyph box reads
   as a bug / half-built asset the moment the player looks top-right — it fails the "reads first,
   looks the part / quality gates hold" bar (X-4, X-6). *Good:* show the coin with something that
   actually renders at phone size — a small drawn/vector gold coin, or drop the emoji for a plain
   gold disc or a `coins` word — never a tofu box.

2. **The coin readout overlaps the right-most selector chip.** With the full three-chip roster
   (Sitt · Ligg · **Legg deg**), the selector row reaches into the top-right corner where the
   readout is anchored, so `0` / `10` is drawn *on top of* the "Legg deg" chip
   (`/tmp/po-p3/00-boot.png`, `t24.png`). *Why it's wrong:* it degrades the legibility of the
   **P2-1 trick selector that is already signed off** — the chip label and the coin count collide.
   *Good:* the coin readout sits clearly clear of the chip row at any roster size (its own line
   below the chips, or the chip row reserves a right-margin), with no overlap.

**Improvements**

3. **The coins are a context-free number — the collection goal isn't legible.** The player
   masters tricks and watches a bare count climb, but nothing on screen says these are coins
   *earned toward adopting a new dog*, and there is nowhere to spend them. *Why it falls short:*
   P3-D3 asks that "the collection axis is visible"; right now the earn side works but its purpose
   is invisible. *Good (buildable now, before any breed model):* give the readout a minimal label
   / affordance conveying purpose (e.g. a "coins" caption or a small toward-a-dog hint). The
   **full adopt UI** (coin price + locked state + breed thumbnail) genuinely needs the owner-gated
   extra breed models — keep it flagged, do **not** fake a breed to fill the panel.

4. **Training has no breed-personality dimension yet (P3-3).** I ran many mark cycles and every
   session trains identically — learn speed, distractibility, window stability and energy are the
   same fixed feel regardless of "which dog." *Why it falls short:* P3-3 requires personality to
   drive the difficulty levers so breeds are "deep kits, not skins." *Good (buildable now per
   BUST-068, no owner needed):* a `BreedPersonality` data model wired to the existing
   `SitWindow` / cadence / learn-speed levers, keyed to the **Labrador as breed #1**, so even the
   single starter breed has a defined temperament and the levers are proven before more breeds land.

**Changes**

5. **There is no collection / roster surface (P3-4).** Coins accrue with nothing to collect and
   no persisted list of owned dogs — the "roster I'm proud of / bright-spotlit select screen"
   does not exist. *Good (buildable spine now):* persist an owned-dogs roster (starting with the
   Labrador) alongside the coins in the same save, so the collection is a real persisted list the
   adopt / select UI can later render; the **spotlit select-screen visuals and any additional
   breeds stay owner-gated** (P3-1 / P3-2 appearance + P3-D1 / D2 / D4 decisions) and remain
   flags, not buildable this pass.

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
