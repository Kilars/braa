# Process — autonomous build loop

These are the two prompts that drove *Bra!*'s headless "ralph" build loop. They are
kept here for **provenance** — they document *how* the game was actually built — not as
live tooling for this docs repo.

- [mother_prompt.md](mother_prompt.md) — one **builder** iteration: read the
  `.task-board/`, replenish via `scan-project` when empty, run `start-working`, then
  pass the full verify gate (`typecheck` · `test` · `build` · `e2e`) before exiting.
- [father_prompt.md](father_prompt.md) — one **Product Owner** review pass: run the real
  game (`bun run dev` + `scripts/shoot.mjs` on a 390×844 phone viewport), play it
  critically, and append buildable directives to `specs.md` under `## Product Owner
  Review`. The mother loop turns those into tasks the next iteration.

- [loop.sh](loop.sh) — the **external runner** itself: a Bash "ralph" loop that fires a
  fresh headless `claude -p` per iteration, alternating mother (build) and father (PO
  review every `FATHER_EVERY` iters or whenever a pass creates no new work), with
  per-invocation and whole-run guards (`ITER_TIMEOUT`, `--max-budget-usd`,
  `TOTAL_BUDGET_USD`, retries with backoff). It stops only when the PO play-tests and
  leaves `specs.md` byte-for-byte unchanged.

An external runner alternated the two passes (build → review → build …), each in a fresh
context with disk as the only shared memory.

## These target the deprecated game, not this repo

Every path in the prompts and in `loop.sh` — `.task-board/`, `.docs/specs.md`,
`scripts/shoot.mjs`, `bun run dev`, the `mother_prompt.md` / `father_prompt.md` the runner
`cat`s from the repo root — refers to the original game repo, **not** this docs-only repo.
`loop.sh` will not do anything useful here: it `cd`s to its parent's parent and expects the
game tree (task board, scripts, the v1 `specs.md` these prompts read and write). That tree
lives on the
[`deprecated-game`](https://github.com/Kilars/braa/tree/deprecated-game) branch and in
the local `bra` working copy. Run these against that tree, not against the files here.
