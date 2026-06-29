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

### FLAG 2026-06-29 — Phase-1 buildable work is DONE; only owner/PO gates remain (construction clearance)
- **Source:** empty-backlog construction-audit gate (scan-project) after landing 034 + 035.
- **Decision needed:** Drive the **P1-10 Visual-Review sign-off** on the live build — and first
  confirm the **live site actually reflects the completed Phase-1 work**. `deploy-licensed.yml`
  auto-runs on every push to `main` (034/035 pushed), but it **no-ops unless** the
  `GODOT_SCRIPT_ENCRYPTION_KEY` secret and committed `assets/models/dog_licensed.glb.enc` are in
  place (ADR-0006 / task 025). If the deploy is no-opping, the public site still ships the CC0
  idle-only dog (no Sitt / reaction / payoff), so the PO would be reviewing a stale build.
- **Why it's user-only:** the loop can't see CI secrets or the live Pages site, can't run the
  PO play-test (a human visual judgement on the phone), and can't acquire/dispatch the owner's
  encryption key. Every remaining Phase-1 gate is an owner or PO action.
- **Assumption made to keep going:** treated the empty board as the construction clearance —
  all buildable Phase-1 directives (030–035) are landed, pushed, and pass a clean adversarial
  construction audit + green `verify.sh`. The loop now stands down on Phase-1 building and waits
  for the PO sign-off (it will NOT start Phase 2 until P1-10 is signed off in `po-review.md`).
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
