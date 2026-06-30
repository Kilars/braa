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
- **Assumption while building:** the warm **Piper local-neural** Norwegian "Bra!" now ships at
  `assets/audio/bra_tts_placeholder.wav` (task **044 landed 2026-06-30**, voice
  `no_NO-talesyntese-medium`), replacing the robotic espeak stand-in (task 035) under the same
  cue id with no code change. The Piper clip is drop-in replaced by your human Maren recording,
  also with no code change.

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
