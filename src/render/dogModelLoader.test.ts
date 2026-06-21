import { describe, it, expect } from 'vitest';
import {
  selectDogRenderMode,
  resolveLoadState,
  packedToGlbFile,
  type DogLoadState,
} from './dogModelLoader';
import { encryptAsset, importPackKey } from './assetCrypto';

describe('selectDogRenderMode', () => {
  it('returns procedural when the imported-dog flag is off, regardless of load state', () => {
    expect(selectDogRenderMode({ flagEnabled: false, loadState: 'ready' })).toBe('procedural');
  });

  it('returns imported when the flag is on and the model has loaded (ready)', () => {
    expect(selectDogRenderMode({ flagEnabled: true, loadState: 'ready' })).toBe('imported');
  });

  // Fallback is mandatory: with the flag on but the load not cleanly ready, the
  // dog must still render procedurally — never a blank scene.
  it.each<DogLoadState>(['idle', 'loading', 'failed', 'timeout'])(
    'falls back to procedural when the flag is on but load state is %s',
    (loadState) => {
      expect(selectDogRenderMode({ flagEnabled: true, loadState })).toBe('procedural');
    },
  );
});

describe('resolveLoadState (timeout budget)', () => {
  it('promotes a still-loading state to timeout once elapsed exceeds the budget', () => {
    expect(resolveLoadState({ state: 'loading', elapsedMs: 5001, budgetMs: 5000 })).toBe('timeout');
  });

  it('keeps a still-loading state while within the budget', () => {
    expect(resolveLoadState({ state: 'loading', elapsedMs: 5000, budgetMs: 5000 })).toBe('loading');
  });

  it('passes non-loading states through unchanged regardless of elapsed time', () => {
    expect(resolveLoadState({ state: 'ready', elapsedMs: 9999, budgetMs: 5000 })).toBe('ready');
    expect(resolveLoadState({ state: 'failed', elapsedMs: 9999, budgetMs: 5000 })).toBe('failed');
  });
});

// ---------------------------------------------------------------------------
// packedToGlbFile — decrypt a packed artifact into an in-memory Babylon source
// ---------------------------------------------------------------------------
// This is the decrypt-in-memory entry point for the licensed web path (task 103):
// given the fetched packed bytes + the bundle key, it must recover the EXACT glb
// bytes and wrap them in an in-memory File (no fetchable URL). The subsequent
// ImportMeshAsync(file, scene) is render glue covered by Visual Review.
describe('packedToGlbFile', () => {
  // A stand-in "glb" payload — we only assert byte-fidelity, not glTF validity.
  const fakeGlb = () => {
    const bytes = new Uint8Array(512);
    for (let i = 0; i < bytes.length; i++) bytes[i] = (i * 17 + 3) & 0xff;
    // glTF binary magic so the payload looks plausible ("glTF" little-endian).
    bytes.set([0x67, 0x6c, 0x54, 0x46], 0);
    return bytes;
  };

  it('recovers the exact glb bytes from a packed artifact and yields an in-memory .glb File', async () => {
    const key = await importPackKey(crypto.getRandomValues(new Uint8Array(32)));
    const glb = fakeGlb();
    const packed = await encryptAsset(glb, key);

    const file = await packedToGlbFile(packed, key);

    // It is a real in-memory File (no URL involved), named as a glb binary.
    expect(file).toBeInstanceOf(File);
    expect(file.name).toMatch(/\.glb$/);
    expect(file.type).toBe('model/gltf-binary');

    // Byte-for-byte fidelity with the original glb.
    const recovered = new Uint8Array(await file.arrayBuffer());
    expect(Array.from(recovered)).toEqual(Array.from(glb));
  });

  it('rejects when the key cannot decrypt the artifact (no silent passthrough)', async () => {
    const key = await importPackKey(crypto.getRandomValues(new Uint8Array(32)));
    const wrongKey = await importPackKey(crypto.getRandomValues(new Uint8Array(32)));
    const packed = await encryptAsset(fakeGlb(), key);

    await expect(packedToGlbFile(packed, wrongKey)).rejects.toBeTruthy();
  });
});
