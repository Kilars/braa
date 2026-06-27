import { test } from '@playwright/test'
import { mkdirSync } from 'node:fs'

// TEMPORARY capture harness for the task-003 Visual Review. Not a gate.
// `__braPose` freezes the whole cycle (dog pose AND apex tell) at the instant a
// given sit amount occurs, so each frame is EXACTLY the moment it claims — the
// ring is honest: dark through the build, peak only at the seated apex (no
// render-clock/screenshot-latency ambiguity, no manual --apex poking).
const DIR = '.screenshots'

test('capture dog scene for review', async ({ page }) => {
  // Generous headroom: this harness shoots 9 frames AND reloads once (to re-boot
  // the ~5 MB Babylon scene under emulated reduced motion). Under the parallel
  // workers that second cold Babylon parse can brush past the default 30 s and
  // flake the gate — give it room so the review capture stays reliably green.
  test.setTimeout(90_000)
  mkdirSync(DIR, { recursive: true })
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)
  console.log('SCENE_READY=' + (await page.evaluate(() => window.__sceneReady)))

  const frozen = async (amount: number, file: string) => {
    await page.evaluate((a) => window.__braPose?.(a), amount)
    await page.waitForTimeout(120) // let a couple of frames render the pose
    await page.screenshot({ path: `${DIR}/${file}.png` })
  }

  await frozen(0, '01-stand') // idle / standing — ring dark
  await frozen(0.5, '02-build') // mid sit — still far from the apex, ring dark
  await frozen(1, '03-apex') // fully seated apex — dog seated AND ring at peak

  // Build-silhouette frames (task 009 / PO Review I2): the continuous fold from
  // idle to the seated apex must read as ONE lowering, with no rearward
  // hindquarter lump mid-build. Frozen at the exact sit amounts the PO flagged so
  // the reviewer judges the in-between frames, not just the endpoints.
  for (const a of [0.3, 0.5, 0.65, 0.85]) {
    await frozen(a, `build-${Math.round(a * 100)}`)
  }

  // Reaction peak frames (task 005): the dog's happy perk-up at the apex of the
  // reaction, OK vs PERFECT — held stable on the peak regardless of screenshot
  // timing so the reviewer compares the two honestly.
  const reactPeak = async (strength: number, file: string) => {
    await page.evaluate((s) => window.__braCaptureReactPeak?.(1, s), strength)
    await page.waitForTimeout(120)
    await page.screenshot({ path: `${DIR}/${file}.png` })
  }
  await reactPeak(0.55, '04-react-ok') // OK reaction — a modest perk-up
  await reactPeak(1, '05-react-perfect') // PERFECT reaction — bigger hop + wag

  // Where the tier readout actually lands (P1-7) and how the three scored tiers
  // read against the dog/title. One source of truth (main.ts) means the readout,
  // the audio and the reaction always agree — so a *celebrated* tier (PERFECT/OK)
  // is captured with the dog perked up, while a MISS is captured seated-but-calm:
  // the readout is visible but the dog does NOT celebrate (P1-7, P1-5). The pop
  // animation is 700ms (full opacity ~140–490ms in), so settle 260ms before the
  // shot for an honest, fully-lit readout — not a mid-fade frame.
  const showReadout = async (
    tier: 'PERFECT' | 'OK' | 'MISS',
    celebrate: number | null,
    file: string,
  ) => {
    await page.evaluate(
      ({ tier, celebrate }) => {
        if (celebrate === null) window.__braPose?.(1) // seated, no reaction (MISS)
        else window.__braCaptureReactPeak?.(1, celebrate)
        const el = document.querySelector(
          '[data-testid="tier-readout"]',
        ) as HTMLElement | null
        if (el) {
          el.textContent = tier
          el.dataset.tier = tier
          // Pin the readout to its full-opacity *peak* state for the review. The
          // `.show` pop is a CSS opacity animation, and automated Chrome throttles
          // compositor animations off-screen — a timed screenshot lands mid-fade
          // and reads faint no matter how legible the styled text is. Forcing the
          // resting peak (opacity 1, no transform) captures the honest legibility
          // the player sees while the readout is up.
          el.classList.remove('show')
          el.style.animation = 'none'
          el.style.opacity = '1'
          el.style.transform = 'none'
        }
      },
      { tier, celebrate },
    )
    await page.waitForTimeout(160)
    await page.screenshot({ path: `${DIR}/${file}.png` })
  }
  await showReadout('PERFECT', 1, '06-readout-perfect')
  await showReadout('OK', 0.55, '07-readout-ok')
  await showReadout('MISS', null, '08-readout-miss') // visible, but not celebrated

  await page.evaluate(() => window.__braCaptureReactPeak?.(null)) // resume

  // Reduced motion (P1-8, X-5): every cue must stay distinguishable, just
  // dampened. Re-emulate `prefers-reduced-motion` and reload so the scene reads
  // it at boot, then hold the seated apex so the reviewer can confirm the dog,
  // the sit and the apex ring all still read with motion damped.
  await page.emulateMedia({ reducedMotion: 'reduce' })
  await page.reload()
  await page.waitForFunction(() => window.__appReady === true)
  await page.evaluate(() => window.__braPose?.(1))
  await page.waitForTimeout(120)
  await page.screenshot({ path: `${DIR}/09-reduced-motion-apex.png` })
  await page.emulateMedia({ reducedMotion: null })

  console.log('done')
})

// Ligg (lie-down) Visual-Review capture (task 013 / P2-2, P2-3). Switches the
// active trick to Ligg via the registry probe, then freezes the SAME honest
// pose+tell harness across the build into the down. The reviewer must see a long,
// low sphinx that reads unmistakably as *down*, clearly different from the sit,
// with the ring honest (dark through the build, lit only on the fully-down apex).
test('capture ligg scene for review', async ({ page }) => {
  test.setTimeout(90_000)
  mkdirSync(DIR, { recursive: true })
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)
  // Confirm the registry actually exposes Ligg before we capture it.
  const tricks = await page.evaluate(() => window.__braTricks?.())
  console.log('TRICKS=' + JSON.stringify(tricks))
  await page.evaluate(() => window.__braSetTrick?.('ligg'))

  const frozen = async (amount: number, file: string) => {
    await page.evaluate((a) => window.__braPose?.(a), amount)
    await page.waitForTimeout(120)
    await page.screenshot({ path: `${DIR}/${file}.png` })
  }

  await frozen(0, 'ligg-00-stand') // idle / standing — ring dark
  // The build amounts the task calls out: the lowering must read as ONE continuous
  // settle into the down, never a snap, with the ring dark until the apex.
  await frozen(0.3, 'ligg-build-30')
  await frozen(0.5, 'ligg-build-50')
  await frozen(0.7, 'ligg-build-70')
  await frozen(1, 'ligg-03-apex') // fully down — body long+low, forelegs forward, ring lit

  // Mark reaction on Ligg: the celebration must still feel good, OK vs PERFECT
  // distinguishable, paws/belly planted on the shadow (no float).
  const reactPeak = async (strength: number, file: string) => {
    await page.evaluate((s) => window.__braCaptureReactPeak?.(1, s), strength)
    await page.waitForTimeout(120)
    await page.screenshot({ path: `${DIR}/${file}.png` })
  }
  await reactPeak(0.55, 'ligg-04-react-ok')
  await reactPeak(1, 'ligg-05-react-perfect')
  await page.evaluate(() => window.__braCaptureReactPeak?.(null)) // resume

  // Reduced motion must still read as *down* by pose alone (P1-8 / X-5). Re-emulate
  // and reload, re-select Ligg, then hold the fully-down apex.
  await page.emulateMedia({ reducedMotion: 'reduce' })
  await page.reload()
  await page.waitForFunction(() => window.__appReady === true)
  await page.evaluate(() => window.__braSetTrick?.('ligg'))
  await page.evaluate(() => window.__braPose?.(1))
  await page.waitForTimeout(120)
  await page.screenshot({ path: `${DIR}/ligg-09-reduced-motion-apex.png` })
  await page.emulateMedia({ reducedMotion: null })

  console.log('done')
})

// Pick-a-trick selector Visual-Review capture (task 014 / P2-1, X-2). Holds the
// dog at a seated apex for a stable, attractive backdrop, then shoots the chip
// row in each active state. The reviewer must see a small, clear chooser (not a
// second BRA), an unmistakable active chip, and a row that sits well clear of the
// BRA button / apex ring / tier readout — thumb-reachable, one page, portrait.
test('capture trick selector for review', async ({ page }) => {
  test.setTimeout(90_000)
  mkdirSync(DIR, { recursive: true })
  await page.goto('/')
  await page.waitForFunction(() => window.__appReady === true)
  console.log('TRICKS=' + JSON.stringify(await page.evaluate(() => window.__braTricks?.())))

  // Freeze a seated apex so the dog reads as posed context behind the chooser.
  await page.evaluate(() => window.__braPose?.(1))
  await page.waitForTimeout(120)
  await page.screenshot({ path: `${DIR}/selector-01-sitt-active.png` })

  // Choose Ligg: the chip flips active immediately (the chooser's response), even
  // though the frozen capture clock holds the scene's swap until the next cycle.
  await page.getByTestId('trick-chip-ligg').dispatchEvent('pointerup')
  await page.waitForTimeout(120)
  await page.screenshot({ path: `${DIR}/selector-02-ligg-active.png` })

  await page.evaluate(() => window.__braPose?.(null)) // resume
  console.log('done')
})
