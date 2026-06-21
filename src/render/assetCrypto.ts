/**
 * assetCrypto — AES-GCM pack/unpack of a binary asset, in pure Web Crypto.
 *
 * Purpose: the licensed Labrador model is served on the web behind a "pack on
 * web" stance (tech-decisions §3d, task 103). The glb is AES-GCM encrypted at
 * build time (scripts/pack-dog-model.mjs) and decrypted in memory at load time,
 * so it is never exposed as a plain, openly-`curl`-able `.glb` — which satisfies
 * the Royalty-Free license's "not redistributed in an open format" clause.
 *
 * HONEST SECURITY NOTE — this is deterrence, not DRM. The decrypt key ships in
 * the client bundle (it has to: the browser must decrypt). A determined user can
 * still recover the glb. What this DOES buy: it defeats casual raw-fetch and
 * matches the practical bar of a compiled native bundle. Documented as best-effort.
 *
 * Wire format of a packed blob (so the Node build script and the browser agree):
 *
 *     ┌──────────────┬───────────────────────────────┐
 *     │ IV (12 bytes)│ AES-256-GCM ciphertext + tag   │
 *     └──────────────┴───────────────────────────────┘
 *
 * The 12-byte IV is the standard GCM nonce length. It is randomised per call
 * (never reused with the same key) and prepended in the clear, which is safe —
 * GCM only requires the IV be unique, not secret.
 *
 * Web Crypto (`crypto.subtle`) is available both in the browser and in Node ≥ 20,
 * so the identical scheme runs at build time and at load time with no polyfill.
 */

/** GCM nonce length in bytes — the standard 96-bit IV. */
export const IV_BYTES = 12;

/** AES key length in bits (AES-256). */
export const KEY_BITS = 256;

/**
 * Copy a (possibly `SharedArrayBuffer`-backed or offset) byte view into a fresh,
 * standalone `ArrayBuffer`.
 *
 * Web Crypto's `BufferSource` parameters require an `ArrayBuffer`-backed view, but
 * a plain `Uint8Array` is typed over `ArrayBufferLike` (which includes
 * `SharedArrayBuffer`). Copying once normalises the type and guarantees the crypto
 * call sees exactly the intended bytes (no surprise offset/length).
 */
export function bytesToArrayBuffer(view: Uint8Array): ArrayBuffer {
  const buffer = new ArrayBuffer(view.byteLength);
  new Uint8Array(buffer).set(view);
  return buffer;
}

/**
 * Import raw key bytes into a non-extractable AES-GCM `CryptoKey`.
 *
 * @param rawKey 32 bytes (AES-256). Throws via Web Crypto if the length is wrong.
 */
export function importPackKey(rawKey: Uint8Array): Promise<CryptoKey> {
  return crypto.subtle.importKey(
    'raw',
    bytesToArrayBuffer(rawKey),
    { name: 'AES-GCM' },
    false, // not extractable — the imported key cannot be read back out
    ['encrypt', 'decrypt'],
  );
}

/**
 * Encrypt `plaintext` to a packed blob: `IV ‖ ciphertext+tag`.
 *
 * A fresh random IV is generated each call, so encrypting the same bytes twice
 * yields different blobs (both decrypt back to the original).
 */
export async function encryptAsset(plaintext: Uint8Array, key: CryptoKey): Promise<Uint8Array> {
  const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES));
  const cipher = new Uint8Array(
    await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, bytesToArrayBuffer(plaintext)),
  );

  const packed = new Uint8Array(IV_BYTES + cipher.length);
  packed.set(iv, 0);
  packed.set(cipher, IV_BYTES);
  return packed;
}

/**
 * Decrypt a packed blob produced by {@link encryptAsset} back to the original
 * bytes.
 *
 * Rejects (does not return garbage) when:
 *   - the blob is too short to contain an IV,
 *   - the key is wrong, or
 *   - the ciphertext/tag was tampered with (AES-GCM authentication fails).
 */
export async function decryptAsset(packed: Uint8Array, key: CryptoKey): Promise<Uint8Array> {
  if (packed.length <= IV_BYTES) {
    throw new Error('packed asset too short — missing IV or ciphertext');
  }

  const iv = bytesToArrayBuffer(packed.subarray(0, IV_BYTES));
  const cipher = bytesToArrayBuffer(packed.subarray(IV_BYTES));

  const plaintext = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, cipher);
  return new Uint8Array(plaintext);
}
