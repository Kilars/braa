**PO Review**

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

- **Phase 3 — SIGNED OFF 2026-07-04 (owner, larssski).** Dog-breeds phase accepted done at HEAD
  `b2041dc`. The buildable spine shipped and replays clean on the real build: coin economy + drawn
  coin readout, one-active-trick completion menu (learned / available / locked + coins), centered
  camera-facing dog with the scratch feint, late-biased PERFECT window + round BRA button,
  `BreedPersonality` levers, chocolate-Labrador coat variant, the collect → adopt → switch → persist
  roster, the spotlit breed-select showcase (drawn chevrons, training HUD hidden), the textured
  garden, and the joy-beat reaction (no rear-spin / flick). All owner actionable notes (1–7) were
  addressed (tasks 070–079 + 077) and the two showcase bugs are fixed (089 / 090). Accepted
  **as complete as best as possible**: the residual gaps are owner-gated, not core-loop defects, and
  ship with honest stand-ins — a genuinely **distinct second breed model** (P3-D1/D2/D4) and a
  camera-facing **signature clip** (P3-2), the warm human "Bra!" voice, and the live-telemetry
  `POSTHOG_TOKEN` secret. All remain open flags for the owner to close later; none blocks the core
  loop. **Phase 5 is now current** (spec numbering skips 4/7 — difficulty moved to Phase 9).

- **Phase 5 — SIGNED OFF 2026-07-04 (owner, larssski).** Marker-words phase accepted done. The
  buildable stories shipped and verify green (tasks 091–095): unlockable stronger Norwegian marker
  words with per-word timing window + cooldown, the menu showing each word's cost/rest **before**
  loading, the fired word popping up from the BRA button on a successful mark, and a legible
  resting/cooldown readout. Accepted **as complete as best as possible** — the only residual is
  owner-gated: the warm **human "Bra!" / Maren voice** recordings for the alternative words ship
  with honest synthetic stand-ins under the same cue ids (open flag), swappable with no code change.
  **Phase 6 is now current.**

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-07-04

Played the fresh local build (`nix develop -c bash verify.sh` → `build/web`, served over http,
headless Chromium at 390×844 — SwiftShader == the deployed GL Compatibility renderer). Autotapped
the mark loop (`?bra_autotap=1`, dense frame burst `.screenshots/po-p5-mark-06..18`) and drove the
menu with real canvas taps (`092-01/02`). **Two of the four Phase-5 stories are genuinely in and
good — P5-4 and P5-1 — but the phase is not sign-off ready:** the marker word has **no on-screen
presence at all** (P5-3 is unbuilt), and the stronger-word trade-off (P5-2) is invisible in play.

**What's working (do NOT re-task):**
- **P5-4 — load/swap in the menu.** The "Marker words" section renders in the completion menu
  (Bra! / Dyktig! / Flink! / Super! / Kjempebra!) with Active / Switch / Locked badges. A real tap
  on an unlocked word swaps the active word (Bra! Active → Dyktig! Active, Bra! → Switch) and the
  menu stays open — no extra in-round button, X-2 holds (`.screenshots/092-01-words-section.png`,
  `092-02-dyktig-loaded.png`).
- **P5-1 — progressive unlock + voiced lines.** Mastering a trick unlocks Dyktig!; the catalog
  carries a per-word voiced clip (Piper stand-in). The warm human **Maren** delivery is the same
  owner-gated voice flag as Phase 1 — an honest stand-in, not a blocker.

**Improvements (buildable this phase):**

1. **P5-3 — the marker word never appears on screen. Build the word pop.**
   *What I saw:* on a successful mark the only on-screen text is the **"PERFECT"** timing verdict at
   top-centre; the BRA button always reads "BRA"; nothing pops, floats, or bursts for the word
   itself (frame `.screenshots/po-p5-mark-16.png` is a scored apex — "PERFECT" up top, ghosted
   "BRA" button, no word). Loading Dyktig! changes only the audio — visually the mark is byte-identical
   to base "bra."
   *Why it's wrong:* Phase 5's whole headline is *collectible marker words*, and P5-3 requires a
   "big, juicy, on-beat word burst … floats up from the BRA button." Right now the collection is
   invisible in the one moment it should pay off — the player can't see which word fired, so
   unlocking and loading a word has no on-screen reward. During actual play the phase reads as
   "nothing changed."
   *What good looks like:* on every successful mark, the **word that actually fired** (Bra! / Dyktig!
   / Super! / Kjempebra!) bursts big and juicy on the beat — floating up from the BRA button and
   fading — landing exactly with the voice + the dog's reaction. It must read as warm praise, be
   visually **distinct from and not collide with** the "PERFECT" verdict already at top-centre, and
   honour X-5 (reduced motion: dampen the float, never drop the word). Because it shows the word that
   *actually fired*, it also makes the P5-2 cooldown legible (see 2): when a cooling stronger word
   falls back to base, the pop reads "Bra!", so the fallback is visible instead of a silent swap.

2. **P5-2 — the stronger-word trade-off is imperceptible; surface the cooldown.**
   *What I saw:* loaded Dyktig! (window_scale 1.15, cooldown 2 marks). The menu word rows show only
   Active / Switch / Locked — no resting/cooldown state (`092-02`); in play there is no cue that a
   stronger word has gone on cooldown and is now firing base "bra" instead. The downside exists in
   the logic but is invisible to the player.
   *Why it's wrong:* P5-2 asks that loading a stronger word be "a genuine choice, not an obvious
   upgrade." A cost the player can't see isn't a trade-off — right now a stronger word looks like a
   pure win, and the rest that's supposed to balance it happens off-screen.
   *What good looks like:* the cooldown is surfaced where the player decides. At minimum the menu
   word row shows a "Resting (n)" / cooldown badge while a word is cooling, so the cost is readable
   before loading; combined with the fallback pop from (1), the player both sees the stronger word
   fire and sees it rest afterward. Ship this together with P5-3.

_Not signing off: P5-3 is unbuilt and P5-2 is illegible in play. The prior Phase-3 review pass and
the owner's actionable notes (1–7, tasks 070–079 + 077) are archived in the Phase-3 sign-off above
and in git history._
