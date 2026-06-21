// Pack (AES-GCM encrypt) the licensed Labrador glb for the web build.
//
// The Dogs Big Pack Royalty-Free license permits the model inside a compiled app
// but forbids end-users extracting the raw file. On the web a plain
// /models/labrador.glb would be `curl`-able → violates that clause. Per
// tech-decisions §3d we ship the model ENCRYPTED and decrypt it in memory at load
// time (src/render/dogModelLoader.ts → loadPackedDogModel). This is deterrence,
// not DRM — the key ships in the bundle — but it defeats casual raw-fetch and
// satisfies the "not redistributed in an open format" letter of the license.
//
//   bun run scripts/pack-dog-model.mjs
//
// Input : models-build/out_anim.glb   (gitignored, textured licensed glb — task 102)
// Output: public/models/dog.pack       (gitignored — encrypted, not the raw glb)
//
// Wire format (MUST match src/render/assetCrypto.ts):
//   [ IV (12 bytes) ][ AES-256-GCM ciphertext + tag ]
//
// The key is read from src/render/dogPackKey.ts (single source of truth) so the
// artifact uses the exact key the runtime decrypts with.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const IV_BYTES = 12; // GCM nonce length — must match assetCrypto.IV_BYTES

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const glbPath = path.join(root, 'models-build', 'out_anim.glb');
const keyTsPath = path.join(root, 'src', 'render', 'dogPackKey.ts');
const outDir = path.join(root, 'public', 'models');
const outPath = path.join(outDir, 'dog.pack');

// ── Read the licensed glb ───────────────────────────────────────────────────
if (!fs.existsSync(glbPath)) {
  console.error(
    `[pack-dog-model] missing ${path.relative(root, glbPath)}.\n` +
    `Produce the textured licensed glb first (bun run scripts/skin-dog-model.mjs).`,
  );
  process.exit(1);
}
const glb = new Uint8Array(fs.readFileSync(glbPath));

// ── Extract the shared base64 key from the runtime constant (single source) ──
const keySrc = fs.readFileSync(keyTsPath, 'utf8');
const keyMatch = keySrc.match(/DOG_PACK_KEY_B64\s*=\s*['"]([A-Za-z0-9+/=]+)['"]/);
if (!keyMatch) {
  console.error(`[pack-dog-model] could not find DOG_PACK_KEY_B64 in ${path.relative(root, keyTsPath)}`);
  process.exit(1);
}
const rawKey = new Uint8Array(Buffer.from(keyMatch[1], 'base64'));
if (rawKey.length !== 32) {
  console.error(`[pack-dog-model] DOG_PACK_KEY_B64 decodes to ${rawKey.length} bytes; expected 32 (AES-256).`);
  process.exit(1);
}

// ── Encrypt: IV ‖ ciphertext+tag (identical scheme to assetCrypto.encryptAsset) ──
const key = await crypto.subtle.importKey('raw', rawKey, { name: 'AES-GCM' }, false, [
  'encrypt',
  'decrypt',
]);
const iv = crypto.getRandomValues(new Uint8Array(IV_BYTES));
const cipher = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, glb));

const packed = new Uint8Array(IV_BYTES + cipher.length);
packed.set(iv, 0);
packed.set(cipher, IV_BYTES);

// ── Self-verify the round-trip before writing (fail loud, never ship a dud) ──
const check = new Uint8Array(
  await crypto.subtle.decrypt({ name: 'AES-GCM', iv: packed.subarray(0, IV_BYTES) }, key, packed.subarray(IV_BYTES)),
);
if (check.length !== glb.length || check.some((b, i) => b !== glb[i])) {
  console.error('[pack-dog-model] self-verify FAILED — packed artifact does not decrypt to the source glb.');
  process.exit(1);
}

// ── Write the encrypted artifact (gitignored) ───────────────────────────────
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(outPath, packed);

const mib = (n) => (n / (1024 * 1024)).toFixed(2);
console.log(`[pack-dog-model] ✓ packed ${path.relative(root, glbPath)} (${mib(glb.length)} MiB)`);
console.log(`[pack-dog-model] ✓ self-verified decrypt round-trip`);
console.log(`[pack-dog-model] → ${path.relative(root, outPath)} (${mib(packed.length)} MiB, encrypted)`);
console.log('[pack-dog-model] NOTE: deterrence, not DRM — the key ships in the bundle (tech-decisions §3d).');
