/**
 * Pick-a-trick selection state (P2-1) — the single source of truth for which
 * trick the player is training. Pure and DOM-free on purpose: the shell's chip
 * styling and the scene's `setTrick` both read this one model, so the UI and the
 * dog can never disagree about the active trick (the X-2 "one verb" guardrail
 * means the chooser lives apart from the timed BRA tap; this is just state).
 *
 * Depends only on the trick registry types — no Babylon, no DOM — so it stays
 * trivially unit-testable (`trickSelector.test.ts`).
 */

import type { TrickDef, TrickId } from '../core/trick'

export interface TrickSelection {
  /** The tricks offered, in registry order (what the chip row renders). */
  readonly list: readonly TrickDef[]
  /** The currently-active trick id. */
  readonly activeId: TrickId
  /** Select a trick by id; returns true iff the active trick changed. */
  select(id: TrickId): boolean
  /** Subscribe to active-trick changes (the shell re-styles chips, the scene swaps). */
  onChange(fn: (id: TrickId) => void): void
}

export function createTrickSelection(
  list: readonly TrickDef[],
  initialId: TrickId,
): TrickSelection {
  const has = (id: TrickId) => list.some((t) => t.id === id)
  if (!has(initialId)) {
    // Never start pointed at a trick the registry doesn't have — that would let
    // the chips and the scene drift from frame one.
    throw new Error(`Unknown initial trick: ${initialId}`)
  }

  let activeId = initialId
  const listeners: Array<(id: TrickId) => void> = []

  return {
    list,
    get activeId() {
      return activeId
    },
    select(id) {
      if (!has(id)) throw new Error(`Unknown trick: ${id}`)
      if (id === activeId) return false // no-op re-select: no spurious notify
      activeId = id
      for (const fn of listeners) fn(id)
      return true
    },
    onChange(fn) {
      listeners.push(fn)
    },
  }
}
