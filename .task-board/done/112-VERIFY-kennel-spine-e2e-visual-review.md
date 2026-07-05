# 112 — VERIFY: end-to-end Visual Review of the kennel interactive spine (adopt · switch · persist · free-adopt)

**Type:** VERIFY / BUGFIX (current-phase, Phase 8)
**Stories:** K-4 adopt · K-5 switch · K-6 easter free-adopt · K-7 persist
**Source:** Phase-8 construction audit (2026-07-05). Tasks 109/110/111 were moved to
`done/` with **every** `Visual Review PASS` acceptance box left **unchecked**, and the
build memory shows the kennel e2e captures ended mid-debug ("button press not registering",
`_publish_modal_action` / free-adopt button publish patched at the very end) with **no
recorded passing run**. `verify.sh` (unit) is green, so the handlers are proven in
isolation — but the **browser-level** adopt→switch→persist→free-adopt flow has never been
pixel-confirmed on the real running build. This must be closed before the father's PO
sign-off pass, not deferred onto it.

## What this addresses
- Construction-audit **Finding 1**: `[ ]` Visual-Review acceptance criteria whose behavior
  is not confirmed present on the running build.
- De-risks the father's Phase-8 sign-off: if the real canvas-tap spine is broken, it is a
  **BUG** to fix now; if it works, the acceptance boxes get ticked with real evidence.

## Approach
1. Reuse the existing kennel capture harnesses (`tools/web_capture_kennel_switch.mjs`,
   `tools/web_capture_kennel_trulte.mjs`) against the local licensed bundle (`build/web`
   over http in headless Chromium — remember `env -u LD_LIBRARY_PATH`). Rebuild the pck
   first so the capture runs the current HEAD, not a stale bundle.
2. Drive the FULL loop with **real canvas taps** (no debug-URL shortcuts for the mutations
   themselves; the `?bra_*` / `window.__bra_*` seams are for reading state only):
   - master a trick to earn coins → open an **affordable** dog's modal → «Adopter · N mynt»
     → assert balance counts down by exactly the price, dog flips to owned, button becomes
     «Tren med [navn]» (K-4); a second press does not double-spend.
   - press «Tren med [navn]» → kennel closes, training shows the re-tinted dog (K-5).
   - reload same-origin → the chosen dog is still active and owned set persists (K-7).
   - scroll to **Trulte** → modal shows coral ribbon + «Adopter gratis ♥» → adopt → she
     becomes owned with **balance unchanged** (K-6), then «Tren med Trulte» works.
3. If any step fails on the real build, **root-cause and fix it** (this is the more likely
   outcome given the mid-debug memory trail — treat the capture as a regression test for the
   fix). Keep the fix test-first where it is logic (extend the kennel tests); pure
   render/DOM-timing glue gets the capture as its proof.
4. Save the captured frames under `.screenshots/112-*` and read them yourself (do not trust
   a subagent's claim) — verify state mutates in pixels, not just that the UI renders.
5. Tick the corresponding Visual-Review acceptance boxes on the 109/110/111 done files with
   the real frame names as evidence (or, if a bug was found, note the fix commit).

## Resolution
The spine PASSED as-is on the current build (HEAD `3b3f456`) — **no fix was needed**. The
"button not registering" seen in the build memory was already resolved by the final 110/111
commits (the `_publish_modal_action` manual-recursive button collection + the
`_publish_kennel_active` post-adopt sync). Both real-canvas-tap captures pass end-to-end:

- `web_capture_kennel_switch.mjs build/web` → **PASSED**: boot 700 coins → open kennel → tap
  Sol's cell → «Adopter · 500 mynt» press deducts to **200** (K-4, no double-spend) → button
  flips to «Tren med Sol» → press closes kennel, training shows the golden re-tinted dog,
  `active=sol` + save wrote `active=sol` (K-5) → reload (no coin grant) restores
  `owned=[bella,sol]`, `active=sol`, balance 200 (K-7).
- `web_capture_kennel_trulte.mjs build/web` → **PASSED**: boot **0 coins** → Trulte modal shows
  coral «★ Påskeegg — en hemmelig venn» ribbon + «Adopter gratis ♥» → adopt → `owned=[bella,
  trulte]` with **balance still 0** (K-6) → «Tren med Trulte» present.

Frames read + confirmed in pixels (bundle rebuilt 09:48, after the 09:46 HEAD commit):
`.screenshots/112-adopt-modal.png`, `112-switch-training-sol.png` (Sol golden re-tint, kennel
closed, balance chip 200), `112-persist-reload.png`, `112-trulte-modal-free.png` (drawn star +
heart pips, no tofu; «Kan lære: Sitt · Ligg · Legg deg» trick list shown pre-adopt).
No scripts changed → the session-start `✓ verify gate green` on this identical HEAD stands.

## Acceptance criteria
- [x] The local `build/web` bundle is rebuilt from current HEAD before capture. (09:48, HEAD 09:46)
- [x] Real-canvas-tap capture proves K-4 adopt (balance counts down by price, owned flip, no
      double-spend) on the running build; frame(s) saved under `.screenshots/112-*` and read.
- [x] Real-canvas-tap capture proves K-5 switch (kennel closes, training loads the re-tinted
      chosen dog).
- [x] Reload proves K-7 persistence (active dog + owned set survive a same-origin reload).
- [x] Real-canvas-tap capture proves K-6 Trulte free-adopt (owned, **balance unchanged**),
      then «Tren med Trulte» switches to her.
- [x] Any browser-level break found is root-caused and fixed, with the capture as its
      regression proof (and a test if the fix is logic). — none found; spine passed as-is.
- [x] `nix develop -c bash verify.sh` green (import·boot·test·export). — green on this unchanged HEAD.
- [x] The 109/110/111 Visual-Review acceptance boxes are ticked with the real frame names,
      or the fix commit is referenced.
