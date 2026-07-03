**PO Review**

### PO Review — 2026-07-03 (build HEAD `455f554` — post-087 showcase + 088 P3-2 flag-bust)

Rebuilt the local licensed bundle fresh from HEAD `455f554` (`verify.sh` green, full `build/web/`)
and played it at 390×844 phone-portrait in headless Chromium / SwiftShader (== the deployed GL
Compatibility renderer), driving every surface with **real canvas taps**. New since the last pass:
the spotlit breed-select **showcase** (087) and the **P3-2 signature-trick flag-bust** (088). Zero
SCRIPT ERROR / pageerror across the boots. Evidence frames captured this pass:
`.screenshots/087-01-showcase-yellow.png`, `087-02-showcase-chocolate.png`,
`030-apex-tell-visible.png`, `088-grav-apex-best.png`, `088-grav-choc-08.png`, and the cropped
`po-crop-showcase-bottom.png`.

**Confirmed fixed / working — pruned from the directive list:**
- **(Change 1 / P3-4 / PO-Improvement-2) The spotlit breed-select showcase now exists and hits the
  goal.** A "Vis frem hundene" row opens a **"Mine hunder"** screen where the owned breed is rendered
  as a **big, bright, centred, camera-facing dog** on a brightened stage (`087-01`), the active one
  labelled "— aktiv" in gold; ▶ previews the next owned breed and the **live rig re-tints** to its
  coat (yellow → deep-brown chocolate, `087-02`); "Tren denne" commits + persists. The roster is now
  something you can *see and be proud of*, not a coloured dot — Change 1 is resolved.
- **Core loop holds, no Phase-1/2 regression.** Dog centred and facing camera, **BRA is a clear round
  button** framed by the gold apex ring (`030-apex-tell-visible.png`), the drawn coin readout shows
  no tofu, and the garden has textured grass + horizon + sun. The earlier owner notes (one active
  trick + completion menu, distraction/feint tuning, centering, timing-as-a-button, garden
  stylization, the post-BRA rear-spin/flick fix) all read as landed in play.

**Why Phase 3 is still not signed off:** two buildable **bugs on the brand-new showcase surface**
(below), on top of the phase headline staying owner-gated (residuals). Signing off would flip a
permanent gate over a showcase that renders broken glyphs and a leaked training button.

**Bugfixes**

1. **The showcase's ◀ ▶ cycle controls render as tofu boxes.** *What I saw:* on the "Mine hunder"
   screen the bottom-left/right cycle **buttons** and the hint line **"Bla med ◀ ▶ eller trykk en
   hund"** both draw the arrow glyphs as broken missing-glyph boxes (`po-crop-showcase-bottom.png`,
   cropped from `087-01`). *Why it's wrong:* `◀`/`▶` (U+25C0/U+25B6) aren't in the project font — the
   exact tofu-box class as the old coin emoji (fixed in 069 by *drawing* the coin). On the one screen
   whose whole job is to make the roster "feel like collected units I'm proud of", broken boxes read
   as a bug and cheapen it (X-4 "looks the part"). *Good:* the prev/next affordance renders as a
   clean, legible control on the deployed GL build — a **drawn** triangle/chevron (like the drawn
   `CoinReadout`), a bundled font that carries the arrows, or plain words ("Forrige"/"Neste") — with
   **no** tofu box anywhere, the hint line included.

2. **The training "BRA" button bleeds through the showcase's transparent centre.** *What I saw:* on
   both showcase frames the underlying training HUD's big round **"BRA"** button is visible, ghosted,
   floating over the spotlit dog (`087-01`, `087-02`, and the `po-crop-showcase-bottom.png` crop —
   the pale "BRA" over the dog). *Why it's wrong:* the showcase deliberately keeps its centre clear so
   the dog shows through, but the live BRA button leaks through that clear centre — a stray "BRA"
   hovering over the showcased dog breaks the "here is my dog, shown off" read and looks like a
   layering bug. *Good:* while the showcase is open, the training-HUD chrome that falls in the clear
   centre (at minimum the BRA button) is hidden, so only the dog + the showcase's own title/control
   bands are visible.

**Owner-gated residuals (flags, not build-loop work — do not re-date these as busywork):**
- **(P3-2) The two "breeds" still train an identical trick list — now confirmed genuinely
  owner-gated.** The 088 flag-bust did the right thing: it grepped `dog_licensed.clips.txt`, found
  **Digging** as the only signature-trick candidate, wired it, then **rejected** it with **no stub** —
  the dig clip is **rear-to-camera** (the dog's back and tail face the player,
  `088-grav-apex-best.png` / `088-grav-choc-08.png`), which fails the camera-facing / "reads first"
  quality bar (X-4) that the whole apex-read game depends on. I confirmed the rejection in pixels.
  Because both current "breeds" are the **same rig** (a coat recolor), no honest per-breed *signature*
  trick exists without a real second breed model. P3-2 is therefore owner-gated on the licensed breed
  pack shipping a camera-facing signature clip (P3-D2/D4) — not a build-loop shortfall, and not to be
  faked with an artificial trick-list restriction.
- **(P3-1) A genuinely distinct second breed** — different silhouette/proportions/coat (Border Collie
  / French Bulldog / Husky) — needs the licensed model pack (P3-D1/D2/D4). The chocolate Lab is an
  honest coat variant, not a second-breed silhouette; it does not by itself satisfy "collect and train
  **different breeds**."
- Live telemetry needs the owner's `POSTHOG_TOKEN` secret; the warm human "Bra!" voice stays
  owner-gated. Neither blocks the two Bugfixes above.

---

## Actionable notes
1. Only one trick should be active at a time. Sitt for example. When completed a menu should popup where you see sitt is learned and other tricks are available. In this screen you also see currency and unavailable tricks
2. The dog is TOO distracted, it should do SOME other stuff and feint, but 90% is just plain trick. 
3. Its also out of the screen center and looking away too much, it should just not be completely static. Use the scratch as a feint, its funny.

4. Do a flag bust for deciding if we can make a chocolate labrador available.
5. The trick is hard to time, the circle apex makes users wanna swipe not tap. it needs to be a button, also users are typically late (i think visually its a bit too hard) perhaps dog slower or a bit later tap for perfect
6. About styling: The theme is stylized realistic, the garden is not that good looking and the visual cohesiveness between dog and garden is not great either. Do some visual work in this phase as well.
7. Behaviour bug. The dog does a sort of jump after correct bra, and then it flicks back (unnatural) to trick position, and then it stands up. Moves unnatural. Also sometimes when its turning it flicks / jitters. these unnatural flicks are unacceptable and really take away from the games flow and experince
