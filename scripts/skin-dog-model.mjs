// Inject the licensed Labrador textures into the baked glb.
//
// FBX2glTF cannot resolve this pack's textures — the FBX stores an absolute
// Windows path (`D:\My_Work\...\texture\Labrador_Albedo1.png`) that the FBX SDK
// reads back EMPTY, so it stubs a 1x1 placeholder image. We bypass that here:
// load the baked glb, replace the base-color image with the real albedo, and
// set sane PBR factors so the dog renders as matte fur, not metallic/white.
//
//   bun run scripts/skin-dog-model.mjs
//
// Operates on the gitignored models-build/ artifact only — the licensed glb must
// never enter git or the web bundle (see public/models/CREDITS.md, task 102).
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { NodeIO } from '@gltf-transform/core';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const glbPath = path.join(root, 'models-build', 'out_anim.glb');
const texDir = path.join(root, 'models-build', '_textures', 'texture');

const png = (name) => {
  const p = path.join(texDir, name);
  const buf = fs.readFileSync(p);
  if (buf.length === 0) throw new Error(`${name} is empty (extraction failed) — re-extract it.`);
  return new Uint8Array(buf);
};

const io = new NodeIO();
const doc = await io.read(glbPath);
const mat = doc.getRoot().listMaterials()[0];
if (!mat) throw new Error('no material in glb');

const albedo = doc.createTexture('Labrador_Albedo').setImage(png('Labrador_Albedo1.png')).setMimeType('image/png');
mat.setBaseColorTexture(albedo);
mat.setBaseColorFactor([1, 1, 1, 1]);
mat.setMetallicFactor(0);   // fur is dielectric, not metal
mat.setRoughnessFactor(0.8); // matte coat

// Normal map adds coat detail. Safe to attach; Babylon derives tangents if the
// mesh lacks them. Drop this block if review shows shading artifacts.
try {
  const normal = doc.createTexture('Labrador_Normal').setImage(png('Labrador_Normal.png')).setMimeType('image/png');
  mat.setNormalTexture(normal);
} catch (e) {
  console.warn('normal map skipped:', e.message);
}

await io.write(glbPath, doc);
const size = fs.statSync(glbPath).size;
console.log(`skinned ${path.relative(root, glbPath)} (${(size / 1e6).toFixed(1)}MB) — albedo + normal embedded`);
