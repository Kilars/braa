/**
 * importedDogMesh.ts — DogMesh implementation backed by a loaded glTF/glb model.
 *
 * Wraps the output of `loadDogModel()` (task 078) in the exact same `DogMesh`
 * interface as `createDogMesh`, so every call-site in scene.ts (applyPose,
 * setTint, updateShadowX, setAppearance, etc.) works identically regardless of
 * which implementation is active.
 *
 * Architecture:
 *   - We parent all loaded meshes under a single root TransformNode.
 *   - We compute the model's actual bounding box and scale+recenter it so the
 *     imported dog occupies the same frame as the procedural dog (height ≈ 1.2,
 *     feet at root-local y ≈ -0.6). This is derived from the real bounds, not
 *     hard-coded constants, so it works for any glb geometry.
 *   - Whole-body pose channels (bounce, crouch, roll, yaw, breathe) are always
 *     live — they map onto the root node which always exists.
 *   - Per-part channels (headTilt, headLift, tailWag, bodyLean) are mapped onto
 *     skeleton bones IF the skeleton exposes identifiable head/neck/tail/spine
 *     bones (searched case-insensitively) AND no skeletal clip is currently
 *     playing. When a state's AnimationGroup is active it owns the bones (gross
 *     body motion); the procedural per-part channels only drive the bones as a
 *     fallback when no clip matches the state (task 080).
 *   - Materials (PBR from glTF or Standard from older loaders) are collected
 *     at build time. setTint/setEmissive/resetToBreedCoats override them all.
 *     Original materials are cloned and restored by resetToBreedCoats.
 *   - The blob contact shadow disc is created exactly as in createDogMesh:
 *     NOT parented to root, stays flat on the ground (y=0.01) while the dog
 *     bounces.
 *
 * Dev override for Visual Review: load the app with ?importedDog=1 in DEV mode
 * to force the imported path on without touching renderConfig.importedDog.
 * (See dogModelLoader.ts for the flag and scene.ts for the override hook.)
 *
 * Pose channels — live vs deferred:
 *   LIVE (whole-body, mapped on root):
 *     bounceY, crouchY, bodyRollZ, bodyYaw, breatheScaleY
 *   LIVE (if matching bones found AND no skeletal clip active — see task 080):
 *     headTiltZ (head/neck bone Z), headLiftY (head bone Y), headPitch (head bone X),
 *     headYaw (head bone Y), tailWagAngle (tail bone Z), bodyLeanX (spine bone Z)
 *   When a state clip plays, the clip owns the bones and these are skipped.
 *
 * Skeletal clips (task 080): the loaded AnimationGroups are retained and the clip
 * matching the current visual state is played via setVisualState (pure mapping in
 * dogAnimationMap.ts). The constant camera-facing yaw lives on a dedicated facing
 * pivot so the spin trick (root.rotation.y) composes on top of it.
 */

import { TransformNode } from '@babylonjs/core/Meshes/transformNode';
import { MeshBuilder } from '@babylonjs/core/Meshes/meshBuilder';
import { StandardMaterial } from '@babylonjs/core/Materials/standardMaterial';
import { PBRMaterial } from '@babylonjs/core/Materials/PBR/pbrMaterial';
import { Color3 } from '@babylonjs/core/Maths/math.color';
import { Vector3, Quaternion } from '@babylonjs/core/Maths/math.vector';
import type { Scene } from '@babylonjs/core/scene';
import type { Node } from '@babylonjs/core/node';
import type { Bone } from '@babylonjs/core/Bones/bone';
import type { AnimationGroup } from '@babylonjs/core/Animations/animationGroup';
import type { DogMesh } from './dogMesh';
import type { DogPose } from './dogPose';
import type { DogVisual } from './dogState';
import type { DogAppearance } from './dogAppearance';
import type { DogModelResult } from './dogModelLoader';
import { resolveStateClip, clipMotionScale, clipLoops } from './dogAnimationMap';

// ── Pure mapping helpers (exported for unit tests) ──────────────────────────

/**
 * Compute the uniform scale and pre-scale translation offset needed to make a
 * model with the given axis-aligned bounding box occupy `targetHeight` in scene
 * units, with feet at root-local y = -targetHeight/2 and centred on x/z = 0.
 *
 * Both `min` and `max` are in model-local space (before any transform is applied).
 *
 * The offset is in MODEL space (applied before scaling). That is, after the root
 * TransformNode is given:
 *   root.scaling.setAll(scale)
 *   root.position = new Vector3(offset.x * scale, offset.y * scale, offset.z * scale)
 *   ... but usually easier to move the mesh children:
 *   each child.position.addInPlace(offset)
 *
 * In practice we use a pivot TransformNode: attach all meshes to a pivot whose
 * position is `offset` in local space, then scale the parent root. The net result
 * is that the lowest point of the hierarchy lands at -targetHeight/2 in root-local
 * space (matching the procedural dog's feet at y ≈ -0.55 from its root).
 *
 * @param min          bbox minimum corner (model space)
 * @param max          bbox maximum corner (model space)
 * @param targetHeight desired height in root-local units after scaling
 * @returns { scale, offset } — apply offset to mesh before scaling root
 */
export function fitTransform(
  min: { x: number; y: number; z: number },
  max: { x: number; y: number; z: number },
  targetHeight: number,
): { scale: number; offset: { x: number; y: number; z: number } } {
  const height = max.y - min.y;

  // Uniform scale so the model's height equals targetHeight
  const scale = targetHeight / height;

  // Horizontal centroid — shift model so its x/z centre is at 0
  const centroidX = (min.x + max.x) / 2;
  const centroidZ = (min.z + max.z) / 2;

  // Y offset: after applying, the scaled foot (min.y + offset.y) * scale
  // should equal -targetHeight/2.
  // (min.y + offset.y) * scale = -targetHeight/2
  // offset.y = -targetHeight/2/scale - min.y = -height/2 - min.y
  const offsetY = -(height / 2) - min.y;

  return {
    scale,
    offset: {
      x: -centroidX,
      y: offsetY,
      z: -centroidZ,
    },
  };
}

/**
 * The head bone's target local Y for a given head-lift: the captured bind-pose Y
 * plus the pose's lift. A pure SET (bind-relative), never an accumulating `+=`.
 *
 * The procedural dog assigns from a fixed rest offset
 * (`headPivot.position.y = 0.28 + pose.headLiftY`); this mirrors that so the
 * imported rig's head doesn't drift upward when `applyPose` runs every frame.
 *
 * @param bindY    the head bone's captured bind-pose local Y
 * @param headLiftY the per-frame perk-up offset from the pose
 */
export function headBoneY(bindY: number, headLiftY: number): number {
  return bindY + headLiftY;
}

/**
 * Case-insensitive substring bone search.
 *
 * Searches `bones` for the first entry whose `.name` contains `keyword`
 * as a case-insensitive substring. Returns `null` when no match is found.
 * Used to locate head/neck/tail/spine bones generically without hard-coding
 * rig-specific names (since the bone names of the CC0 placeholder and the
 * licensed Labrador differ).
 *
 * @param bones   array of bone-like objects with a `name` property
 * @param keyword search substring (matched case-insensitively)
 */
export function findBone<T extends { name: string }>(bones: T[], keyword: string): T | null {
  const lower = keyword.toLowerCase();
  return bones.find(b => b.name.toLowerCase().includes(lower)) ?? null;
}

// ── Bind-pose capture / restore (task 080) ──────────────────────────────────
// A node-like animation target (TransformNode or Bone) — the structural subset we
// snapshot. glTF clips animate these nodes' transforms; resetting the skeleton's bone
// rest matrices does NOT undo that, so we snapshot and restore the nodes directly.
interface PoseTarget {
  position: Vector3;
  rotationQuaternion: Quaternion | null;
  rotation: Vector3;
  scaling: Vector3;
}
interface NodeSnapshot {
  target: PoseTarget;
  position: Vector3;
  rotationQuaternion: Quaternion | null;
  rotation: Vector3;
  scaling: Vector3;
}

/**
 * Snapshot the current (bind-pose) transform of every distinct node any clip animates.
 * Call once at build time, after stopping all clips and before any animation has been
 * evaluated, so the captured transforms are the standing rest pose.
 */
function captureBindPose(groups: AnimationGroup[]): NodeSnapshot[] {
  const seen = new Set<unknown>();
  const out: NodeSnapshot[] = [];
  for (const g of groups) {
    for (const ta of g.targetedAnimations) {
      const t = ta.target as PoseTarget | null;
      if (!t || seen.has(t)) continue;
      seen.add(t);
      // Only node-like targets carry a full transform; skip morph/other targets.
      if (!t.position || !t.scaling) continue;
      out.push({
        target: t,
        position: t.position.clone(),
        rotationQuaternion: t.rotationQuaternion ? t.rotationQuaternion.clone() : null,
        rotation: t.rotation.clone(),
        scaling: t.scaling.clone(),
      });
    }
  }
  return out;
}

/** Restore every snapshotted node to its captured bind-pose transform. */
function restoreBindPose(snapshot: NodeSnapshot[]): void {
  for (const s of snapshot) {
    s.target.position.copyFrom(s.position);
    if (s.rotationQuaternion && s.target.rotationQuaternion) {
      s.target.rotationQuaternion.copyFrom(s.rotationQuaternion);
    } else {
      s.target.rotation.copyFrom(s.rotation);
    }
    s.target.scaling.copyFrom(s.scaling);
  }
}

// ── Collected material union type ───────────────────────────────────────────
// A loaded glTF usually produces PBRMaterial; older formats may produce
// StandardMaterial. We handle both so setTint/setEmissive work on any glb.
type KnownMaterial = PBRMaterial | StandardMaterial;

/** Set the diffuse/albedo colour on a material regardless of type. */
function setDiffuse(mat: KnownMaterial, c: Color3): void {
  if (mat instanceof PBRMaterial) {
    mat.albedoColor.copyFrom(c);
  } else {
    mat.diffuseColor.copyFrom(c);
  }
}

/** Set the emissive colour on a material regardless of type. */
function setEmissiveMat(mat: KnownMaterial, c: Color3): void {
  // Both PBRMaterial and StandardMaterial expose `.emissiveColor`; only the
  // *diffuse* split (albedoColor vs diffuseColor) needs a type branch.
  mat.emissiveColor.copyFrom(c);
}

// ── Target geometry constants (must match procedural dog's framing) ──────────
// The procedural dog has its feet at root-local y ≈ -0.55 and overall height
// ≈ 1.08 when root is at BASE_Y=0.6. We target 1.2 to include a small margin
// (the imported mesh may be slightly taller/shorter than primitives).
const TARGET_HEIGHT = 1.2;

// ── Camera-facing base yaw (task 080) ───────────────────────────────────────
// The imported Labrador rig's bind-pose forward points the wrong way for our
// camera (it renders facing away). We bake a constant Y-rotation onto a dedicated
// FACING pivot — NOT the root — because `applyPose` owns `root.rotation.y` for the
// `bodyYaw` spin trick; putting the facing offset on the root would be overwritten
// every frame and would also rebase the spin. The facing pivot sits at the model's
// vertical centreline (x=z=0 after centring) so rotating it turns the dog in place
// without shifting it off-centre. The exact value is Visual-Review-tuned: the rig's
// bind pose faces +Z (away from the camera, which looks down +Z). We turn it to a
// front-three-quarter — nose toward the camera AND screen-right. Pure profile (+X, a
// quarter turn) clipped the long Labrador's head off the portrait edge and read flat;
// the 3/4 turn foreshortens the body so it fits the portrait width and gives the more
// engaging "hero" angle. Direction from the +Z rest: nose = (sin θ, 0, cos θ); 3π/4 →
// (+0.71, 0, −0.71) = front-right toward camera.
const CAMERA_FACING_YAW = (3 * Math.PI) / 4;

// ── createImportedDogMesh ────────────────────────────────────────────────────

/**
 * Build a `DogMesh` backed by a loaded glTF/glb model.
 *
 * Called from scene.ts when `selectDogRenderMode()` returns `'imported'`.
 * The returned object is a drop-in replacement for the one returned by
 * `createDogMesh` — every method signature is identical.
 *
 * @param scene      the Babylon scene (needed for MeshBuilder and TransformNode)
 * @param model      the result of `loadDogModel()` — meshes, skeletons, anim groups
 * @param appearance initial breed appearance (coat colours, proportions, ear style)
 */
export function createImportedDogMesh(
  scene: Scene,
  model: DogModelResult,
  appearance: DogAppearance,
): DogMesh {

  // ── Root TransformNode ────────────────────────────────────────────────────
  // All imported meshes are re-parented here. The scene places root.position.y
  // at BASE_Y (just like the procedural dog), so we only need root-local framing.
  const root = new TransformNode('dog', scene);

  // ── Facing pivot (task 080) ───────────────────────────────────────────────
  // Carries the constant camera-facing yaw. It sits BETWEEN root and the framing
  // pivot so its origin coincides with the root origin (= the model's vertical
  // centreline after centring); rotating it turns the dog in place without
  // de-centring it. Root keeps owning `rotation.y` for the spin trick, which now
  // composes on top of this facing yaw. Set after the bounds are computed (a
  // Y-rotation about the centreline is height- and centre-preserving, so framing
  // is unaffected).
  const facingPivot = new TransformNode('dog-facing-pivot', scene);
  facingPivot.parent = root;

  // ── Pivot for centring / framing ──────────────────────────────────────────
  // We introduce a pivot child TransformNode instead of individually offsetting
  // every mesh. This keeps the mesh hierarchy intact (parent→child relationships
  // from the glTF are preserved) while letting us reframe the whole model by
  // adjusting pivot.position and root.scaling.
  const pivot = new TransformNode('dog-model-pivot', scene);
  pivot.parent = facingPivot;

  // Re-parent the model's TOP-LEVEL ancestor node(s) under the pivot, preserving
  // the full glTF hierarchy beneath them. The loader's root nodes carry the
  // glTF→Babylon coordinate conversion AND, for a rigged model, a scaled armature
  // (this CC0 dog scales its `AnimalArmature` 100×). Re-parenting individual leaf
  // meshes — as an earlier pass did — strips those transforms and collapses the
  // skinned mesh into a vertical sliver. Walking up to each mesh's topmost ancestor
  // and re-parenting THAT keeps the armature + coordinate transforms intact.
  const topAncestors = new Set<Node>();
  for (const mesh of model.meshes) {
    let node: Node = mesh;
    while (node.parent) node = node.parent;
    topAncestors.add(node);
  }
  for (const node of topAncestors) {
    node.parent = pivot;
  }

  // ── Compute bounding box of the full imported hierarchy ───────────────────
  // Force the world matrix to be fresh (nodes just got re-parented so bounds may
  // be stale), then read the hierarchy's aggregate bounding box.
  root.computeWorldMatrix(true);

  // Walk all meshes to collect min/max in WORLD space (root is at origin now).
  // For a skinned mesh, refresh the bounds with the skeleton applied so the box
  // reflects the deformed (armature-scaled) geometry — not the raw bind-pose
  // vertices, which ignore the 100× armature and would frame the dog to the wrong
  // size. Falls back to bind-pose bounds if the refresh is unsupported.
  let globalMin = new Vector3(Infinity, Infinity, Infinity);
  let globalMax = new Vector3(-Infinity, -Infinity, -Infinity);
  for (const mesh of model.meshes) {
    if (mesh.skeleton) {
      try { mesh.refreshBoundingInfo({ applySkeleton: true }); } catch { /* keep bind-pose bounds */ }
    }
    mesh.computeWorldMatrix(true);
    const info = mesh.getBoundingInfo();
    const wMin = info.boundingBox.minimumWorld;
    const wMax = info.boundingBox.maximumWorld;
    globalMin = Vector3.Minimize(globalMin, wMin);
    globalMax = Vector3.Maximize(globalMax, wMax);
  }

  // Fallback: if bounds are degenerate (e.g. skeleton-only, no geometry yet),
  // use a unit cube so we don't divide by zero.
  const bboxHeight = globalMax.y - globalMin.y;
  const safeBboxHeight = bboxHeight > 0.001 ? bboxHeight : 1;

  const safeMin = bboxHeight > 0.001
    ? { x: globalMin.x, y: globalMin.y, z: globalMin.z }
    : { x: -0.5, y: -0.5, z: -0.5 };
  const safeMax = bboxHeight > 0.001
    ? { x: globalMax.x, y: globalMax.y, z: globalMax.z }
    : { x: 0.5, y: 0.5, z: 0.5 };

  void safeBboxHeight; // used via safeMin/safeMax

  // Compute the scale and recentring offset
  const { scale, offset } = fitTransform(safeMin, safeMax, TARGET_HEIGHT);

  // Apply the FIT scale to the facing pivot (NOT the root) and the centring
  // offset to the inner pivot. The offset is in model space (before scaling).
  //
  // Why the fit scale lives on facingPivot, not root (task 080): scene.ts owns
  // `root.scaling` for the per-state scale (BASE/OFFERING/DISTRACTOR_SCALE), the
  // same as the procedural dog — it calls `root.scaling.setAll(scaleFor)` every
  // frame. If the fit scale lived on root it would be clobbered each frame and
  // the dog would render at the procedural baseline size (the "oversized" tell in
  // §3f). Keeping the fit scale on facingPivot leaves root as the clean state-scale
  // node, so the imported dog frames correctly AND the offering/distractor pops
  // still work. facingPivot's Y-rotation is height-invariant, so combining the
  // facing yaw + uniform fit scale on one node is clean (no shear).
  facingPivot.scaling.setAll(scale);
  pivot.position.set(offset.x, offset.y, offset.z);

  // Turn the (now centred) model to face the camera. Applied on the facing pivot
  // so the spin trick's root.rotation.y composes on top instead of fighting it.
  // (Set after scale/offset: a Y-rotation about the centred vertical axis preserves
  // both the framing height and the x/z centring.)
  facingPivot.rotation.y = CAMERA_FACING_YAW;

  // ── Collect materials ─────────────────────────────────────────────────────
  // Gather every unique material from the loaded meshes so setTint/setEmissive
  // can override them all. We recognise PBRMaterial (typical for glTF) and
  // StandardMaterial (older formats). Other types are ignored (usually internals).
  const materials: KnownMaterial[] = [];
  const matSeen = new Set<string>();

  for (const mesh of model.meshes) {
    const mat = mesh.material;
    if (!mat) continue;
    if (matSeen.has(mat.uniqueId.toString())) continue;
    matSeen.add(mat.uniqueId.toString());

    if (mat instanceof PBRMaterial || mat instanceof StandardMaterial) {
      materials.push(mat);
    }
  }

  // ── Breed coat state ──────────────────────────────────────────────────────
  // We store the current breed coat as the DogMesh contract requires. For the
  // imported model we also apply the coat colour as a diffuse tint over the
  // model's own textures (matching how the procedural dog is coloured).
  let _breedCoat = appearance.coat.clone();
  let _breedBellyCoat = (appearance.coatBelly ?? appearance.coat).clone();

  // Apply initial breed coat over the model materials
  for (const mat of materials) {
    setDiffuse(mat, _breedCoat);
    setEmissiveMat(mat, new Color3(0, 0, 0));
  }

  // ── Bone lookup — head, tail, spine ──────────────────────────────────────
  // We probe the first skeleton (if any) for recognisable bones so we can map
  // the per-part pose channels. The search is purely by name substring so it
  // works generically for any rig (no hard-coded bone ids).
  //
  // Bones NOT found → their channels are no-op'd (see applyPose below).
  // These per-part procedural channels only drive the bones when NO skeletal clip
  // is active (task 080): with a clip playing, the clip owns the bones.
  let headBone: Bone | null = null;
  let tailBone: Bone | null = null;
  let spineBone: Bone | null = null;

  if (model.skeletons.length > 0) {
    const bones = model.skeletons[0].bones;
    // Try 'head' first; fall back to 'neck' (some rigs have a neck but no named head bone)
    headBone = findBone(bones, 'head') ?? findBone(bones, 'neck');
    // 'tail' — first tail bone in the chain is usually the root of the tail
    tailBone = findBone(bones, 'tail');
    // 'spine' — first spine bone for body lean
    spineBone = findBone(bones, 'spine');
  }

  // Capture the head bone's bind-pose local Y once. applyPose assigns the lift
  // bind-relative (headBoneY) each frame instead of accumulating it with `+=`,
  // which would walk the head upward unboundedly while the imported dog is live.
  const headBindY = headBone ? headBone.position.y : 0;

  // ── Skeletal animation clips (task 080) ───────────────────────────────────
  // Retain the AnimationGroups the loader produced and index them by name. The
  // glTF loader auto-starts the first group, so stop them all up-front — the
  // dog's pose is owned by setVisualState/applyPose, not by whatever clip the
  // loader happened to start. resolveStateClip (pure, tested) picks WHICH clip a
  // state maps to; this glue just plays it. activeGroup is the clip currently
  // playing (null = none → procedural pose drives the bones; see applyPose).
  const animationGroups: AnimationGroup[] = model.animationGroups ?? [];
  const clipNames = animationGroups.map(g => g.name);
  const groupByName = new Map<string, AnimationGroup>(animationGroups.map(g => [g.name, g]));
  for (const g of animationGroups) g.stop();

  // Bind-pose snapshot of every node the clips animate. The glTF loader animates the
  // linked TransformNodes (not the skeleton bones), so Skeleton.returnToRest() does NOT
  // undo a clip's pose — a stopped Sitting clip leaves its nodes seated, and a subtle
  // Idle_1 (head/breath only) can't restore standing. We snapshot each animated node's
  // initial transform now (the rig is at its standing bind pose — we just stopped every
  // clip and no render has evaluated them yet) and restore it on every clip change, so
  // each new clip starts from a clean standing base. See restoreBindPose() below.
  const bindPose = captureBindPose(animationGroups);

  let activeGroup: AnimationGroup | null = null;
  let activeState: DogVisual | null = null;
  let activeReducedMotion = false;

  // ── Blob contact shadow (mirrors createDogMesh exactly) ───────────────────
  // NOT parented to root — stays flat on the ground (y=0.01) even when the
  // dog bounces or jumps. updateShadowX() keeps its x in sync each frame.
  const shadowMat = new StandardMaterial('dog-shadow-mat', scene);
  shadowMat.diffuseColor = new Color3(0, 0, 0);
  shadowMat.alpha = 0.28;
  // Disable lighting: blob shadow should appear equally dark under any light angle.
  shadowMat.disableLighting = true;

  const blobShadow = MeshBuilder.CreateDisc(
    'dog-shadow',
    { radius: 0.52, tessellation: 24 },
    scene,
  );
  blobShadow.rotation.x = Math.PI / 2;      // rotate flat
  blobShadow.position.set(0, 0.01, 0);       // just above ground to avoid z-fighting
  // No parent — unconditionally on the ground
  blobShadow.material = shadowMat;
  blobShadow.receiveShadows = false;

  // ── Return the DogMesh contract ───────────────────────────────────────────
  return {
    root,

    get breedCoat(): Color3 { return _breedCoat; },
    get breedBellyCoat(): Color3 { return _breedBellyCoat; },

    /**
     * Override the diffuse/albedo of ALL imported materials to a single colour.
     * Used for the semantic state tints (confused orange, happy gold, etc.).
     * Mirrors createDogMesh.setTint — flattens any two-tone markings under the tint.
     */
    setTint(c: Color3): void {
      for (const mat of materials) {
        setDiffuse(mat, c);
      }
    },

    /**
     * Restore all materials to the current breed coat colour and zero emissive.
     * Called on idle to return to the breed's natural appearance.
     * Note: we restore to _breedCoat (the breed overlay), not the raw glb colours,
     * so the tint pipeline is consistent with the procedural dog.
     */
    resetToBreedCoats(): void {
      for (let i = 0; i < materials.length; i++) {
        // Restore breed coat (main coat for all materials — belly distinction is Phase 4)
        setDiffuse(materials[i], _breedCoat);
        // Zero emissive (clear any state glow)
        setEmissiveMat(materials[i], new Color3(0, 0, 0));
      }
    },

    /**
     * Set the emissive colour on ALL imported materials.
     * Creates the warm glow on offering/happy states that reads on top of any tint.
     */
    setEmissive(c: Color3): void {
      for (const mat of materials) {
        setEmissiveMat(mat, c);
      }
    },

    /**
     * Update the stored breed coat and re-apply to materials.
     * Called when the active dog switches breeds (dog-switch / adopt).
     * Phase 4 (task 082) will add per-breed proportion scaling for imported models.
     */
    setAppearance(newAppearance: DogAppearance): void {
      _breedCoat = newAppearance.coat.clone();
      _breedBellyCoat = (newAppearance.coatBelly ?? newAppearance.coat).clone();
      // Apply new coat immediately so the colour change is instant
      for (const mat of materials) {
        setDiffuse(mat, _breedCoat);
        setEmissiveMat(mat, new Color3(0, 0, 0));
      }
      // Proportion scaling (bodyGirth/legLength/earStyle) is deferred to
      // Phase 4 (task 082) — the imported rig needs bone-driven scaling.
    },

    /** Keep the blob shadow centred under the dog's lateral position. */
    updateShadowX(x: number): void {
      blobShadow.position.x = x;
    },

    /**
     * Drive the dog's gross body motion from the embedded skeletal clip that
     * matches the visual state (task 080). Called every frame from scene.ts;
     * cheap because it only (re)starts a clip when the state actually changes.
     *
     * - resolveStateClip (pure) picks the clip name for the state, or null.
     * - null → stop any active clip so the procedural pose (applyPose) drives the
     *   bones — graceful fallback for a rig missing that clip.
     * - reducedMotion damps the playback rate (D13: calm, not frozen).
     */
    setVisualState(state: DogVisual, opts?: { reducedMotion?: boolean; trickId?: string }): void {
      const reduced = opts?.reducedMotion ?? false;
      // trickId makes the offering clip trick-aware: down-family tricks (ligg/legg-deg/
      // sov) resolve to a Lie clip instead of the shared Sitting one (task 120). Within
      // a round trickId is constant, so this only changes the clip when the trick does.
      const name = resolveStateClip(state, clipNames, { trickId: opts?.trickId });
      const next = name ? groupByName.get(name) ?? null : null;
      const speed = clipMotionScale(reduced);

      if (next !== activeGroup) {
        activeGroup?.stop();
        // Restore the standing bind pose before the next clip starts. A stopped clip
        // leaves its animated nodes posed (e.g. seated), and a subtle clip like Idle_1
        // only animates head/breath — so without this reset the previous Sitting/Scratching
        // body pose would persist, making idle look identical to offering. Full-body clips
        // (sit/scratch) then fully re-pose from standing; subtle ones layer on top of it.
        restoreBindPose(bindPose);
        if (next) {
          next.speedRatio = speed;
          next.start(clipLoops(state), speed);
        }
        activeGroup = next;
        activeState = state;
        activeReducedMotion = reduced;
        return;
      }

      // Same clip still playing — only react if the reduced-motion preference
      // toggled mid-state (keeps the playback rate honest without a restart).
      if (next && (reduced !== activeReducedMotion || state !== activeState)) {
        next.speedRatio = speed;
        activeReducedMotion = reduced;
        activeState = state;
      }
    },

    /**
     * Apply a DogPose to the imported model each frame.
     *
     * Channel mapping:
     *
     * ALWAYS LIVE (root-level transforms — no bone names needed):
     *   bounceY        → root.position.y  (handled by scene.ts: BASE_Y + bounceY + crouchY)
     *   crouchY        → root.position.y  (same — additive in scene.ts, not here)
     *   bodyRollZ      → root.rotation.z  (roll trick)
     *   bodyYaw        → root.rotation.y  (spin trick)
     *   breatheScaleY  → root.scaling.y * scale (subtle breathing)
     *
     * NOTE: bounceY and crouchY are NOT applied here. They are applied by scene.ts:
     *   root.position.y = BASE_Y + pose.bounceY + (pose.crouchY ?? 0) + pulseY + flourishY
     * This matches exactly how createDogMesh works (see scene.ts lines 394–400).
     *
     * LIVE IF BONES FOUND (per-part channels mapped onto skeleton bones):
     *   headTiltZ      → headBone.rotation.z  (confused tilt)
     *   headLiftY      → headBone.position.y += (local offset — approximate)
     *   headPitch      → headBone.rotation.x  (howl up / sleep down)
     *   headYaw        → headBone.rotation.y  (idle look-around)
     *   tailWagAngle   → tailBone.rotation.z  (wag)
     *   bodyLeanX      → spineBone.rotation.z (body lean)
     *
     * SKIPPED when a skeletal clip is active (the clip owns the bones, task 080)
     * or when no matching bones were found:
     *   headTiltZ, headLiftY, headPitch, headYaw, tailWagAngle, bodyLeanX
     */
    applyPose(pose: DogPose): void {
      // ── Whole-body transforms ──────────────────────────────────────────
      // bodyRollZ: roll around the forward axis (rull trick) — on root.
      root.rotation.z = pose.bodyRollZ ?? 0;
      // bodyYaw: turn in place around the up axis (snurr trick) — on root, so it
      // composes on top of the facing pivot's constant camera-facing yaw.
      root.rotation.y = pose.bodyYaw ?? 0;
      // breatheScaleY: subtle Y breathing swell. Applied to the facing pivot's Y
      // scale (which carries the uniform fit scale) — NOT root, because scene.ts
      // owns root.scaling for the per-state scale. (breatheScaleY ≈ 1.0, so the
      // facing pivot's Y stays near the fit `scale`.)
      facingPivot.scaling.y = scale * pose.breatheScaleY;

      // bounceY and crouchY are NOT applied here — scene.ts owns root.position.y.
      // (This matches the procedural dog's contract exactly — see dogMesh.ts comment.)

      // ── Per-channel ownership (task 080) ───────────────────────────────────
      // When a skeletal clip is playing, IT owns the bones (gross body motion);
      // writing the procedural head/tail/spine channels here would fight the clip
      // and double-rotate. Whole-body channels above (roll/yaw/breathe) live on
      // OUR root TransformNode — clips never touch it — so they always compose.
      // With no clip active (missing clip → null), the procedural pose drives the
      // bones as before, so a rig without a matching clip degrades gracefully.
      if (activeGroup) return;

      // ── Per-part bone transforms (if bones were found at build time) ──
      if (headBone) {
        // headTiltZ: confused side-tilt (Z rotation on the head bone)
        // headYaw: idle look-around (Y rotation)
        // headPitch: howl up / sleep down (X rotation)
        headBone.rotation.z = pose.headTiltZ;
        headBone.rotation.y = pose.headYaw ?? 0;
        headBone.rotation.x = pose.headPitch ?? 0;
        // headLiftY: perk-up — assign bind-relative (captured headBindY + lift)
        // so it can't accumulate across frames. Mirrors the procedural dog, which
        // assigns from a fixed rest offset rather than adding onto last frame.
        headBone.position.y = headBoneY(headBindY, pose.headLiftY);
      }
      // else: headTiltZ/headLiftY/headPitch/headYaw deferred to task 080

      if (tailBone) {
        // tailWagAngle: wag around Z on the tail bone.
        // In the procedural dog this is -0.8 + wagAngle (base angle + additive).
        // For the imported rig the base pose is set by the glb bind pose, so we
        // apply the wag as an additive rotation only. This may look subtler than
        // the procedural wag until task 080 adds a clip-based animation.
        tailBone.rotation.z = pose.tailWagAngle;
      }
      // else: tailWagAngle deferred to task 080

      if (spineBone) {
        // bodyLeanX: forward/back lean of the body (Z rotation on spine).
        // Additive on top of the bind pose.
        spineBone.rotation.z = pose.bodyLeanX;
      }
      // else: bodyLeanX deferred to task 080
    },
  };
}

// Note: the dev-only `?importedDog=1` URL override lives in dogModelLoader.ts
// (`devOverrideImportedDog`), not here. That keeps scene.ts able to decide
// whether to enter the imported path without statically importing this module
// (which pulls in PBRMaterial), so this whole file stays in the lazy chunk.

// ── Note on original-material snapshots ──────────────────────────────────────
// resetToBreedCoats() restores to _breedCoat (the breed overlay) rather than the
// glb's raw colours, since restoring raw glb colours would break the tint pipeline
// for breed switches (task 079 documents this choice). If task 082's Visual Review
// decides raw restoration is preferable, re-capture the glb's own diffuse/emissive
// at build time (the old `_originalDiffuse`/`_originalEmissive` snapshots, removed in
// task 111 as dead code with no reader) and swap the resetToBreedCoats loop to use
// them instead of _breedCoat.
