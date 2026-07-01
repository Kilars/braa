# Flags for the human — decisions the autonomous loop can't make for you

This is the loop's **async channel to you**. The loop never blocks waiting for an answer:
when it hits something only you can decide, it makes the best-supported assumption, keeps
building, and records the open question here for you to resolve when you next check in.

**Two-gate rule — not every uncertainty lands here.** A flag is raised only when BOTH:
1. the work surfaced something genuinely **user-only** — a product / scope / legal / asset /
   owner decision, or an ambiguity whose answers lead to materially different outcomes (NOT
   a technical fork the loop can reason out itself), AND
2. the **orchestrator** (the mother iteration's main agent) agrees it's material enough to
   warrant your attention.

Technical choices the loop can resolve, it resolves — best assumption, recorded in the task
file — and those do **not** come here. **Subagents never write this file; only the
orchestrator does.**

## Protocol

- **Raising:** the orchestrator appends a new `### FLAG` entry at the **top of Open**,
  dated, then continues the loop on its stated assumption. Check for an existing open flag
  on the same issue first — update it, don't duplicate.
- **Non-blocking:** raising a flag never stops the loop. A genuine hard block additionally
  parks its task in `.task-board/on-hold/` while every other task keeps moving; the flag is
  just the heads-up to you.
- **Resolving:** when you answer (edit the flag inline, or reply in a session), the loop
  applies your decision and moves the entry to **Resolved** with the outcome. Keep resolved
  flags as a short audit trail; prune them when stale.

Entry format:

```
### FLAG <YYYY-MM-DD> — <short title>
- **Source:** <task id / step that surfaced it>
- **Decision needed:** <what only you can decide>
- **Why it's user-only:** <why the loop can't just pick>
- **Assumption made to keep going:** <what the loop did in the meantime>
```

## Open

### FLAG 2026-07-01 — Phase 3 (breeds) asserted "owner-gated on breed assets" + unresolved owner-decisions P3-D1/D2/D4  ·  **busted 2026-07-01 (BUST-068) — economy/personality spine DE-GATED; only extra breed MODELS + the 3 decisions stay owner-gated**
- **Source:** the board/memory assert "all Phase-3 stories sit on the owner-gated breed-asset block," and `phase3.md` marks **P3-D1** (lock the launch breed set), **P3-D2** (universal vs. signature tricks), **P3-D4** (per-breed clip coverage) as **unresolved owner-decisions** "to resolve before this phase is sliced." Phase 2 was just signed off (Phase 3 is now current), and this gate was **never raised as a flag** — so Iteration step 2's sweep would miss it, the exact anti-pattern that skipped the Phase-2 roster. Raised + busted here.
- **The bust (against the raw asset inventory, NOT the running game — behavior ≠ inventory):** `ls assets/models/` + `assets/models/dog_licensed.clips.txt` show exactly **one** licensed model — the **Labrador** (every one of the 113 clips is `Arm_Labrador|…`). There is **no** Border Collie / French Bulldog / Husky glb on disk. So the breed-**appearance** half of P3-1 ("reads clearly as that real breed" — distinct silhouette/coat) and any breed-**exclusive** signature-trick clips (P3-2) are **genuinely owner-asset-gated** — they need models the pack doesn't ship.
- **What builds WITHOUT the owner (routed to build tasks):**
  - **P3-D3 light economy — already DECIDED by the owner** (breeds unlock via earned currency; the spec says "Phase 3 pulls a light economy forward"). Master a trick → earn coins → a **persistent coin balance** → adopt-cost / locked-state logic. Pure test-first logic; hooks the existing `TrickProgress.just_mastered()` one-shot and persists via `TrickStore`. **Zero dependency** on which breeds ship (D1) or which tricks are signature (D2). Strongest buildable slice → **routed to build task 068** (the coin economy core, this iteration).
  - **P3-3 personality → difficulty levers** — a `BreedPersonality` data model (learn speed, distractibility, window stability, energy) modulating the existing `SitWindow`/`TrickProgress`/cadence, keyed to the Labrador as breed #1. The **system** is buildable now; follow-up task.
  - **P3-4 roster persistence** — extends the existing `TrickStore`; follow-up.
- **Narrowed residual (genuinely owner-gated — stays flagged):** the additional breed **models** (Border Collie / French Bulldog / Husky visual assets) + any breed-exclusive signature-trick clips absent from the Labrador rig; and the three **owner-decisions** P3-D1 / P3-D2 / P3-D4. These wait on the owner supplying models + recording the decisions.
- **Assumption while building:** build the economy (then personality) spine against the single Labrador breed (breed #1), behind the PO-signed Sitt/Ligg/Legg deg roster; coins accrue **additively** so the Phase-2 experience is unregressed. The multi-breed selector/adopt UI wires in once the owner supplies ≥1 more breed model and locks D1/D2.

### FLAG 2026-07-01 — The Phase-2 trick roster (P2-1/P2-2/P2-3) is "owner-gated"  ·  **busted 2026-07-01 (BUST-064) — MOSTLY DE-GATED, scope narrowed to 3 absent clips**
- **Source:** `.docs/specs/po-review.md` (the 2026-07-01 PO pass) **asserted** the trick roster is
  "owner-gated on trick clips — the licensed Labrador ships only the Sitt, so there is no second
  trick." This assertion was never raised as a flag, so Iteration step 2's flag-bust sweep would
  have missed it — exactly the anti-pattern that skipped P2-1/2/3 before. The orchestrator raised it
  here and busted it the same pass.
- **The bust (against the raw manifest, NOT the running game — behavior ≠ inventory):** grep of the
  committed inventory `assets/models/dog_licensed.clips.txt` (139 lines, the real licensed glb clip
  list) shows the asset **already holds** two more trick's clips beyond Sitt:
  - **Ligg** (lie down) → `Lie_start / Lie_loop_1|2 / Lie_end` — **PRESENT, unwired → BUILD task, not owner-gated.**
  - **Legg deg** (settle on belly) → `Lie_belly_start|loop|end` (+ `Lie_Sleep_*`) — **PRESENT, unwired → BUILD task.**
  These are exactly the P2-2 starter set ("**Sitt**, **Ligg**, **Legg deg**, then expand"). The app
  only *wires* Sitt (`DogClips.resolve()` resolves only `sitting`-vocab clips), so the running game
  shows one trick — but the asset holds three. **Routed to build tasks:** **065** (wire Ligg as a real,
  distinct, markable second trick — this iteration) and **067** (Legg deg, follow-up); the two-entry
  selector P2-1 is **066** (a real two-trick chooser is not the "one-entry selector" the PO warned
  against — that caution was premised on there being only one trick, which the manifest refutes).
- **Narrowed residual (genuinely owner-gated — clips ABSENT from the asset):** **Gi labb** (paw/shake),
  **Rull** (roll over), and **Snurr** (spin) have **no** matching clip in the manifest (a grep for
  paw/shake/roll/spin finds only decoys like `Crouch_*` / `Jump*`, none a clean trick apex). These
  three stay owner-gated until the owner supplies clips (or they are hand-authored). The phase's
  headline "more tricks" is therefore **buildable now** to a 3-trick roster (Sitt+Ligg+Legg deg) —
  it is **not** blocked purely on the owner.
- **Assumption while building:** 065 wires Ligg through the existing (already per-trick-keyed)
  `TrickProgress`/`TrickStore` + trick-agnostic `SitWindow`/`SitLoop`, reachable via a debug param
  (`?bra_trick=ligg`, the same harness pattern as `?bra_force_lock`) until the P2-1 selector (066)
  lands; default gameplay stays Sitt so the PO-verified current experience is unregressed.

### FLAG 2026-06-29 — The warm *human* "Bra!" voice (and the Phase-5 praise words) is owner-gated  ·  **busted 2026-06-30 (BUST-043) — scope narrowed**
- **Source:** P1-6 mark payoff (`scripts/payoff_player.gd`); owner review 2026-06-29.
  De-gated by **BUST-043** (2026-06-30) — this flag was raised *whole* with **no spike**, the
  anti-pattern `mother_prompt.md` names; the flag bust found most of it was buildable.
- **Narrowed decision needed (owner-only now):** supply a real, warm, **human "Bra!"** recording
  (the "Maren" delivery) — or any short Maren sample to clone from — to drop in under the stable
  voice cue id; and later the Phase-5 praise words (*dyktig, flink, super, kjempebra*), each its
  own voiced line. **Only the literal human voice remains owner-gated.**
- **What the bust de-gated (no longer owner-gated):** a *warm, near-human* synthetic stand-in is
  buildable **offline with no owner action** — local **neural** TTS (**Piper**, `nb_NO`) replaces
  the robotic espeak clip under the same cue id, no code change. Routed to build task **044**.
  **Correction of the original reasoning:** X-7 is a *runtime*-offline constraint; **baking a
  voice file at authoring time does not violate it** (the game still plays a static `.wav`). The
  old "X-7 … so a cloud-voice substitute is out too" was wrong — it conflated runtime with
  authoring, which is exactly why the whole capability got flagged instead of spiked.
- **Assumption while building:** the stand-in at `assets/audio/bra_tts_placeholder.wav` is now a
  **bright, light, female native-Swedish** Piper "Bra!" — voice **`sv_SE-alma-medium`** (task
  **060 landed 2026-07-01**, owner directive: brighter/lighter/female). "Bra" is the same word +
  pronunciation in Swedish and Norwegian, so the cue stays correct. This supersedes task 044's
  neutral `no_NO-talesyntese-medium` clip (f0 149 Hz → **227 Hz female**; centroid 811 → **1116 Hz
  brighter**), same cue id, **no code change**. Reproducible via `tools/gen_bra_voice.sh`. The
  clip is still drop-in replaced by your warm **human Maren** recording, also with no code change —
  **that literal human voice is all this flag still gates.** (The timbre/gender is judged on the
  owner's on-device listen of the live site; the owner said "just deploy," so it shipped.)

## Resolved

### FLAG 2026-06-30 — Coat seam + belly "sliver" (licensed-asset UV/tangent seam) — RESOLVED 2026-06-30 (PO accepted as-is)
- **Outcome:** the owner (larssski) reviewed the **live deployed build** and judged the coat
  **fine at native phone size** — the seam is sub-perceptible in real play, only visible under
  magnification (as the 039 spike found). Accepted **as-is (WONTFIX — cosmetic)**; **no owner
  re-export is required** for Phase 1. This closes the last non-voice owner gate.
- **Root cause kept on record (for any future re-export):** a UV/tangent seam baked into
  `dog_licensed.glb` — both body halves mirror onto one 2048² UV atlas (gap ~0.90 at the
  centreline); the GLB ships **no TANGENT attribute**, so Godot's import-time MikkTSpace tangents
  diverge ~90° across the seam and the normal map shades the two sides oppositely. **Not**
  geometry, **not** transparency; can't be fixed in-engine without dropping the normal map (which
  strips coat detail). **If the asset is ever re-exported for other reasons**, bake per-vertex
  tangents, tag the normal map, and pad the albedo UV-island edges to remove it at the source.
  Until/unless that happens, the seam ships and is accepted.
- **Task 040** (the in-engine mitigation) is **moot** — premise already proven a no-op (gitignored
  `.import` files regenerated from defaults in CI); archived alongside this resolution.

### FLAG 2026-06-29 — Phase-1 deploy reflectance + live P1-10 visual sign-off (owner/PO gates) — RESOLVED 2026-06-30
- **Outcome:** the PO's **2026-06-30** review pass (`.docs/specs/po-review.md`) drove the **live
  deployed Pages site itself** (not a local export) at 390×844 and confirmed it now serves the
  **licensed Sitt build** — the live boot log reads
  `dog loaded: res://assets/models/dog_licensed.glb (1 coat surface(s) forced opaque)` and
  `dog can Sitt — looping a sit every 1.2s (real apex from the licensed Labrador)`. So the
  deploy is **no longer no-opping** to the CC0 idle-only dog (the `GODOT_SCRIPT_ENCRYPTION_KEY`
  secret + committed `.glb.enc` are in place, ADR-0006 / 025). The **P1-10 live-deployed-site
  visual gate is CLEARED**: full sit loop runs live, dog sits legibly + centered + shadow-grounded
  every cycle, and the **apex tell fires on the deployed build** (live burst: max 678 gold px,
  gold on 3/60 frames, dark in idle) — the live-pixel proof the prior pass demanded, taken on the
  deployed build the gate names. The carried-over **P1-4** blocker is also confirmed RESOLVED in
  live pixels.
- **Still open (tracked by the other two flags, NOT this one):** the warm **human** "Bra!" voice
  + on-device audio listen (voice flag below), and the **coat re-export** (coat-seam flag above).
  Phase 1 is **not** yet signed off — but the deploy/P1-10 concern this flag raised is settled.
