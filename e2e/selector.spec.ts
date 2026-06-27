import { expect, test } from '@playwright/test'

/**
 * Pick-a-trick selector (task 014 / P2-1). The chooser is the player-facing
 * driver for the trick registry (012) and the real second trick (013): a chip
 * tap must select a trick, flip the active chip, and swap the trick the dog
 * actually performs — without ever becoming a second gameplay verb (X-2). We
 * assert the deterministic DOM + scene wiring; the chip *look* is the Visual
 * Review. `__braActiveTrick` reads the scene's live performed trick (no pixels).
 */
test("the selector switches the dog's performed trick (Sitt ↔ Ligg)", async ({
  page,
}) => {
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)

  const sitt = page.getByTestId('trick-chip-sitt')
  const ligg = page.getByTestId('trick-chip-ligg')
  await expect(sitt).toBeVisible()
  await expect(ligg).toBeVisible()
  await expect(sitt).toHaveText('Sitt')
  await expect(ligg).toHaveText('Ligg')

  // Starts on Sitt: the active chip and the scene agree (one source of truth).
  await expect(sitt).toHaveAttribute('aria-pressed', 'true')
  await expect(ligg).toHaveAttribute('aria-pressed', 'false')
  expect(await page.evaluate(() => window.__braActiveTrick?.())).toBe('sitt')

  // Choosing Ligg flips the active chip immediately (a calm chooser response),
  // and swaps the performed trick by the next cycle (applied at idle, no pop).
  await ligg.dispatchEvent('pointerup')
  await expect(ligg).toHaveAttribute('aria-pressed', 'true')
  await expect(sitt).toHaveAttribute('aria-pressed', 'false')
  await page.waitForFunction(() => window.__braActiveTrick?.() === 'ligg')

  // And back to Sitt — the swap is reversible and stays in sync both ways.
  await sitt.dispatchEvent('pointerup')
  await expect(sitt).toHaveAttribute('aria-pressed', 'true')
  await page.waitForFunction(() => window.__braActiveTrick?.() === 'sitt')
})

test('the chooser never overlaps the BRA button or its apex ring (X-2)', async ({
  page,
}) => {
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)

  const bar = await page.getByTestId('trick-bar').boundingBox()
  const bra = await page.getByTestId('bra-button').boundingBox()
  const ring = await page.getByTestId('apex-ring').boundingBox()
  const readout = await page.getByTestId('tier-readout').boundingBox()
  expect(bar).toBeTruthy()
  expect(bra).toBeTruthy()

  // The whole chip row sits above the BRA button — it is not part of the timing
  // hit area, so a thumb reaching for a chip can't graze the verb (X-2, P1-7).
  expect(bar!.y + bar!.height).toBeLessThanOrEqual(bra!.y)
  if (ring) expect(bar!.y + bar!.height).toBeLessThanOrEqual(ring.y + 1)
  if (readout) expect(bar!.y + bar!.height).toBeLessThanOrEqual(readout.y + 1)

  // And it stays within the portrait viewport (one page, no off-screen chips).
  expect(bar!.x).toBeGreaterThanOrEqual(0)
  expect(bar!.x + bar!.width).toBeLessThanOrEqual(390)
})
