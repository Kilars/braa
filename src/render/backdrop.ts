import {
  Color3,
  DynamicTexture,
  MeshBuilder,
  StandardMaterial,
  type Scene,
} from '@babylonjs/core'

/**
 * The cheap, bright Pokémon-GO-style training ground (tech-decisions §2b): a
 * gradient sky back-plane and a radial-gradient grass disc, both drawn from
 * `DynamicTexture`s painted once at setup. No skybox, no post-processing, no
 * shadow map — just two extra unlit quads, safe on mobile (spec P1-1, X-4).
 *
 * The far edge of the ground is tuned to meet the sky horizon colour so there is
 * no hard seam, and the eye is pulled to the centre (where the dog sits) by the
 * radial falloff.
 */

const SKY_TOP = '#3f7fe0' // richer blue overhead
const SKY_HORIZON = '#cfe7fb' // pale haze at the horizon
const GRASS_CENTRE = '#86d36a' // vivid grass under the dog
const GRASS_EDGE = '#cfe7fb' // fades to the sky colour at the rim

export function setupBackdrop(scene: Scene): void {
  scene.clearColor = Color3.FromHexString(SKY_HORIZON).toColor4(1)

  // --- Sky: a tall back-plane with a vertical gradient, behind everything. ---
  const sky = MeshBuilder.CreatePlane('sky', { width: 40, height: 40 }, scene)
  sky.position.set(0, 6, 16)
  sky.isPickable = false
  sky.renderingGroupId = 0

  const skyTex = new DynamicTexture(
    'skyTex',
    { width: 8, height: 512 },
    scene,
    false,
  )
  const skyCtx = skyTex.getContext() as CanvasRenderingContext2D
  const skyGrad = skyCtx.createLinearGradient(0, 0, 0, 512)
  skyGrad.addColorStop(0, SKY_TOP)
  skyGrad.addColorStop(1, SKY_HORIZON)
  skyCtx.fillStyle = skyGrad
  skyCtx.fillRect(0, 0, 8, 512)
  skyTex.update()

  const skyMat = new StandardMaterial('skyMat', scene)
  skyMat.diffuseTexture = skyTex
  skyMat.emissiveTexture = skyTex // unlit: show the painted colour directly
  skyMat.disableLighting = true
  skyMat.specularColor = new Color3(0, 0, 0)
  skyMat.backFaceCulling = false
  sky.material = skyMat

  // --- Ground: a radial grass disc, bright at centre, fading to the horizon. ---
  const ground = MeshBuilder.CreateGround(
    'ground',
    { width: 24, height: 24, subdivisions: 1 },
    scene,
  )
  ground.position.y = 0
  ground.isPickable = false

  const grassTex = new DynamicTexture(
    'grassTex',
    { width: 512, height: 512 },
    scene,
    true,
  )
  const gCtx = grassTex.getContext() as CanvasRenderingContext2D
  const radial = gCtx.createRadialGradient(256, 256, 24, 256, 256, 300)
  radial.addColorStop(0, GRASS_CENTRE)
  radial.addColorStop(1, GRASS_EDGE)
  gCtx.fillStyle = radial
  gCtx.fillRect(0, 0, 512, 512)
  grassTex.update()

  const groundMat = new StandardMaterial('groundMat', scene)
  groundMat.diffuseTexture = grassTex
  groundMat.specularColor = new Color3(0.05, 0.08, 0.05)
  ground.material = groundMat
  ground.renderingGroupId = 0

  // Static backdrop: freeze world matrices so they cost nothing per frame.
  sky.freezeWorldMatrix()
  ground.freezeWorldMatrix()
}
