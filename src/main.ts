import './style.css'
import { createShell } from './app/shell'
import { createTrickSelection } from './app/trickSelector'
import { createMarkAudio } from './audio/markCue'
import { createScene } from './render/scene'
import { TRICKS, type TrickId } from './core/trick'

/**
 * Entry point. Mounts the shell, stands up the Babylon dog scene on the canvas,
 * and wires the one verb: a BRA tap scores against the live apex window (task
 * 002 via the scene), the apex-tell ring pulses on the honest scoring peak
 * (P1-4), and the tier readout reflects the tap. `window.__appReady` /
 * `window.__sceneReady` let e2e wait deterministically without sampling pixels.
 */

declare global {
  interface Window {
    __appReady?: boolean
    __sceneReady?: boolean
    /** Shared-clock start of the sit cycle — lets e2e target the apex exactly. */
    __braStartTime?: number
    /** Score a tap at an arbitrary clock time (deterministic wiring probe). */
    __braScoreAt?: (now: number) => string
    /** Current sit phase, for deterministic capture/poll (no pixel sampling). */
    __braPhase?: () => string
    /** Freeze the dog at a fixed sit amount (Visual-Review capture only). */
    __braPose?: (amount: number | null) => void
    /**
     * Freeze a reaction-peak frame: dog at sit `amount` with a mark reaction of
     * `strength` at its apex, or `null` to resume (Visual-Review capture only).
     */
    __braCaptureReactPeak?: (amount: number | null, strength?: number) => void
    /** The ids of the registry's tricks, for the selector + deterministic e2e. */
    __braTricks?: () => string[]
    /** Switch the active trick by id (Phase 2; throws on an unknown id). */
    __braSetTrick?: (id: string) => void
    /** The trick the dog is currently performing (deterministic e2e read). */
    __braActiveTrick?: () => string
  }
}

function start(): void {
  const root = document.getElementById('app')
  if (!root) throw new Error('Missing #app mount point')

  const shell = createShell(root)
  const { canvas, braButton, apexRing, tierReadout } = shell

  const reducedMotion = window.matchMedia?.(
    '(prefers-reduced-motion: reduce)',
  ).matches

  const scene = createScene(canvas, {
    reducedMotion,
    onApex: (proximity) => {
      // Drive the ring straight from the per-frame apex proximity (0..1).
      apexRing.style.setProperty('--apex', proximity.toFixed(3))
    },
  })

  // The payoff: a warm "Bra!" + crisp click on a successful mark (P1-6, X-3).
  // Unlock the AudioContext on the first gesture so the first BRA is audible.
  const audio = createMarkAudio()
  braButton.addEventListener('pointerdown', () => audio.unlock(), { once: true })

  let tierTimer: number | undefined
  braButton.addEventListener('pointerup', () => {
    const now = performance.now()
    // One scored tier drives every cue — audio, the dog's reaction, and the
    // on-screen readout — so they can never disagree (P1-6, P1-7).
    const tier = scene.scoreTapNow(now)
    audio.play(tier) // silent on Miss / dead tap
    scene.react(tier, now) // dog perks up on OK/PERFECT; a no-op otherwise
    // A dead tap (no window open) does nothing — no feedback (P1-5).
    if (tier === 'NONE') return
    tierReadout.textContent = tier
    tierReadout.dataset.tier = tier
    tierReadout.classList.remove('show')
    // Reflow so the animation restarts even on rapid repeat taps.
    void tierReadout.offsetWidth
    tierReadout.classList.add('show')
    window.clearTimeout(tierTimer)
    tierTimer = window.setTimeout(() => tierReadout.classList.remove('show'), 700)
  })

  // The trick chooser (P2-1): one source of truth for the active trick. A chip
  // tap selects; the selection then mirrors itself into BOTH the chip styling and
  // the scene, so the UI and the dog can never drift. This is a calm
  // between-attempts choice, wired to `pointerup` like any chip — never part of
  // the timed BRA tap path (X-2): selecting a trick is not a gameplay verb.
  const selection = createTrickSelection(TRICKS, 'sitt')
  shell.setActiveChip(selection.activeId)

  // Apply a switch at the next IDLE so the dog finishes its current trick instead
  // of snapping mid-build (the chip flips active immediately; the pose follows at
  // the next cycle start — no pose pop). `pending === null` means "nothing to
  // apply". The capture probe `__braSetTrick` stays immediate for Visual Review.
  let pending: TrickId | null = null
  const applyPendingTrick = () => {
    if (pending !== null && scene.stateAt(performance.now()).phase === 'IDLE') {
      scene.setTrick(pending)
      pending = null
    }
    requestAnimationFrame(applyPendingTrick)
  }
  requestAnimationFrame(applyPendingTrick)

  selection.onChange((id) => {
    shell.setActiveChip(id) // chooser responds instantly; never touches the tap path
    pending = id // scene swaps at the next idle (applyPendingTrick)
  })
  shell.trickChips.forEach((chip) =>
    chip.addEventListener('pointerup', () =>
      selection.select(chip.dataset.trickId as TrickId),
    ),
  )

  // Deterministic wiring probes for e2e (assert the apex/score plumbing without
  // sampling pixels). Cheap and side-effect-free in production.
  window.__braStartTime = scene.startTime
  window.__braScoreAt = (now) => scene.scoreTapNow(now)
  window.__braPhase = () => scene.stateAt(performance.now()).phase
  window.__braPose = (amount) => scene.setPose(amount)
  window.__braCaptureReactPeak = (amount, strength) =>
    scene.captureReactPeak(amount, strength)
  window.__braTricks = () => TRICKS.map((t) => t.id)
  window.__braSetTrick = (id) => scene.setTrick(id as TrickId)
  window.__braActiveTrick = () => scene.activeTrickId()

  window.__sceneReady = scene.ready
  window.__appReady = true
}

start()
