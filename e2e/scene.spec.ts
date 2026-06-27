import { expect, test } from '@playwright/test'

// The sit cycle's Phase-1 cadence (src/core/sitCycle.ts SIT_TIMINGS). The first
// apex — the fully-seated instant of cycle 0 — lands idle+build after start.
const IDLE_MS = 1600
const BUILD_MS = 700
const APEX_OFFSET = IDLE_MS + BUILD_MS // 2300ms after startTime

test('dog scene boots and wires the apex window to the BRA score', async ({ page }) => {
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)

  // The scene reports a definite readiness state (tolerant of headless no-GPU):
  // either way the verb must stay wired. (Task 003: assert flags, not pixels.)
  const sceneReady = await page.evaluate(() => window.__sceneReady)
  expect(typeof sceneReady).toBe('boolean')

  // The apex-tell ring is mounted on the marker (the honest "now" cue, P1-4).
  await expect(page.getByTestId('apex-ring')).toBeAttached()

  // The render layer exposes the shared-clock start, so we can target the apex.
  const start = await page.evaluate(() => window.__braStartTime)
  expect(typeof start).toBe('number')

  const tierAt = (now: number) =>
    page.evaluate((t) => window.__braScoreAt?.(t), now)

  // A tap exactly on the apex scores PERFECT — the tell marks the real peak.
  expect(await tierAt((start as number) + APEX_OFFSET)).toBe('PERFECT')

  // A tap during idle has no window to mark → does nothing (NONE).
  expect(await tierAt((start as number) + 500)).toBe('NONE')

  // A tap during an active sit but well outside the window → MISS (no penalty).
  expect(await tierAt((start as number) + APEX_OFFSET + 320)).toBe('MISS')
})
