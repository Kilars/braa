/**
 * The app shell: a portrait scene with a `<canvas>` (the 3D dog surface) under a
 * DOM overlay. The overlay holds the one *gameplay* verb — the big BRA marker
 * (X-2) with its apex-tell ring (P1-4) and tier readout (P1-7) — plus, from
 * Phase 2, a small trick selector (P2-1). The selector is a calm between-attempts
 * chooser, deliberately kept clear of the marker so it never competes with the
 * BRA tap for the timing moment (X-2). Rendering and scoring wire into these
 * handles from `main.ts`.
 */

import { TRICKS, type TrickId } from '../core/trick'

export interface Shell {
  root: HTMLElement
  canvas: HTMLCanvasElement
  braButton: HTMLButtonElement
  /** The ring around the marker that pulses on the apex (driven per frame). */
  apexRing: HTMLElement
  /** Brief PERFECT / OK / MISS readout shown on a scored tap. */
  tierReadout: HTMLElement
  /** The trick chooser row (P2-1); one chip per registry trick. */
  trickBar: HTMLElement
  /** The per-trick chips, in registry order; each carries `dataset.trickId`. */
  trickChips: HTMLButtonElement[]
  /** Reflect the active trick on the chips (sole styling path; no timing impact). */
  setActiveChip(id: TrickId): void
}

export function createShell(root: HTMLElement): Shell {
  root.innerHTML = ''
  root.classList.add('app-shell')

  const canvas = document.createElement('canvas')
  canvas.className = 'scene-canvas'
  canvas.dataset.testid = 'scene-canvas'

  const overlay = document.createElement('div')
  overlay.className = 'ui-overlay'

  const title = document.createElement('h1')
  title.className = 'title'
  title.textContent = 'Bra!'

  const tierReadout = document.createElement('div')
  tierReadout.className = 'tier-readout'
  tierReadout.dataset.testid = 'tier-readout'
  tierReadout.setAttribute('aria-live', 'polite')

  const marker = document.createElement('div')
  marker.className = 'marker'

  const apexRing = document.createElement('div')
  apexRing.className = 'apex-ring'
  apexRing.dataset.testid = 'apex-ring'
  apexRing.setAttribute('aria-hidden', 'true')

  const braButton = document.createElement('button')
  braButton.type = 'button'
  braButton.className = 'bra-button'
  braButton.dataset.testid = 'bra-button'
  braButton.textContent = 'BRA'
  braButton.setAttribute('aria-label', 'Marker — BRA')

  // The trick chooser (P2-1): a single horizontal chip row of the registry's
  // tricks, labelled in Norwegian. A radiogroup, not a toolbar — exactly one
  // trick is active at a time, so each chip is an `aria-pressed` toggle the
  // player picks between. It renders ABOVE the marker group (see `.bottom-stack`)
  // so it stays thumb-reachable yet never overlaps the BRA button, the apex ring,
  // or the tier readout — it is not a second thing to time (X-2, P1-7).
  const trickBar = document.createElement('div')
  trickBar.className = 'trick-bar'
  trickBar.dataset.testid = 'trick-bar'
  trickBar.setAttribute('role', 'group')
  trickBar.setAttribute('aria-label', 'Velg triks')

  const trickChips = TRICKS.map((trick) => {
    const chip = document.createElement('button')
    chip.type = 'button'
    chip.className = 'trick-chip'
    chip.dataset.testid = `trick-chip-${trick.id}`
    chip.dataset.trickId = trick.id
    chip.textContent = trick.label
    chip.setAttribute('aria-pressed', 'false')
    return chip
  })
  trickBar.append(...trickChips)

  const setActiveChip = (id: TrickId): void => {
    for (const chip of trickChips) {
      const active = chip.dataset.trickId === id
      chip.classList.toggle('is-active', active)
      chip.setAttribute('aria-pressed', String(active))
    }
  }

  // Keep the tap feedback with the verb, just above the BRA button — where the
  // player's eye and thumb already are at the tap — so it lands clear of the dog
  // instead of printing across the dog's mid-body (P1-7: feedback the player
  // actually sees, without obscuring the reaction it celebrates).
  const markerGroup = document.createElement('div')
  markerGroup.className = 'marker-group'

  marker.append(apexRing, braButton)
  markerGroup.append(tierReadout, marker)

  // Anchor the chooser and the verb together at the bottom, stacked: the chooser
  // sits a clear gap above the readout so the two never overlap (X-2). The dog
  // keeps the centre of the frame.
  const bottomStack = document.createElement('div')
  bottomStack.className = 'bottom-stack'
  bottomStack.append(trickBar, markerGroup)

  overlay.append(title, bottomStack)
  root.append(canvas, overlay)

  return {
    root,
    canvas,
    braButton,
    apexRing,
    tierReadout,
    trickBar,
    trickChips,
    setActiveChip,
  }
}
