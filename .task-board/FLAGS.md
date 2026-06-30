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

### FLAG 2026-06-30 — Coat seam + belly "sliver" is a licensed-asset UV/tangent seam (owner re-export)
- **Source:** task **039** (SPIKE — root-cause of the PO's P1-1/P1-9 "residual coat seams +
  stray sliver" improvement). Findings in `.task-board/done/039-…`; evidence under
  `.screenshots/039-spike-*` (`-bellyseam.png` is the clearest).
- **Decision needed (owner):** re-export the licensed Labrador (`assets/models/dog_licensed.glb`)
  with **per-vertex tangents baked** (Blender → glTF, "Export Tangents" on) **and/or re-bake the
  normal map** so tangent-space values match across the body symmetry seam. That is the only
  thing that removes the **hard belly-centreline shading band** (the "sliver") and the symmetric
  flank arcs.
- **Why it's user-only:** the spike proved this is **not** stray geometry and **not** a
  transparency gap (the mesh is 1 surface / 1 material; `CoatOpaque.flatten` neither causes nor
  can hide it; no sky shows through). It is a **shading seam baked into the asset's UV layout**:
  both body halves mirror onto one 2048² atlas with a UV gap up to **0.90** at the centreline, so
  Godot's import-time MikkTSpace tangents diverge ~90° across the seam and the normal map bends
  shading in opposite directions on each side. The GLB ships **no TANGENT attribute**, so the
  only in-engine alternative — dropping the normal map — would strip all coat detail (fails
  P1-1). Fixing the tangents requires editing the asset, which is owner-gated.
- **Assumption made to keep going:** the loop drafted a cheap **in-engine partial mitigation**
  as task **040**, but on picking it up **2026-06-30 found its premise was false** — so 040 is
  **parked on-hold (owner-gated)**, not built. Why: the `.import` files it would edit
  (`dog_licensed_Labrador_{Albedo,Normal}.png.import`) are **gitignored** (broad
  `dog_licensed*` glob) → never committed → **absent in CI**, and the licensed deploy runs
  `godot --headless --import` on a fresh checkout that **regenerates them from defaults** (the
  textures are *extracted from the GLB* at import; empirically confirmed). So those edits are a
  **no-op on the deployed build**, and are unverifiable locally (the `verify.sh` export uses the
  CC0 dog). The mipmap half is also partly redundant — `process/fix_alpha_border=true` is
  **already set** (Godot's built-in zero-alpha-edge mipmap fix) and disabling mipmaps would
  trade a faint band for coat **shimmer**. Project-wide `[importer_defaults]` and un-ignoring
  the `.import` files were both considered and rejected (blunt / clobbered-by-extraction /
  unvalidatable against the fail-closed licensed-deploy contract). **The single robust fix is
  the owner re-export** — and while re-exporting, please ALSO: author/tag the **normal map**
  correctly, and **pad the albedo UV-island edges** so mipmap bleed is mooted at the source.
  That one action fixes everything 040 chased, at the source. This remains a P1-1/P1-9 *polish*
  gap, not a core-loop blocker — it does not change the P1-10 sign-off being the gate.
  (FYI: licensed-asset *import settings* are entirely uncommitted today — CI uses Godot
  defaults — so the only deterministic place to control them is the re-export itself.)

### FLAG 2026-06-29 — The warm *human* "Bra!" voice (and the Phase-5 praise words) is owner-gated
- **Source:** P1-6 mark payoff (`scripts/payoff_player.gd`); owner review 2026-06-29.
- **Decision needed:** Supply a real, warm, **human "Bra!"** recording (the "Maren" delivery) to
  drop in under the stable voice cue id — and later the Phase-5 praise words (*dyktig, flink,
  super, kjempebra*), each as its own voiced line.
- **Why it's user-only:** a specific person's warm voice is an asset the loop cannot synthesize
  or acquire — there is no technical fork to reason out. (X-7 keeps the game offline, so a
  cloud-voice substitute is out too.)
- **Assumption made to keep going:** the abstract sine-tone "blip" was not an honest attempt at
  a spoken word. Replaced it with a *genuinely spoken* one — an offline `espeak-ng` Norwegian
  **"Bra!"** (`assets/audio/bra_tts_placeholder.wav`), wired under the same cue id (task **035**).
  It is robotic and a clear placeholder; your recording replaces the file with **no code change**.
  Until then the spoken stand-in ships instead of a tone.

## Resolved

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
