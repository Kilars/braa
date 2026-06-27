import { describe, expect, it } from 'vitest'
import { TRICKS, type TrickId } from '../core/trick'
import { createTrickSelection } from './trickSelector'

/**
 * The pick-a-trick selection state (P2-1): the ONE source of truth for which
 * trick is active. It is pure and DOM-free so the wiring in `main.ts` (chips →
 * scene) can never drift — the chip styling and `scene.setTrick` both read this
 * model. X-2 guardrail: choosing a trick is a between-attempts decision, not a
 * second gameplay verb, so this model only tracks "which trick", nothing timed.
 */
describe('trick selection state', () => {
  it('starts on the initial trick and lists the registry', () => {
    const sel = createTrickSelection(TRICKS, 'sitt')
    expect(sel.activeId).toBe('sitt')
    expect(sel.list.map((t) => t.id)).toContain('ligg')
  })

  it('select changes the active trick and fires onChange once', () => {
    const sel = createTrickSelection(TRICKS, 'sitt')
    let fired: string | null = null
    let count = 0
    sel.onChange((id) => {
      fired = id
      count++
    })
    expect(sel.select('ligg')).toBe(true)
    expect(sel.activeId).toBe('ligg')
    expect(fired).toBe('ligg')
    expect(count).toBe(1)
  })

  it('re-selecting the active trick is a no-op (no spurious onChange)', () => {
    const sel = createTrickSelection(TRICKS, 'sitt')
    let count = 0
    sel.onChange(() => count++)
    expect(sel.select('sitt')).toBe(false)
    expect(count).toBe(0)
  })

  it('notifies every subscriber on a change', () => {
    const sel = createTrickSelection(TRICKS, 'sitt')
    const seen: string[] = []
    sel.onChange((id) => seen.push(`a:${id}`))
    sel.onChange((id) => seen.push(`b:${id}`))
    sel.select('ligg')
    expect(seen).toEqual(['a:ligg', 'b:ligg'])
  })

  it('throws on an unknown id rather than silently selecting nothing', () => {
    const sel = createTrickSelection(TRICKS, 'sitt')
    expect(() => sel.select('nope' as TrickId)).toThrow()
    // The active trick is unchanged after a rejected select.
    expect(sel.activeId).toBe('sitt')
  })

  it('throws when constructed with an initial id not in the list', () => {
    expect(() => createTrickSelection(TRICKS, 'nope' as TrickId)).toThrow()
  })
})
