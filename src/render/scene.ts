import {
  ArcRotateCamera,
  Color3,
  DirectionalLight,
  Engine,
  HemisphericLight,
  Scene,
  Vector3,
} from '@babylonjs/core'
import { scoreTap, type MarkTier } from '../core/mark'
import { reactionAt, REACTION_PEAK_MS } from '../core/reaction'
import { sitStateAt, SIT_TIMINGS, type SitState, type SitTimings } from '../core/sitCycle'
import { getTrick, type TrickId } from '../core/trick'
import { NORMAL_TUNING } from '../core/tuning'
import { windowAtApex } from '../core/window'
import { setupBackdrop } from './backdrop'
import { createBlobShadow, createDog } from './dog'

/**
 * The Phase-1 render layer entry point: it stands up a Babylon engine on the
 * canvas the shell left in place, builds the bright backdrop + the dog + its
 * blob shadow, and runs the render loop. Every frame it reads the pure sit
 * cycle (`sitStateAt`) to pose the dog and to fire the honest apex tell exactly
 * on the scoring peak (spec P1-3, P1-4) — the same `apexTime` the BRA tap scores
 * against (`scoreTapNow` → task 002's `scoreTap`), so the tell and the score can
 * never disagree.
 *
 * WebGL is treated as optional: if the engine cannot start (e.g. a headless
 * environment with no GPU), the scene degrades to a `ready: false` handle that
 * still scores taps off the shared clock, so the app boots and the BRA verb
 * stays wired (the e2e gate asserts readiness flags, not pixels).
 */

export interface SceneOptions {
  /** Dampen ambient/idle motion without removing any state cue (P1-8, X-5). */
  reducedMotion?: boolean
  /**
   * Per-frame apex-tell signal in [0,1]: 0 = nothing to mark, 1 = exactly on the
   * scoring peak. Non-zero only inside the PERFECT band around the apex, so the
   * UI's tell is honest and never fires on empty air (P1-4).
   */
  onApex?: (proximity: number) => void
}

export interface SceneHandle {
  /** Whether a live WebGL scene is actually rendering. */
  readonly ready: boolean
  /** Score a BRA tap right now against the active sit window (task 002). */
  scoreTapNow(now: number): MarkTier
  /**
   * Switch which trick the dog performs (Phase 2). The pose, scoring window, and
   * apex tell all follow the active trick's cadence on its next cycle. Throws on
   * an unknown id (via `getTrick`) so the scene never silently mis-poses.
   */
  setTrick(id: TrickId): void
  /** The id of the trick the dog is currently performing (the active cadence/pose). */
  activeTrickId(): TrickId
  /**
   * Trigger the dog's happy reaction for a scored tap at `now` (P1-6). A no-op
   * for MISS / NONE — there is nothing to celebrate. PERFECT reacts bigger than
   * OK; the perk-up eases back to rest on its own.
   */
  react(tier: MarkTier, now: number): void
  /** The dog's sit state at `now` (for tests / capture; no pixel sampling). */
  stateAt(now: number): SitState
  /**
   * Freeze the whole sit cycle — dog pose *and* apex tell — at the instant that
   * sit amount in [0,1] occurs (0 = standing, 1 = the seated apex), or pass
   * `null` to resume the live cycle. For deterministic Visual-Review capture
   * only — not used in play.
   */
  setPose(amount: number | null): void
  /**
   * Freeze a deterministic Visual-Review frame at a reaction's peak: the dog
   * held at sit `amount` in [0,1] with a mark reaction of `strength` in [0,1] at
   * its apex, or `null` to resume the live loop. Capture-only — not used in play.
   */
  captureReactPeak(amount: number | null, strength?: number): void
  /** The sit cycle's start instant on the shared clock (ms). */
  readonly startTime: number
  dispose(): void
}

/**
 * Map a capture sit amount in [0,1] to an instant on the shared clock by
 * scrubbing cycle 0's BUILD phase: 0 = the start of the build (standing), 1 =
 * the apex (fully seated). Freezing the render clock here drives *both* the dog
 * pose and the apex tell from one instant, so a captured frame is honest — the
 * ring peaks only when the dog is actually seated at the apex, never at random
 * against the live loop.
 */
export function poseFreezeTime(
  amount: number,
  startTime: number,
  timings: SitTimings = SIT_TIMINGS,
): number {
  const a = Math.max(0, Math.min(1, amount))
  return startTime + timings.idleMs + a * timings.buildMs
}

export function createScene(
  canvas: HTMLCanvasElement,
  options: SceneOptions = {},
): SceneHandle {
  const startTime = performance.now()
  const reducedMotion = options.reducedMotion ?? false

  // The trick the dog is currently performing (Phase 2). Sitt by default — its
  // cadence is byte-identical to Phase 1. `setTrick` swaps this; the pose, the
  // scoring window, and the apex tell all read its timings, so they can never
  // disagree about which trick is active.
  let activeTrick = getTrick('sitt')

  const activeWindowAt = (now: number) => {
    const st = sitStateAt(startTime, now, activeTrick.timings)
    // A tap during IDLE has nothing to mark → no window (scoreTap → NONE).
    return st.phase === 'IDLE' ? null : windowAtApex(st.apexTime)
  }

  const scoreTapNow = (now: number): MarkTier => scoreTap(activeWindowAt(now), now)
  const stateAt = (now: number): SitState =>
    sitStateAt(startTime, now, activeTrick.timings)

  let engine: Engine | null = null
  try {
    engine = new Engine(canvas, true, { preserveDrawingBuffer: false, stencil: false })
  } catch {
    engine = null
  }

  if (!engine) {
    // No GPU: stay wired (scoring works), but render nothing.
    return {
      ready: false,
      scoreTapNow,
      setTrick(id) {
        activeTrick = getTrick(id)
      },
      activeTrickId: () => activeTrick.id,
      react() {},
      stateAt,
      setPose() {},
      captureReactPeak() {},
      startTime,
      dispose() {},
    }
  }

  const scene = new Scene(engine)

  // Framed for portrait: a 3/4 view (off the dog's front-right) so the sit reads
  // as a sit — haunches dropping, chest rising — instead of foreshortening away
  // head-on (P1-3). Dog centred and fully in frame (P1-1, X-1).
  const camera = new ArcRotateCamera(
    'cam',
    Math.PI / 2 + 0.7, // swung around toward the dog's side
    1.12, // elevated, looking down enough to read the seated base
    7.4,
    new Vector3(0, 0.7, 0),
    scene,
  )
  camera.fov = 0.78
  camera.minZ = 0.1

  const hemi = new HemisphericLight('hemi', new Vector3(0, 1, 0.2), scene)
  hemi.intensity = 0.85
  hemi.groundColor = new Color3(0.5, 0.55, 0.4)

  const key = new DirectionalLight('key', new Vector3(-0.4, -0.8, 0.5), scene)
  key.intensity = 0.95
  key.diffuse = new Color3(1, 0.97, 0.9)

  setupBackdrop(scene)
  const blobShadow = createBlobShadow(scene)
  const blobShadowBase = blobShadow.scaling.x
  const dog = createDog(scene)

  // Hold neutral until assembled, then fade in — never a primitive flash (P1-1).
  let revealed = false
  // A frozen shared-clock instant for deterministic Visual-Review capture, or
  // null in play. Freezing the *clock* (not just the pose) keeps the dog and the
  // apex tell on one timeline, so a captured frame can never show a build pose
  // under a peak ring (or a seated apex under a dark ring).
  let frozenNow: number | null = null

  // The active mark reaction (P1-6): when it last fired and how strong (PERFECT
  // reads bigger than OK). `reactionAt` turns these into a per-frame perk-up that
  // eases back to rest on its own, so no explicit "end" bookkeeping is needed.
  let reactStart: number | null = null
  let reactStrength = 0
  const react = (tier: MarkTier, now: number): void => {
    // Only a successful mark earns a reaction — nothing to celebrate otherwise.
    if (tier !== 'OK' && tier !== 'PERFECT') return
    reactStart = now
    reactStrength = tier === 'PERFECT' ? 1 : 0.55
  }

  engine.runRenderLoop(() => {
    const now = frozenNow ?? performance.now()
    const st = sitStateAt(startTime, now, activeTrick.timings)
    const reaction = reactionAt(reactStart, now, reactStrength)
    // The active trick's poseKind selects the kinematics; the build axis
    // (st.sitAmount, 0→1) and cadence already follow activeTrick.timings, so the
    // pose, the scoring window, and the apex tell never disagree about the trick.
    dog.pose(st.sitAmount, now, reducedMotion, activeTrick.poseKind, reaction)
    // Grow the contact shadow a touch with the perk-up so the dog stays visually
    // anchored as it bobs — the shadow tracks the energy instead of sitting still
    // under a risen body (Visual-Review fix for the float read, D12).
    const shadowScale = blobShadowBase * (1 + reaction.bounce * 0.14)
    blobShadow.scaling.x = shadowScale
    // A lie-down lays a long footprint reaching forward of center (the forelegs
    // extend out front); stretch the contact shadow along the body and slide it
    // forward so those paws rest ON the shadow instead of hovering off its front
    // edge (D12). Scaled by the build amount so it morphs with the pose, and zero
    // for the sit — the sit's round shadow stays exactly as shipped.
    const lieAmt = activeTrick.poseKind === 'liedown' ? st.sitAmount : 0
    blobShadow.scaling.y = shadowScale * (1 + lieAmt * 0.7)
    blobShadow.position.z = lieAmt * 0.4

    if (!revealed) {
      dog.reveal()
      revealed = true
    }

    // Apex tell: brightest exactly on the scoring peak, ramping across the
    // scoring window's half-width so it reads as "now" without lying about
    // where the peak is (P1-4). Silent during idle — nothing to mark.
    if (options.onApex) {
      const halfWindow = NORMAL_TUNING.windowWidthMs / 2
      const dist = Math.abs(now - st.apexTime)
      const proximity = Math.max(0, 1 - dist / halfWindow)
      options.onApex(st.phase === 'IDLE' ? 0 : proximity)
    }

    scene.render()
  })

  const onResize = () => engine?.resize()
  window.addEventListener('resize', onResize)

  return {
    ready: true,
    scoreTapNow,
    setTrick(id) {
      activeTrick = getTrick(id)
    },
    activeTrickId: () => activeTrick.id,
    react,
    stateAt,
    setPose(amount) {
      frozenNow =
        amount === null ? null : poseFreezeTime(amount, startTime, activeTrick.timings)
    },
    captureReactPeak(amount, strength = 1) {
      if (amount === null) {
        frozenNow = null
        reactStart = null
        reactStrength = 0
        return
      }
      // Freeze the clock at the seated instant and place the reaction so this
      // frozen frame lands exactly on the perk-up's peak — a stable frame for the
      // reviewer no matter when the screenshot is taken.
      frozenNow = poseFreezeTime(amount, startTime, activeTrick.timings)
      reactStart = frozenNow - REACTION_PEAK_MS
      reactStrength = strength
    },
    startTime,
    dispose() {
      window.removeEventListener('resize', onResize)
      scene.dispose()
      engine?.dispose()
    },
  }
}
