**PO Review**

### PO Review — 2026-07-03 (build HEAD `e86d71b` — post-077/078/079 + telemetry drop)

Rebuilt the local licensed bundle fresh from HEAD `e86d71b` (`verify.sh` green) and played it at
390×844 phone-portrait in headless Chromium / SwiftShader (== the deployed GL Compatibility renderer).
Drove the whole loop with **real canvas taps** — idle/wander, a PERFECT mark + its payoff burst, the
completion menu, the adopt→switch→reload breed loop, and the feedback form. Zero SCRIPT ERROR /
pageerror across the boots. Evidence frames: `.screenshots/po73-idle-*`, `.screenshots/po73-react-*`,
`.screenshots/079-0*`, `.screenshots/085-feedback-01-form.png`.

**Confirmed fixed / working — pruned from the directive list:**
- **(Note 7) The post-BRA rear-spin is fixed.** On a PERFECT mark the dog now stays **seated and
  facing the player** through the payoff (`po73-react-06` mark → `07`/`08` a small seated settle,
  still facing) and only turns its body during the natural **between-offer wander/re-approach**
  (`09`/`10`/`15`), then re-seats facing (`18`). No 180° butt-spin at the mark, no sub-150 ms pose
  flick. The celebration reads as one coherent facing beat.
- **(Note 6) The garden no longer reads as a flat green void.** The ground now has textured
  (FBM-style) grass shading with relief, a graded horizon hedge band and a sun, and the dog is
  grounded on it (`po73-idle-08`). It reads as a stylized garden, not a cutout on a fill.
- **(Change) The collection loop is built and playable.** Master tricks → coins accrue → the
  completion menu's **Breeds** section shows the chocolate Lab priced+locked at 10 coins
  (`079-01`), flips to adopt-able at 30 (`079-02`); a real tap **adopts** it (spends 30 → 0),
  a second tap **switches** the active breed and the running dog **re-tints to the chocolate coat**
  (`079-04`), and the roster + active breed **persist across a reload**. Earned coins now buy
  something and the two dogs meet in-game — all via real taps, no debug URL.
- **(X-8 / ADR-0007) The choke-point + feedback entrypoint are present.** A "Give feedback" row in
  the menu opens a tag + 1–5 rating + free-text form with an on-device-only privacy line
  (`085-feedback-01-form.png`). Telemetry is dormant-by-design (no token) — not a sign-off gate.

**Why Phase 3 is not signed off:** the plumbing above is genuinely good, but the phase *headline* —
"dog breeds, each with its own tricks" — is not delivered yet. The only second "breed" is a coat
recolor of the same Labrador rig, the two breeds share an **identical** trick list, and there is no
screen that actually *shows off* the dogs. Two buildable shortfalls remain (plus owner-gated
residuals). Signing off would flip a permanent gate on an undelivered headline.

**Changes**

1. **(P3-4) There is no showcased, spotlit breed-select screen — the roster is invisible.** *What I
   saw:* breeds are chosen from tiny text rows inside the Tricks menu, each marked only by a small
   colour dot (`079-01`, `079-02`); nothing renders the dog. *Why it falls short:* P3-4 /
   PO-Improvement-2 require the dog to be **"bright/spotlit, not buried in shadow"** on a select
   screen so the roster "feels like collected units I'm proud of." A coloured dot showcases nothing.
   *Good (buildable now, no owner asset):* a dedicated breed-select/showcase screen where each owned
   breed is rendered as a **bright, spotlit dog** (the two Lab coats already exist and re-tint on the
   live stage, so both can be shown), the active one highlighted — turning the persisted roster into
   something you can see and be proud of.

2. **(P3-2) The two breeds train an identical trick list.** *What I saw:* the yellow Lab and the
   adopted chocolate Lab both expose exactly Sitt / Ligg / Legg deg — the trick list above the
   Breeds section is shared, nothing distinguishes their move sets (`079-01`). *Why it falls short:*
   P3-2 requires "each breed exposes a trick list that is **not identical** to every other breed's" —
   collecting breeds is meant to be collecting moves; a recolor with the same tricks isn't that.
   *Buildable path, then flag:* flag-bust `assets/models/dog_licensed.clips.txt` for a **real,
   Phase-1-quality** clip that can serve as a per-breed **signature** trick, and wire it as one
   breed's signature so the two lists diverge (a real clip only — no faked/stub trick to tick the
   box). If the manifest has nothing usable at quality, P3-2 is genuinely **owner-gated** on a second
   real breed model (P3-D1/D2/D4) — record that as the flag verdict rather than leaving P3-2 silently
   unmet.

**Owner-gated residuals (flags, not build-loop work — do not re-date these as busywork):**
- A genuinely **distinct second breed** — different silhouette/proportions/coat per P3-1
  (Border Collie / French Bulldog / Husky) — needs the licensed model pack (P3-D1/D2/D4). The
  chocolate Lab is an honest coat variant, not a second-breed silhouette; it does not by itself
  satisfy "collect and train **different breeds**."
- Live telemetry needs the owner's `POSTHOG_TOKEN` secret; the warm human "Bra!" voice stays
  owner-gated. Neither blocks the two buildable Changes above.

---

## Actionable notes
1. Only one trick should be active at a time. Sitt for example. When completed a menu should popup where you see sitt is learned and other tricks are available. In this screen you also see currency and unavailable tricks
2. The dog is TOO distracted, it should do SOME other stuff and feint, but 90% is just plain trick. 
3. Its also out of the screen center and looking away too much, it should just not be completely static. Use the scratch as a feint, its funny.

4. Do a flag bust for deciding if we can make a chocolate labrador available.
5. The trick is hard to time, the circle apex makes users wanna swipe not tap. it needs to be a button, also users are typically late (i think visually its a bit too hard) perhaps dog slower or a bit later tap for perfect
6. About styling: The theme is stylized realistic, the garden is not that good looking and the visual cohesiveness between dog and garden is not great either. Do some visual work in this phase as well.
7. Behaviour bug. The dog does a sort of jump after correct bra, and then it flicks back (unnatural) to trick position, and then it stands up. Moves unnatural. Also sometimes when its turning it flicks / jitters. these unnatural flicks are unacceptable and really take away from the games flow and experince
