/**
 * Dog model load path + the pure render-mode decision.
 *
 * Part of the Pokémon-GO Visuals epic (task 078). The whole point of this module
 * is to let us migrate the dog to an imported, rigged glTF model *behind a flag*
 * while ALWAYS keeping the procedural dog as a guaranteed fallback — so the app is
 * never broken while the asset pipeline matures.
 *
 * The decision (`selectDogRenderMode`) is a PURE function, unit-tested here. The
 * actual `ImportMeshAsync`/`SceneLoader` glue lives in `loadDogModel()` below —
 * render glue, covered by Visual Review (task 078/079).
 */

import type { Scene } from '@babylonjs/core/scene';
import type { AbstractMesh } from '@babylonjs/core/Meshes/abstractMesh';
import type { Skeleton } from '@babylonjs/core/Bones/skeleton';
import type { AnimationGroup } from '@babylonjs/core/Animations/animationGroup';
import { decryptAsset, bytesToArrayBuffer } from './assetCrypto';

/** Result returned by a successful `loadDogModel` call. */
export interface DogModelResult {
  meshes: AbstractMesh[];
  skeletons: Skeleton[];
  animationGroups: AnimationGroup[];
}

/** Filename handed to Babylon so its glTF plugin loads the buffer as binary glb. */
const IN_MEMORY_GLB_NAME = 'dog.glb';
/** MIME type of a binary glTF (`.glb`) payload. */
const GLB_MIME = 'model/gltf-binary';

/**
 * Lazily load the glTF/glb dog model from `url`.
 *
 * The `@babylonjs/loaders` glTF plugin is imported **dynamically** so it stays
 * in its own lazy chunk and does not bloat the entry bundle (consistent with the
 * code-split pattern used for Babylon core in tasks 036/040).
 *
 * - On success: resolves with `{ meshes, skeletons, animationGroups }`.
 * - On any failure (network, parse, etc.): **rejects** so the caller can catch it
 *   and treat it as `'failed'` — never throws uncaught to the UI.
 *
 * The caller is responsible for managing load state via `DogLoadState` and
 * falling back to the procedural dog via `selectDogRenderMode`.
 */
/**
 * Import a dog glb at its true REST pose, with the glTF loader's animation
 * auto-start DISABLED, and return the `DogModelResult`.
 *
 * Babylon's glTF loader otherwise auto-plays the FIRST embedded clip on load. For
 * some rigs that first clip is a non-rest pose — e.g. the CC0 rig's `Death` clip,
 * which sprawls the dog flat — and `createImportedDogMesh`'s
 * `refreshBoundingInfo({ applySkeleton: true })` then bakes that sprawled pose into
 * the framing bounds, yielding a wildly wrong fit scale + a corrupted bind-pose
 * snapshot (the "exploded dog" regression, task 080 Visual Review). Forcing
 * `animationStartMode = NONE` means bounds and the bind-pose snapshot are both taken
 * at the authored rest pose for ANY rig; `createImportedDogMesh` then explicitly
 * starts the per-state clip itself.
 *
 * The mode is set via a scoped `OnPluginActivatedObservable` hook (added before the
 * import, removed in `finally`) so it only affects this one load.
 */
async function importDogModelAtRest(scene: Scene, source: string | File): Promise<DogModelResult> {
  // Lazy / dynamic import — keeps the glTF loader out of the entry chunk so the
  // initial bundle is unaffected when the flag is off (default). This import lands
  // in its own lazy chunk at build time (Vite splits dynamic imports).
  const [{ ImportMeshAsync, SceneLoader }, { GLTFLoaderAnimationStartMode }] = await Promise.all([
    import('@babylonjs/core/Loading/sceneLoader'),
    import('@babylonjs/loaders/glTF'),   // side-effect: registers the glTF plugin
  ]);

  const observer = SceneLoader.OnPluginActivatedObservable.add((loader) => {
    if (loader.name === 'gltf') {
      (loader as unknown as { animationStartMode: number })
        .animationStartMode = GLTFLoaderAnimationStartMode.NONE;
    }
  });

  try {
    const result = await ImportMeshAsync(source, scene);
    return {
      meshes: result.meshes,
      skeletons: result.skeletons,
      animationGroups: result.animationGroups,
    };
  } finally {
    SceneLoader.OnPluginActivatedObservable.remove(observer);
  }
}

export async function loadDogModel(scene: Scene, url: string): Promise<DogModelResult> {
  return importDogModelAtRest(scene, url);
}

/**
 * Decrypt a packed (AES-GCM) model artifact into an in-memory `File` that Babylon
 * can load directly — the licensed web path's decrypt-in-memory step (task 103).
 *
 * The licensed glb is NEVER written to disk or exposed at a fetchable URL: we hand
 * Babylon a `File` built from the decrypted bytes, and its glTF plugin reads the
 * binary from memory (the `.glb` name tells the plugin which loader to use). The
 * file is named `dog.glb` purely so the extension routes it to the glb loader;
 * nothing serves it.
 *
 * Rejects (rather than returning a corrupt source) if the key cannot decrypt the
 * artifact — AES-GCM authentication failure propagates straight out.
 *
 * @param packed the fetched packed bytes (`IV ‖ ciphertext+tag`, see assetCrypto)
 * @param key    the AES-GCM key (shipped in the bundle — deterrence, not DRM)
 */
export async function packedToGlbFile(packed: Uint8Array, key: CryptoKey): Promise<File> {
  const glbBytes = await decryptAsset(packed, key);
  // Normalise into a standalone ArrayBuffer so the File owns exactly the glb bytes
  // (decryptAsset may return a view over a larger buffer).
  const buffer = bytesToArrayBuffer(glbBytes);
  return new File([buffer], IN_MEMORY_GLB_NAME, { type: GLB_MIME });
}

/**
 * Load the licensed dog model from a packed artifact, fully in memory.
 *
 * Mirrors {@link loadDogModel} but takes the encrypted bytes + key instead of a
 * URL: decrypt → wrap in a `File` → hand to Babylon's glTF loader. No plaintext
 * glb ever touches disk, `public/`, or a fetchable URL.
 *
 * - On success: resolves with `{ meshes, skeletons, animationGroups }`.
 * - On any failure (wrong key, tampered blob, parse error): **rejects** so the
 *   caller can fall back to the procedural dog exactly as with `loadDogModel`.
 */
export async function loadPackedDogModel(
  scene: Scene,
  packed: Uint8Array,
  key: CryptoKey,
): Promise<DogModelResult> {
  // Decrypt first so a bad key fails fast before we pay for the loader chunk.
  const file = await packedToGlbFile(packed, key);
  // Same rest-pose import as the plain path: never auto-start the first clip, so the
  // licensed rig is framed + bind-pose-snapshotted at rest (task 080).
  return importDogModelAtRest(scene, file);
}

/**
 * Imported-dog feature flag. **Default OFF this phase.**
 *
 * The imported render path is gated on a staged `.glb` (task 077 — owner purchase
 * gate) plus its loader glue + scene wiring + Visual Review (task 079). Flip
 * `importedDog` to `true` only once that model lands and the Labrador slice passes
 * Visual Review; until then the app renders the procedural dog exactly as today.
 */
export const renderConfig: { importedDog: boolean } = {
  // PERSONAL-USE FLIP (temp, 2026-06-21): imported path ON. Revert before any
  // public ship — licensed web-extraction clause still open (tech-decisions §3d).
  importedDog: true,
};

/**
 * Returns true if the dev URL override `?importedDog=1` is active.
 *
 * Lives in this lightweight, eagerly-imported module (not in `importedDogMesh.ts`)
 * so `scene.ts` can decide whether to enter the imported path WITHOUT statically
 * importing `importedDogMesh` — that module pulls in `PBRMaterial` + the glTF
 * material stack, which must stay in the lazy `babylon-loaders` chunk.
 *
 * Always returns false in production (import.meta.env.DEV guard); this is purely a
 * dev-time Visual Review convenience. Load: http://localhost:5173/?importedDog=1
 */
export function devOverrideImportedDog(): boolean {
  if (!import.meta.env.DEV) return false;
  try {
    return new URLSearchParams(location.search).get('importedDog') === '1';
  } catch {
    return false;
  }
}

/**
 * Returns true if the dev URL override `?licensedDog=1` is active.
 *
 * Routes the imported-dog load through the LICENSED, packed/encrypted descriptor
 * (resolveDogModelDescriptor with allowLicensed+present → `{ kind: 'packed' }`),
 * so the real Labrador can be Visual-Reviewed without flipping any committed
 * default. Combine with `?importedDog=1` and a packed artifact in public/models/:
 *   1. bun run pack-dog-model            (emits public/models/dog.pack)
 *   2. open /?importedDog=1&licensedDog=1 (DEV only)
 *
 * Always false in production (import.meta.env.DEV guard) — the committed web build
 * never serves the licensed asset until the swap is intentionally enabled.
 */
export function devOverrideLicensedDog(): boolean {
  if (!import.meta.env.DEV) return false;
  try {
    return new URLSearchParams(location.search).get('licensedDog') === '1';
  } catch {
    return false;
  }
}

/** Lifecycle of the imported-model load attempt. */
export type DogLoadState = 'idle' | 'loading' | 'ready' | 'failed' | 'timeout';

/** Which dog implementation the scene should build. */
export type DogRenderMode = 'imported' | 'procedural';

export interface RenderModeInput {
  /** Feature flag — is the imported-dog path enabled at all? Default OFF this phase. */
  flagEnabled: boolean;
  /** Current state of the async model load. */
  loadState: DogLoadState;
}

/**
 * Decide whether to render the imported model or fall back to the procedural dog.
 *
 * Fallback is mandatory: only a flag-enabled, cleanly-`ready` load yields
 * `'imported'`. Everything else — flag off, still loading, failed, or timed out —
 * yields `'procedural'` so the dog is always playable.
 */
export function selectDogRenderMode({ flagEnabled, loadState }: RenderModeInput): DogRenderMode {
  return flagEnabled && loadState === 'ready' ? 'imported' : 'procedural';
}

export interface TimeoutInput {
  /** Current raw load state. */
  state: DogLoadState;
  /** Milliseconds elapsed since the load began. */
  elapsedMs: number;
  /** Milliseconds we are willing to wait before giving up on the imported model. */
  budgetMs: number;
}

/**
 * Convert a still-`loading` state into `timeout` once it has outrun its budget,
 * so the scene can fall back to the procedural dog instead of waiting forever.
 * Any non-`loading` state passes through unchanged.
 */
export function resolveLoadState({ state, elapsedMs, budgetMs }: TimeoutInput): DogLoadState {
  if (state === 'loading' && elapsedMs > budgetMs) return 'timeout';
  return state;
}
