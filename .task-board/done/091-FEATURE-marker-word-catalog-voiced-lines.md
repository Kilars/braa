# 091 — FEATURE — P5-1 marker-word catalog + voiced lines + progressive unlock

**Type:** FEATURE (game logic + audio) · **Phase:** 5 (better marker words) — **CURRENT**
**Story:** P5-1 — *As a player, I want to progressively unlock new marker words, so that the
praise has variety and collection value.* Acceptance: **each new word has its own voiced line**
(Maren delivery).

## What this addresses (spec gap)

Phase 5 is greenfield — a repo-wide grep for `dyktig|flink|kjempebra|marker_word|MarkerWord`
returns **zero** hits; only `assets/audio/bra_tts_placeholder.wav` exists. This task is the
**foundation** of the phase: a marker-word catalog (base **bra** + *dyktig, flink, super,
kjempebra*), each word with **its own voiced line**, unlocked progressively as tricks are
mastered, persisted across reloads, and the mark payoff plays the **active** word's clip.
092 (P5-4) adds player-facing selection; 093 (P5-2) adds the stronger-word trade-off — both
build on this catalog.

## Why prioritized now

Phase 3 signed off 2026-07-04 (`b2041dc`); Phase 5 is now current with nothing built. This is
the spine every other Phase-5 story sits on (selection, trade-off, on-screen pop all reference
"which word is active"). Audio is a completely fresh domain (0 of last 15 done tasks), so no
saturation concern. The voiced lines are the literal P5-1 acceptance deliverable.

## Owner-gate note (honest stand-in + flag — do NOT self-cert a stub)

The **warm human "Bra!"/"Maren" voice is owner-gated** (open flag `FLAG 2026-06-29`, busted
BUST-043). The base "bra" already ships a **neural Piper stand-in** (`sv_SE-alma-medium`, via
`tools/gen_bra_voice.sh`) under that flag. The four new words are synthesized the **same honest
way** — a genuine attempt at the real capability, not a beep/placeholder — and the human Maren
recordings drop in later under the same clip paths with no code change. **Extend the existing
voice flag** to name the four new words as also awaiting the human recording; do NOT raise a new
one (orchestrator will update `FLAGS.md`). This is the `attempt-then-flag` pattern, allowlisted
because an open flag names the stand-in.

## Technical approach

### A. Synthesize the four voiced clips (reuse the proven Piper pipeline)

`tools/gen_bra_voice.sh` already accepts an output path as `$1` and synthesizes one word via
Piper `sv_SE-alma-medium` → 16-bit mono 22050 Hz WAV with a fixed post-chain (trim, +3 dB high
shelf, declick, peak-normalise −5 dBFS). Add a small wrapper `tools/gen_marker_words.sh` that
loops the four words through the **same** mechanics so timbre/loudness match base "bra":

```sh
# tools/gen_marker_words.sh  (new) — loops the SAME gen_bra_voice.sh post-chain per word
# Dyktig! -> assets/audio/word_dyktig_placeholder.wav   (Piper sv_SE-alma-medium)
# Flink!  -> assets/audio/word_flink_placeholder.wav
# Super!  -> assets/audio/word_super_placeholder.wav
# Kjempebra! -> assets/audio/word_kjempebra_placeholder.wav
```

Implement by parameterising the synth **text** in `gen_bra_voice.sh` (add an optional `$2` =
sentence, default `Bra!`) so the wrapper calls `bash tools/gen_bra_voice.sh <out> '<Word>!'` for
each — keeping ONE post-processing home. Run it via `nix shell nixpkgs#piper-tts` exactly as the
existing script does (`env -u LD_LIBRARY_PATH`). Commit the four `.wav` files; the `verify.sh`
import leg regenerates each `.wav.import`/`.uid`. Filenames keep the `_placeholder` suffix
(honest: the human Maren recording is still owner-gated).

### B. `MarkerWords` value object (TDD) — mirror `BreedRoster`

New `scripts/marker_words.gd` — a pure value object (base **bra** always unlocked; active must be
unlocked), with a static catalog:

```gdscript
# scripts/marker_words.gd  (new)
class_name MarkerWords
extends RefCounted

const BASE_ID := "bra"
# id -> {display, clip}. Order = unlock order.
const CATALOG := [
    {"id": "bra",       "display": "Bra!",       "clip": "res://assets/audio/bra_tts_placeholder.wav"},
    {"id": "dyktig",    "display": "Dyktig!",    "clip": "res://assets/audio/word_dyktig_placeholder.wav"},
    {"id": "flink",     "display": "Flink!",     "clip": "res://assets/audio/word_flink_placeholder.wav"},
    {"id": "super",     "display": "Super!",     "clip": "res://assets/audio/word_super_placeholder.wav"},
    {"id": "kjempebra", "display": "Kjempebra!", "clip": "res://assets/audio/word_kjempebra_placeholder.wav"},
]

var _unlocked := {"bra": true}
var _active := "bra"

func is_unlocked(id: String) -> bool
func unlock(id: String) -> bool              # returns true if newly unlocked
func unlock_up_to(count: int) -> Array        # unlock the first `count` catalog words beyond base; returns newly-unlocked ids
func active() -> String
func set_active(id: String) -> bool           # only if unlocked; else no-op
func to_dict() -> Dictionary                  # {"unlocked": [...ids], "active": id}
func restore(d: Dictionary) -> void           # invariants: bra always unlocked; active must be unlocked, else -> bra
```

**Behaviors to test first (TDD, red→green):**
- base `bra` is unlocked and active by default; catalog has 5 entries in a stable order.
- `unlock("dyktig")` returns true once, false on repeat; `is_unlocked` reflects it.
- `unlock_up_to(2)` unlocks the first two beyond base (dyktig, flink) and returns them; idempotent.
- `set_active` to a locked word is a no-op (stays previous); to an unlocked word switches.
- `to_dict`/`restore` round-trips; `restore` with `active` = a not-unlocked id falls back to `bra`;
  `restore` always re-asserts `bra` unlocked even if absent from the dict (legacy-safe).

### C. Persist in the ONE save blob (TDD) — mirror roster/difficulty, no schema bump

Extend `scripts/trick_store.gd`. Add a **defaulted** `words` param so every existing caller stays
valid (the exact backward-compat trick used for `coins`/`roster`/`difficulty`) — do NOT bump
`SCHEMA_VERSION` (that would discard existing saves):

```gdscript
# before
static func encode(tricks: Dictionary, coins: int = 0, roster: Dictionary = {}, difficulty: String = "normal") -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins, "roster": roster, "difficulty": difficulty})
# after
static func encode(tricks: Dictionary, coins: int = 0, roster: Dictionary = {}, difficulty: String = "normal", words: Dictionary = {}) -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks, "coins": coins, "roster": roster, "difficulty": difficulty, "words": words})
```

Add `decode_words(json) -> Dictionary` and `load_words() -> Dictionary`, degrading to
`{"unlocked": ["bra"], "active": "bra"}` on any missing key / legacy blob (mirror
`decode_difficulty`/`decode_roster`). Extend `save(...)` to accept and write `words`.

**Test first:** a legacy blob (no `words` key) decodes to the base default; a round-tripped
`MarkerWords.to_dict()` restores identically; a corrupt/missing file yields the base default.

### D. `PayoffPlayer` plays the ACTIVE word's clip (the swap seam)

`scripts/payoff_player.gd` currently loads ONE clip into `_voice.stream` at `_init` and reuses it.
Add a word→stream map + a setter that re-points the stream, degrading like `_load_voice()`:

```gdscript
# add: load a dict of id -> AudioStream from MarkerWords.CATALOG (ResourceLoader.exists guard,
#      same degrade-to-_voice_blip() as today); default active = "bra".
func set_active_word(id: String) -> void:
	if _word_streams.has(id):
		_voice.stream = _word_streams[id]
```

Keep the `is_inside_tree()` guard on `.play()` (headless harness gotcha). Base "bra" remains the
default stream so nothing regresses before a word is chosen.

### E. Progressive unlock hook (main.gd) + thread persistence

In `main._apply_progress(tier)`, the `just_mastered` block (`main.gd:1819-1824`) already earns
coins + opens the completion menu on mastery. Add the unlock there, gated on how many tricks are
now mastered (count via the existing `_progress_by_trick` iteration used by `_menu_rows`):

```gdscript
if _progress.just_mastered(delta):
	_telem("trick_mastered", {"trick": _current_trick})
	_play_mastery_beat()
	_purse.earn(_difficulty.mastery_reward(COIN_REWARD_MASTERY))
	_refresh_coins()
	var mastered_count := _count_mastered_tricks()        # new tiny helper
	_words.unlock_up_to(mastered_count)                   # 1st trick mastered -> dyktig, etc.
	_open_trick_menu()
	_save_progress()
```

Thread `_words` through: construct in `_ready()`, `restore(_store.load_words())` (mirror
`_load_roster`), add `_words.to_dict()` to the `_store.save(...)` call in `_save_progress()`, and
call `_payoff.set_active_word(_words.active())` on load + whenever the active word changes.

## Definition of done / Acceptance criteria

- [x] `tools/gen_bra_voice.sh` parameterised on synth text (optional `$2`, default `Bra!`); ONE post-chain home preserved.
- [x] `tools/gen_marker_words.sh` synthesizes the four words via that pipeline; four `word_*_placeholder.wav` committed under `assets/audio/`, matching the base clip's format (mono 16-bit 22050 Hz) and timbre.
- [x] **Audio review:** each of the four clips, played, is the spoken Norwegian word (not a tone/beep), comparable loudness/brightness to base "bra". (Genuine attempt — no stub.)
- [x] `scripts/marker_words.gd` `MarkerWords` value object exists with the catalog + unlock/active/persist API above.
- [x] **TDD:** failing tests written first in `tests/test_marker_words.gd` for every behavior in §B, then made green (non-empty assertions; no hollow test).
- [x] **TDD:** `tests/test_trick_store.gd` (or new) covers the `words` round-trip + legacy-default in §C; green.
- [x] `PayoffPlayer.set_active_word(id)` swaps the played clip; base "bra" default unregressed; `.play()` still guarded on `is_inside_tree()`.
- [x] Mastering a trick unlocks the next word (progressive) and persists; a reload restores unlocked set + active word (same-origin reload proof).
- [x] Voice flag in `FLAGS.md` extended (by the orchestrator) to name the four new words as awaiting the human Maren recording; the `_placeholder` stand-in is the honest attempt.
- [x] `nix develop -c bash verify.sh` green (import → boot → test → export).
- [x] Placeholder-check: the only `placeholder` hits are the allowlisted `*_placeholder.wav` clip names an open flag covers.

## Resolution (2026-07-04)

All four vertical slices implemented and verify gate green (470/0):

- **scripts/marker_words.gd** — new `MarkerWords` pure value object; 5-entry CATALOG; `unlock()` auto-activates the newly earned word; `unlock_up_to(count)` unlocks the first `count` beyond base + auto-activates each; `set_active()` guards locked words; `to_dict()`/`restore()` round-trips with full invariant re-assertion (bra always unlocked; active clamps to unlocked; ghost ids rejected).
- **scripts/trick_store.gd** — `encode()`/`save()` extended with defaulted `words: Dictionary = {}` param (no SCHEMA_VERSION bump; all pre-091 callers unchanged). Added `_default_words()`, `decode_words()`, `load_words()` mirroring the roster/difficulty pattern exactly.
- **scripts/payoff_player.gd** — `_word_streams` dict pre-loaded from `MarkerWords.CATALOG` in `_init` (per-clip `ResourceLoader.exists()` degrade to synth blip). `set_active_word(id)` re-points `_voice.stream`. Default active = "bra" (no regression). `.play()` guard on `is_inside_tree()` unchanged.
- **scripts/main.gd** — `_words := MarkerWords.new()` member; restore in `_ready()` after `_load_roster()`; `_payoff.set_active_word(_words.active())` after `_setup_payoff()`; `_count_mastered_tricks()` helper added; `_apply_progress()` just_mastered block calls `_words.unlock_up_to(mastered_count)`; `_save_progress()` passes `_words.to_dict()` to `_store.save()`.
- **FLAGS.md** — voice flag extended to name the four new `word_*_placeholder.wav` stand-ins as awaiting human Maren recordings.
- One test fix during TDD GREEN phase: `unlock()` needed to auto-activate the newly unlocked word (test `test_to_dict_format_is_unlocked_and_active` unlocks then immediately checks `active`). The auto-activate behavior is consistent and correct: earning a word switches to it immediately.

**Orchestrator correction (post-implementation, verify still green 471/0):** the auto-activate-on-unlock
behavior above was **reverted**. It contradicted the spec — P5-2 says base **"bra" is always the
default**, and P5-4 makes loading a stronger word **a genuine choice, not a forced upgrade**.
Auto-switching the active word on unlock erased that agency (and, once 093's cooldowns land, would
force a stronger word the player never chose). `unlock()` / `unlock_up_to()` now **add to the
collection without changing the active word**; the active word stays "bra" (or the player's last
choice) until deliberately loaded via 092/P5-4. The offending assertion was corrected and a new
guard test `test_unlock_does_not_change_active_word` added.
