import { describe, it, expect } from 'vitest';
import {
  DOG_MODEL_URL,
  PACKED_DOG_MODEL_URL,
  resolveDogModelSource,
  resolveDogModelDescriptor,
} from './dogModelSource';

describe('DOG_MODEL_URL', () => {
  it('is a non-empty string ending in .glb', () => {
    expect(DOG_MODEL_URL).toBeDefined();
    expect(typeof DOG_MODEL_URL).toBe('string');
    expect(DOG_MODEL_URL.length).toBeGreaterThan(0);
    expect(DOG_MODEL_URL).toMatch(/\.glb$/);
  });
});

describe('resolveDogModelSource', () => {
  it('returns DOG_MODEL_URL when allowLicensed is false (regardless of licensedAssetPresent)', () => {
    const resultWithoutAsset = resolveDogModelSource({
      allowLicensed: false,
      licensedAssetPresent: false,
    });
    expect(resultWithoutAsset).toBe(DOG_MODEL_URL);

    const resultWithAsset = resolveDogModelSource({
      allowLicensed: false,
      licensedAssetPresent: true,
    });
    expect(resultWithAsset).toBe(DOG_MODEL_URL);
  });

  it('returns DOG_MODEL_URL (CC0 fallback) when allowLicensed is true but licensedAssetPresent is false', () => {
    const result = resolveDogModelSource({
      allowLicensed: true,
      licensedAssetPresent: false,
    });
    expect(result).toBe(DOG_MODEL_URL);
    expect(result.length).toBeGreaterThan(0);
  });

  it('returns a licensed model path (different from DOG_MODEL_URL, ending in .glb) when allowLicensed and licensedAssetPresent are both true', () => {
    const result = resolveDogModelSource({
      allowLicensed: true,
      licensedAssetPresent: true,
    });
    expect(result).not.toBe(DOG_MODEL_URL);
    expect(result.length).toBeGreaterThan(0);
    expect(result).toMatch(/\.glb$/);
  });
});

describe('resolveDogModelDescriptor', () => {
  /**
   * The descriptor is what the loader actually consumes (task 103). It carries a
   * `kind` so the loader knows whether to fetch a plain glb URL or to fetch the
   * encrypted artifact and decrypt it in memory:
   *   - CC0 / fallback → { kind: 'plain', url: '/models/dog.glb' }
   *   - licensed+present (web) → { kind: 'packed', url: '/models/dog.pack' }
   * The licensed glb is NEVER exposed as a plain, openly-fetchable file on web.
   */

  it('returns a plain CC0 descriptor when allowLicensed is false', () => {
    expect(
      resolveDogModelDescriptor({ allowLicensed: false, licensedAssetPresent: false }),
    ).toEqual({ kind: 'plain', url: DOG_MODEL_URL });

    expect(
      resolveDogModelDescriptor({ allowLicensed: false, licensedAssetPresent: true }),
    ).toEqual({ kind: 'plain', url: DOG_MODEL_URL });
  });

  it('returns a plain CC0 descriptor when allowLicensed but the asset is absent', () => {
    expect(
      resolveDogModelDescriptor({ allowLicensed: true, licensedAssetPresent: false }),
    ).toEqual({ kind: 'plain', url: DOG_MODEL_URL });
  });

  it('returns a packed descriptor (not a plain .glb) when allowLicensed and present', () => {
    const descriptor = resolveDogModelDescriptor({
      allowLicensed: true,
      licensedAssetPresent: true,
    });
    expect(descriptor.kind).toBe('packed');
    expect(descriptor.url).toBe(PACKED_DOG_MODEL_URL);
    // The packed path must NOT be served as an openly-fetchable plain glb.
    expect(descriptor.url).not.toMatch(/\.glb$/);
    expect(descriptor.url).not.toBe(DOG_MODEL_URL);
  });
});
