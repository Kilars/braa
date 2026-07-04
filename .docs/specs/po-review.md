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

Played the fresh local build at HEAD `bf58a75` (the `build/web` pck rebuilt 21:16, after the 097
commit at 21:15), served over http and driven in headless Chromium at 390×844 — SwiftShader == the
deployed GL Compatibility renderer. Idle composition captured (`.screenshots/po-p6-idle-a/b/c.png`),
the mark loop autotapped (`?bra_autotap=1`, dense burst `.screenshots/po-p6-mark-00..29.png`), the
top HUD and BRA button zoomed at 3× (`.screenshots/po-p6-hud-zoom.png`, `po-p6-bra-zoom.png`), and
the completion menu popped on mastery (`.screenshots/po-p6-menu.png`). **Zero console errors on
every run.** The design-system **foundation** (096) and the **training-page HUD/BRA restyle** (097)
are genuinely in and good — but Phase 6 promises the DS applied to **"all aspects of game, menu,
training page visuals etc."** and the goal training screen, and two large surfaces still fall short:
the **completion menu ignores the design system entirely**, and the **garden is nowhere near the
goal composition**. Not sign-off ready.

**What's working (do NOT re-task):**
- **DS foundation (096).** Token vault + real OFL fonts (Baloo 2 / Nunito / JetBrains Mono) + Godot
  Theme are live — the training-page text now renders in the real display/body faces, not the
  fallback. No scattered `Color(...)` literals in the restyled surfaces.
- **Training-page HUD (097).** White rounded **"Triks"** pill top-left, white **coin** pill (gold
  coin + count) top-right, slate **"Sitt"** trick label, and the learned bar with a right-aligned
  `%` readout — all reading as the DS light aesthetic (`.screenshots/po-p6-hud-zoom.png`). Matches
  the goal HUD's structure.
- **BRA button.** Big rounded **BLUE** button anchored at the bottom with a darker-blue **bottom-lip
  depth** and cream Baloo **"BRA"** display text (`.screenshots/po-p6-bra-zoom.png`) — the goal's
  button, well delivered.
- **Word pop (P5 carry-over).** On a successful mark the fired word ("Bra!") pops and floats up from
  the BRA button, gold and distinct from the top-centre "PERFECT" verdict
  (`.screenshots/po-p6-mark-12.png`). No regression from the Phase-5 sign-off; the core loop
  (idle → sit → face-camera → apex → mark → PERFECT + word pop → joyful reaction → loop) replays
  clean, no console errors — no earlier-phase regression.

**Bugfix / Change (buildable this phase):**

1. **The completion menu ignores the design system — restyle it to the DS.**
   *What I saw:* mastering Sitt pops the **Tricks** menu, and it is still the **old dark-navy panel
   with a gold hairline border, gold section labels, and gold row badges** (`.screenshots/po-p6-menu.png`)
   — the Phase-3/5 theme, untouched by 096/097. Its three action buttons even mix languages
   ("Vis frem hundene" / "Give feedback" / "Keep training").
   *Why it's wrong:* Phase 6 explicitly scopes the DS to **"menu … visuals etc."** The menu is the
   single largest UI surface, and right next to the now-light training page it reads as **two
   different apps** — a dark modal over a bright, paper-pill garden. The DS Theme (SLATE-on-light)
   was clearly never applied here.
   *What good looks like:* the menu is a **light PAPER card** built from the DS tokens — `panel()`
   surface (PAPER bg, hairline BORDER, soft card shadow, `R_LG` corners), **SLATE** headings/body in
   the Baloo/Nunito faces, **BLUE** for the active/primary accent (active trick, active word,
   selected breed), **GOLD** reserved for the coin only, DS **pill** rows for tricks / breeds /
   marker words, and the three actions as DS buttons (primary BLUE "Keep training", secondary paper
   pills). Same information + interactions, DS skin — so opening the menu no longer breaks the visual
   language. While here, make the three action buttons one language (Norwegian, to match the rows).

**Improvement (buildable this phase):**

2. **The garden composition falls well short of the goal training screen — build the ambiance.**
   *What I saw:* the running garden is **noisy blocky FBM grass + a blurred sun/horizon and nothing
   else** — no path, no house, no fence, no border bushes, no ground coins, and only the faintest
   grounding under the dog (`.screenshots/po-p6-idle-a.png`, `-idle-c.png`, `-mark-14.png`). The dog
   reads as **floating on an empty field**.
   *Why it's wrong:* phase6.md names the goal screen (`.docs/specs/assets/goal-training-screen.png`)
   as the visual target — *"match the composition, grounding, and juice, not the exact pixels."* The
   goal garden is a **place**: a winding **path curving back to a small house** top-right, a **white
   picket fence** line across the mid-ground, **low bushes** framing the corners, a couple of **gold
   coins on the grass**, a clear **horizon hedge/hills**, and a soft **shadow ellipse grounding** the
   dog. Ours has none of that layered depth, and the grass reads as pixel noise rather than the
   goal's smoother painterly grass.
   *What good looks like:* build the goal's stylized garden — horizon hedge/hills, the path-to-house,
   the fence line, a few ambient bushes and ground coins framing the centered dog, and a real
   grounding shadow — composed so the centered dog and the bottom BRA button sit in a believable,
   juicy garden that reads at a glance. Not pixel-exact; match the **layered composition + grounding
   + ambient juice**, in the DS palette (sky/grass/BLUE/GOLD) so it coheres with the restyled HUD.

**Polish (buildable this phase, minor):**

3. **Top HUD: add the "Triks" menu glyph and hold legibility over the bright sky.**
   *What I saw:* the goal pill reads **"☰ Triks"**; ours is just **"Triks"** with no menu glyph, and
   the whole top HUD washes out faint against the bright sun band at 1× (`.screenshots/po-p6-hud-zoom.png`,
   `po-p6-idle-a.png`).
   *Why it's wrong / good:* the hamburger signals "menu" and the goal shows it; the HUD must stay
   legible over the sky. Add a **drawn** menu glyph (never a tofu/font-fallback box) to the Triks
   pill and give the pills enough fill/opacity or a subtle shadow to read over the bright sky.

_Not signing off: the completion menu is not on the design system and the garden is far from the goal
composition — both buildable, neither owner-gated. Phase-5 directives are resolved and archived in the
Phase-5 sign-off above and in git history._
