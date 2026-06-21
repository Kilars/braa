/**
 * dogPackKey — the AES-256 key used to pack/unpack the licensed dog model.
 *
 * ⚠️ Intentionally public. This key ships in the client bundle because the browser
 * must decrypt the packed glb at load time. That makes the scheme DETERRENCE, not
 * DRM (see assetCrypto.ts): it defeats casual raw-`curl` of an open-format `.glb`
 * and satisfies the Royalty-Free license's "not redistributed in an open format"
 * clause (tech-decisions §3d), but a determined user can still recover the model.
 *
 * Single source of truth: the Node build script (scripts/pack-dog-model.mjs) reads
 * THIS base64 string so the artifact it encrypts uses the exact key the runtime
 * decrypts with. Keep `DOG_PACK_KEY_B64` on one line — the script extracts it by
 * regex rather than executing TypeScript.
 */

import { importPackKey } from './assetCrypto';

/** Base64-encoded 32-byte (AES-256) key. Shared with scripts/pack-dog-model.mjs. */
export const DOG_PACK_KEY_B64 = 'l2+1W6NliXP3sO/MQI9cSR71xelCNYF5wSRGObyIWsc=';

/** Decode {@link DOG_PACK_KEY_B64} into its raw 32 key bytes (works in browser + Node). */
export function dogPackKeyBytes(): Uint8Array {
  const binary = atob(DOG_PACK_KEY_B64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

/** Import the bundle key as an AES-GCM `CryptoKey` for decrypting the packed model. */
export function loadDogPackKey(): Promise<CryptoKey> {
  return importPackKey(dogPackKeyBytes());
}
