/**
 * Dog model load path + the pure render-mode decision.
 *
 * Part of the Pokémon-GO Visuals epic (task 078). The whole point of this module
 * is to let us migrate the dog to an imported, rigged glTF model *behind a flag*
 * while ALWAYS keeping the procedural dog as a guaranteed fallback — so the app is
 * never broken while the asset pipeline matures.
 *
 * The decision (`selectDogRenderMode`) is a PURE function, unit-tested here. The
 * actual `ImportMeshAsync`/`SceneLoader` glue + scene wiring is render glue covered
 * by Visual Review and is blocked on a concrete `.glb` (task 077, owner gate).
 */

/**
 * Imported-dog feature flag. **Default OFF this phase.**
 *
 * The imported render path is gated on a staged `.glb` (task 077 — owner purchase
 * gate) plus its loader glue + scene wiring + Visual Review (task 079). Flip
 * `importedDog` to `true` only once that model lands and the Labrador slice passes
 * Visual Review; until then the app renders the procedural dog exactly as today.
 */
export const renderConfig: { importedDog: boolean } = {
  importedDog: false,
};

/** Lifecycle of the imported-model load attempt. */
export type DogLoadState = 'idle' | 'loading' | 'ready' | 'failed' | 'timeout';

/** Which dog implementation the scene should build. */
export type DogRenderMode = 'imported' | 'procedural';

export interface RenderModeInput {
  /** Feature flag — is the imported-dog path enabled at all? Default OFF this phase. */
  flagEnabled: boolean;
  /** Current state of the async model load. */
  loadState: DogLoadState;
}

/**
 * Decide whether to render the imported model or fall back to the procedural dog.
 *
 * Fallback is mandatory: only a flag-enabled, cleanly-`ready` load yields
 * `'imported'`. Everything else — flag off, still loading, failed, or timed out —
 * yields `'procedural'` so the dog is always playable.
 */
export function selectDogRenderMode({ flagEnabled, loadState }: RenderModeInput): DogRenderMode {
  return flagEnabled && loadState === 'ready' ? 'imported' : 'procedural';
}

export interface TimeoutInput {
  /** Current raw load state. */
  state: DogLoadState;
  /** Milliseconds elapsed since the load began. */
  elapsedMs: number;
  /** Milliseconds we are willing to wait before giving up on the imported model. */
  budgetMs: number;
}

/**
 * Convert a still-`loading` state into `timeout` once it has outrun its budget,
 * so the scene can fall back to the procedural dog instead of waiting forever.
 * Any non-`loading` state passes through unchanged.
 */
export function resolveLoadState({ state, elapsedMs, budgetMs }: TimeoutInput): DogLoadState {
  if (state === 'loading' && elapsedMs > budgetMs) return 'timeout';
  return state;
}
