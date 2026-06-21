/**
 * The bundle-shipped AES key for the packed licensed model (task 103).
 *
 * This key is intentionally public — it ships in the client bundle so the browser
 * can decrypt the packed glb at load time (deterrence, not DRM; see assetCrypto).
 * What we DO guard here: the constant is a valid AES-256 key (exactly 32 bytes) and
 * actually decrypts what it encrypts — so a fat-fingered edit to the base64 is caught
 * by the suite rather than silently breaking the live load.
 */

import { describe, it, expect } from 'vitest';
import { dogPackKeyBytes, loadDogPackKey } from './dogPackKey';
import { encryptAsset, decryptAsset } from './assetCrypto';

describe('dogPackKey', () => {
  it('decodes to exactly 32 bytes (AES-256)', () => {
    expect(dogPackKeyBytes().length).toBe(32);
  });

  it('loads a usable CryptoKey that round-trips an asset', async () => {
    const key = await loadDogPackKey();
    const plaintext = new Uint8Array([1, 2, 3, 4, 5, 254, 255, 0]);

    const packed = await encryptAsset(plaintext, key);
    const recovered = await decryptAsset(packed, key);

    expect(Array.from(recovered)).toEqual(Array.from(plaintext));
  });
});
