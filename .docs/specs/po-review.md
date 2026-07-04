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

### PO Review — 2026-07-05 (Phase 6 — design system + training-page ambiance)

Replayed the fresh local build at HEAD `6096a41` (`build/web` rebuilt 00:42 via `verify.sh` after the
101 commit), served over http and driven in headless Chromium at 390×844 — SwiftShader == the deployed
GL Compatibility renderer. Idle composition captured (`.screenshots/po-p6-idle-a/b/c.png`), the mark
loop autotapped (`?bra_autotap=1`, dense burst `.screenshots/po-p6-mark-00..29.png`), lower-third +
house zoomed (`.screenshots/zz-coins.png`, `zz-house.png`), a gold-pixel + tan-coverage scan run, and
the completion menu popped on mastery (`.screenshots/po-p6-menu.png`). **Zero console errors on every
run.** Task 101 **fixed the fence** (pickets now read on both sides of the gate — pruned). But it
**over-corrected the path** and the **coins still don't read**, so the garden composition still falls
short of the goal — and in one respect (dog now sitting on dirt, not grass) it reads *worse* than the
previous pass. Not sign-off ready.

**What's working (do NOT re-task):**
- **DS foundation (096) + training-page HUD/BRA (097).** Token vault + real OFL fonts + Godot Theme
  live; white **"Triks"** + **coin** pills, slate **"Sitt"** label, learned bar with `%` readout; big
  rounded **BLUE** BRA button with darker-blue bottom-lip depth (`po-p6-mark-14.png`). Matches the goal
  HUD/button.
- **Completion menu (098).** Mastering Sitt pops a **light DS PAPER card** (`po-p6-menu.png`): slate
  **"Tricks"** heading, pale-pill rows for tricks / breeds / marker words, **BLUE** for active/available
  accents, **GOLD** reserved to the coin only, hairline border + soft card shadow + rounded corners,
  Norwegian actions ("Vis frem hundene" / "Gi tilbakemelding" / primary blue "Fortsett treningen"). The
  visual language holds — no regression.
- **"Triks" glyph + HUD legibility (100).** The Triks pill carries the **drawn 3-bar menu glyph** left
  of the label (no tofu); both pills read over the bright sun band — no regression.
- **Fence across both sides (101) — prior sub-directive RESOLVED.** The white picket fence now renders
  as a line on **both** sides of the path with a gate gap for the path (`po-p6-idle-a/b/c.png`). Pruned.
- **Core loop / word pop (P5 carry-over, no regression).** The idle → sit → face-camera → apex → mark →
  PERFECT + word pop → joyful reaction → loop replays clean across the 30-frame burst, zero console
  errors — no earlier-phase regression.

**Improvement (buildable this phase — the remaining blocker):**

1. **The garden path over-corrected into a full-width dirt wedge — the dog no longer sits on grass.**
   The previous "inverted-perspective, narrows-to-a-point" path is gone, but the fix swung too far: the
   tan path is now so wide in the foreground that it **fills the whole lower half of the frame** — a
   gold-pixel/coverage scan of the idle frame reads the **bottom 200 px band as 54 % tan**, and the dog
   sits squarely on **dirt**, with green grass surviving only as thin slivers at the far left/right
   edges (`po-p6-idle-a/b/c.png`, `zz-coins.png`). This loses the whole *garden* read — it looks like a
   dog standing in the middle of a wide dirt road, not centered on a grassy lawn. In the goal
   (`assets/goal-training-screen.png`) the dog is centered on **green grass**; the path is a **slim
   winding ribbon** — roughly a quarter of the foreground width — that passes **to the side of** the dog
   and recedes to the house top-right, never under the dog's feet. *Good:* shrink the near-end width
   hard (the taper *direction* — wide-near → narrow-far — is now correct, it is simply far too wide) and
   shift the ribbon so it runs **beside** the centered dog, leaving the dog grounded on green grass with
   the path clearly a path, not the whole floor.
2. **The coins still don't read as coins.** They were shrunk and repositioned, but a gold-pixel scan of
   the idle frame finds **zero** coin-gold pixels anywhere on the grass — the only gold in the frame is
   the HUD coin-pill icon (top-right). What survives in-world is a faint greenish-yellow tick floating
   at mid-field on the left margin (`po-p6-idle-b.png`), which reads as a smudge, not a coin. In the
   goal the coins are **small, unmistakably gold discs resting low on the green grass** in the lower
   third, framing the dog. *Good:* make them read as actual gold coins on the ground — grounded low in
   the lower third on grass (once the dog is back on grass), clearly gold, sized to read but not crowd
   the dog. If the billboard is collapsing edge-on in GL-Compat, keep `billboard_keep_scale=true` and
   size via the mesh (per the 101 note) — but verify in captured pixels that a gold coin is actually
   visible, not just that the node exists.
3. **Minor — the house reads as a blown-out tower.** At the path's end the house is a tall, narrow
   cream box with a pyramidal blue roof, its face washed near-white by the sun bloom (`zz-house.png`).
   It reads more like a silo/tower than the goal's cozy little **cottage** (wider than tall, a simple
   gable roof, a small window/door). *Good:* soften the bloom on its face and give it cottage
   proportions so it reads as a home at the end of the path. Once the dog is back on grass, re-confirm
   the grounding shadow ellipse reads under the seated dog.
   Keep everything in the DS palette (sky/grass/BLUE/GOLD) so it coheres with the restyled HUD. Match
   the goal's **layered composition + grounding** (dog on grass, slim path, grounded gold coins), not
   the exact pixels.

_Not signing off: the garden still reads as unfinished — the path over-corrected into a full-width
dirt wedge (dog on dirt, 54 % of the foreground tan) and the coins render as zero visible gold on the
grass. Both are buildable, not owner-gated. The fence sub-directive is resolved and pruned; the DS
HUD/BRA/menu, core loop, and earlier phases replay clean with no regression._
