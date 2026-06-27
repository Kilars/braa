import {
  Color3,
  Mesh,
  MeshBuilder,
  StandardMaterial,
  TransformNode,
  Vector3,
  type Scene,
} from '@babylonjs/core'
import type { ReactionState } from '../core/reaction'
import type { PoseKind } from '../core/trick'

/**
 * A composed, clearly-recognizable dog — head, ears, snout, body, four legs,
 * tail — built from rounded primitives assembled into a real silhouette (spec
 * P1-1: reads immediately as a dog; never a *bare* primitive standing in for the
 * dog). Warm Labrador colouring, the breed the licensed pack will later drop in
 * behind this same contract (tech-decisions §3h).
 *
 * It exposes one pose verb, `pose(buildAmount, now, reducedMotion, poseKind)`,
 * driven by the pure cycle timing (`src/core/sitCycle.ts`): `buildAmount` 0 =
 * standing/idle, 1 = the fully-built apex. `poseKind` selects which trick the
 * one build axis drives (Phase 2, task 013):
 *   - `'sit'` lowers the haunches and lifts the chest about the shoulder so it
 *     reads unmistakably as a *sit* — front legs planted, hind legs folding.
 *   - `'liedown'` lowers the whole body long and low, slides the forelegs forward
 *     onto the ground and tucks the hind legs, so it reads unmistakably as
 *     *down* (a sphinx), clearly different from a deep sit (P2-2).
 * Either way: no foot-slide, no T-pose, no snap (P1-2, P1-3). Ambient idle motion
 * (breathing, tail sway, head bob) layers on top so the dog never looks frozen;
 * under reduced motion it is dampened, never removed (P1-8).
 */

const STAND_Y = 1.02 // shoulder/hip height when standing
const FRONT_Z = 0.5 // front legs / shoulder pivot z (dog faces +z, the camera)
const SIT_ANGLE = -0.8 // rad; negative tilts the rear down, chest/head up

// --- Ligg (lie-down) kinematics. The same 0→1 build axis as the sit, but it
// drives a long, low *down* (a sphinx), not a folded-upright sit. The body
// drops close to the ground, the forelegs slide forward to lie on it, and the
// hind legs tuck flat — so the silhouette reads horizontal and long, never the
// vertical proud-front of a sit (P2-2: clearly different from sit). Tuned for
// legibility on a phone; the Visual Review is the gate. ---
const LIE_BODY_DROP = 0.6 // how far the body/front lowers toward the ground at the apex
const LIE_BODY_TILT = 0.05 // rad; a touch of nose-down rest, otherwise level (not a sit's rear-down)
const LIE_FRONT_REACH = -1.32 // rad; rotate the forelegs forward to extend onto the ground
const LIE_HIND_FOLD = 1.2 // rad; swing the hind legs back+down to rest on the ground (sub-90°, not folded up)
const LIE_HEAD_PITCH = -0.06 // keep the sphinx head alert/level (counters the slight body tilt)
const GOLD = new Color3(0.86, 0.66, 0.34)
const GOLD_DARK = new Color3(0.7, 0.52, 0.26)
const DARK = new Color3(0.08, 0.07, 0.06)

/** No active reaction — the dog rests (used every frame outside a mark). */
const NO_REACTION: ReactionState = { bounce: 0, wag: 0, pop: 0 }

/** Resting forward tilt of the floppy ears; a mark perks them up from here. */
const EAR_REST_X = 0.15

export interface Dog {
  /**
   * Pose the dog for a build amount in [0,1] at wall-clock `now` (ms). `poseKind`
   * selects which trick the build axis drives (`'sit'` by default — Phase-1 feel).
   * An optional `reaction` (from `reactionAt`) layers a happy perk-up on top after
   * a successful mark (P1-6); omit it for the resting loop.
   */
  pose(
    buildAmount: number,
    now: number,
    reducedMotion: boolean,
    poseKind?: PoseKind,
    reaction?: ReactionState,
  ): void
  /** Fade the dog in once the model is assembled (P1-1: no flash on load). */
  reveal(): void
  /** Current world-x, so the blob shadow can track it (always ~0 in Phase 1). */
  readonly x: number
  readonly root: TransformNode
}

function mat(scene: Scene, name: string, color: Color3): StandardMaterial {
  const m = new StandardMaterial(name, scene)
  m.diffuseColor = color
  m.specularColor = new Color3(0.04, 0.04, 0.04) // matte, no plastic highlight
  m.emissiveColor = color.scale(0.12) // gentle fill so it never reads black
  return m
}

export function createDog(scene: Scene): Dog {
  const gold = mat(scene, 'dogGold', GOLD)
  const goldDark = mat(scene, 'dogGoldDark', GOLD_DARK)
  const dark = mat(scene, 'dogDark', DARK)

  const root = new TransformNode('dog', scene)

  // Everything that pivots into the sit hangs off the shoulder.
  const shoulder = new TransformNode('dogShoulder', scene)
  shoulder.parent = root
  shoulder.position.set(0, STAND_Y, FRONT_Z)

  const parts: Mesh[] = []
  const add = (m: Mesh, parent: TransformNode, material: StandardMaterial) => {
    m.parent = parent
    m.material = material
    m.isPickable = false
    m.visibility = 0 // revealed together after assembly (no primitive flash)
    parts.push(m)
    return m
  }

  // --- Body: rounded forms only — soft barrel + chest + a distinct rump — so
  // the rear resolves into a haunch, never a hard angular slab. ---
  const torso = MeshBuilder.CreateSphere(
    'torso',
    { diameter: 0.8, segments: 14 },
    scene,
  )
  torso.scaling.set(0.92, 0.86, 1.78) // stretched into a barrel along the spine
  torso.position.set(0, 0.0, -0.5)
  add(torso, shoulder, gold)

  // Chest fill so the front reads broad where the neck meets the body.
  const chest = MeshBuilder.CreateSphere(
    'chest',
    { diameter: 0.82, segments: 12 },
    scene,
  )
  chest.position.set(0, 0.0, 0.18)
  chest.scaling.set(1, 1.02, 0.92)
  add(chest, shoulder, gold)

  // Rump: a rounded rear end over the hind legs. Seated flush into the torso
  // line (not perched above it) so the body reads as one form, not two balloons.
  const rump = MeshBuilder.CreateSphere(
    'rump',
    { diameter: 0.78, segments: 12 },
    scene,
  )
  rump.position.set(0, -0.02, -1.0)
  rump.scaling.set(1.0, 0.98, 0.98)
  add(rump, shoulder, gold)

  // Neck: a gold column bridging the chest up to the head so the head never
  // reads as detached — especially in the seated up-tilt where it lifts away.
  const neck = MeshBuilder.CreateSphere('neck', { diameter: 0.42, segments: 12 }, scene)
  neck.scaling.set(0.92, 1.3, 0.92)
  neck.position.set(0, 0.24, 0.34)
  neck.rotation.x = -0.5 // lean forward, following chest → head
  add(neck, shoulder, gold)

  // --- Head group at the front, lifted above the shoulder. ---
  const head = new TransformNode('headGroup', scene)
  head.parent = shoulder
  head.position.set(0, 0.46, 0.44)

  const skull = MeshBuilder.CreateSphere(
    'skull',
    { diameter: 0.62, segments: 12 },
    scene,
  )
  skull.scaling.set(1, 0.96, 1.05)
  add(skull, head, gold)

  // Muzzle: a rounded form, not a hard-edged box — an open box face read as a
  // dark cavity/hole at the apex up-tilt. Longer than wide so it reads as a snout.
  const snout = MeshBuilder.CreateSphere('snout', { diameter: 0.32, segments: 12 }, scene)
  snout.scaling.set(0.76, 0.72, 1.3)
  snout.position.set(0, -0.12, 0.42)
  add(snout, head, goldDark)

  // Nose: a small pad on the top-front of the muzzle. Kept small and raised so
  // it never presents as a big black disc (a "third eye"/void) when tilted up.
  const nose = MeshBuilder.CreateSphere('nose', { diameter: 0.11, segments: 8 }, scene)
  nose.position.set(0, -0.09, 0.6)
  add(nose, head, dark)

  // Floppy Labrador ears — soft, flattened drops down the sides of the skull
  // (rounded, never a hard box that reads as a cube edge-on at the apex tilt).
  const earMeshes: Mesh[] = []
  for (const side of [-1, 1] as const) {
    const ear = MeshBuilder.CreateSphere(
      `ear${side}`,
      { diameter: 0.26, segments: 10 },
      scene,
    )
    ear.scaling.set(0.5, 1.35, 0.85) // thin and long — a hanging ear
    ear.position.set(side * 0.26, 0.0, -0.05)
    ear.rotation.set(EAR_REST_X, 0, side * 0.42)
    add(ear, head, goldDark)
    earMeshes.push(ear)
  }

  // Eyes — seated high on the skull and set apart, clear of the muzzle so they
  // never merge with the snout edge or read mismatched from a 3/4 angle.
  for (const side of [-1, 1] as const) {
    const eye = MeshBuilder.CreateSphere(
      `eye${side}`,
      { diameter: 0.09, segments: 8 },
      scene,
    )
    eye.position.set(side * 0.18, 0.08, 0.23)
    add(eye, head, dark)
  }

  // --- Tail at the rear, sweeping up and back. ---
  const tail = MeshBuilder.CreateCylinder(
    'tail',
    { height: 0.62, diameterTop: 0.06, diameterBottom: 0.16, tessellation: 8 },
    scene,
  )
  const tailPivot = new TransformNode('tailPivot', scene)
  tailPivot.parent = shoulder
  tailPivot.position.set(0, 0.18, -1.28)
  tail.parent = tailPivot
  tail.position.set(0, 0.26, 0)
  tail.rotation.set(-0.9, 0, 0)
  tail.material = goldDark
  tail.isPickable = false
  tail.visibility = 0
  parts.push(tail)

  // --- Legs. Front legs stay planted (children of root); hind legs fold. ---
  const leg = (
    name: string,
    parent: TransformNode,
    x: number,
    z: number,
    material: StandardMaterial,
  ) => {
    const l = MeshBuilder.CreateCylinder(
      name,
      { height: STAND_Y, diameterTop: 0.2, diameterBottom: 0.22, tessellation: 10 },
      scene,
    )
    // Pivot at the top of the leg so folding/standing rotates from the hip.
    l.setPivotPoint(new Vector3(0, STAND_Y / 2, 0))
    l.position.set(x, -STAND_Y / 2, z)
    add(l, parent, material)
    // A paw so the foot reads as a foot, not a pipe. Parent it to the LEG (not the
    // legs node) and place it at the leg's local bottom, so it rides the leg as the
    // hind legs fold into the sit. (Previously the paw hung off the legs node and
    // stayed at the standing spot, so a folding hind leg left its paw behind as a
    // floating disconnected blob mid-build — a Visual-Review blocker against
    // P1-3/P1-9.) Front legs never fold, so their paws simply sit at the foot.
    const paw = MeshBuilder.CreateSphere(`${name}Paw`, { diameter: 0.24, segments: 8 }, scene)
    paw.position.set(0, -STAND_Y / 2 + 0.06, 0.04)
    add(paw, l, goldDark)
    return { leg: l, paw }
  }

  const frontLegs = new TransformNode('frontLegs', scene)
  frontLegs.parent = root
  frontLegs.position.set(0, STAND_Y, FRONT_Z)
  // Captured so the lie-down can swing the forelegs forward onto the ground; the
  // sit never touches them (planted), so it resets them to these standing values.
  const { leg: frontL } = leg('frontLegL', frontLegs, -0.24, 0, gold)
  const { leg: frontR } = leg('frontLegR', frontLegs, 0.24, 0, gold)

  const hindLegs = new TransformNode('hindLegs', scene)
  hindLegs.parent = shoulder
  hindLegs.position.set(0, 0, -1.05) // hip, level with the shoulder when standing
  const { leg: hindL, paw: hindPawL } = leg('hindLegL', hindLegs, -0.26, 0, gold)
  const { leg: hindR, paw: hindPawR } = leg('hindLegR', hindLegs, 0.26, 0, gold)

  // Tail sway, breathing and head bob all hang off these base rotations.
  const tailBaseX = tail.rotation.x

  const dog: Dog = {
    root,
    x: 0,
    reveal() {
      for (const p of parts) p.visibility = 1
    },
    pose(buildAmount, now, reducedMotion, poseKind = 'sit', reaction = NO_REACTION) {
      const a = Math.max(0, Math.min(1, buildAmount))

      // The branch bakes pose-specific values the shared block below layers onto:
      // the head pitch (idle bob + mark chin-lift ride on it), and how the tail
      // sits and wags. Sit looks proud-up with its shipped up-swept wag; the down
      // trails the tail back along the ground with a gentler wag so a big mark
      // swing never reads as a detached stick over the low body.
      let headPosePitch: number
      let tailPitch: number
      let wagScale: number

      if (poseKind === 'liedown') {
        // === Ligg (lie-down): a long, low sphinx. The whole body drops toward
        // the ground and stays roughly level — NOT the sit's rear-down fold — the
        // forelegs swing forward onto the ground and the hind legs tuck flat, so
        // the silhouette reads horizontal and unmistakably *down*, never a deep
        // sit (P2-2). One 0→1 build axis, same as the sit. ===
        shoulder.rotation.x = a * LIE_BODY_TILT
        shoulder.position.y = STAND_Y - a * LIE_BODY_DROP

        // Forelegs slide forward to lie on the ground; the front of the rig lowers
        // with the chest (same drop) so the legs stay attached as the body settles
        // — no foot-slide, no detached pillars under a lowered chest.
        frontLegs.position.y = STAND_Y - a * LIE_BODY_DROP
        frontL.rotation.x = a * LIE_FRONT_REACH
        frontR.rotation.x = a * LIE_FRONT_REACH

        // Hind legs extend back-and-down to REST on the ground behind the lying
        // body (a relaxed "sploot"), not folded up past horizontal — a >90° tuck
        // (the sit's move, where the haunch is raised) would swing the paws UP off
        // the ground here and read as floating blobs at the low rear. A sub-90°
        // fold angles the leg down so the paw lands on the shadow; kept fairly
        // long so it actually reaches the ground from the lowered hip.
        const fold = a * LIE_HIND_FOLD
        hindL.rotation.x = fold
        hindR.rotation.x = fold
        const hindScale = 1 - a * 0.3
        hindL.scaling.y = hindScale
        hindR.scaling.y = hindScale
        hindPawL.scaling.y = 1 / hindScale
        hindPawR.scaling.y = 1 / hindScale

        // Rump settles to the ground at its base form — the body drop already put
        // the rear down, so the sit's mid-build hump (which would balloon the low
        // rear) is intentionally absent here.
        rump.position.z = -1.0
        rump.position.y = -0.02
        rump.scaling.z = 0.98

        headPosePitch = a * LIE_HEAD_PITCH
        // Lay the tail back near-horizontal so it trails behind the lying body
        // (a resting down), and damp the wag swing so even a PERFECT flurry stays
        // tucked against the rump instead of swinging up into a detached stick.
        tailPitch = tailBaseX - a * 0.85
        wagScale = 1 - a * 0.55
      } else {
        // === Sitt: the Phase-1 sit kinematics, byte-identical (every transform
        // below is the shipped sit). Front legs stay planted — reset them in case
        // the previous frame was a lie-down that had swung them forward. ===
        const s = a
        frontLegs.position.y = STAND_Y
        frontL.rotation.x = 0
        frontR.rotation.x = 0

        // Sit: rotate the rear down about the shoulder while the chest lifts a
        // touch — the spine slopes up from the seated haunches to a proud front.
        shoulder.rotation.x = s * SIT_ANGLE
        shoulder.position.y = STAND_Y + s * 0.06

        // Fold the hind legs flat under the haunches as the hip drops, so they
        // read as tucked thighs on the ground, not splayed pipes.
        const fold = s * 1.55
        hindL.rotation.x = fold
        hindR.rotation.x = fold
        const hindScale = 1 - s * 0.5
        hindL.scaling.y = hindScale
        hindR.scaling.y = hindScale
        // The paws ride the folding legs (they are children of the leg), so the foot
        // stays at the end of the leg — but countering the leg's vertical squish keeps
        // the paw round instead of flattening it into a disc as the thigh shortens.
        hindPawL.scaling.y = 1 / hindScale
        hindPawR.scaling.y = 1 / hindScale

        // Tuck the hindquarter through the build so the lowering reads as ONE
        // continuous fold instead of ballooning rearward mid-build (PO Review I2,
        // P1-3). The corrective is a hump that vanishes at BOTH ends — idle (s=0)
        // and the already-clean seated apex (s=1) are untouched — and peaks across
        // the lumpy 0.5–0.65 band, drawing the rump mass forward+down and shrinking
        // its rearward bulge so the haunch folds *with* the hip instead of jutting
        // back like a rearing pose. (Driving the rump linearly with s — as the task
        // sketch did — would have shifted the apex off its clean values; the hump
        // keeps the apex byte-identical, which is the PO's explicit constraint.)
        const tuck = s * (1 - s) // 0 at both ends, max 0.25 at s=0.5
        rump.position.z = -1.0 + tuck * 0.72 // forward (+z); back to -1.0 at the apex
        rump.position.y = -0.02 - tuck * 0.3 // settle down; back to -0.02 at the apex
        rump.scaling.z = 0.98 - tuck * 0.5 // pull the rearward bulge in; back to 0.98 at apex

        headPosePitch = s * 0.3
        tailPitch = tailBaseX // shipped up-swept tail
        wagScale = 1 // shipped wag amplitude (sit stays byte-identical)
      }

      // === Shared ambient life + mark reaction (both poses). Dampened, not
      // removed, under reduced motion (P1-8), so the trick still reads by pose
      // alone. The `a`-keyed terms collapse to the shipped sit values when
      // poseKind is 'sit' (a === s), keeping the sit byte-identical. ===
      const amp = reducedMotion ? 0.25 : 1
      const t = now / 1000
      // Grounded squash-and-settle on a successful mark (PO Review I1): the chest
      // puffs proud while the torso compresses a touch — pure scaling, so the
      // planted paws never lift off the contact shadow (D12).
      const pop = reaction.pop * amp
      // Breathing: a small vertical swell on the torso/chest.
      const breathe = 1 + Math.sin(t * 2.2) * 0.02 * amp
      torso.scaling.y = breathe * (1 - pop * 0.1)
      chest.scaling.y = 1.05 * breathe * (1 + pop * 0.26)
      // Head: a calm idle bob (damped as the build completes) over the pose's own
      // pitch — proud-up for the sit, level for the down.
      head.rotation.x =
        0.12 + Math.sin(t * 1.7) * 0.05 * amp * (1 - 0.6 * a) + headPosePitch
      // Tail sway, livelier the more the dog is engaged in the trick. A successful
      // mark wags it harder (reaction.wag) and faster on top of the idle sway.
      const wagAmp = 0.12 + 0.18 * a + reaction.wag * 1.15 * amp
      const wagRate = 3.4 + reaction.wag * 11 // a quick, happy flurry on a mark
      tail.rotation.z = Math.sin(t * wagRate) * wagAmp * amp * wagScale
      tail.rotation.x = tailPitch

      // Reaction (P1-6 / PO Review I1): a *grounded* celebration that reads as
      // joy on its own — the squash-and-settle above plus a crisp chin + ear
      // lift, NOT a raised rig, so the planted paws never separate from the
      // contact shadow (D12). PERFECT (strength 1) pops distinctly harder than OK.
      root.position.y = 0 // no float — paws stay glued to the shadow
      head.rotation.x -= reaction.bounce * 0.72 * amp // crisper chin lift
      for (const ear of earMeshes) ear.rotation.x = EAR_REST_X - pop * 0.75 // ears perk up
    },
  }

  return dog
}

/**
 * The blob shadow (tech-decisions §2): a flat, soft, semi-transparent disc just
 * above the ground that anchors the dog so it never floats (spec P1-1, D12). No
 * shadow map, no per-frame GPU cost beyond one unlit disc.
 */
export function createBlobShadow(scene: Scene): Mesh {
  const disc = MeshBuilder.CreateDisc('blobShadow', { radius: 0.95, tessellation: 32 }, scene)
  disc.rotation.x = Math.PI / 2
  disc.position.y = 0.012
  disc.isPickable = false

  const m = new StandardMaterial('blobShadowMat', scene)
  m.diffuseColor = new Color3(0, 0, 0)
  m.emissiveColor = new Color3(0, 0, 0)
  m.specularColor = new Color3(0, 0, 0)
  m.disableLighting = true
  m.alpha = 0.26
  disc.material = m
  return disc
}
