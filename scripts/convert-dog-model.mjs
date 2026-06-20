// Convert the licensed Dogs Big Pack Labrador (Labrador_FBX.rar) → glb.
//
// Headless, no sudo, no Blender. Resolves the FBX→glb step that gated the
// Pokémon-GO Visuals epic (see .docs/tech-decisions.md §3e).
//
// Why this exists: system `7z` (even 24.08) CANNOT decode this RAR — it is RAR5
// with RAR-7.x compression (method v6) and silently writes 0-byte files. Use the
// WASM unRAR (`node-unrar-js`) instead. The `fbx2gltf` npm package ships a prebuilt
// Linux binary that does the actual conversion.
//
// One-time dev deps (NOT in package.json — licensed-asset tooling, installed ad hoc):
//   npm i node-unrar-js fbx2gltf
// Then:
//   node scripts/convert-dog-model.mjs
//
// Outputs (gitignored — the licensed asset must not enter git):
//   models-build/out_anim.glb   rigged mesh + 113 clips (from Labrador_anim_IP.fbx)
//   models-build/out_base.glb   rigged mesh, no clips  (from Labrador.fbx)
//
// NOTE: the pack's albedo texture (Labrador_Albedo1.png) is missing from the .rar,
// so the glb is currently untextured (white). Supply the texture folder to skin it.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const rar = path.join(root, 'Labrador_FBX.rar');
const outDir = path.join(root, 'models-build');
const tmpDir = path.join(outDir, '_fbx');

const SOURCES = [
  { fbx: 'Labrador_anim_IP.fbx', out: 'out_anim.glb' }, // animated, in-place
  { fbx: 'Labrador.fbx', out: 'out_base.glb' }, // static base mesh
];

async function main() {
  if (!fs.existsSync(rar)) throw new Error(`Missing ${rar} (the licensed Labrador drop).`);
  fs.mkdirSync(tmpDir, { recursive: true });

  const { createExtractorFromData } = await import('node-unrar-js').catch(() => {
    throw new Error('Run `npm i node-unrar-js fbx2gltf` first (dev-only conversion deps).');
  });
  const convert = (await import('fbx2gltf')).default;

  const data = new Uint8Array(fs.readFileSync(rar)).buffer;
  const extractor = await createExtractorFromData({ data });
  const want = SOURCES.map((s) => s.fbx);
  const extracted = extractor.extract({ files: want });
  for (const file of extracted.files) {
    if (!file.extraction) continue;
    fs.writeFileSync(path.join(tmpDir, path.basename(file.fileHeader.name)), Buffer.from(file.extraction));
  }

  for (const { fbx, out } of SOURCES) {
    const src = path.join(tmpDir, fbx);
    const dest = path.join(outDir, out);
    await convert(src, dest, ['--binary', '--anim-framerate', 'bake30']);
    console.log(`wrote ${path.relative(root, dest)} (${fs.statSync(dest).size} bytes)`);
  }
  console.log('Done. See .docs/tech-decisions.md §3e for staging + the missing-texture note.');
}

main().catch((e) => {
  console.error(String(e.message || e));
  process.exit(1);
});
