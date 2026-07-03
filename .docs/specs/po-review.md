**PO Review**

### PO Review — 2026-07-03 (build HEAD `b7f8d51` — post-089 drawn-chevrons + 090 HUD-hide)

Rebuilt the local licensed bundle fresh from HEAD `b7f8d51` (`verify.sh` green, full `build/web/`)
and **replayed every surface** at 390×844 phone-portrait in headless Chromium / SwiftShader (== the
deployed GL Compatibility renderer) with **real canvas taps**. Zero SCRIPT ERROR / pageerror across
the boots. Evidence captured this pass: `.screenshots/087-01-showcase-yellow.png`,
`087-02-showcase-chocolate.png`, `po-crop-showcase-bottom-091.png` (cropped control band),
`072-menu-open.png`, `034-reaction-05.png` / `034-reaction-09.png`, `085-feedback-02-filled.png`.

**Both prior Bugfixes verified FIXED in pixels — pruned from the directive list:**
- **(Bugfix 1 — tofu cycle controls) RESOLVED by 089.** On "Mine hunder" the bottom-left/right cycle
  controls now draw as clean filled white triangles in dark rounded boxes — no missing-glyph boxes —
  and the hint line reads **"Bla med pilene eller trykk en hund"**, reworded to name the arrows in
  words so no `◀`/`▶` glyph is embedded anywhere (`po-crop-showcase-bottom-091.png`). Tofu gone.
- **(Bugfix 2 — BRA button bleed-through) RESOLVED by 090.** Neither showcase frame shows the
  training "BRA" button ghosted over the spotlit dog; the training-HUD chrome is hidden while the
  showcase is open, so only the dog + the showcase's own title/control bands render (`087-01`,
  `087-02`). The clean-centre "here is my dog, shown off" read now holds.

**Everything else replayed clean — no new buildable shortfall found.** Core loop reads well (dog
centred + camera-facing, **BRA a clear round button** inside the gold apex ring, drawn coin readout,
textured garden); the post-BRA reaction is joyful and stays camera-facing with **no rear-spin/flick**
(077 holds, `034-reaction-*`); the completion menu is legible with an honest learned / available /
locked trick list + coins + a Breeds section (`072-menu-open.png`); the feedback form opens, fills,
and renders cleanly (`085-feedback-02-filled.png`). No Phase-1 / Phase-2 regression.

**Why Phase 3 still isn't signed off — now blocked PURELY on the owner (no buildable directive
remains).** With both showcase bugs fixed, every remaining unmet acceptance criterion needs a real
**second breed model** from the licensed pack, which the build loop cannot produce:
- **(P3-1) A genuinely distinct second breed.** The two owned "breeds" are the same rig — a yellow
  Lab and its chocolate recolor (`087-01` vs `087-02`): identical silhouette/proportions, only coat
  colour differs. That is an honest coat variant, not a second-breed silhouette, so "collect and
  train **different breeds**" is not yet met. Needs the licensed model pack (P3-D1/D2/D4).
- **(P3-2) Breeds bring different tricks.** Both "breeds" still train the identical Sitt / Ligg /
  Legg deg list — the acceptance criterion ("a trick list not identical to every other breed's") is
  unmet. The 088 flag-bust already grepped `dog_licensed.clips.txt`, found only rear-to-camera
  **Digging** as a signature candidate, and correctly **rejected** it (fails the camera-facing read,
  X-4) with **no stub**. A real per-breed signature trick needs a second breed model with a
  camera-facing signature clip — owner-gated, and not to be faked with an artificial restriction.
- **(P3-3) Breeds feel different to train.** The `BreedPersonality` levers are built, but with only a
  recolor there is no genuinely distinct breed for them to differentiate — this rides on the same
  model gate.
- Live telemetry still needs the owner's `POSTHOG_TOKEN` secret; the warm human "Bra!" voice stays
  owner-gated. Neither is a Phase-3 sign-off gate (X-8).

**Net:** Phase-3 buildable work is exhausted and green — the two showcase bugs are fixed and every
other surface replays clean. The phase is blocked purely on the owner-gated licensed breed pack
(P3-D1/D2/D4) plus the owner secrets/voice. There is **no new buildable directive to file**, and I
will **not** re-date the owner-gated residuals as busywork — once the board confirms terminal-zero,
the next unchanged pass should end the run so the human can add the breed models / secrets.

---

## Actionable notes
1. Only one trick should be active at a time. Sitt for example. When completed a menu should popup where you see sitt is learned and other tricks are available. In this screen you also see currency and unavailable tricks
2. The dog is TOO distracted, it should do SOME other stuff and feint, but 90% is just plain trick. 
3. Its also out of the screen center and looking away too much, it should just not be completely static. Use the scratch as a feint, its funny.

4. Do a flag bust for deciding if we can make a chocolate labrador available.
5. The trick is hard to time, the circle apex makes users wanna swipe not tap. it needs to be a button, also users are typically late (i think visually its a bit too hard) perhaps dog slower or a bit later tap for perfect
6. About styling: The theme is stylized realistic, the garden is not that good looking and the visual cohesiveness between dog and garden is not great either. Do some visual work in this phase as well.
7. Behaviour bug. The dog does a sort of jump after correct bra, and then it flicks back (unnatural) to trick position, and then it stands up. Moves unnatural. Also sometimes when its turning it flicks / jitters. these unnatural flicks are unacceptable and really take away from the games flow and experince
