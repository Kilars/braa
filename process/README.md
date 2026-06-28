# Process — autonomous build loop

These are the two prompts and the runner for *Bra!*'s headless "ralph" build loop.
As of the **v2** rebuild they are **live tooling for this repo** — the loop builds the
v2 game here, from scratch, against [`specs2.md`](../specs2.md) at the repo root. (They
originally drove the deprecated game in the sibling `bra` tree; that history is preserved
on the `deprecated-game` branch.)

- [mother_prompt.md](mother_prompt.md) — one **builder** iteration: read the
  `.task-board/`, replenish via `scan-project` when empty, run `start-working`, then
  pass the full verify gate (`nix develop -c bash verify.sh` — Godot import · boot ·
  test · export) before exiting.
- [father_prompt.md](father_prompt.md) — one **Product Owner** review pass: run the real
  game (the deployed Godot Web/PWA build, driven in a headless browser on a 390×844 phone
  viewport), play it critically, and append buildable directives to `specs2.md` under
  `## Product Owner Review`. The mother loop turns those into tasks the next iteration.

- [loop.sh](loop.sh) — the **external runner** itself: a Bash "ralph" loop that fires a
  fresh headless `claude -p` per iteration, alternating mother (build) and father (PO
  review every `FATHER_EVERY` iters or whenever a pass creates no new work), with
  per-invocation and whole-run guards (`ITER_TIMEOUT`, `--max-budget-usd`,
  `TOTAL_BUDGET_USD`, retries with backoff). It stops only when the PO play-tests and
  leaves `specs2.md` byte-for-byte unchanged.

An external runner alternated the two passes (build → review → build …), each in a fresh
context with disk as the only shared memory.

## Running it (v2, in this repo)

`loop.sh` `cd`s to the repo root (its parent's parent) and drives the build from there:

```bash
cd /home/larsski/Code/braa && ./process/loop.sh        # unbounded; stops only on the
                                                        # budget cap or a hard failure
```

What's wired for v2:

- **Spec** — [`specs2.md`](../specs2.md) (phased user stories) at the repo root is the
  source of truth. Everything that reads the spec (scan, the prompts, `spec_hash`) points
  straight at it.
- **Skills** — `scan-project` / `start-working` / `task-board` / `tdd` live in
  `.claude/skills/`. `scan-project` is tuned for a **from-scratch, phased** build: it
  scaffolds a runnable Godot project first, then works the **current phase** (Phase 1),
  refusing to start later phases until the current one is complete.
- **Father (PO) is deferred** — the play-test pass needs a reviewable app, so `loop.sh`
  skips it until `project.godot` exists (see `app_runnable`).
- **No auto-stop** — `MAX_ITER=0` (the default) runs until `TOTAL_BUDGET_USD` or a hard
  failure. The old "stop when the game matches the spec" `break` is now just a log;
  re-add it in the father block if you want that behaviour back.

> ⚠️ The loop runs `claude` with `--dangerously-skip-permissions`. Only run it in a
> sandbox / throwaway environment.
