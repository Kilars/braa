**PO Review**

**Improvements**

3. **The coins are a context-free number — the collection goal isn't legible.** The player
   masters tricks and watches a bare count climb, but nothing on screen says these are coins
   *earned toward adopting a new dog*, and there is nowhere to spend them. *Why it falls short:*
   P3-D3 asks that "the collection axis is visible"; right now the earn side works but its purpose
   is invisible. *Good (buildable now, before any breed model):* give the readout a minimal label
   / affordance conveying purpose (e.g. a "coins" caption or a small toward-a-dog hint). The
   **full adopt UI** (coin price + locked state + breed thumbnail) genuinely needs the owner-gated
   extra breed models — keep it flagged, do **not** fake a breed to fill the panel.

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


