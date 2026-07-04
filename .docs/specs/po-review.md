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

### PO Review — 2026-07-04 (Phase 6 — design system + training-page ambiance)

Replayed the fresh local build at HEAD `63ee0ea` (`build/web` rebuilt tonight via `verify.sh`, gate
green, after the 098/099/100 commits), served over http and driven in headless Chromium at 390×844 —
SwiftShader == the deployed GL Compatibility renderer. Idle composition captured
(`.screenshots/po-p6-idle-a/b/c.png`), the mark loop autotapped (`?bra_autotap=1`, dense burst
`.screenshots/po-p6-mark-00..29.png`), the top HUD and BRA button zoomed at 3×
(`.screenshots/po-p6-hud-zoom.png`, `po-p6-bra-zoom.png`), and the completion menu popped on mastery
(`.screenshots/po-p6-menu.png`). **Zero console errors on every run.** Big progress this iteration:
**two of the three prior directives are fixed and pruned** — the menu is now on the design system,
and the "Triks" glyph + HUD legibility landed. **One directive remains:** the garden now has all the
goal's *elements* but three of them read as **broken/unfinished**, so the composition still falls
short of the goal screen. Not sign-off ready — but close.

**What's working (do NOT re-task):**
- **DS foundation (096) + training-page HUD/BRA (097).** Token vault + real OFL fonts + Godot Theme
  live; white **"Triks"** + **coin** pills, slate **"Sitt"** label, learned bar with `%` readout
  (`po-p6-hud-zoom.png`); big rounded **BLUE** BRA button with darker-blue bottom-lip depth
  (`po-p6-bra-zoom.png`). Matches the goal HUD/button.
- **Completion menu (098) — prior directive #1 RESOLVED.** Mastering Sitt now pops a **light DS PAPER
  card** (`po-p6-menu.png`): slate **"Tricks"** heading, pale-pill rows for tricks / breeds / marker
  words, **BLUE** for active/available accents, **GOLD** reserved to the coin only, hairline border +
  soft card shadow + rounded corners. The three actions are now **one language** (Norwegian: "Vis
  frem hundene" / "Gi tilbakemelding" / primary blue "Fortsett treningen"). It no longer reads as a
  dark modal over a light page — the visual language holds. Pruned from the log.
- **"Triks" glyph + HUD legibility (100) — prior directive #3 RESOLVED.** The Triks pill now carries
  the **drawn 3-bar menu glyph** left of the label (no tofu), and both pills read cleanly over the
  bright sun band at 3× (`po-p6-hud-zoom.png`). Pruned from the log.
- **Core loop / word pop (P5 carry-over, no regression).** On a mark the fired word ("Bra!") pops and
  floats up from the BRA button, distinct from the top-centre "PERFECT" (`po-p6-mark-14.png`); the
  idle → sit → face-camera → apex → mark → PERFECT + word pop → joyful reaction → loop replays clean,
  zero console errors — no earlier-phase regression.

**Improvement (buildable this phase — the one remaining blocker):**

1. **The garden has the goal's elements but three of them read as broken — refine the composition.**
   Task 099 genuinely added the horizon hedge, house, path, fence, coins, bushes and a firmer shadow,
   and it is a big step up from the empty field. But played at 390×844 (`po-p6-idle-a/b/c.png`,
   `po-p6-mark-14.png`, and the garden visible behind `po-p6-menu.png`) three elements land wrong and
   pull the eye:
   - **The path tapers to a sharp point in mid-field — perspective is inverted.** The tan path is
     *wide near the house (far)* and *narrows to a floating point* at the dog's chest level, ending in
     empty grass — the opposite of real perspective, so it reads as a floating triangle, not a path.
     In the goal the path is a continuous winding ribbon, **widest in the foreground** (nearest the
     viewer / BRA button) and narrowing as it recedes to the house. *Good:* widen the near end and run
     the ribbon down past/around the dog toward the bottom so it clearly leads to the house — no
     mid-field point.
   - **The coins are oversized and float at the dog's shoulder height.** They read as big golden orbs
     hovering in mid-field, not coins on the ground (`po-p6-idle-b.png`). In the goal the coins are
     **small and sit low on the grass** near the corner bushes. *Good:* shrink them and drop them to
     rest on the grass in the lower third, framing (not crowding) the centered dog.
   - **The fence is on the left only.** The goal's white picket fence is a **line across the whole
     mid-ground**, with a gate gap where the path passes; ours has a short segment left of the path
     and nothing on the right (`po-p6-idle-a/b.png`). *Good:* extend the fence across the right side
     too, keeping the gate gap for the path.
   - **Minor:** the grounding shadow under the seated dog is still faint (`po-p6-mark-14.png`) and the
     corner bushes read weakly next to the loud coins — firm the shadow ellipse a touch and let the
     bushes register once the coins shrink.
   Keep everything in the DS palette (sky/grass/BLUE/GOLD) so it coheres with the restyled HUD. Match
   the goal's **layered composition + grounding**, not the exact pixels.

_Not signing off: the garden composition still reads as unfinished (floating path point, oversized
floating coins, half-built fence) — buildable, not owner-gated. The menu-DS and HUD-glyph directives
are resolved and pruned; the core loop and earlier phases replay clean with no regression._
