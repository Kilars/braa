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

- [loop.sh](loop.sh) — the **external runner** itself: a Bash "ralph" loop that fires a
  fresh headless `claude -p` per iteration, alternating mother (build) and father (PO
  review every `FATHER_EVERY` iters or whenever a pass creates no new work), with
  per-invocation and whole-run guards (`ITER_TIMEOUT`, `--max-budget-usd`,
  `TOTAL_BUDGET_USD`, retries with backoff). The **done signal** is when *every* phase is
  signed off and the PO play-tests and leaves `.docs/specs/po-review.md` byte-for-byte
  unchanged; by default (`MAX_ITER=0`) the loop only logs that and keeps running until the
  budget cap or a hard failure (see **No auto-stop** below).

An external runner alternated the two passes (build → review → build …), each in a fresh
context with disk as the only shared memory.

## Running it (v2, in this repo)

`loop.sh` `cd`s to the repo root (its parent's parent) and drives the build from there:

```bash
cd /home/larsski/Code/braa && ./process/loop.sh        # unbounded; stops only on the
                                                        # budget cap, a hard failure, or you
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
- **No auto-stop** — `MAX_ITER=0` (the default) runs until `TOTAL_BUDGET_USD` or a hard
  failure. The old "stop when the game matches the spec" `break` is now just a log;
  re-add it in the father block if you want that behaviour back.
- **Flags** — the loop never blocks on a prompt. When it hits a genuinely **user-only**
  decision and the orchestrator agrees it's material, it appends a non-blocking note to
  [`.task-board/FLAGS.md`](../.task-board/FLAGS.md) and keeps building on its best
  assumption. That file rides the per-task commit/push, so open flags show up for you to
  resolve whenever you next check in.

> ⚠️ The loop runs `claude` with `--dangerously-skip-permissions`. Only run it in a
> sandbox / throwaway environment.
