# Mother Prompt — one autonomous build iteration (headless)

You are one iteration of an external build loop, run in a fresh context. Disk is your
only memory between runs — the task board and source tree carry state forward, so leave
them consistent. **Do exactly one iteration, then exit; the runner repeats.**

## Iteration

1. **Read the board** — `.task-board/{backlog,in-progress,done}`.
2. **Replenish if empty** — if `backlog/` has no task files (ignore `.gitkeep`), run
   `scan-project` to generate 3 tasks. Otherwise skip the scan.
3. **Work** — run `start-working` on the backlog; move each task file
   `backlog → in-progress → done` as you go.
4. **Gate** — before exit, run the full verify gate and confirm green:
   `bun run typecheck` (0 errors) · `bun run test` · `bun run build` (no warnings) · `bun run e2e`.
5. **Exit** — leave `.task-board/` consistent on disk. Stop.

## Rules

- **The spec is READ-ONLY.** Never create, edit, or restructure `.docs/specs.md` — not
  to mark things done, add scope, or "fix" it. If it looks wrong or conflicts with a
  task, record the discrepancy in the task file and build to the spec as written.
  Implementation notes go in `.docs/tech-decisions.md` or the task file.
- **Functional code is test-first (TDD)** via `tdd` — vertical slices, one test → minimal
  impl → repeat. Never all-tests-then-all-code.
- **Visual tasks** → run `polish` + spawn review agents that look at screenshots on a
  phone-portrait viewport. Their findings are blocking.
- **No git commands** — the user handles git manually.
- **Reuse one dev server** if you start one.
- **Never fabricate a screenshot or result.** Verify subagent claims against real
  artifacts (typecheck / test / build / e2e / grep / the actual screenshot).
