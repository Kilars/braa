# DIST: Capacitor store-wrap scaffolding

**Status**: Done
**Created**: 2026-06-14
**Priority**: Low
**Labels**: distribution, build, tooling
**Estimated Effort**: Medium

## Context & Motivation

tech-decisions §1: ship to iOS/Android by wrapping the PWA with **Capacitor**.
Scaffold Capacitor (config + scripts + docs) so the native wrap is ready. NOTE:
actually adding/building native platforms needs Android SDK / Xcode (NOT available
here) — so this task SCAFFOLDS only; it documents the `cap add` / `cap sync` /
build steps without running them.

## Affected Components
- Add: `@capacitor/core`, `@capacitor/cli` (devdep). (Do NOT install `@capacitor/android`/`ios` platform packages unless they install cleanly without SDKs — prefer documenting them.)
- Create: `capacitor.config.ts` (appId e.g. `app.bra.dogtraining`, appName "Bra!", `webDir: 'dist'`, a sensible `server`/`backgroundColor`)
- Modify: `package.json` (scripts like `cap:sync` → `cap sync`, and document `cap:add:android`/`cap:add:ios`)
- Create/append: a short "Building native apps" section in README.md (or a `.docs/native-build.md`) with the exact steps: `bun run build`, `npx cap add android`, `npx cap sync`, open in Android Studio / Xcode — and the prerequisite SDKs.
- Dependencies: 037 (PWA/dist); Blocking: none

## Approach
- `bun add -d @capacitor/core @capacitor/cli`. Run `npx cap init "Bra!" app.bra.dogtraining --web-dir dist` OR hand-author `capacitor.config.ts` (cleaner, avoids interactive prompts). 
- Do NOT run `cap add android/ios` (needs SDKs) — document it instead.
- Ensure the existing Vite build (`dist/`) is the `webDir`.
- Confirm nothing breaks: `bun run build` still emits `dist/`, the web app/PWA still works.

## Verification (honest — native build can't run here)
- `capacitor.config.ts` is valid TS (typecheck or a node import check) with `webDir: 'dist'`.
- `bun run build` still succeeds; `dist/` present; `bun run test`/`typecheck`/`e2e` still green.
- State clearly that native platform add/build is documented-only (no Android SDK/Xcode here).

## Progress Log
- 2026-06-14 — Task created (iteration 16)
- 2026-06-14 — Implemented: deps added, config authored, script added, docs created

## Resolution

**Deps added:** `@capacitor/core@8.4.0` and `@capacitor/cli@8.4.0` installed as
devDependencies via `bun add -d`. `@capacitor/android` and `@capacitor/ios` are
NOT installed — native platform add/build is documented-only (no Android SDK /
Xcode in this environment).

**`capacitor.config.ts`** (hand-authored at repo root):
```ts
import type { CapacitorConfig } from "@capacitor/cli";
const config: CapacitorConfig = {
  appId: "app.bra.dogtraining",
  appName: "Bra!",
  webDir: "dist",
  backgroundColor: "#7ec8f0",
};
export default config;
```
Type-checks with 0 errors (both `bun run typecheck` and `bunx tsc --noEmit` standalone).

**`package.json` script added:** `"cap:sync": "cap sync"`.

**Docs:** `.docs/native-build.md` created with full step-by-step native build
instructions (prerequisites, one-time `cap add`, iterative sync, IDE open).
README.md updated with a "Building native apps" section linking to it, plus
`cap:sync` row in the quick-start command table.

**Verification results:**
- `bun run typecheck` → 0 errors
- `bun run build` → success, `dist/` emitted (PWA + service worker intact)
- `bun run test` → 368 tests passing (23 files)
- `bun run e2e` → E2E SMOKE PASS
- Native platforms (android/ios): documented-only — no `cap add` run, no SDKs needed.

## Acceptance Criteria
- [x] `@capacitor/core` + `@capacitor/cli` added; `capacitor.config.ts` (appId/appName/webDir: dist) valid
- [x] `package.json` has a `cap:sync` (and documented add) script; README/native-build doc lists the exact native steps + SDK prerequisites
- [x] `bun run build` still emits dist; web/PWA unaffected
- [x] `bun run test` green; `bun run typecheck` 0; `bun run e2e` PASS
- [x] Resolution states native add/build is documented-only (no SDKs here)
