# Process — autonomous build loop

These are the two prompts and the runner for *Bra!*'s headless "ralph" build loop.
As of the **v2** rebuild they are **live tooling for this repo** — the loop builds the
v2 game here, from scratch, against the spec in [`.docs/specs/`](../.docs/specs/). (They
originally drove the deprecated game in the sibling `bra` tree; that history is preserved
on the `deprecated-game` branch.)

- [mother_prompt.md](mother_prompt.md) — one **builder** iteration: read the
  `.task-board/`, replenish via `scan-project` when empty, run `start-working`, then
  pass the full verify gate (`nix develop -c bash verify.sh` — Godot import · boot ·
  test · export) before exiting.
- [father_prompt.md](father_prompt.md) — one **Product Owner** review pass: it resolves the
  **current phase** (the lowest `phaseN.md` not yet in the `## Phase Sign-off` list in
  `.docs/specs/po-review.md`), runs the real game (the deployed Godot Web/PWA build, driven
  in a headless browser on a 390×844 phone viewport), and play-tests *that phase*
  critically. It then either appends buildable directives under `## Product Owner Review`
  (the mother loop turns those into tasks next iteration) **or**, if the current phase is
  clean **and** no earlier signed-off phase has regressed (it replays them too), **signs it
  off** in the Phase Sign-off list — which is what advances the loop to the next phase.

- [analyst_prompt.md](analyst_prompt.md) — one **daily telemetry** pass (ADR-0007). Once per local
  calendar day the runner pulls anonymous PostHog stats + raw feedback via
  [`tools/telemetry_pull.mjs`](../tools/telemetry_pull.mjs) and, only if there's data, hands it to
  this pass, which files **Tier-1** tuning tasks (numeric, reversible) / **Tier-2** proposal flags
  (feature ideas, owner-gated — with an adaptive support threshold). It **no-ops until there are
  players** and never pastes raw feedback (possible PII) into the public board.

- [loop.sh](loop.sh) — the **external runner** itself: a Bash "ralph" loop that fires a
  fresh headless `claude -p` per iteration, alternating mother (build) and father (PO
  review every `FATHER_EVERY` iters or whenever a pass creates no new work), with
  per-invocation runaway guards (`ITER_TIMEOUT`, `--max-budget-usd`, `MAX_TURNS`, retries with
  backoff — there is **no cumulative spend cap**). The **done signal** is when the mother's scan
  finds no work AND the PO then play-tests and leaves `.docs/specs/po-review.md` byte-for-byte
  unchanged (the whole game is complete, or it is blocked purely on the owner); by default
  (`MAX_ITER=0`) the loop **exits on its own** on that signal (see **Auto-stop on no-work** below).

An external runner alternated the two passes (build → review → build …), each in a fresh
context with disk as the only shared memory.

## Running it (v2, in this repo)

`loop.sh` `cd`s to the repo root (its parent's parent) and drives the build from there:

```bash
cd /home/larsski/Code/braa && ./process/loop.sh        # unbounded; stops on no-work,
                                                        # a hard failure, or you
```

### Stopping it cleanly

Run it in the **foreground** of a terminal and press **`q`** to stop. The loop kills the
in-flight `claude` together with its **whole subagent/tool subtree** (godot, chromium,
`verify.sh`, …) and then exits — no orphaned processes left running. **Ctrl-C** (SIGINT)
and **SIGTERM** do the same thing.

Each `claude` invocation runs in its own session (`setsid`), so a single process-group
signal tears the entire tree down at once (a `pgrep` tree-walk sweeps up any stragglers).
A *backgrounded* run (`./process/loop.sh &`) can't read `q`, and bash makes background
scripts ignore SIGINT — stop a detached run with `kill -TERM <pid>` instead.

What's wired for v2:

- **Spec** — [`.docs/specs/`](../.docs/specs/) (phased user stories, one file per phase +
  `index.md` for the shared frame) is the source of truth; the PO log lives in
  `.docs/specs/po-review.md`. Everything that reads the spec (scan, the prompts,
  `spec_hash`) points at that directory.
- **Skills** — `scan-project` / `start-working` / `task-board` / `tdd` live in
  `.claude/skills/`. `scan-project` is tuned for a **from-scratch, phased** build: it
  scaffolds a runnable Godot project first, then works the **current phase** (the lowest
  `phaseN.md` not yet signed off), refusing to start later phases until the current one is
  **signed off** in `po-review.md`'s `## Phase Sign-off` list (the explicit PO gate — not
  merely code-complete). It emits **0–3** tasks per round; it returns **zero** only when the
  phase is built **and** passes scan's adversarial **construction audit** (the orchestrator's
  clearance — no dead seams, hollow tests, or faked assets), and that clean zero is what
  hands off to the father. A phase's permanent sign-off thus needs **two independent
  clearances**: the orchestrator's construction audit + the father's visual/regression
  review.
- **Father (PO) is deferred** — the play-test pass needs a reviewable app, so `loop.sh`
  skips it until `project.godot` exists (see `app_runnable`).
- **Auto-stop on no-work** — `MAX_ITER=0` (the default) runs until there's nothing left to do:
  the mother's `scan-project` returns zero on an empty board **and** the father then play-tests
  and leaves `.docs/specs/po-review.md` unchanged (true completion, or blocked purely on the
  owner). The loop then **exits on its own**. It also stops on a hard failure or when you press
  `q`. There is **no cumulative spend cap** — the per-invocation `--max-budget-usd`, `MAX_TURNS`,
  and `ITER_TIMEOUT` remain as single-iteration runaway guards.
- **Telemetry (daily analyst)** — needs `POSTHOG_API_KEY` + `POSTHOG_ID` (the personal read key +
  numeric project id) in a **gitignored `process/.env`** for the local pull; without them the pull
  returns `no_data` and the analyst skips. The raw pull lands in gitignored `.telemetry/` (feedback
  can contain PII — never committed). Disable the whole pass with `ANALYST_ENABLED=0`.

- **Flags** — the loop never blocks on a prompt. When it hits a genuinely **user-only**
  decision and the orchestrator agrees it's material, it appends a non-blocking note to
  [`.task-board/FLAGS.md`](../.task-board/FLAGS.md) and keeps building on its best
  assumption. That file rides the per-task commit/push, so open flags show up for you to
  resolve whenever you next check in.

> ⚠️ The loop runs `claude` with `--dangerously-skip-permissions`. Only run it in a
> sandbox / throwaway environment.
