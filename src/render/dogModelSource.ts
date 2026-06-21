/**
 * Single source of truth for the dog model file + the pure source selector.
 *
 * The CC0 → licensed-Labrador swap is a ONE-LINE change here (task 102): flip the
 * selector inputs once the owner delivers the texture + the PWA-license scope is
 * decided. The licensed `.glb` is only ever introduced in a license-cleared build
 * path (Capacitor/native or a pack/encrypt step) — never copied into `public/` on a
 * web build (tech-decisions §3d). See tech-decisions for the swap recipe + gate.
 */

/** CC0 placeholder dog model — web-safe to ship (no attribution/redistribution issue). */
export const DOG_MODEL_URL = `${import.meta.env.BASE_URL}models/dog.glb`;

/** Licensed Labrador model path — only present in a license-cleared build. */
const LICENSED_DOG_MODEL_URL = `${import.meta.env.BASE_URL}models/labrador.glb`;

/**
 * Packed (AES-GCM encrypted) licensed model artifact — the ONLY form the licensed
 * Labrador takes on the web build (tech-decisions §3d, task 103). It is emitted by
 * `scripts/pack-dog-model.mjs` and decrypted in memory at load time; it is NOT a
 * plain `.glb` and is deliberately not openly fetchable as an open-format model.
 */
export const PACKED_DOG_MODEL_URL = `${import.meta.env.BASE_URL}models/dog.pack`;

export interface ModelSourceInput {
  /** Build allows the licensed asset (e.g. native/Capacitor build, license cleared). */
  allowLicensed: boolean;
  /** The licensed glb is actually present in this build. */
  licensedAssetPresent: boolean;
}

/** Pick the live dog model, always falling back to the web-safe CC0 placeholder. */
export function resolveDogModelSource(
  { allowLicensed, licensedAssetPresent }: ModelSourceInput,
): string {
  return allowLicensed && licensedAssetPresent
    ? LICENSED_DOG_MODEL_URL
    : DOG_MODEL_URL;
}

/**
 * A loadable dog-model source. `kind` tells the loader HOW to consume `url`:
 *   - `'plain'`  → fetch the glb URL and hand it straight to Babylon (CC0 path).
 *   - `'packed'` → fetch the encrypted artifact, decrypt it in memory, then load
 *     into Babylon from the decrypted buffer (licensed web path — never a plain glb).
 */
export type DogModelDescriptor =
  | { kind: 'plain'; url: string }
  | { kind: 'packed'; url: string };

/**
 * Resolve the dog-model source as a descriptor the loader can act on.
 *
 * Mirrors {@link resolveDogModelSource}'s gating, but returns the richer shape the
 * runtime needs to choose between the plain-fetch and decrypt-in-memory load paths.
 * The CC0 fallback is always a plain glb; only the licensed-and-present web path
 * returns the packed (encrypted) descriptor.
 */
export function resolveDogModelDescriptor(
  { allowLicensed, licensedAssetPresent }: ModelSourceInput,
): DogModelDescriptor {
  return allowLicensed && licensedAssetPresent
    ? { kind: 'packed', url: PACKED_DOG_MODEL_URL }
    : { kind: 'plain', url: DOG_MODEL_URL };
}
