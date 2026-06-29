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

### FLAG 2026-06-29 — Phase-1 deploy reflectance + live P1-10 visual sign-off (owner/PO gates)
> **Corrected 2026-06-30** — the earlier "buildable work is DONE / construction-clearance"
> framing was **premature**: the PO's 2026-06-29 re-play of the live build (`po-review.md`)
> reopened the **P1-4 apex tell** (it rendered only under the `?bra_force_tell` seam and was
> invisible in real play) and surfaced three buildable Phase-1 improvements. P1-4 is now
> **re-fixed and landed (task 036)** — the live path was blanked by a null-Variant web-marshal
> collapsing `motion_scale` to 0; fixed + headless live-path regression test, but its **pixel
> sign-off is still a PO action on the deployed build**. Buildable Phase-1 work is therefore
> **not** fully cleared: the loop will pick up the PO's remaining improvements next
> (coat hairline-seams + stray sliver `P1-1/9`, apex ring occludes the "BRA" word `P1-4`,
> tier readout overlaps the dog's head `P1-7`).
- **Decision needed (owner/PO, unchanged):** confirm the **live site actually reflects the
  completed Phase-1 work**, then drive the **P1-10 Visual-Review sign-off** on it.
  `deploy-licensed.yml` auto-runs on every push to `main` but **no-ops unless** the
  `GODOT_SCRIPT_ENCRYPTION_KEY` secret and committed `assets/models/dog_licensed.glb.enc` are in
  place (ADR-0006 / task 025). If the deploy is no-opping, the public site still ships the CC0
  idle-only dog (no Sitt / reaction / payoff), so the PO would be reviewing a stale build — and
  the just-landed 036 live-tell fix would not be visible to verify.
- **Why it's user-only:** the loop can't see CI secrets or the live Pages site, can't run the
  PO play-test (a human visual judgement on the phone), and can't acquire/dispatch the owner's
  encryption key. The live pixel proof of the apex tell (a no-seam free-run burst with max gold
  > 0, or a `?bra_autotap=1` apex frame showing the ring) is a PO/owner action on the deployed
  build — the loop cannot build the licensed dog locally.
- **Assumption made to keep going:** landed the P1-4 live-path fix (036, verify green), corrected
  this flag, and will continue building the PO's remaining Phase-1 improvements rather than
  standing down. The loop will NOT start Phase 2 until P1-10 is signed off in `po-review.md`.
  Still pending alongside this: the on-device audio listen and the warm human voice (below).

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

_(none)_
