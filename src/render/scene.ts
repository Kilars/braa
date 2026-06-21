import { Engine } from "@babylonjs/core/Engines/engine";
import { Scene } from "@babylonjs/core/scene";
import { Vector3 } from "@babylonjs/core/Maths/math.vector";
import { Color3, Color4 } from "@babylonjs/core/Maths/math.color";
import { ArcRotateCamera } from "@babylonjs/core/Cameras/arcRotateCamera";
import { HemisphericLight } from "@babylonjs/core/Lights/hemisphericLight";
import { MeshBuilder } from "@babylonjs/core/Meshes/meshBuilder";
import { StandardMaterial } from "@babylonjs/core/Materials/standardMaterial";
import type { RoundState } from '../core/round';
import type { MarkResult } from '../core/mark';
import { dogVisualState, DogVisualOpts } from './dogState';
import { createDogMesh } from './dogMesh';
import { dogPose } from './dogPose';
import { rewardPulse } from './rewardPulse';
import { masteryFlourish } from './masteryFlourish';
import { breedAppearance, type DogAppearance } from './dogAppearance';
import { setupBackdrop, applyBackdropTier } from './backdrop';
import { kennelTier } from './backdropTier';
import { handAnim, type RewardKind } from './handReward';
import { renderConfig, loadDogModel, loadPackedDogModel, resolveLoadState, selectDogRenderMode, devOverrideImportedDog, devOverrideLicensedDog, type DogLoadState } from './dogModelLoader';
import { resolveDogModelDescriptor } from './dogModelSource';
// NOTE: `createImportedDogMesh` is intentionally NOT imported statically — it
// pulls in PBRMaterial + the glTF material stack. It is dynamically imported
// inside the flag-gated block below so that weight lives in the lazy
// `babylon-loaders` chunk and never ships when the imported-dog flag is off.

// BASE_EMISSIVE is constant; BASE_COLOR is now derived from the breed coat at runtime.
const BASE_EMISSIVE = new Color3(0, 0, 0);
const BASE_SCALE = 1;
const BASE_Y = 0.6;

// Visual state colours
const OFFERING_COLOR = new Color3(0.9, 0.75, 0.5);      // slightly brighter warm
const OFFERING_EMISSIVE = new Color3(0.15, 0.12, 0.05);  // subtle warm glow
const OFFERING_SCALE = 1.1;

const CONFUSED_COLOR = new Color3(0.85, 0.5, 0.15);  // orange tint
const CONFUSED_EMISSIVE = new Color3(0.1, 0.04, 0);

const HAPPY_COLOR = new Color3(1.0, 0.82, 0.1);     // gold
const HAPPY_EMISSIVE = new Color3(0.25, 0.18, 0);   // warm gold glow

// Distractor: neutral grey, no apex highlight — "wrong behavior, don't mark"
const DISTRACTOR_COLOR = new Color3(0.55, 0.55, 0.55);   // flat grey
const DISTRACTOR_EMISSIVE = new Color3(0, 0, 0);          // no glow
const DISTRACTOR_SCALE = 0.9;                              // slightly smaller / withdrawn

// Misbehaving: agitated red tint — dog is doing the bad habit, do NOT mark
const MISBEHAVING_COLOR = new Color3(0.85, 0.2, 0.15);   // vivid red
const MISBEHAVING_EMISSIVE = new Color3(0.2, 0.0, 0.0);  // red glow

// Disengaged (task 107): the dog has walked off (engagement empty). A muted, cool
// blue-grey — deliberately distinct from the neutral distractor grey and the warm
// offering — reads as "withdrawn / done with you". No glow. Paired with the seated,
// back-turned pose + an edge offset below so it's tellable apart at a glance.
// A clearly COOL blue — not just desaturated — so it never collides with the
// neutral distractor grey. Reads as "withdrawn / sulking" on the warm grass.
const DISENGAGED_COLOR = new Color3(0.34, 0.41, 0.6);
const DISENGAGED_EMISSIVE = new Color3(0, 0, 0);          // no glow
// Smaller than any in-play state: a walked-off dog reads as withdrawn / farther off.
const DISENGAGED_SCALE = 0.82;
// The back-turned dog faces into the screen (rump to camera), so its on-screen
// footprint is narrow — it can sit well toward the frame edge without clipping,
// which makes the "trotted off to the side" read spatially clear.
const DISENGAGED_EDGE_X = 0.6;

// Disengage beats (task 112): the meter's escalation, tinted as a graded ramp of
// increasing withdrawal that lands on the cool DISENGAGED_COLOR — itch (warm-grey,
// barely off) → flop (cool-grey, low energy) → bark (steely cool-blue, agitated). Each
// pairs with its distinct pose in dogPose.ts; together they read at a glance on a phone.
const ITCH_COLOR = new Color3(0.62, 0.6, 0.55);      // warm grey — mildly "meh"
const ITCH_EMISSIVE = new Color3(0, 0, 0);
const FLOP_COLOR = new Color3(0.52, 0.54, 0.58);     // cool grey — bored, low energy
const FLOP_EMISSIVE = new Color3(0, 0, 0);
const BARK_COLOR = new Color3(0.45, 0.5, 0.62);      // steely cool-blue — protest/sass
const BARK_EMISSIVE = new Color3(0.05, 0.06, 0.1);   // faint cool glow — "awake / agitated"
// Subtle shrink reinforces the "pulling away" ramp toward the walked-off DISENGAGED_SCALE.
const FLOP_SCALE = 0.95;
const BARK_SCALE = 0.93;

/**
 * Creates and starts the Babylon.js placeholder scene.
 * Renders a primitive-composed dog on a simple ground.
 *
 * Returns an object with:
 *   - `updateDog(state, now)` — call each frame to reflect game state
 *   - `setBreed(breedId)` — switch the active breed coat + proportions live
 *   - `dispose()` — cleanup
 */
export function createScene(
  canvas: HTMLCanvasElement,
  initialAppearance: DogAppearance = breedAppearance('labrador'),
  initialUpgradeIds: string[] = [],
): {
  updateDog: (state: RoundState, now: number, opts?: DogVisualOpts) => void;
  setBreed: (breedId: string) => void;
  /** Register a successful mark so the dog plays a brief reward pulse. Replaces (refresh-not-stack). */
  notifyMark: (tier: MarkResult, markAt: number) => void;
  /** Register a mastery event — triggers the bigger/longer hand gesture. */
  notifyMastery: (masteryAt: number) => void;
  /** Update the backdrop tier live when kennel upgrades are purchased. */
  setKennelUpgrades: (ids: string[]) => void;
  dispose: () => void;
} {
  const engine = new Engine(canvas, true, {
    preserveDrawingBuffer: true,
    stencil: true,
  });

  const scene = new Scene(engine);
  // clearColor matches the sky horizon colour from backdrop.ts so any tiny
  // gap between the sky plane edge and the viewport edge is invisible.
  scene.clearColor = new Color4(0.82, 0.91, 0.98, 1);

  // Camera — trainer POV looking down at the dog.
  // Target raised to y=0.6 (sphere centre) so the dog sits in the middle of
  // the portrait frame rather than drifting to the upper area.
  // Beta reduced (shallower angle) so more ground shows below the dog and
  // the sky band is narrow; radius pulled in for a closer, mobile-friendly crop.
  const camera = new ArcRotateCamera(
    "camera",
    -Math.PI / 2,
    1.42,          // ~81° from vertical — sky band minimal, dog centered in portrait
    4.5,           // closer radius → dog fills more of the frame
    new Vector3(0, 0.6, 0), // target = sphere centre, not world origin
    scene,
  );
  camera.lowerRadiusLimit = 3;
  camera.upperRadiusLimit = 10;

  // Ambient hemisphere fill — intensity and colours tuned by setupBackdrop below
  const light = new HemisphericLight("light", new Vector3(0, 1, 0), scene);
  light.intensity = 1.2;
  light.diffuse = new Color3(1, 0.97, 0.9);
  light.groundColor = new Color3(0.45, 0.55, 0.4);

  // Primitive-composed dog mesh (body, head, ears, snout, legs, tail).
  // Always built synchronously — guarantees no blank frame while the optional
  // imported model loads in the background (task 078).
  //
  // `let` (not `const`) so task 079 can swap this binding to an importedDogMesh
  // once the background glb load settles. All closures below (applyVisualTint,
  // updateDog, setBreed, etc.) close over the `dog` BINDING, not its value, so
  // a single reassignment here redirects every call-site automatically.
  let dog = createDogMesh(scene, initialAppearance);
  dog.root.position.y = BASE_Y;

  // ── Imported-dog background load (flag-gated, default OFF) ────────────────
  // When renderConfig.importedDog is true (or the dev override ?importedDog=1
  // is active in DEV mode), kick off an async load of the glb while the
  // procedural dog renders immediately. The spinner (#hud-loading) is shown
  // during the load window and hidden when the load settles — success, failure,
  // or timeout.
  //
  // With the flag OFF and no dev override (the committed default): this entire
  // block is skipped and scene.ts behaves byte-for-byte identically to before
  // task 078/079.
  //
  // Dev-only Visual Review override: load with ?importedDog=1 in the URL to
  // force the imported path on without touching renderConfig.importedDog.
  // Example: http://localhost:5173/?importedDog=1
  const _devForceImported = devOverrideImportedDog();
  const MODEL_BUDGET_MS = 10_000; // 10 s timeout budget for the imported model
  if (renderConfig.importedDog || _devForceImported) {
    // Show the existing #hud-loading spinner while the model is in flight.
    // The spinner is already used for the lazy-Babylon window (task 043).
    const spinner = document.getElementById('hud-loading');
    if (spinner) spinner.style.display = '';

    let dogLoadState: DogLoadState = 'loading';
    const loadStartMs = performance.now();
    // Capture the appearance at load-kick-off time so we can pass it to
    // createImportedDogMesh when the load settles (the breed may change
    // in-flight, but we use the current appearance as the initial coat).
    const appearanceAtLoad = initialAppearance;

    // The selector resolves the model SOURCE descriptor: the CC0 placeholder (web
    // default, a plain glb URL) or the licensed Labrador (a packed/encrypted artifact
    // decrypted in memory — never a plain fetchable glb, tech-decisions §3d / task 103).
    // Flipping { allowLicensed, licensedAssetPresent } to both true is the entire swap
    // recipe (see tech-decisions §3h): the packed branch then loads the encrypted model.
    // Committed default: allowLicensed false → the CC0 plain glb. The DEV-only
    // `?licensedDog=1` override flips both inputs so the packed licensed Labrador
    // can be Visual-Reviewed locally (no effect in production — DEV guard).
    // PERSONAL-USE FLIP (temp, 2026-06-21): force the licensed packed Labrador on
    // so a plain `bun run dev` (no ?licensedDog=1) shows the real model. Revert
    // before any public ship — tech-decisions §3d. Public CI lacks dog.pack →
    // fetch 404 → graceful procedural fallback, so the deployed site stays safe.
    const _licensed = devOverrideLicensedDog() || true;
    const source = resolveDogModelDescriptor({ allowLicensed: _licensed, licensedAssetPresent: _licensed });
    const loadModel = source.kind === 'packed'
      // Licensed web path: fetch the opaque .pack, decrypt with the bundle key, and
      // load Babylon from the in-memory buffer. The key import is dynamic so the crypto
      // key stays out of the default entry chunk while this branch is dormant (flag off).
      ? (async () => {
          const [{ loadDogPackKey }, res] = await Promise.all([
            import('./dogPackKey'),
            fetch(source.url),
          ]);
          if (!res.ok) throw new Error(`packed model fetch failed: ${res.status}`);
          const packed = new Uint8Array(await res.arrayBuffer());
          return loadPackedDogModel(scene, packed, await loadDogPackKey());
        })()
      // CC0 path (committed default): plain glb URL straight into Babylon.
      : loadDogModel(scene, source.url);

    loadModel
      .then(async (loaded) => {
        dogLoadState = 'ready';

        // Apply the timeout budget retroactively to guard against an extremely
        // slow load that squeaked past the budget at the very end.
        const elapsed = performance.now() - loadStartMs;
        dogLoadState = resolveLoadState({ state: dogLoadState, elapsedMs: elapsed, budgetMs: MODEL_BUDGET_MS });

        // Use the OR of the committed flag and the dev override so the decision
        // function sees a consistent boolean — the dev override has no effect in prod.
        const flagEnabled = renderConfig.importedDog || _devForceImported;
        const mode = selectDogRenderMode({ flagEnabled, loadState: dogLoadState });

        if (mode === 'imported') {
          // ── DONE(079): swap procedural dog for the imported DogMesh ────────
          // Dynamic import so createImportedDogMesh (+ its PBRMaterial dependency)
          // stays in the lazy `babylon-loaders` chunk — never shipped when the
          // flag is off. The glTF loader chunk is already in flight from
          // loadDogModel(), so this resolves from cache without an extra round-trip.
          const { createImportedDogMesh } = await import('./importedDogMesh');

          // Build the imported dog from the loaded model. It returns the exact
          // same DogMesh interface, so every existing closure (applyVisualTint,
          // updateDog, setBreed, the render loop's dog.updateShadowX / dog.applyPose)
          // continues to work without modification.
          const importedDog = createImportedDogMesh(scene, loaded, appearanceAtLoad);
          importedDog.root.position.y = BASE_Y;

          // Dispose the procedural dog (frees its geometry + materials from VRAM)
          // and hide its root so it doesn't render even transiently.
          dog.root.getChildMeshes().forEach(m => m.dispose());
          dog.root.dispose();

          // Redirect the `dog` binding — all closures below now call importedDog.*
          // because they captured the `dog` variable, not its original value.
          dog = importedDog;
        }
        // In all other cases (including unexpected mode) the procedural dog stays.
      })
      .catch((_err) => {
        // Catch-all: load failed for any reason. Fall back to procedural silently —
        // never let a rejected promise surface uncaught to the UI.
        dogLoadState = 'failed';
        const _mode = selectDogRenderMode({ flagEnabled: renderConfig.importedDog || _devForceImported, loadState: dogLoadState });
        // mode === 'procedural' — the procedural dog already renders, nothing to do.
      })
      .finally(() => {
        // Hide the spinner regardless of outcome (ready / failed / anything).
        if (spinner) spinner.style.display = 'none';
      });

    // Belt-and-suspenders timeout: if the promise hasn't settled within the budget
    // window, resolve the state ourselves and hide the spinner so the player is
    // never stuck watching the spinner indefinitely.
    setTimeout(() => {
      if (dogLoadState === 'loading') {
        dogLoadState = resolveLoadState({ state: 'loading', elapsedMs: MODEL_BUDGET_MS + 1, budgetMs: MODEL_BUDGET_MS });
        // dogLoadState is now 'timeout' → selectDogRenderMode returns 'procedural'
        // The procedural dog is already live. Just hide the spinner.
        if (spinner) spinner.style.display = 'none';
      }
    }, MODEL_BUDGET_MS);
  }
  // ── End imported-dog block ─────────────────────────────────────────────────

  // Ground plane — material will be enhanced by setupBackdrop
  const ground = MeshBuilder.CreateGround(
    "ground",
    { width: 10, height: 10 },
    scene,
  );
  const groundMat = new StandardMaterial("ground-mat", scene);
  groundMat.diffuseColor = new Color3(0.38, 0.72, 0.38);
  ground.material = groundMat;

  // Training-ground backdrop: sky gradient + ground gradient + vignette + key light
  // Pass the initial tier so the scene boots with the correct kennel dressing.
  setupBackdrop(scene, ground as unknown as { material: StandardMaterial | null }, light, kennelTier(initialUpgradeIds));

  // ── Trainer's hand mesh ────────────────────────────────────────────────────
  // Placeholder mitt: palm box + two finger boxes + a small treat sphere, held
  // fingers/treat-up so the treat points toward the dog's muzzle.
  // The dog's head/muzzle sits at world ≈ (0.8, 0.8, 0). The hand rests off-frame
  // at the bottom-right (head side) and IN FRONT of the dog on Z (toward the
  // camera, which looks along +Z) so it is never occluded by the dog body.
  // On a trigger it rises so the treat reaches the muzzle (mark) or pats the head
  // crown (mastery), then retracts fully off-frame.
  const HAND_REST_X = 0.38;      // centre-right, under the head/chest → fully in frame at peak
  const HAND_REST_Y = -0.65;     // just below the ground plane → hidden under the horizon at rest
  const HAND_REST_Z = -0.8;      // IN FRONT of the dog (toward camera) → never occluded

  const handMat = new StandardMaterial("hand-mat", scene);
  handMat.diffuseColor = new Color3(0.95, 0.72, 0.62);   // warm skin — pinker than the tan dog so it reads
  handMat.specularColor = new Color3(0.08, 0.08, 0.08);

  const treatMat = new StandardMaterial("treat-mat", scene);
  treatMat.diffuseColor = new Color3(0.6, 0.36, 0.14);   // biscuit brown
  treatMat.emissiveColor = new Color3(0.18, 0.09, 0);    // warm glow so the reward reads

  // Palm
  const palm = MeshBuilder.CreateBox("hand-palm", { width: 0.36, height: 0.28, depth: 0.16 }, scene);
  palm.material = handMat;

  // Two finger stubs on top of palm
  const finger1 = MeshBuilder.CreateBox("hand-f1", { width: 0.10, height: 0.22, depth: 0.12 }, scene);
  finger1.material = handMat;
  finger1.parent = palm;
  finger1.position.set(-0.09, 0.25, 0);

  const finger2 = MeshBuilder.CreateBox("hand-f2", { width: 0.10, height: 0.22, depth: 0.12 }, scene);
  finger2.material = handMat;
  finger2.parent = palm;
  finger2.position.set(0.09, 0.25, 0);

  // Treat sphere held above the palm (points toward the dog's muzzle)
  const treat = MeshBuilder.CreateSphere("hand-treat", { diameter: 0.18, segments: 8 }, scene);
  treat.material = treatMat;
  treat.parent = palm;
  treat.position.set(0, 0.4, 0);

  // Park the palm at its rest position
  palm.position.set(HAND_REST_X, HAND_REST_Y, HAND_REST_Z);

  // Resize handling
  const onResize = () => engine.resize();
  window.addEventListener("resize", onResize);

  engine.runRenderLoop(() => {
    const now = performance.now();

    // ── Drive trainer's hand from handAnim ──────────────────────────────────
    // progress 0 → hand at rest (off-frame); progress 1 → hand at the dog's muzzle.
    // reach: 'mark' = 1.0 (quick treat offered at the muzzle); 'mastery' = 1.6
    // (a bigger, longer pat reaching the head crown).
    const { progress, reach } = handAnim(now, lastRewardAt, lastRewardKind, { reducedMotion });
    if (progress > 0.001) {
      palm.setEnabled(true);
      // Vertical: the hand rises out of the ground (rest Y=-0.65, hidden under the
      // horizon) so even the reduced-motion half-progress lifts the treat clear of
      // the ground plane. The PALM stays low (chest/leg level) so it never covers
      // the dog's head — only the treat reaches up to the muzzle. Mastery lifts only
      // slightly higher; its "bigger" reads via scale + its longer window (1300ms vs
      // 650ms), NOT by climbing over the face.
      //   mark    peak palm-y ≈ 0.45 (treat ≈ muzzle 0.85)
      //   mastery peak palm-y ≈ 0.52 (treat ≈ muzzle, head still fully visible)
      //   reduced (progress 0.5) still clears the ground (treat ≳ 0.3)
      const VTRAVEL = 1.1;
      const masteryLift = (reach - 1) * 0.12;
      palm.position.y = HAND_REST_Y + progress * (VTRAVEL + masteryLift);
      // Drift gently toward the head as it rises (kept in-frame — no right-edge clip)
      palm.position.x = HAND_REST_X + progress * 0.1;
      palm.position.z = HAND_REST_Z;
      // Mastery hand reads a little bigger than a per-mark treat offer; the rest of
      // the "bigger" comes from its longer 1300ms hold (vs 650ms for a mark).
      palm.scaling.setAll(1 + (reach - 1) * 0.35);
    } else {
      palm.setEnabled(false);
      palm.position.set(HAND_REST_X, HAND_REST_Y, HAND_REST_Z);
      palm.scaling.setAll(1);
    }

    // Keep blob shadow centered under the dog regardless of state
    dog.updateShadowX(dog.root.position.x);
    scene.render();
  });

  // ── Reduced-motion media query ─────────────────────────────────────────────
  // Read once; the listener updates it on change (e.g. OS setting toggled mid-session).
  // Reuses the same matchMedia mechanism as the CSS @media (prefers-reduced-motion)
  // already present in hud.css — one signal, applied consistently to both CSS and JS.
  const reducedMotionMq = window.matchMedia('(prefers-reduced-motion: reduce)');
  let reducedMotion = reducedMotionMq.matches;
  reducedMotionMq.addEventListener('change', (e) => { reducedMotion = e.matches; });

  // ── Per-mark reward pulse state ────────────────────────────────────────────
  // Stores the most recent successful mark so the render loop can apply a
  // brief additive bounce+wag pulse over the current pose. Subsequent marks
  // REPLACE (refresh-not-stack) — mirrors the confused-debuff rule in specs.
  let lastMarkTier: MarkResult = 'MISS';
  let lastMarkAt: number | null = null;

  // ── Hand reward trigger state ──────────────────────────────────────────────
  // Separate from the dog pulse — tracks the hand animation's trigger time and
  // kind. notifyMark sets kind='mark'; notifyMastery sets kind='mastery'.
  // Subsequent calls replace (refresh-not-stack) matching the pulse rule.
  let lastRewardAt: number | null = null;
  let lastRewardKind: RewardKind = 'mark';

  // ── Mastery flourish state ─────────────────────────────────────────────────
  // Separate from the hand's lastRewardAt — keyed to the dog's bigger celebratory
  // flourish (leap + happy spin + fast wag) layered over the sustained happy state.
  // Subsequent calls replace (refresh-not-stack), like the pulse rule.
  let lastMasteryAt: number | null = null;

  // ── Tint / emissive helpers ────────────────────────────────────────────────
  // Idle: call resetToBreedCoats() to restore the two-tone (coat + belly).
  // Semantic states (offering/happy/confused/distractor/misbehaving): single tint
  // overrides both materials via setTint() — two-tone collapses to one colour,
  // which is fine (the semantic hue is the signal, not the breed markings).
  function applyVisualTint(visual: ReturnType<typeof dogVisualState>): void {
    switch (visual) {
      case 'offering':
        dog.setTint(OFFERING_COLOR);
        dog.setEmissive(OFFERING_EMISSIVE);
        break;
      case 'confused':
        dog.setTint(CONFUSED_COLOR);
        dog.setEmissive(CONFUSED_EMISSIVE);
        break;
      case 'happy':
        dog.setTint(HAPPY_COLOR);
        dog.setEmissive(HAPPY_EMISSIVE);
        break;
      case 'distractor':
        dog.setTint(DISTRACTOR_COLOR);
        dog.setEmissive(DISTRACTOR_EMISSIVE);
        break;
      case 'misbehaving':
        dog.setTint(MISBEHAVING_COLOR);
        dog.setEmissive(MISBEHAVING_EMISSIVE);
        break;
      case 'disengaged':
        dog.setTint(DISENGAGED_COLOR);
        dog.setEmissive(DISENGAGED_EMISSIVE);
        break;
      case 'itch':
        dog.setTint(ITCH_COLOR);
        dog.setEmissive(ITCH_EMISSIVE);
        break;
      case 'flop':
        dog.setTint(FLOP_COLOR);
        dog.setEmissive(FLOP_EMISSIVE);
        break;
      case 'bark':
        dog.setTint(BARK_COLOR);
        dog.setEmissive(BARK_EMISSIVE);
        break;
      default:
        // idle → restore two-tone breed colours (coat + belly)
        dog.resetToBreedCoats();
        break;
    }
  }

  // ── Scale per state (tint-layer only scale, unrelated to pose bounce) ──────
  function scaleFor(visual: ReturnType<typeof dogVisualState>): number {
    switch (visual) {
      case 'offering':    return OFFERING_SCALE;
      case 'distractor':  return DISTRACTOR_SCALE;
      case 'disengaged':  return DISENGAGED_SCALE;
      case 'flop':        return FLOP_SCALE;
      case 'bark':        return BARK_SCALE;
      default:            return BASE_SCALE;
    }
  }

  // ── updateDog: pose-driven per-state visuals ───────────────────────────────
  // All motion (bounce, jitter, head-tilt, tail-wag, breathing) is computed by
  // dogPose() and applied via applyPose(). Tint/emissive/scale remain per-state.
  function updateDog(state: RoundState, now: number, opts?: DogVisualOpts): void {
    const visual = dogVisualState(state, now, opts);

    // Expose current visual state on #hud for screenshot polling / debugging.
    const hud = document.getElementById('hud');
    if (hud) hud.dataset['dog'] = visual;

    // ── Tint & emissive ──────────────────────────────────────────────────────
    // applyVisualTint handles idle (two-tone reset) vs semantic states (flat tint)
    applyVisualTint(visual);
    dog.root.scaling.setAll(scaleFor(visual));

    // ── Skeletal clip selection (imported model only, task 080) ──────────────
    // The imported Labrador plays an embedded AnimationGroup per state; the
    // procedural primitive dog has no setVisualState and is unaffected (optional
    // chaining). reducedMotion damps the clip rate, consistent with the pose path.
    dog.setVisualState?.(visual, { reducedMotion, trickId: opts?.trickId });

    // ── Pose (replaces all per-state jitter/bounce ad-hoc code) ─────────────
    // peakProximity + tellStrength are the SAME values that drive the UI apex ring
    // (computed in main.ts from the attempt's peak, passed in via opts) — one
    // source of truth keeps the on-dog apex crest and the UI gold ring in sync.
    const pose = dogPose(visual, now, {
      reducedMotion,
      peakProximity: opts?.peakProximity,
      tellStrength: opts?.tellStrength,
      trickId: opts?.trickId,
    });

    // ── Per-mark reward pulse (additive, layered over current pose) ──────────
    // rewardPulse returns 0..1 intensity; scale into small additive bounce +
    // tail-wag boost layered BEFORE applyPose so both channels are applied together.
    // PERFECT peak (1.0) → +0.10 Y bounce, +0.6 wag boost; OK (0.55) → less.
    // Cap is via the pulse math (WINDOW_MS) + the 0.12 clamp below.
    const pulseIntensity = rewardPulse(now, lastMarkAt, lastMarkTier, { reducedMotion });
    const pulseBounceY = Math.min(pulseIntensity * 0.10, 0.12);
    pose.tailWagAngle = pose.tailWagAngle + pulseIntensity * 0.6 * Math.sin(now * 0.025);

    // ── Mastery flourish (bigger leap + happy spin + fast wag) ──────────────
    // Layered additively over the sustained happy state, decaying via masteryFlourish.
    // Applied after the per-mark pulse so both stack; masteryFlourish is larger and
    // longer-lived (1200ms vs 500ms), making mastery visibly exceed a normal mark.
    const flourish = masteryFlourish(now, lastMasteryAt, { reducedMotion });
    pose.bodyYaw = (pose.bodyYaw ?? 0) + flourish.spinYaw;           // happy spin (partial yaw, not full rotation)
    pose.tailWagAngle = pose.tailWagAngle * (1 + flourish.wagBoost); // faster wag on mastery

    dog.applyPose(pose);

    // bounceY + crouchY → root Y position.
    // bounceY lifts the root (happy/misbehaving jump).
    // crouchY lowers the root toward the ground (sit/lie/settle trick poses — negative values).
    // pulseBounceY is the additive reward pulse on top (applied to position, not pose).
    // flourish.leapY is the bigger mastery leap, also applied to position.
    dog.root.position.x = 0;
    dog.root.position.y = BASE_Y + pose.bounceY + (pose.crouchY ?? 0) + pulseBounceY + flourish.leapY;

    // Distractor special case: shift root X away from trainer (body already leans)
    if (visual === 'distractor') {
      dog.root.position.x = 0.25;
      dog.root.position.y = BASE_Y - 0.05;
    } else if (visual === 'disengaged') {
      // Walked off toward the frame edge (still fully in view). Keep the seated y
      // from the pose's crouchY (already applied above) — only the lateral offset
      // changes, reading as "trotted off and sat down". The blob shadow follows
      // via updateShadowX(dog.root.position.x) in the render loop.
      dog.root.position.x = DISENGAGED_EDGE_X;
    }
  }

  return {
    updateDog,
    /** Switch the active breed — recolours and rescales the dog mesh immediately. */
    setBreed(breedId: string): void {
      dog.setAppearance(breedAppearance(breedId));
    },
    /** Register a successful mark (PERFECT or OK). Replaces any prior mark (refresh-not-stack). */
    notifyMark(tier: MarkResult, markAt: number): void {
      lastMarkTier = tier;
      lastMarkAt = markAt;
      // Also trigger the hand's treat gesture on every successful mark
      lastRewardKind = 'mark';
      lastRewardAt = markAt;
    },
    /** Register a mastery event — triggers the bigger/longer hand gesture. */
    notifyMastery(masteryAt: number): void {
      lastRewardKind = 'mastery';
      lastRewardAt = masteryAt;
      // Also kick off the dog's mastery flourish (bigger leap + happy spin + fast wag).
      // Replaces any prior masteredAt (refresh-not-stack).
      lastMasteryAt = masteryAt;
    },
    /** Update the backdrop live when kennel upgrades change. No scene rebuild. */
    setKennelUpgrades(ids: string[]): void {
      applyBackdropTier(scene, kennelTier(ids));
    },
    dispose() {
      window.removeEventListener("resize", onResize);
      engine.stopRenderLoop();
      scene.dispose();
      engine.dispose();
    },
  };
}
