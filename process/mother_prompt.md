# Mother Prompt — one autonomous build iteration (headless)

You are one iteration of an external build loop, run in a fresh context. Disk is your
only memory between runs — the task board and source tree carry state forward, so leave
them consistent. **Do exactly one iteration, then exit; the runner repeats.**

## Iteration

1. **Read the board** — `.task-board/{backlog,in-progress,done}`.
2. **Replenish if empty** — if `backlog/` has no task files (ignore `.gitkeep`), run
   `scan-project` to generate 3 tasks. It finds gaps between `.docs/specs.md` (including
   the **Product Owner Review** notes the PO/father pass appends there) and the
   implementation. Otherwise skip the scan.
3. **Work** — run `start-working` on the backlog; move each task file
   `backlog → in-progress → done` as you go.
4. **Gate** — before exit, run the full verify gate and confirm green:
   `bun run typecheck` (0 errors) · `bun run test` · `bun run build` (no warnings) · `bun run e2e`.
5. **Exit** — leave `.task-board/` consistent on disk. Stop.

## Rules

- **The spec is READ-ONLY for you.** Never create, edit, or restructure `.docs/specs.md`
  — not to mark things done, add scope, or "fix" it. Only the **PO/father** review pass
  writes to specs; you read it and build to it. If it looks wrong or conflicts with a
  task, record the discrepancy in the task file and build to the spec as written.
  Implementation notes go in `.docs/tech-decisions.md` or the task file.
- **Don't block features — retry first.** Premature/false blocks are the single biggest
  source of lost progress here. Before you ever mark a task `blocked`/`on-hold` for a
  *technical* reason, try **2–3 genuinely different approaches** and record the exact
  command + real error for each. "Tool not on PATH" ≠ impossible — check npm / WASM /
  prebuilt-binary routes first. Only escalate a block that survives multiple real
  attempts. Genuine **owner / legal / asset** gates are real, but name precisely what's
  missing and keep every other part of the work moving around it.
- **Functional code is test-first (TDD)** via `tdd` — vertical slices, one test → minimal
  impl → repeat. Never all-tests-then-all-code.
- **Visual tasks** → run `polish` + spawn review agents that look at screenshots on a
  phone-portrait viewport. Their findings are blocking.
- **No git commands** — the user handles git manually.
- **Reuse one dev server** if you start one.
- **Never fabricate a screenshot or result.** Verify subagent claims against real
  artifacts (typecheck / test / build / e2e / grep / the actual screenshot).
