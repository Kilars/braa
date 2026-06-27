import { expect, test } from '@playwright/test'

/**
 * Phase-1 close-out (task 006): the whole loop is wired end to end. A *real* BRA
 * tap during a sit must land an on-screen tier on `pointerup` (P1-7), driven by
 * the same scored tier as the audio + the dog reaction (one source of truth in
 * `main.ts`, so they cannot disagree). The loop must keep working across cycles
 * without degrading (P1-9). Audio can't be asserted headless; the "feels good"
 * judgement is the Visual Review. Here we assert the deterministic DOM wiring.
 */
test('a real BRA tap during a sit shows a tier readout, and the loop repeats', async ({
  page,
}) => {
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)

  const button = page.getByTestId('bra-button')
  const readout = page.getByTestId('tier-readout')

  const tapDuringSit = async () => {
    // Tap on the seated apex plateau (HOLD): a window is open, so the scored
    // tier is always PERFECT/OK/MISS — never a dead NONE — and the readout fires.
    await page.waitForFunction(() => window.__braPhase?.() === 'HOLD')
    await button.dispatchEvent('pointerup')
    await expect(readout).toHaveAttribute('data-tier', /^(PERFECT|OK|MISS)$/)
    await expect(readout).toHaveText(/^(PERFECT|OK|MISS)$/)
  }

  await tapDuringSit()

  // Prove the loop repeats (P1-9): let it return to idle, then mark the next sit.
  await page.waitForFunction(() => window.__braPhase?.() === 'IDLE')
  await tapDuringSit()
})
