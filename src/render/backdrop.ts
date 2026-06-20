/**
 * src/render/backdrop.ts
 *
 * Cheap mobile-friendly training-ground backdrop for the dog scene.
 *
 * Approach (documented in tech-decisions.md §2-Rendering):
 * - SKY: A large back-plane mesh at z=−12 with a DynamicTexture vertical
 *   gradient (pale near-horizon → deeper sky-blue at top). No skybox, no
 *   post-processing — just one extra quad draw call.
 * - GROUND: The existing 10×10 ground plane gets a DynamicTexture radial
 *   gradient (bright grass centre fading to a desaturated edge). The far
 *   edge blends toward the sky horizon colour so the ground-to-sky join
 *   is soft rather than a hard line.
 * - VIGNETTE: A stretched hemisphere shell (inside-facing normals, unlit,
 *   near-black, low alpha) around the scene darkens the corners and frames
 *   the dog without any post-processing pipeline cost.
 *
 * All DynamicTextures are created once at setup time and never redrawn, so
 * the per-frame cost is zero beyond the two extra quad draw calls.
 */

import { Scene } from "@babylonjs/core/scene";
import { MeshBuilder } from "@babylonjs/core/Meshes/meshBuilder";
import { StandardMaterial } from "@babylonjs/core/Materials/standardMaterial";
import { DynamicTexture } from "@babylonjs/core/Materials/Textures/dynamicTexture";
import { Color3, Color4 } from "@babylonjs/core/Maths/math.color";
import { Vector3 } from "@babylonjs/core/Maths/math.vector";
import { DirectionalLight } from "@babylonjs/core/Lights/directionalLight";
import { HemisphericLight } from "@babylonjs/core/Lights/hemisphericLight";
import type { AbstractMesh } from "@babylonjs/core/Meshes/abstractMesh";
import { backdropTierConfig } from "./backdropTier";

// ── Palette ────────────────────────────────────────────────────────────────────
// Sky: horizon pale → deep top (Pokémon-GO-ish soft daylight blue)
const SKY_TOP    = { r: 0.32, g: 0.55, b: 0.88 }; // richer blue up top
const SKY_HORIZ  = { r: 0.76, g: 0.89, b: 0.98 }; // pale hazy near horizon

// Ground: centre bright grass → edges fade toward horizon colour
const GROUND_CTR = { r: 0.46, g: 0.80, b: 0.43 }; // bright vivid grass
const GROUND_EDG = { r: 0.68, g: 0.82, b: 0.72 }; // desaturated near edge (reads as distance)

// Texture resolution — small enough to be instant on mobile; gradient is smooth enough
const SKY_W = 4;    // sky is just a gradient column, 4 px wide is fine
const SKY_H = 128;
const GND_SIZE = 256; // ground needs a 2D radial gradient

/** CSS-style "r,g,b" string from 0-1 floats (no alpha) */
function rgb(r: number, g: number, b: number): string {
  return `rgb(${Math.round(r * 255)},${Math.round(g * 255)},${Math.round(b * 255)})`;
}

/** Linear interpolate two colour channels */
function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

// ── Sky gradient backplane ─────────────────────────────────────────────────────

/**
 * Creates a wide quad at the back of the scene rendered as a sky gradient.
 * The quad is large enough that no edge is visible in the portrait crop.
 * It's placed at z=−14 and sized so it fills the whole sky area seen by the
 * ArcRotateCamera at beta≈1.42, radius 4.5.
 *
 * `renderingGroupId = 0` puts it behind everything else (dog is group 1).
 */
function createSkyPlane(scene: Scene): void {
  // Gradient texture: column of pixels, bottom = horizon, top = deep sky
  const tex = new DynamicTexture("sky-tex", { width: SKY_W, height: SKY_H }, scene, false);
  const ctx = tex.getContext();

  // Draw a vertical gradient: bottom portion = horizon pale, top = deep sky.
  // The sky plane is large; only the lower 40% of its height is typically
  // visible in portrait (camera beta≈1.42), so we push the deep blue
  // colour into the bottom 50% of the texture so it's always in frame.
  const grad = ctx.createLinearGradient(0, SKY_H, 0, 0);
  grad.addColorStop(0.0,  rgb(SKY_HORIZ.r, SKY_HORIZ.g, SKY_HORIZ.b)); // very bottom = horizon
  grad.addColorStop(0.25, rgb(
    lerp(SKY_HORIZ.r, SKY_TOP.r, 0.3),
    lerp(SKY_HORIZ.g, SKY_TOP.g, 0.3),
    lerp(SKY_HORIZ.b, SKY_TOP.b, 0.3),
  ));
  grad.addColorStop(0.55, rgb(SKY_TOP.r, SKY_TOP.g, SKY_TOP.b)); // deep sky already by middle
  grad.addColorStop(1.0,  rgb(SKY_TOP.r, SKY_TOP.g, SKY_TOP.b)); // stays deep at top
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, SKY_W, SKY_H);
  tex.update();

  const mat = new StandardMaterial("sky-mat", scene);
  mat.diffuseTexture = tex;
  mat.emissiveColor = new Color3(1, 1, 1); // unlit — shows the texture colour directly
  mat.disableLighting = true;
  mat.backFaceCulling = false;

  // Large plane facing the camera; positioned to cover the sky area visible
  // at camera beta≈1.42, radius 4.5, target y=0.6.
  // Width/height are generous so no edge is visible even on very wide viewports.
  const sky = MeshBuilder.CreatePlane("sky-plane", { width: 60, height: 40 }, scene);
  sky.position = new Vector3(0, 5, -14);
  sky.material = mat;
  sky.renderingGroupId = 0;          // behind everything
  sky.isPickable = false;
  sky.checkCollisions = false;
  // Slight forward tilt to face the camera angle better
  sky.rotation.x = -0.12;
}

// ── Ground gradient texture ────────────────────────────────────────────────────

/**
 * Returns a DynamicTexture with a radial gradient centred in the UV space:
 * bright grass centre → desaturated/pale edge (reads as distance + softened horizon).
 */
function createGroundTexture(scene: Scene): DynamicTexture {
  const tex = new DynamicTexture("ground-tex", { width: GND_SIZE, height: GND_SIZE }, scene, false);
  const ctx = tex.getContext();
  const half = GND_SIZE / 2;

  // Radial gradient: centre of texture → corner
  const grad = ctx.createRadialGradient(half, half, 0, half, half, half * 1.5);
  grad.addColorStop(0.0,  rgb(GROUND_CTR.r, GROUND_CTR.g, GROUND_CTR.b));
  grad.addColorStop(0.45, rgb(GROUND_CTR.r, GROUND_CTR.g, GROUND_CTR.b));
  grad.addColorStop(0.75, rgb(
    lerp(GROUND_CTR.r, GROUND_EDG.r, 0.5),
    lerp(GROUND_CTR.g, GROUND_EDG.g, 0.5),
    lerp(GROUND_CTR.b, GROUND_EDG.b, 0.5),
  ));
  grad.addColorStop(1.0,  rgb(GROUND_EDG.r, GROUND_EDG.g, GROUND_EDG.b));

  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, GND_SIZE, GND_SIZE);
  tex.update();

  return tex;
}

// ── Tier prop constants ────────────────────────────────────────────────────────
// All props are placed at the scene edges (x ≤ −3 or x ≥ 3, z ≤ −3 or z ≥ 3)
// so they never overlap the centred dog framing zone (D12).

/** Colour for bush spheres — medium-dark green, unlit. */
const BUSH_COLOR  = new Color3(0.22, 0.55, 0.18);
/** Colour for agility cones — softened orange so it accents, not competes with the dog. */
const CONE_COLOR  = new Color3(0.84, 0.44, 0.18);
/** Colour for jump pole + bar — warm cream to match the park's warm palette. */
const POLE_COLOR  = new Color3(0.88, 0.80, 0.62);
/** Colour for fence segments. */
const FENCE_COLOR = new Color3(0.70, 0.58, 0.38);

/**
 * Module-level cache of tier-prop meshes, keyed by name.
 * Re-used by applyBackdropTier to show/hide without re-allocating.
 */
const _tierProps: Map<string, AbstractMesh> = new Map();

/** Cached reference to the fill (hemisphere) light set in setupBackdrop. */
let _hemiLight: HemisphericLight | null = null;
/** Base intensity of the hemi light before tier boosts. */
const _HEMI_BASE_INTENSITY = 0.8;
/** Cached reference to the ground material so tier updates can tint it lusher. */
let _groundMat: StandardMaterial | null = null;

/**
 * Return (or create) a named mesh.  Factory is only called once.
 */
function getOrCreate(name: string, factory: () => AbstractMesh): AbstractMesh {
  if (!_tierProps.has(name)) {
    _tierProps.set(name, factory());
  }
  return _tierProps.get(name)!;
}

/** Create a single bush sphere with position (x, z). */
function makeBush(scene: Scene, name: string, x: number, z: number): AbstractMesh {
  const mat = new StandardMaterial(`${name}-mat`, scene);
  mat.diffuseColor = BUSH_COLOR;
  mat.specularColor = new Color3(0, 0, 0); // matte; lit by scene key/hemi lights
  const mesh = MeshBuilder.CreateSphere(name, { diameter: 0.9, segments: 5 }, scene);
  mesh.position.set(x, 0.3, z);
  mesh.material = mat;
  mesh.isPickable = false;
  mesh.setEnabled(false);
  return mesh;
}

/** Create an agility cone at position (x, z). */
function makeCone(scene: Scene, name: string, x: number, z: number): AbstractMesh {
  const mat = new StandardMaterial(`${name}-mat`, scene);
  mat.diffuseColor = CONE_COLOR;
  mat.specularColor = new Color3(0, 0, 0); // matte; lit by scene key/hemi lights
  const mesh = MeshBuilder.CreateCylinder(name, {
    diameterTop: 0, diameterBottom: 0.22, height: 0.4, tessellation: 12,
  }, scene);
  mesh.position.set(x, 0.2, z);
  mesh.material = mat;
  mesh.isPickable = false;
  mesh.setEnabled(false);
  return mesh;
}

/** Create a jump-bar pole (tall thin cylinder) at position (x, z). */
function makeJumpPole(scene: Scene, name: string, x: number, z: number): AbstractMesh {
  const mat = new StandardMaterial(`${name}-mat`, scene);
  mat.diffuseColor = POLE_COLOR;
  mat.specularColor = new Color3(0, 0, 0); // matte; lit by scene key/hemi lights
  const mesh = MeshBuilder.CreateCylinder(name, {
    diameter: 0.08, height: 1.0, tessellation: 6,
  }, scene);
  mesh.position.set(x, 0.5, z);
  mesh.material = mat;
  mesh.isPickable = false;
  mesh.setEnabled(false);
  return mesh;
}

/** Create a horizontal jump bar (thin box) between two poles. */
function makeJumpBar(scene: Scene, name: string, x: number, z: number): AbstractMesh {
  const mat = new StandardMaterial(`${name}-mat`, scene);
  mat.diffuseColor = POLE_COLOR; // cream rail, matches the pole
  mat.specularColor = new Color3(0, 0, 0); // matte; lit by scene key/hemi lights
  const mesh = MeshBuilder.CreateBox(name, { width: 1.1, height: 0.06, depth: 0.06 }, scene);
  mesh.position.set(x, 0.55, z);
  mesh.material = mat;
  mesh.isPickable = false;
  mesh.setEnabled(false);
  return mesh;
}

/** Create one fence segment (thin flat box) at position (x, z) with given rotation. */
function makeFenceSegment(scene: Scene, name: string, x: number, z: number, rotY: number): AbstractMesh {
  const mat = new StandardMaterial(`${name}-mat`, scene);
  mat.diffuseColor = FENCE_COLOR;
  mat.specularColor = new Color3(0, 0, 0); // matte; lit by scene key/hemi lights
  const mesh = MeshBuilder.CreateBox(name, { width: 1.6, height: 0.6, depth: 0.06 }, scene);
  mesh.position.set(x, 0.3, z);
  mesh.rotation.y = rotY;
  mesh.material = mat;
  mesh.isPickable = false;
  mesh.setEnabled(false);
  return mesh;
}

/**
 * Ensure all tier props exist in the scene (idempotent).
 * All props start disabled; applyBackdropTier enables/disables per tier.
 */
function ensureTierProps(scene: Scene): void {
  // NOTE on placement: the camera sits at ≈(0, 1.28, -4.45) looking toward +Z
  // (target (0,0.6,0)). So "behind the dog" — visible, never occluding the
  // centered dog — is POSITIVE z, and the in-frame horizontal band narrows with
  // distance. All props sit on the grass at small |x|, positive z, near the
  // horizon behind the dog.

  // Tier 1+: two bushes flanking the dog, kept CLOSE (small z) so they stay
  // prominent and read as the first clear upgrade.
  getOrCreate('bush-bl', () => makeBush(scene, 'bush-bl',  -1.7, 2.7));
  getOrCreate('bush-br', () => makeBush(scene, 'bush-br',   1.7, 2.7));

  // Tier 2+: STRICTLY ADDITIVE over tier 1 — the two front bushes (z 2.7) stay
  // visible; the cones sit slightly BEHIND them (z 2.9) and are now small + softly
  // coloured so they accent rather than compete with the dog. Two more bushes and
  // a cream jump set fill in to the back-left.
  getOrCreate('bush-ml', () => makeBush(scene, 'bush-ml',  -2.1, 3.6));
  getOrCreate('bush-mr', () => makeBush(scene, 'bush-mr',   2.1, 3.6));
  getOrCreate('cone-a',  () => makeCone(scene, 'cone-a',   -1.4, 2.9));
  getOrCreate('cone-b',  () => makeCone(scene, 'cone-b',    1.4, 2.9));
  getOrCreate('jump-pole-a', () => makeJumpPole(scene, 'jump-pole-a', -1.9, 3.2));
  getOrCreate('jump-pole-b', () => makeJumpPole(scene, 'jump-pole-b', -0.9, 3.2));
  getOrCreate('jump-bar',    () => makeJumpBar(scene,  'jump-bar',    -1.4, 3.2));

  // Tier 3: more bushes + a fence line across the far background (at the horizon)
  getOrCreate('bush-fl', () => makeBush(scene, 'bush-fl',  -1.0, 4.2));
  getOrCreate('bush-fr', () => makeBush(scene, 'bush-fr',   1.0, 4.2));
  getOrCreate('bush-fc', () => makeBush(scene, 'bush-fc',   0.0, 4.5));
  getOrCreate('fence-l', () => makeFenceSegment(scene, 'fence-l', -2.0, 4.0, 0));
  getOrCreate('fence-r', () => makeFenceSegment(scene, 'fence-r',  2.0, 4.0, 0));
  getOrCreate('fence-c', () => makeFenceSegment(scene, 'fence-c',  0.0, 4.0, 0));
}

// ── Public API ─────────────────────────────────────────────────────────────────

/**
 * Set up the training-ground backdrop in `scene`:
 * 1. Sky gradient back-plane (replaces flat clearColor — clearColor stays
 *    nearly-matching the sky horizon so any tiny gaps are invisible).
 * 2. Radial gradient on the ground material (brighter under dog, fades at edges).
 * 3. Subtle dark corner vignette via an inside-hemisphere shell.
 * 4. Adds a warm DirectionalLight key-light for cleaner dog separation;
 *    tunes the existing HemisphericLight to be softer fill.
 * 5. Builds (but disables) all tier props; enables those appropriate for `tier`.
 *
 * @param scene       The Babylon scene.
 * @param groundMesh  The existing ground mesh (created by scene.ts).
 * @param hemiLight   The existing HemisphericLight (created by scene.ts).
 * @param tier        Initial kennel tier (0–3; defaults to 0).
 */
export function setupBackdrop(
  scene: Scene,
  groundMesh: { material: StandardMaterial | null },
  hemiLight: HemisphericLight,
  tier: 0 | 1 | 2 | 3 = 0,
): void {
  // 1. Sky back-plane
  createSkyPlane(scene);

  // 2. Ground gradient texture — apply to existing ground material
  const groundMat = groundMesh.material as StandardMaterial;
  if (groundMat) {
    groundMat.diffuseTexture = createGroundTexture(scene);
    // Slight emissive so the bright centre of the ground doesn't go dark in shadow
    groundMat.emissiveColor = new Color3(0.06, 0.1, 0.06);
    // Retain some diffuse tinting for the light to act on
    groundMat.diffuseColor = new Color3(1, 1, 1); // use texture colour directly
    _groundMat = groundMat; // cache for per-tier lushness tinting
  }

  // 3. Subtle corner vignette — inside-facing hemisphere, dark, low alpha
  const vignetteMat = new StandardMaterial("vignette-mat", scene);
  vignetteMat.disableLighting = true;
  vignetteMat.diffuseColor = new Color3(0, 0, 0);
  vignetteMat.alpha = 0.28;
  vignetteMat.backFaceCulling = false;

  const shell = MeshBuilder.CreateSphere("vignette-shell", {
    diameter: 18,
    segments: 8,
    sideOrientation: 1, // BACKSIDE (inside faces only)
  }, scene);
  shell.position = new Vector3(0, 2, 0);
  shell.scaling.x = 1;
  shell.scaling.y = 0.5; // flatten — we want corner darkening, not a full dark dome
  shell.scaling.z = 0.8;
  shell.material = vignetteMat;
  shell.isPickable = false;
  shell.renderingGroupId = 1; // same as dog layer so it renders on top of sky

  // 4. Key light — warm directional from upper-front-left (3/4 front lighting)
  //    Gives the dog clean separation from the ground with a subtle rim/shadow.
  const keyLight = new DirectionalLight("key-light", new Vector3(-0.5, -1.2, 0.6), scene);
  keyLight.diffuse = new Color3(1.0, 0.96, 0.88);  // warm white
  keyLight.intensity = 0.7;

  // Tune the hemisphere to be a softer ambient fill (key light takes the lead)
  hemiLight.intensity = _HEMI_BASE_INTENSITY;
  hemiLight.diffuse = new Color3(0.95, 0.93, 0.85);  // cooler/softer fill
  hemiLight.groundColor = new Color3(0.42, 0.52, 0.38); // warm grass bounce

  // Cache the hemi light for tier updates
  _hemiLight = hemiLight;

  // 5. Pre-build all tier props (disabled) and apply the initial tier
  ensureTierProps(scene);
  applyBackdropTier(scene, tier);
}

/**
 * Update the backdrop to match a new kennel tier — live, no scene rebuild.
 *
 * Shows/hides the pre-built prop meshes and nudges the fill-light intensity
 * based on the tier config. Safe to call on every kennel purchase.
 *
 * @param scene  The Babylon scene (used only to ensure props exist; meshes
 *               created by setupBackdrop are reused via the module-level cache).
 * @param tier   Target tier (0–3).
 */
export function applyBackdropTier(scene: Scene, tier: 0 | 1 | 2 | 3): void {
  // Ensure the prop pool exists (no-op if setupBackdrop already called it)
  ensureTierProps(scene);

  const cfg = backdropTierConfig(tier);

  // ── Bush visibility ──────────────────────────────────────────────────────
  // Tier 1+: corner bushes
  _tierProps.get('bush-bl')?.setEnabled(cfg.bushCount >= 2);
  _tierProps.get('bush-br')?.setEnabled(cfg.bushCount >= 2);
  // Tier 2+: mid-edge bushes
  _tierProps.get('bush-ml')?.setEnabled(cfg.bushCount >= 4);
  _tierProps.get('bush-mr')?.setEnabled(cfg.bushCount >= 4);
  // Tier 3: far-back bushes
  _tierProps.get('bush-fl')?.setEnabled(cfg.bushCount >= 6);
  _tierProps.get('bush-fr')?.setEnabled(cfg.bushCount >= 6);
  _tierProps.get('bush-fc')?.setEnabled(cfg.bushCount >= 6);

  // ── Agility props (tier 2+) ──────────────────────────────────────────────
  _tierProps.get('cone-a')?.setEnabled(cfg.agilityProps);
  _tierProps.get('cone-b')?.setEnabled(cfg.agilityProps);
  _tierProps.get('jump-pole-a')?.setEnabled(cfg.agilityProps);
  _tierProps.get('jump-pole-b')?.setEnabled(cfg.agilityProps);
  _tierProps.get('jump-bar')?.setEnabled(cfg.agilityProps);

  // ── Fence line (tier 3) ──────────────────────────────────────────────────
  _tierProps.get('fence-l')?.setEnabled(cfg.fenceLine);
  _tierProps.get('fence-r')?.setEnabled(cfg.fenceLine);
  _tierProps.get('fence-c')?.setEnabled(cfg.fenceLine);

  // ── Fill-light intensity boost ───────────────────────────────────────────
  if (_hemiLight) {
    _hemiLight.intensity = _HEMI_BASE_INTENSITY + cfg.fillBoost;
  }

  // ── Ground lushness tint ───────────────────────────────────────────────────
  // Push the ground texture greener with tier by damping its red/blue channels;
  // green stays at 1 so higher tiers read as richer, greener grass.
  if (_groundMat) {
    const g = cfg.groundGreenBoost;
    _groundMat.diffuseColor = new Color3(1 - g * 1.6, 1, 1 - g * 1.2);
  }
}
