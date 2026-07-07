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

- **Phase 6 — Visual Review passed 2026-07-05 (PO, father pass).** Design-system + training-page
  ambiance phase accepted done at HEAD `a3750fe`. Played the fresh local licensed bundle (`build/web`,
  rebuilt at this HEAD via `verify.sh`, gate green) served over http and driven in headless Chromium at
  390×844 — SwiftShader == the deployed GL Compatibility renderer. **Zero console errors on every run**
  (idle ×3, a 30-frame `?bra_autotap=1` mark burst, the completion menu on mastery). The training page
  now reads as the goal (`assets/goal-training-screen.png`): a clean rounded HUD (white **"Triks"** pill
  with the drawn 3-bar menu glyph + **coin** pill, slate **"Sitt"** label, learned bar with `%`), the
  licensed dog **centered and grounded on green grass**, a **slim winding tan path** that passes to the
  **right** of the dog and recedes to a small **cottage** (cream walls, blue door/window, gable roof)
  top-right, a **white picket fence** across the mid-ground with a gate gap, **gold coins** framing the
  dog, a grounding shadow, green bushes, and a big rounded **BLUE BRA** button anchored at the bottom —
  all in the DS palette (sky/grass/BLUE, GOLD reserved to the coin). The completion menu is a light DS
  **paper card** (slate "Tricks" heading, pale-pill trick/breed/marker-word rows, blue accents,
  Norwegian actions). The three round-2 garden directives from the `6096a41` pass are all **fixed and
  verified in my own pixels**: (1) the **path** no longer over-corrects into a dirt wedge — the dog sits
  on green grass and the path is a slim ribbon to the side; (2) the **coins** read as real gold — an
  in-world gold-pixel scan (excluding the HUD pill) counts **9146** coin-gold pixels framing the dog on
  both sides (was **zero** the prior pass), and a 3× zoom shows actual gold discs; (3) the **house**
  reads as a cozy cottage, not a blown-out tower. Re-checked the earlier signed-off phases on the same
  build — **no regression**: **Phase 1** the Sitt core loop (idle → wander → face-camera → seated apex →
  cyan approach ring → mark → joyful reaction → loop) replays clean across the burst; **Phase 2** the
  three-trick roster (Sitt learned / Ligg / Legg deg available) + learned bar render; **Phase 3** the
  coin economy + breeds (Labrador active / Chocolate locked 30) render; **Phase 5** the marker words
  (Bra! active / Dyktig! switch / Flink! / Super! / Kjempebra! locked) render — all intact in the
  completion menu. Accepted **as complete as best as possible**: Phase 6's own stories are fully
  buildable and all delivered; the only residuals are the same long-standing **owner-gated** flags
  carried from earlier phases (the warm human "Bra!" / Maren voice, the coat UV/tangent re-export),
  which ship with honest stand-ins and don't touch the design-system work. **Phase 8 (kennel) is now
  current.**

- **Phase 8 — Visual Review passed 2026-07-05 (PO, father pass).** Kennel browse-and-adopt roster
  accepted done at HEAD `0ff7902`. Played on the **live deployed Pages site**
  (https://kilars.github.io/braa/) at 390×844 in headless Chromium — the only build that renders the
  **licensed Labrador** (live boot log confirms `dog loaded: res://assets/models/dog_licensed.glb …
  dog can Sitt`); the deployed pck refreshed at 10:06 GMT to this HEAD, so item 1 below could be
  judged on the real rig exactly as Phases 1/2 were. **Zero relevant console errors; browse-grid →
  inspect-modal driven with real canvas taps.** The prior pass's sole blocker is **fixed and confirmed
  in my own pixels on the licensed build:** Bella-the-Labrador now renders as her **warm cream/golden
  training coat** on her blue owned-rarity band — no longer a blue-grey dog
  (`.screenshots/LIVE117-kennel-grid.png`, top-left cell); the 117 `KennelDog.portrait_tint()` decouples
  the coat modulate from the rarity `band_tint`, so the rarity band stays coloured while every dog reads
  a plausible coat (Bella cream, Nova grey, Balder/Sniff brown, Sol golden, Pontus grey, Lykke brown,
  Trulte grey-tan). The minor fold-in also landed: in Bella's modal the «Bella» title now sits on a
  **bottom nameplate clear of the dog's face** (`.screenshots/LIVE117-bella-modal.png`), which also shows
  the warm blurb, 4 data rows (Læreevne/Energi/Mot/Fokus), Raseegenskaper chips (Snill · Tålmodig ·
  Glupen), the «Godbit-radar» Unikt-trekk card, «Kan lære: Sitt · Ligg · Legg deg» (K-8), and the green
  «Trener nå» action for the owned dog. **K-1/K-3** the 8 cells (Bella · Nova · Balder · Sol · Pontus ·
  Lykke · Sniff · Trulte) fill the full 844 px portrait with no dead grey, correct names / breeds /
  prices / owned + «Påskeegg»/«Gratis» tags, under the «Kennelen · Profesjonell fasilitet» header + coin
  chip; **K-2** the inspect modal opens on tap; **K-3/K-4/K-5/K-6/K-7** adopt / affordability-gate /
  switch-to-training / Trulte free-adopt easter egg / persisted roster were driven end-to-end clean in
  the prior passes (`f5b8efb`), and 117 changed only the portrait tint + nameplate, leaving the tap/modal
  path intact. Re-checked the earlier signed-off phases — **no regression**: 117's diff is confined to
  `kennel_dog.gd` + `kennel_screen.gd` (touches no training / menu / economy / marker-word code), and
  closing the kennel restores the Phase-6 training page + Phase-1/2 core mark loop — cream Labrador
  centred facing camera on green grass, tan path, cottage, white picket fence, gold coins, blue BRA
  button (`.screenshots/105-kennel-03-closed.png`). Accepted **as complete as best as possible**: the
  only residuals are the long-standing **owner-gated** flags — distinct per-breed **models** (BUST-068,
  P3-D1/D2/D4) and camera-facing **signature clips** (P3-2), so all 8 breeds are honest tint stand-ins of
  the one licensed rig and share the core Sitt / Ligg / Legg deg trick list (K-8 is honest — a breed only
  offers a trick its rig actually has a clean clip for; no per-breed trick is faked). None blocks the
  kennel experience. **Phase 9 is now current.**

- **Phase 9 — Visual Review passed 2026-07-05 (PO, father pass).** Difficulty phase accepted done at
  HEAD `5331e49`. Played the fresh local licensed bundle (`build/web`, rebuilt at this HEAD via
  `verify.sh`, gate green — Sitt-capable Labrador) served over http and driven in headless Chromium at
  390×844 (SwiftShader == the deployed GL Compatibility renderer). **Zero console errors on every run**
  (fresh training boot, a `?bra_autotap=1` mastery burst, the completion menu on a normal dog and on a
  special dog). The two Improvements that blocked the prior pass are both **fixed and verified in my own
  pixels:** (1) the "Vanskelighet" rows now show the reward/challenge trade inline — Normal baseline / no
  annotation, **Hard «×1.4 mynt · smalere vindu»**, **Expert «×2 mynt · mye smalere vindu»** — same
  dimmed-subtitle treatment as the marker-word rows (Dyktig! «+15% · hviler 2»), derived from the
  `Difficulty` model, so the trade is legible at the point of choice (`.screenshots/PO9-01-normal.png`);
  (2) the special-dog lock now states the **reason** — on Nova (EPIC) the section carries the one-line
  note **«Spesialhunder trener alltid på Hard»** under the Vanskelighet heading, Normal/Expert greyed and
  Hard badged «Låst» (`.screenshots/PO9-03-locked.png`). **P4-1** a real canvas tap flips the global mode
  on a normal dog (Normal → Expert, `window.__bra_difficulty` normal→expert, «Valgt» badge moves) and is
  **swallowed** on a special dog (Nova stays Hard); **P4-2/P4-3/P4-4** the mode scales window radii, tell
  intensity, feint chance, bar erosion **and** the mastery coin payout on top of the breed (effective =
  breed × mode), wired + unit-tested; **P4-5** background grace is armed on the resume notification and
  unit-tested (inert headless). Re-checked the earlier signed-off phases on the same build — **no
  regression**: **Phase 1** the Sitt core loop (autotap mastered Sitt clean, licensed Labrador centred +
  grounded facing camera on green grass, `.screenshots/PO9-04-training.png`); **Phase 2** the three-trick
  roster (Sitt Learned / Ligg / Legg deg Available); **Phase 3** the coin economy + breeds (Labrador
  Active / Chocolate Locked 30, coin chip); **Phase 5** the marker words (Bra! Active / Dyktig! Switch /
  Flink! / Super! / Kjempebra! Locked); **Phase 6** the training page still pixel-matches the goal (tan
  path → cottage, white picket fence, gold coins, blue BRA button, DS paper completion card); **Phase 8**
  the kennel — the only kennel-code change since its sign-off is two **additive** pure lock predicates in
  `kennel_dog.gd` (`locks_difficulty()` / `locked_difficulty_id()`), which don't touch the render / adopt
  / modal path, and closing back to training restores the Phase-6 page. Accepted **as complete as best as
  possible**: Phase 9's own stories are fully buildable and all delivered; the only residuals are the same
  long-standing **owner-gated** flags carried from earlier phases (the warm human "Bra!" / Maren voice, the
  coat UV/tangent re-export, distinct per-breed models), which ship with honest stand-ins and don't touch
  the difficulty work. **Phase 10 (play mode) is now current.**

---

## Product Owner Review

> Owner play-test notes from driving the **real running game** on a phone-portrait
> viewport (390×844). Each pass replays the **current phase** (the lowest phase not yet in
> Phase Sign-off above), prunes what is now fixed, and lists concrete, buildable
> directives. The build loop turns these into tasks. **Prune-as-you-go applies to THIS
> section only — never touch the Phase Sign-off list above except to append a new
> sign-off.**

### PO Review — 2026-07-07 (PO, father pass 19) — polish-lens pass: pass-18 directive (154 menu blue-on-light text → AA) verified landed and correct in-pixel; the blue-on-light **contrast sweep has converged** (I re-measured the last-suspect kennel trait chips and they already clear AA by token); ONE new buildable X-4 defect on a DIFFERENT lens — the **kennel grid dog portraits swing from dead-front mugshot to full side-profile** across cells, violating the code's own "front-¾, face clearly to camera, never a side profile" invariant and disagreeing with the modal's front-¾ framing of the same dog

Nineteenth pass, run fresh and stateless under the polish/critique lens. HEAD is `1f5e899` (the 154 menu-contrast commit).
I reviewed the **fresh local licensed bundle** — `build/web`, rebuilt at this HEAD via `nix develop -c bash verify.sh` (gate green,
pck 08:1x, so it carries 154), served over http and driven in headless Chromium at 390×844 (SwiftShader == the deployed GL
Compatibility renderer) — via a no-autotap boot (training at rest), the completion/pause **Triks** menu (opened via the Triks pill),
and the **kennel** (opened via the published `window.__bra_kennel_btn` centre → `window.__bra_kennel_active` reports `bella`, then a
cell tap → Bella modal). `window.__bra_current_trick` reports `sitt`; **zero console errors** on every run. Evidence for every claim
is a screenshot I captured this pass (`.screenshots/P19-*`) plus PIL pixel crops + WCAG contrast maths and the code tokens I read.

**Re-verified fixed (pruned) — the pass-18 menu-contrast directive (154) landed and is correct:** both offenders now read as a
deeper, legible blue in my own pixels. The **«Gi tilbakemelding»** ghost button label measures **~5.55:1** on its ~[251,251,247]
white fill (was ~2.9:1), and the **«Tilgjengelig»** availability badges now render in the deeper blue — the new `BLUE_INK` token
`#2a66b3` computes to **4.96:1** on CREAM (I recomputed it; well over the 4.5:1 bar) and reads visibly crisper than the old
`DesignSystem.BLUE` in the zoom (`.screenshots/P19-02-menu.png`, `/tmp/p19_rows.png`). The residual anti-alias softening on the
thin small-font strokes is **uniform** — the intended dark «Ligg» title and dark-ink «Trener nå» measure the same way by darkest-pixel,
so it's font rendering, not a blue-specific gap. `NAME_LEARNED / BADGE_LEARNED / BADGE_AVAILABLE / SECONDARY_TEXT+OUTLINE /
BREED_NAME_ACTIVE / WORD_NAME_ACTIVE / DIFF_NAME_ACTIVE` are all repointed onto `BLUE_INK`; `BLUE` (fills) + `BLUE_DARK` (depth)
untouched. Directive resolved — removed.

**Contrast sweep converged (no new contrast directive):** I chased the last plausible blue-on-light hold-out — the kennel modal's
**Raseegenskaper** trait chips (Snill · Tålmodig · Glupen), which *look* soft in the zoom (`.screenshots/P19-04-kennel-modal.png`,
`/tmp/p19_chips.png`). They are **already AA**: `kennel_screen.gd:58/59` uses `C_TRAIT_INK #3a6a9a` on `C_TRAIT_BG #e8f0f8`, which I
computed to **4.92:1** — the soft look is the same uniform small-font anti-alias as the (fixed) menu text, not a contrast fail. Stat
labels are ~7.9:1. So the 149→151→153→154 blue-on-light AA arc is **done**; do not re-open it — there is no remaining sub-AA text.

**Also re-verified clean (no new directive):** the training page still matches the goal (pale-blue sky + sun, cream Labrador centred
facing camera on bright even grass, deep-blue BRA button, tan path → blue-roof cottage, white picket fence both sides, small grounded
garden coins + rose accent — `.screenshots/P19-01-training.png`); the pass-16 trick-selector ACTIVE state (152) holds (crisp dark-ink
«Trener nå» on the Sitt row); the 153 primary CTAs are deep-blue with legible white labels. **No structural regression** in the
signed-off phases (1/2/3/5/6/8/9).

**Improvements**

1. **The kennel grid renders the eight dog portraits at wildly inconsistent orientations — from a stiff dead-front mugshot to a full
   broadside side-profile — instead of the consistent flattering front-¾ "face clearly to camera" the code intends and the inspect
   modal already delivers. Several cells show the dog in pure profile with its face turned away toward the cell edge, which is both
   the exact framing the code claims it prevents and a poorer, less inviting way to present a dog you're deciding whether to adopt
   (X-4 layout/cohesion, on the signed-off Phase-8 kennel grid — this specific per-cell ANGLE was never reviewed by the contrast-
   focused passes 12–18).** *What I saw* (`.screenshots/P19-03-kennel-grid.png`): **Pontus** (`/tmp/p19_pontus.png`) and **Bella**
   (`/tmp/p19_toprow.png`) render as *full side-profiles* — the entire flank, all four legs side-on, the snout pointing at the cell
   edge and the face NOT toward the viewer; meanwhile **Trulte** (`/tmp/p19_trulte.png`) and **Nova** render *dead-front* — symmetric
   head-on mugshots. Only the mid-cells (Sol, Lykke) land in the intended flattering three-quarter. The per-cell yaw
   (`kennel_screen.gd:101 PORTRAIT_THREE_QUARTER 0.42` + `:109 PORTRAIT_YAW_SPREAD [0.12,-0.40,0.34,-0.22,0.46,-0.14,0.26,-0.34]`)
   resolves to a spread of roughly **1°→50°** off dead-on, so the low-|delta| cells (Nova/Trulte) sit at a stiff ~1–5° dead-front and
   the high-|delta| cells (Pontus/Bella/Balder/Sniff) swing to ~31–50°, reading as side-profiles. *Why it falls short:* (a) **the code's
   own invariant is violated** — `:106` says the spread is "kept within ±0.5 rad so every dog still reads front-¾ face-on, never a
   rear/side profile" and `:101` "face clearly to camera", yet Pontus/Bella are unmistakable side-profiles with the face turned away;
   (b) **grid↔modal inconsistency for the SAME dog** — tapping Bella's side-profile cell opens a correct front-¾ hero bust of Bella
   (`.screenshots/P19-04-kennel-modal.png`, `MODAL_PORTRAIT_YAW 0.0`), so the two views of one dog disagree; (c) **worse merchandising**
   — a dead-front mugshot is stiff and a side-profile hides the face, and the face is what makes a dog inviting to adopt; a consistent
   flattering three-quarter across all eight cells reads as one cohesive, considered roster. *What "good" looks like:* re-centre and
   **narrow** `PORTRAIT_YAW_SPREAD` so all eight cells stay inside a tight flattering front-¾ band (never the ~1° dead-on end, never the
   ~50° side-profile end — e.g. keep every cell within ~15°–38° off face-on), matching the modal's front-¾ hero framing, while
   **preserving the per-cell angle variety** that 131 deliberately added so no two identical-model Labradors read the same (the point of
   the spread stands — just keep its range within "face clearly to camera"). Verify in capture on the 8-cell grid that no cell is a
   dead-front mugshot and none is a side-profile; the dog's face should read toward the viewer in every cell. Buildable, no owner asset
   — a tuning of the two existing yaw constants (the distinct-per-breed MODELS that would make orientation moot stay owner-gated,
   BUST-068).

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still
**empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review and cannot be given buildable stories without
inventing scope, which is out of bounds). The standing asset flags (distinct per-breed **models**, camera-facing
**signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated. The loop's next buildable
work is the kennel grid-portrait orientation directive above; the owner still owns the Phase-10 spec + the asset flags.
