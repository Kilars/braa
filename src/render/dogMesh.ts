import { TransformNode } from "@babylonjs/core/Meshes/transformNode";
import { MeshBuilder } from "@babylonjs/core/Meshes/meshBuilder";
import { StandardMaterial } from "@babylonjs/core/Materials/standardMaterial";
import { Color3 } from "@babylonjs/core/Maths/math.color";
import type { Scene } from "@babylonjs/core/scene";
import type { DogPose } from "./dogPose";
import { type DogAppearance, breedAppearance } from "./dogAppearance";

export interface DogMesh {
  root: TransformNode;
  /** The breed coat used as the idle/baseline colour — tint state overlays ride on top. */
  readonly breedCoat: Color3;
  /** The breed belly coat (if two-tone breed), or same as breedCoat for single-coat breeds. */
  readonly breedBellyCoat: Color3;
  /** Apply a semantic tint to ALL body parts (flattens two-tone for confused/distractor/etc). */
  setTint: (c: Color3) => void;
  /** Restore both coat and belly materials to the current breed's colours (call on idle). */
  resetToBreedCoats: () => void;
  setEmissive: (c: Color3) => void;
  /** Recolour + rescale existing parts to match a new appearance (e.g. after dog-switch). */
  setAppearance: (appearance: DogAppearance) => void;
  /** Update the blob contact shadow's X position to match the dog's lateral position. */
  updateShadowX: (x: number) => void;
  /**
   * Apply a DogPose to the dog's sub-parts each frame.
   * - headTiltZ: head Z-rotation (confused tilt)
   * - headLiftY: head Y-offset (perk up / lift)
   * - tailWagAngle: tail Z-rotation (wag)
   * - bodyLeanX: body X-rotation (lean forward/away)
   * - bounceY: root Y-offset added on top of BASE_Y (happy/misbehaving jump)
   * - breatheScaleY: body Y-scale (idle breathing)
   */
  applyPose: (pose: DogPose) => void;
}

/**
 * Assembles a primitive-composed dog from Babylon shapes.
 *
 * Parts: body (capsule, horizontal), head (sphere), snout (box), two ears
 * (cylinders, tapered), four legs (cylinders), tail (cylinder, angled up),
 * two eyes (spheres, own material), nose (sphere, own material), and a flat
 * blob-shadow disc parented under root for contact grounding (D12).
 * All parented under a single root TransformNode so per-state transforms
 * (scale/position/jitter) move the whole dog including the shadow.
 *
 * Tint and emissive are applied to the BODY shared material only.
 * Eyes, nose, and shadow have their own materials and are NOT affected by
 * setTint/setEmissive — black eyes stay black, shadow stays dark under any
 * tint state.
 *
 * Material: low specularColor + high specularPower for a fur-ish soft sheen
 * (no harsh plastic hotspot).
 *
 * Overall bounding height ≈ 1.2 so camera framing (target y=0.6, radius 4.5)
 * still centres the dog; root should be placed at y=0.6 (same as the old sphere).
 *
 * Layout (all positions in root-local space, dog faces +X):
 *   Body centre: (0, 0, 0) — horizontal capsule
 *   Head:        (+0.55, +0.28, 0)
 *   Snout:       (+0.80, +0.18, 0) — small box in front of head
 *   Ear L:       (+0.45, +0.52, +0.14) — left (towards camera)
 *   Ear R:       (+0.45, +0.52, -0.14) — right (away from camera)
 *   Legs: four cylinders at (±0.30, -0.38, ±0.16)
 *   Tail:        (-0.52, +0.14, 0) — angled cylinder at the back
 *
 * With body half-height ≈ 0.26 and legs hanging −0.38 below root the paw tips
 * reach y ≈ −0.55 (in root space). Head top reaches y ≈ +0.53. Full extent in
 * root space: ~1.08; placed at root y=0.6 the dog occupies world y 0.05–1.13,
 * nicely centred on camera target y=0.6.
 */
export function createDogMesh(scene: Scene, appearance: DogAppearance = breedAppearance('labrador')): DogMesh {
  const root = new TransformNode("dog", scene);

  // ── Shared body material (breed coat, fur-ish — no plastic hotspot) ──────
  const mat = new StandardMaterial("dog-mat", scene);
  mat.diffuseColor = appearance.coat.clone();
  mat.emissiveColor = new Color3(0, 0, 0);
  // Kill harsh specular: low specularColor + high specularPower = soft sheen, no hotspot
  mat.specularColor = new Color3(0.05, 0.05, 0.05);
  mat.specularPower = 64;

  // ── Belly / chest material (second tone for two-tone breeds) ──────────────
  // For single-coat breeds (no coatBelly), bellyMat mirrors the main coat so
  // the assignment below is harmless and no visible change occurs.
  const bellyMat = new StandardMaterial("dog-belly-mat", scene);
  bellyMat.diffuseColor = (appearance.coatBelly ?? appearance.coat).clone();
  bellyMat.emissiveColor = new Color3(0, 0, 0);
  bellyMat.specularColor = new Color3(0.05, 0.05, 0.05);
  bellyMat.specularPower = 64;

  // Track the current breed coats so scene.ts can read them for idle-state reset
  let _breedCoat = appearance.coat.clone();
  let _breedBellyCoat = (appearance.coatBelly ?? appearance.coat).clone();

  // ── Body ─────────────────────────────────────────────────────────────────
  // Capsule lying on its side (z-rotation 90°) — rounded horizontal torso
  const body = MeshBuilder.CreateCapsule(
    "dog-body",
    { radius: 0.26, height: 0.90, tessellation: 12, subdivisions: 2 },
    scene,
  );
  body.rotation.z = Math.PI / 2;
  body.parent = root;
  body.material = mat;

  // Apply initial body girth (scale X+Z around the body capsule, keeping its rotation in mind)
  // bodyGirth > 1 = stockier, < 1 = leaner
  body.scaling.x = appearance.bodyGirth;
  body.scaling.z = appearance.bodyGirth;

  // ── Chest patch (two-tone belly tone, POV-visible) ────────────────────────
  // A flattened ellipsoid on the front-facing underside of the body. Camera
  // is ~81° from vertical (mostly horizontal) so this front/belly area is
  // clearly visible. For two-tone breeds (Border Collie, Husky) this shows as
  // a white chest blaze; for single-coat breeds bellyMat == mat and it blends in.
  const chest = MeshBuilder.CreateSphere(
    "dog-chest",
    { diameter: 1, segments: 8 },
    scene,
  );
  // Flatten into a large chest-facing patch:
  // X=0.52 (deep, covers front half of body), Y=0.22 (thin in height), Z=0.55 (wide)
  // Position at (0.12, -0.06, 0) — lower-front of the body capsule, facing trainer
  chest.scaling.set(0.52, 0.22, 0.55);
  chest.position.set(0.12, -0.06, 0);
  chest.parent = root;
  chest.material = bellyMat;

  // ── Head pivot ───────────────────────────────────────────────────────────
  // A TransformNode placed at the head's natural centre so all head-attached
  // parts (head sphere, snout, ears, eyes, nose) rotate together around it.
  // Pose transforms (headTiltZ, headLiftY) are applied to this pivot.
  const headPivot = new TransformNode("dog-head-pivot", scene);
  headPivot.position.set(0.55, 0.28, 0);
  headPivot.parent = root;

  // ── Head ─────────────────────────────────────────────────────────────────
  const head = MeshBuilder.CreateSphere(
    "dog-head",
    { diameter: 0.46, segments: 12 },
    scene,
  );
  // Position is now relative to headPivot (offset from pivot centre = 0)
  head.position.set(0, 0, 0);
  head.parent = headPivot;
  head.material = mat;

  // ── Snout ─────────────────────────────────────────────────────────────────
  // Small flattened box protruding from the lower-front of the head.
  // Position relative to headPivot: original root-space (0.82, 0.16, 0) minus
  // headPivot centre (0.55, 0.28, 0) = (0.27, -0.12, 0).
  const snout = MeshBuilder.CreateBox(
    "dog-snout",
    { width: 0.22, height: 0.14, depth: 0.18 },
    scene,
  );
  snout.position.set(0.27, -0.12, 0);
  snout.parent = headPivot;
  // Snout uses belly tone — shows as white blaze/muzzle on two-tone breeds;
  // blends in on single-coat breeds (bellyMat == main coat colour).
  snout.material = bellyMat;

  // ── Face blaze / forehead patch ───────────────────────────────────────────
  // A flat disc on the front-face of the head — the classic Border Collie white
  // blaze between the eyes. Highly visible from the trainer POV (facing the dog).
  // For single-coat breeds bellyMat == mat, so the blaze is invisible.
  // Position relative to headPivot: (0.20, 0.05, 0) — front face of the head sphere.
  const blaze = MeshBuilder.CreateSphere(
    "dog-blaze",
    { diameter: 1, segments: 6 },
    scene,
  );
  // Flat disc: X=0.06 (very thin, sits on head surface), Y=0.22 (tall, blaze stripe), Z=0.14 (narrow)
  blaze.scaling.set(0.06, 0.22, 0.14);
  blaze.position.set(0.20, 0.05, 0);
  blaze.parent = headPivot;
  blaze.material = bellyMat;

  // ── Ears ─────────────────────────────────────────────────────────────────
  // Tapered cylinders (cone-ish). Floppy = flopped outward; pricked = straight up.
  // Positions relative to headPivot: original (0.44, 0.52, ±0.14) minus (0.55, 0.28, 0)
  // = (-0.11, 0.24, ±0.14).
  const earOpts = {
    diameterTop: 0.04,
    diameterBottom: 0.13,
    height: 0.22,
    tessellation: 8,
  };

  // Helper: apply ear rotation based on earStyle
  function applyEarStyle(
    left: ReturnType<typeof MeshBuilder.CreateCylinder>,
    right: ReturnType<typeof MeshBuilder.CreateCylinder>,
    style: DogAppearance['earStyle'],
  ) {
    if (style === 'pricked') {
      // Straight up — ears point upward, only slight outward splay
      left.rotation.set(0.1, 0, 0.15);
      right.rotation.set(-0.1, 0, -0.15);
    } else {
      // Floppy — flopped outward and slightly forward
      left.rotation.set(0.35, 0, 0.3);
      right.rotation.set(-0.35, 0, -0.3);
    }
  }

  const earL = MeshBuilder.CreateCylinder("dog-ear-l", earOpts, scene);
  earL.position.set(-0.11, 0.24, 0.14);
  earL.parent = headPivot;
  earL.material = mat;

  const earR = MeshBuilder.CreateCylinder("dog-ear-r", earOpts, scene);
  earR.position.set(-0.11, 0.24, -0.14);
  earR.parent = headPivot;
  earR.material = mat;

  applyEarStyle(earL, earR, appearance.earStyle);

  // ── Legs ──────────────────────────────────────────────────────────────────
  // Four cylinders at body corners; legLength scales their height.
  const BASE_LEG_HEIGHT = 0.36;
  const legOpts = { diameter: 0.11, height: BASE_LEG_HEIGHT, tessellation: 8 };
  const BASE_LEG_Y = -0.38;
  const legPositions: [number, number, number][] = [
    [0.30, BASE_LEG_Y, 0.16],   // front-left
    [0.30, BASE_LEG_Y, -0.16],  // front-right
    [-0.30, BASE_LEG_Y, 0.16],  // back-left
    [-0.30, BASE_LEG_Y, -0.16], // back-right
  ];
  const legNames = ["dog-leg-fl", "dog-leg-fr", "dog-leg-bl", "dog-leg-br"];
  const legs: ReturnType<typeof MeshBuilder.CreateCylinder>[] = [];

  for (let i = 0; i < 4; i++) {
    const leg = MeshBuilder.CreateCylinder(legNames[i], legOpts, scene);
    // Scale Y for legLength; also shift Y so top of leg stays at body bottom
    const ll = appearance.legLength;
    leg.scaling.y = ll;
    // Shift the leg's Y centre so the top stays attached to the body
    // (base Y is -0.38; at ll=1 the centre is at -0.38; longer legs drop further)
    leg.position.set(legPositions[i][0], BASE_LEG_Y - (ll - 1) * (BASE_LEG_HEIGHT / 2), legPositions[i][2]);
    leg.parent = root;
    // Front legs (indices 0, 1) get the belly/chest tone — highly visible from
    // the trainer POV. Back legs (2, 3) keep the main coat.
    leg.material = i < 2 ? bellyMat : mat;
    legs.push(leg);
  }

  // ── Tail pivot ────────────────────────────────────────────────────────────
  // TransformNode at the tail base so wagAngle rotates around that point.
  const tailPivot = new TransformNode("dog-tail-pivot", scene);
  tailPivot.position.set(-0.55, 0.18, 0);
  tailPivot.parent = root;

  // ── Tail ──────────────────────────────────────────────────────────────────
  // Thin cylinder angled upward at the dog's rear.
  // Position relative to tailPivot = (0, 0, 0); base rotation stays.
  const tail = MeshBuilder.CreateCylinder(
    "dog-tail",
    { diameterTop: 0.04, diameterBottom: 0.08, height: 0.28, tessellation: 6 },
    scene,
  );
  // Angle ~45° up-and-back (base rotation; wag adds to Z)
  tail.rotation.set(0, 0, -0.8);
  tail.position.set(0, 0, 0);
  tail.parent = tailPivot;
  tail.material = mat;

  // ── Eyes + Nose (own materials — NOT affected by setTint) ─────────────────
  // Parented to headPivot so they move with the head.
  // Positions relative to headPivot: original root-space minus (0.55, 0.28, 0).
  //   leftEye:  (0.76-0.55, 0.34-0.28, +0.11) = (0.21, 0.06, +0.11)
  //   rightEye: (0.76-0.55, 0.34-0.28, -0.11) = (0.21, 0.06, -0.11)
  //   nose:     (0.94-0.55, 0.18-0.28,  0)    = (0.39, -0.10,  0)
  const eyeMat = new StandardMaterial("dog-eye-mat", scene);
  eyeMat.diffuseColor = new Color3(0.05, 0.05, 0.05);
  eyeMat.specularColor = new Color3(0.1, 0.1, 0.1);
  eyeMat.specularPower = 32;

  const leftEye = MeshBuilder.CreateSphere(
    "dog-eye-l",
    { diameter: 0.07, segments: 6 },
    scene,
  );
  leftEye.position.set(0.21, 0.06, 0.11);
  leftEye.parent = headPivot;
  leftEye.material = eyeMat;

  const rightEye = MeshBuilder.CreateSphere(
    "dog-eye-r",
    { diameter: 0.07, segments: 6 },
    scene,
  );
  rightEye.position.set(0.21, 0.06, -0.11);
  rightEye.parent = headPivot;
  rightEye.material = eyeMat;

  // Nose — small dark sphere at the front tip of the snout
  const noseMat = new StandardMaterial("dog-nose-mat", scene);
  noseMat.diffuseColor = new Color3(0.04, 0.04, 0.04);
  noseMat.specularColor = new Color3(0.15, 0.15, 0.15);
  noseMat.specularPower = 48;

  const nose = MeshBuilder.CreateSphere(
    "dog-nose",
    { diameter: 0.07, segments: 6 },
    scene,
  );
  nose.position.set(0.39, -0.10, 0);
  nose.parent = headPivot;
  nose.material = noseMat;

  // ── Blob contact shadow (NOT affected by setTint) ──────────────────────────
  // A flat, soft, semi-transparent dark disc at world y=0.01 (just above the
  // ground) that tracks the dog's lateral x each frame via updateShadowX().
  // NOT parented to root so it always stays on the ground even when the dog
  // bounces or jumps (happy/misbehaving states).
  const shadowMat = new StandardMaterial("dog-shadow-mat", scene);
  shadowMat.diffuseColor = new Color3(0, 0, 0);
  shadowMat.alpha = 0.28;
  // Disable lighting so the shadow colour is always solid dark regardless of
  // scene lighting angle (a blob shadow should look the same in any light).
  shadowMat.disableLighting = true;

  const blobShadow = MeshBuilder.CreateDisc(
    "dog-shadow",
    { radius: 0.52, tessellation: 24 },
    scene,
  );
  // Rotate flat; y=0.01 sits just above the grass plane to avoid z-fighting
  blobShadow.rotation.x = Math.PI / 2;
  blobShadow.position.set(0, 0.01, 0);
  // No parent — stays at ground level unconditionally
  blobShadow.material = shadowMat;
  blobShadow.receiveShadows = false;

  // ── Tint / emissive hooks — body parts only; eyes/nose/shadow excluded ─────
  return {
    root,
    get breedCoat(): Color3 { return _breedCoat; },
    get breedBellyCoat(): Color3 { return _breedBellyCoat; },

    /**
     * Apply a semantic tint to ALL body parts (both coat and belly materials).
     * Used for confused/distractor/misbehaving/offering/happy states where a
     * single semantic colour overrides the breed markings.
     * For idle, call resetToBreedCoats() instead to restore the two-tone.
     */
    setTint: (c: Color3) => {
      mat.diffuseColor.copyFrom(c);
      bellyMat.diffuseColor.copyFrom(c);
    },

    /**
     * Restore both coat and belly materials to the current breed colours.
     * Call this for idle/baseline state so two-tone breeds remain two-tone.
     */
    resetToBreedCoats: () => {
      mat.diffuseColor.copyFrom(_breedCoat);
      bellyMat.diffuseColor.copyFrom(_breedBellyCoat);
      mat.emissiveColor.set(0, 0, 0);
      bellyMat.emissiveColor.set(0, 0, 0);
    },

    setEmissive: (c: Color3) => {
      mat.emissiveColor.copyFrom(c);
      bellyMat.emissiveColor.copyFrom(c);
    },

    /**
     * Recolour + rescale to a new appearance. Called when the active dog changes
     * (dog-switch or adopt) — cheaper than rebuilding the whole mesh.
     */
    setAppearance(newAppearance: DogAppearance): void {
      // Store new breed coats and reset both materials
      _breedCoat = newAppearance.coat.clone();
      _breedBellyCoat = (newAppearance.coatBelly ?? newAppearance.coat).clone();
      mat.diffuseColor.copyFrom(newAppearance.coat);
      bellyMat.diffuseColor.copyFrom(_breedBellyCoat);

      // Body girth — scale X and Z of the body capsule
      body.scaling.x = newAppearance.bodyGirth;
      body.scaling.z = newAppearance.bodyGirth;

      // Leg length — rescale and reposition all legs
      const ll = newAppearance.legLength;
      for (let i = 0; i < legs.length; i++) {
        legs[i].scaling.y = ll;
        legs[i].position.set(
          legPositions[i][0],
          BASE_LEG_Y - (ll - 1) * (BASE_LEG_HEIGHT / 2),
          legPositions[i][2],
        );
      }

      // Ear style
      applyEarStyle(earL, earR, newAppearance.earStyle);
    },

    /** Call each frame to keep the blob shadow centered under the dog. */
    updateShadowX: (x: number) => { blobShadow.position.x = x; },

    /**
     * Apply a DogPose to the dog's moving sub-parts.
     * Called every frame by scene.ts after dogPose() computes the current pose.
     *
     * Mapping:
     *   headTiltZ      → headPivot.rotation.z  (confused tilt / side-lean)
     *   headLiftY      → headPivot.position.y offset from rest (perk up)
     *   headPitch      → headPivot.rotation.x  (howl up / sleep down — trick-specific)
     *   headYaw        → headPivot.rotation.y (idle look-around)
     *   tailWagAngle   → tail.rotation.z added on top of base -0.8 angle (wag)
     *   bodyLeanX      → body.rotation.z (lean forward/away — body capsule leans)
     *   bounceY        → root.position.y offset (scene handles BASE_Y + bounceY)
     *   breatheScaleY  → body.scaling.y (subtle breathing swell)
     *   crouchY        → root.position.y additive offset (lower toward ground for sit/lie)
     *   bodyRollZ      → root.rotation.z (partial body roll — rull trick)
     *   bodyYaw        → root.rotation.y (turn in place — snurr trick)
     */
    applyPose: (pose: DogPose) => {
      // Head: tilt (Z), lift (Y offset from rest), pitch (X — howl/sleep trick cues), and yaw (Y — idle look-around)
      headPivot.rotation.z = pose.headTiltZ;
      headPivot.rotation.x = pose.headPitch ?? 0;
      headPivot.rotation.y = pose.headYaw ?? 0;   // idle look-around
      headPivot.position.y = 0.28 + pose.headLiftY;

      // Tail: wag by rotating around Z on top of the base -0.8 angle
      tail.rotation.z = -0.8 + pose.tailWagAngle;

      // Body lean: rotate the body capsule around Z (forward/back lean)
      body.rotation.z = Math.PI / 2 + pose.bodyLeanX;

      // Breathing: scale the body Y slightly (breatheScaleY is near 1.0)
      // Note: bodyGirth already set scaling.x/z; breatheScaleY only adjusts Y
      body.scaling.y = pose.breatheScaleY;

      // Trick-specific body transforms applied to the root so all parts move together.
      // bodyRollZ: partial roll for rull (rotate around forward/Z axis — kept modest).
      // bodyYaw: turn-in-place for snurr (rotate around up/Y axis).
      // crouchY: lower the whole dog toward the ground (additive on BASE_Y in scene.ts).
      root.rotation.z = pose.bodyRollZ ?? 0;
      root.rotation.y = pose.bodyYaw   ?? 0;
      // crouchY is additive on the scene's BASE_Y — scene.ts applies: root.position.y = BASE_Y + bounceY + crouchY
      // bounceY is already handled in scene.ts; expose crouchY via the pose so scene.ts can include it.

      // bounceY is handled in scene.ts (root.position.y = BASE_Y + pose.bounceY + (pose.crouchY ?? 0))
      // so that the shadow x-sync stays correct
    },
  };
}
