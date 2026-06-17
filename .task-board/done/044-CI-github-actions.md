# CI: GitHub Actions workflow (typecheck + test + build)

**Status**: Backlog
**Created**: 2026-06-14
**Priority**: Low
**Labels**: ci, tooling
**Estimated Effort**: Simple

## Context & Motivation

No CI. Add a GitHub Actions workflow that runs the quality gates on push/PR so
regressions are caught automatically (if/when the repo is pushed to GitHub).

## Affected Components
- Create: `.github/workflows/ci.yml`
- Dependencies: none; Blocking: none

## Approach
- Workflow `name: CI`, `on: [push, pull_request]`, one `build` job on `ubuntu-latest`:
  - `actions/checkout@v4`
  - `oven-sh/setup-bun@v2` (pin a version)
  - `bun install --frozen-lockfile` (or `bun install`)
  - `bun run typecheck`
  - `bun run test`
  - `bun run build`
- OPTIONAL second job (or steps) for e2e — only if reliable: install Playwright chromium (`bunx playwright install --with-deps chromium`), start `bun run dev &`, wait for the port, set `PW_CHROME` to the installed browser, run `bun run e2e`. If this is fiddly/uncertain in CI, OMIT e2e from CI and note it (don't add a flaky job).
- Use the EXACT script names from package.json.

## Verification (honest — GitHub Actions can't run locally)
- The YAML is valid (parse it: `bunx js-yaml .github/workflows/ci.yml` or a node `yaml`/`JSON` check, or at minimum a careful read — flag that it can't be executed here).
- Every `bun run <script>` referenced exists in package.json.
- State clearly in Resolution that the workflow is authored but unverified-in-CI (needs a GitHub remote + a push to actually run).

## Progress Log
- 2026-06-14 — Task created (iteration 15)

## Resolution
_(added when complete)_

## Acceptance Criteria
- [ ] `.github/workflows/ci.yml` runs checkout → setup-bun → install → typecheck → test → build on push/PR
- [ ] Script names match package.json exactly; YAML parses without error
- [ ] e2e either included reliably or explicitly omitted-with-reason (no flaky CI job)
- [ ] Resolution notes it's unverified-in-CI (no remote run available here)
- [ ] No app code changed; `bun run test` still green
