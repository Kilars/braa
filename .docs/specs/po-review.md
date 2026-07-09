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

### PO Review — 2026-07-09 (PO, father pass 71) — critique/polish pass. Pass-70's breed-showcase caption directive (task 196) **re-verified in pixels and resolved** (pruned): the two SUBTLE captions now sit on opaque near-black scrim chips and clear AA in the *actual render* — «Labrador» subtitle **7.38:1** and «Adopter flere hunder for å bla» hint **13.99:1** (were 2.40 / 2.05), tasteful dark caption tags, zero console errors (`.screenshots/P71-c-showcase.png`, `P71-c-sub.png`, `P71-c-hint.png`). **ONE new buildable X-6 directive:** the **same analytic-vs-render AA gap 196 just closed for the captions still stands on the sibling showcase chrome on the identical surface** — the «Tilbake» back button renders as a **grey label at ~2.35–3.15:1** (its white@0.96 `BTN_SECONDARY_TEXT` under-covers over the translucent ghost pill; 171 fixed it *analytically* only), and the «Trener nå» status pill renders at **4.03:1** (dark INK on the pale `cfd6dd` fill, also under the 4.5:1 bar in-pixel). No sign-off (Phase 10 owner-gated on its empty spec).

Fresh, stateless pass. HEAD `8a99121` (task 196; board empty); `build/web/` rebuilt at HEAD via `verify.sh` (gate green — Sitt-capable licensed Labrador bundled locally, ~39 MB `index.pck` refreshed 05:26), served over http (`python3 -m http.server 8099`) and driven in headless Chromium at 390×844 (SwiftShader == the deployed GL Compatibility renderer), `env -u LD_LIBRARY_PATH`. **Zero game console errors** on every run — training boot (`?bra_autotap=1`, PERFECT verdict + cyan approach ring on a camera-facing apex), the «Triks» menu, the breed showcase, the kennel grid + Sol modal. (Contrast figures below are measured off the captured PNGs with a WCAG-luminance sampler — brightest text pixel of each line vs the pill/band it sits on.)

**Pass-70 directive RESOLVED (196 backed both showcase captions with an opaque-dark scrim chip) — re-verified in pixels, pruned.** Task 196 (`8a99121`) routed the «Labrador» subtitle + «Adopter flere …» hint through `_make_caption()` + `_caption_row()`: a content-sized Label in the thick `font_display` face, full-opaque white `SUBTLE`, centred on an opaque `CAPTION_SCRIM` (= DS `INK`@1.0) rounded chip (radius 8, 10×3 pad). The scrim forces the band behind the thin strokes to near-black (lum ~0.02), so the caption clears AA regardless of the bright-grass bleed the translucent stage band lets through. Measured this pass off the captured chips: subtitle **7.38:1**, hint **13.99:1** (both ≥4.5:1). The chips read as tasteful small dark tags, subordinate to the crisp-white «Mine hunder» / «Bella — aktiv» titles; empty subtitle (name==breed) hides its chip. Resolved; not re-filed.

**Improvement (X-6, WCAG AA — the breed-showcase bottom-control chrome renders sub-AA — the same render gap 196 just fixed for the captions on this very surface).** 196 proved the showcase's translucent stage band lets bright grass bleed up so thin-stroke text over it never reaches its analytic colour; it fixed the two captions but left the sibling «Tilbake» / «Trener nå» chrome — fixed *analytically* by 171 — untouched, and in the actual render they fail AA.
- **What I saw / measured:** in the spotlit showcase (`.screenshots/P71-showbottom.png`, `P71-tilbake.png`, `P71-trener.png`), the **«Tilbake» back pill** renders its label as a muted **grey**, not the intended white — the brightest text pixel reaches only lum **0.229** over the pill (**3.15:1** peak; the 99th-percentile body of the strokes is **2.35:1**), well under the 4.5:1 AA bar and visibly greyed. The **«Trener nå»** non-tappable status pill measures **4.03:1** (dark INK text, brightest-dark ~0.128, on the pale `cfd6dd` fill at ~0.666), also just under AA. The code *intends* both to be legible — `BTN_SECONDARY_TEXT = white@0.96` on the darkening `BTN_SECONDARY` ghost pill (`breed_showcase_view.gd:80-81`) and dark `INK` on `commit_disabled_fill() = cfd6dd` (`:102,107`) — but the render lands short. (The ◀▶ chevrons share `BTN_SECONDARY_TEXT` and would inherit the same gap, but with a single owned dog the carousel is a verified no-op and they are correctly hidden, so they're not live this pass.)
- **Why it's wrong:** AA legibility is the design bar and an explicit cross-cutting rule ("call out AA fails"). This is precisely the analytic-vs-render trap 196 diagnosed: 171's contrast test pins the *analytic composite* (`chrome_ink_over` ≈ 4.9:1) rather than the shipped pixels, and the thin `font_body_bold` 17px strokes under-cover the translucent `black@0.45` ghost pill, so white@0.96 composites to a grey ~0.23 peak → ~2.4–3.1:1. The «Tilbake» control is the primary way *out* of the showcase and it reads as a disabled ghost; «Trener nå» is the dog's current-state status. Both sit directly under the two captions 196 just made crisp — so the surface now has a legible caption tier above a sub-AA control tier, the lone AA fail left on the showcase.
- **What "good" looks like:** lift **both** bottom-control labels to clear **≥4.5:1 verified from an actual captured screenshot** (not only the analytic composite), reusing 196's own proven lever on this same surface — back the «Tilbake» (and, when live, the chevron) chrome with an **opaque** dark fill (as 196's `CAPTION_SCRIM`, not the translucent `black@0.45`) so the white label composites against a stable near-black base and the thin strokes clear AA; and darken the «Trener nå» ink and/or the `cfd6dd` fill so its dark-on-pale label clears AA in-pixel too. Keep the ghost-pill *look* subordinate (a quiet dark tag, like the caption chips), the spotlight-glow translucent band, the titles and pills as-is. This is not a revert of 171 — it closes the render gap 171's analytic fix left, exactly as 196 did for the captions.

**Surface sweep — otherwise clean (re-verified this pass, in my own pixels):**
- **Training page** (`P71-a-training.png`, `P71-topbar.png`): matches the goal art — blue BRA hero CTA, hamburger + «Triks» + «Kennel» nav pills (full «Kennel», no truncation), gold coin pill «5000», «Sitt … 0%» learned bar with opaque cream track, cream Labrador centred/grounded on grass (faces camera at a seated apex, cyan approach ring at the mark), tan path → blue-roofed cottage, white picket fence, gold + rose coins.
- **«Triks» menu** (`P71-b-menu.png`): DS paper card — «Triks» Baloo-2 title over coin pill, trick rows (Sitt «Trener nå» / Ligg · Legg deg «Tilgjengelig» / Gi labb «Låst»), «Raser» (Bella «aktiv» / Brun lab «Adopter 30»), blue-ghost «Vis frem hundene» + «Gi tilbakemelding» + solid-blue «Fortsett treningen» primary. Row names flush-aligned (195), section headings uniform (193). (Marker-word section reveals after mastery — verified structurally in prior passes; not re-litigated.)
- **Breed showcase** (`P71-c-showcase.png`): «Mine hunder» / «Bella — aktiv» white titles + «Labrador» scrim-chip caption (196, AA-clear), cream Labrador spotlit on the garden (HUD hidden), «Bella» page-dot indicator (**5.76:1**, AA-clear), «Adopter flere …» hint scrim chip (196), bottom-control chrome AA flagged above.
- **Kennel** (`P71-e-kennel.png` grid, `P71-f-modal.png` Sol modal): 8 cells fill the 844 portrait under «Kennelen · Profesjonell fasilitet · 8 plasser» + coin chip, front-¾ full-body poses, Norwegian rarity/status corner badges (Bella «Din hund»/green, Nova «Episk»/violet, Balder+Sol «Sjelden»/blue, Pontus/Lykke/Sniff «Vanlig»/slate, Trulte «Påskeegg»/coral — dark-ink AA per 149), gold coin price chips descending by rarity (Nova 900 › Balder 650 › Sol 500 › Sniff 320 › Pontus 350 › Lykke 300; owned Bella none + faint-green tint; Trulte «Gratis»). Sol modal: golden hero bust matching the grid cell, blurb, 4 blue stat meters with the empty segment a present slate track (188), «Raseegenskaper» chips (Vennlig · Glad · Tålmodig), «Unikt trekk» (Alles venn), «Kan lære: Sitt · Ligg · Legg deg», solid-blue «Adopter 🪙 500» primary, unified light-disc ✕ (189). Coats: Bella cream, Sol golden, Trulte the clean silver-white from 192, Nova dark.

**Considered but NOT filed — owner-gated / intentional, not buildable polish.** (1) The four warm-brown breeds (Balder/Schäferhund, Pontus/Gravhund, Lykke/Spisshund, Sniff/Beagle) read as similar mid-browns — but their catalog tints already span a genuine value/hue range and their real identities are **pattern/shape** (shepherd saddle, dachshund body, beagle tricolor) a single-colour tint on the one shared Labrador rig cannot convey; the honest fix is distinct per-breed **models** (BUST-068, P3-D1/D2/D4), a standing owner flag. (2) The trick-row «Tilgjengelig» vs the other sections' «Bytt» switch badge — kept (tricks carry a «Lært» learned state the others lack; see pass-70's resolved-195 note). (3) The active-state badge word differs across sections (trick «Trener nå», breed/word «Aktiv», difficulty «Valgt») — each reads correctly in its own context and pass-68 deliberately kept «Valgt»; not re-litigated. (4) The showcase dog is a live idle that can turn rear/side between frames — animation timing, not a fixable layout defect.

**No regression** in any signed-off phase: every surface renders as before, the autotap burst drove a clean camera-facing apex + cyan approach ring, the «Triks» menu + breed showcase + kennel grid + modal all drive clean — closing back restores the Phase-6 training page + Phase-1/2 core mark loop (cream Labrador centred facing camera on green grass, tan path, cottage, fence, coins, blue BRA). Zero console errors throughout.

**No sign-off.** Phases 1/2/3/5/6/8/9 remain signed with no regression. Phase 10 (`phase10.md`) is still **empty/deferred** — owner-gated (no spec ⇒ cannot Visual-Review, cannot invent scope). This pass re-verifies the 196 caption-scrim fix (subtitle 7.38:1 / hint 13.99:1), prunes it, and files **one buildable X-6 directive** (lift the breed-showcase bottom-control chrome — «Tilbake» ~2.35–3.15:1 + «Trener nå» 4.03:1 — to clear AA in the actual render, the same render gap 196 closed for the captions). The standing asset flags (distinct per-breed **models**, camera-facing **signature clips**, warm human "Bra!"/Maren voice, coat UV re-export) remain owner-gated.
