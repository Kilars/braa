/**
 * TDD tests for assetCrypto — AES-GCM pack/unpack of a binary asset.
 *
 * This is the pure crypto core behind the licensed-Labrador "pack on web"
 * distribution stance (tech-decisions §3d, task 103). The model glb is encrypted
 * at build time and decrypted in memory at load time so it is never served as a
 * plain, openly-fetchable file.
 *
 * Honest security note (tested as such): the key ships in the client bundle, so
 * this is deterrence, not DRM. The contract we DO guarantee and test:
 *   - decrypt(encrypt(bytes)) === bytes  (lossless round-trip)
 *   - a wrong key rejects (cannot recover plaintext)
 *   - a tampered blob rejects (AES-GCM auth tag fails)
 *   - the packed output is not the plaintext (no accidental passthrough)
 *
 * Web Crypto is used so the exact same scheme runs in the browser at load time
 * and in the Node build script (scripts/pack-dog-model.mjs).
 */

import { describe, it, expect } from 'vitest';
import { encryptAsset, decryptAsset, importPackKey } from './assetCrypto';

/** A fresh random 32-byte (AES-256) key as a CryptoKey. */
async function randomKey() {
  return importPackKey(crypto.getRandomValues(new Uint8Array(32)));
}

/** Deterministic, non-trivial plaintext that includes a 0x00 and high bytes. */
function samplePlaintext() {
  const n = 1024;
  const bytes = new Uint8Array(n);
  for (let i = 0; i < n; i++) bytes[i] = (i * 31 + 7) & 0xff;
  return bytes;
}

describe('encryptAsset / decryptAsset round-trip', () => {
  it('decrypt(encrypt(bytes)) returns the original bytes', async () => {
    const key = await randomKey();
    const plaintext = samplePlaintext();

    const packed = await encryptAsset(plaintext, key);
    const recovered = await decryptAsset(packed, key);

    expect(Array.from(recovered)).toEqual(Array.from(plaintext));
  });

  it('round-trips an empty payload', async () => {
    const key = await randomKey();
    const packed = await encryptAsset(new Uint8Array(0), key);
    const recovered = await decryptAsset(packed, key);
    expect(recovered.length).toBe(0);
  });

  it('packed output is not the plaintext (it is actually encrypted)', async () => {
    const key = await randomKey();
    const plaintext = samplePlaintext();
    const packed = await encryptAsset(plaintext, key);

    // Packed is longer (IV + GCM tag) and its body does not equal the plaintext.
    expect(packed.length).toBeGreaterThan(plaintext.length);
    expect(Array.from(packed.subarray(0, plaintext.length))).not.toEqual(
      Array.from(plaintext),
    );
  });

  it('uses a fresh IV each call (two encryptions differ, both decrypt back)', async () => {
    const key = await randomKey();
    const plaintext = samplePlaintext();

    const a = await encryptAsset(plaintext, key);
    const b = await encryptAsset(plaintext, key);

    expect(Array.from(a)).not.toEqual(Array.from(b)); // different IV → different blob
    expect(Array.from(await decryptAsset(a, key))).toEqual(Array.from(plaintext));
    expect(Array.from(await decryptAsset(b, key))).toEqual(Array.from(plaintext));
  });
});

describe('decryptAsset rejection cases', () => {
  it('rejects when the key is wrong', async () => {
    const key = await randomKey();
    const wrongKey = await randomKey();
    const packed = await encryptAsset(samplePlaintext(), key);

    await expect(decryptAsset(packed, wrongKey)).rejects.toBeTruthy();
  });

  it('rejects when the packed blob has been tampered with', async () => {
    const key = await randomKey();
    const packed = await encryptAsset(samplePlaintext(), key);

    // Flip a byte in the ciphertext region (past the 12-byte IV).
    const tampered = packed.slice();
    tampered[tampered.length - 1] ^= 0xff;

    await expect(decryptAsset(tampered, key)).rejects.toBeTruthy();
  });

  it('rejects a truncated blob that is too short to contain an IV', async () => {
    const key = await randomKey();
    await expect(decryptAsset(new Uint8Array(4), key)).rejects.toBeTruthy();
  });
});
