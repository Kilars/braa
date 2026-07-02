**PO Review**

### PO Review — 2026-07-02

Played the current build (HEAD `29d0580`) on the local licensed bundle at 390×844 phone-portrait
(headless Chromium / SwiftShader = the deployed GL Compatibility renderer). Boot log confirms the
licensed Labrador + "can Sitt" + feinting; **zero** SCRIPT ERROR / pageerror across boot + play.

**Confirmed fixed / working this pass:**
- **Coin readout (069) — the "coins" caption ships and reads cleanly.** A drawn gold coin + count +
  a "coins" caption sit on their own top line, clear of the chip row; no tofu-box glyph. This meets
  the *minimal* "make the collection axis legible" ask, so **Improvement-3 is pruned** — only the
  spend-side adopt UI stays owner-gated (a flag, not a directive; don't fake a breed to fill it).
- **Trick selector (066)** switches the active trick on tap (Sitt→Ligg→Legg deg→Sitt, verified by
  canvas taps + `__bra_current_trick`).
- **P2-11 holds into Phase 3** — for a real trick the dog turns to face the camera POV and performs
  it head-on and centred (free-05/08 approach with the trainer ring; free-03/07/10 sit facing forward).

**Sharpening for the owner's Actionable notes below (what "good" looks like, buildable now):**
- *Note 2 (too distracted):* I watched roughly a third of offers abort as feints — real markable
  moments feel scarce. Good = ~**90%** real completed tricks, ~**10%** feints/distraction.
- *Note 3 (off-centre / looking away):* between offers the dog stands **rear-on**, tail to the
  player (`free-00`). Good = keep it framed and generally facing the player between offers (alive,
  not a statue, but never a long rear-on stretch); add a **scratch** as one of the feints — it's funny.
- *Notes 1 & 4 and Improvement-4 / Change-5 below stand as written — all still unbuilt this pass:
  no completion popup, no `BreedPersonality`, no persisted roster in the running build.*

**Improvements**

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

## Actionable notes
1. Only one trick should be active at a time. Sitt for example. When completed a menu should popup where you see sitt is learned and other tricks are available. In this screen you also see currency and unavailable tricks
2. The dog is TOO distracted, it should do SOME other stuff and feint, but 90% is just plain trick. 
3. Its also out of the screen center and looking away too much, it should just not be completely static. Use the scratch as a feint, its funny.

4. Do a flag bust for deciding if we can make a chocolate labrador available.


