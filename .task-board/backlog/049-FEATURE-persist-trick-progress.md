# FEATURE: 049 — Leave and come back: persist per-trick learned progress (P2-5)

**Status**: Backlog
**Created**: 2026-06-30
**Type**: FEATURE (save/load logic — **test-first / TDD**; no Visual Review needed — it's pure
state persistence behind the existing learned bar)
**Priority**: High — completes the 045 learned-bar story: a bar you fill toward mastery is only
meaningful if it **survives a reload**. Independent of 048; clean pure save/load round-trip.
**Labels**: phase-2, logic, persistence, save, offline, tdd, p2-5, x-7
**Estimated Effort**: Small–Medium (one focused session)

## What it addresses (spec gap)

`.docs/specs/phase2.md` **P2-5 — Leave and come back** is unimplemented. Today `TrickProgress`
(045) lives only in memory — `main._progress` resets to 0 on every boot, so the learned bar and
mastery (a "safe checkpoint" by spec) evaporate when the page reloads. The spec:

- **Per-trick learned progress persists** (introduces a local save).
- Pause/resume supported; **no timer forces play**.

This also satisfies cross-cutting **X-7 — fully offline-capable**: saves are local (Godot
`user://`, IndexedDB-backed on web), **no backend, no account** — exactly what the spec mandates.
(Pause/resume: there is already no forcing timer; this task makes the resumed state carry the
saved progress. A full pause-screen UI, if wanted, is later/secondary — note it, don't build it.)

## Technical approach

Split the **pure JSON (de)serialization** from the **disk I/O** so the round-trip is unit-testable
headless, then wire it into `main.gd`'s existing progress path. Keyed per trick from day one (the
selector P2-1 and more tricks P2-2 drop into the same map later), with exactly one trick today: Sitt.

### 1. New class `TrickStore` (TDD — write the failing tests first)

A `RefCounted` save store. Pure (de)serialization is separately testable; the `user://` read/write
works headless in Godot, so the full round-trip is also unit-testable.

**Before:** _(no file)_

**After — `scripts/trick_store.gd` (sketch — final shape decided in the red-green loop):**

```gdscript
class_name TrickStore
extends RefCounted
## Local persistence for per-trick learned progress (P2-5 / X-7). One JSON map
## {trick_id: {value, mastered}} at user:// — IndexedDB-backed on web, no backend, no account.
## Pure (de)serialization is split from disk I/O so the round-trip is unit-testable headless.

const SAVE_PATH := "user://braa_save.json"
const SCHEMA_VERSION := 1

## Pure: model map -> JSON string. {sitt: {value: 0.6, mastered: false}} -> "{...}".
static func encode(tricks: Dictionary) -> String:
	return JSON.stringify({"version": SCHEMA_VERSION, "tricks": tricks})

## Pure: JSON string -> model map. Corrupt / empty / wrong-version -> {} (clean default, no crash).
static func decode(text: String) -> Dictionary:
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("version") != SCHEMA_VERSION:
		return {}
	var tricks = parsed.get("tricks")
	return tricks if typeof(tricks) == TYPE_DICTIONARY else {}

func save(tricks: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(encode(tricks))

func load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}                       # first run — clean zero state, never a crash
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	return decode(f.get_as_text()) if f != null else {}
```

`TrickProgress` gets a tiny serialize/restore pair so the store stays dumb about the model's rules
(mastery latch, floor) — the model owns its own shape:

```gdscript
# scripts/trick_progress.gd
func to_dict() -> Dictionary:
	return {"value": value, "mastered": mastered}

func restore(d: Dictionary) -> void:
	value = clampf(float(d.get("value", 0.0)), FLOOR, MASTERY)
	mastered = bool(d.get("mastered", false))
```

### 2. `main.gd` — load on boot, save on change

**Before (`scripts/main.gd:_apply_progress`):** updates `_progress` and the bar, no persistence.

**After:** on `_start_dog` (or boot), construct `_store := TrickStore.new()`, `load()` the map, and
`restore()` the current trick's entry into `_progress` (then push it to the learned bar so a
returning player sees their filled bar / gold mastered bar immediately). After every
`_apply_progress`, write back:

```gdscript
func _apply_progress(tier: SitWindow.Tier) -> void:
	... # existing fill/erode + confused beat + just_mastered celebration
	_store.save({TRICK_ID_SITT: _progress.to_dict()})   # persist after each change
```

Mastery's **safe-checkpoint** guarantee must survive a reload: a saved `mastered: true` restores
`mastered` so re-practice still can't drop below mastery (the floor logic in `apply()` already
enforces it once `mastered` is set). Keep `TRICK_ID_SITT` a named constant (no scattered literal).

## TDD — behaviors to test first (`tests/test_trick_store.gd`, + extend `test_trick_progress.gd`)

Per `.claude/skills/tdd/SKILL.md` — red first. Assert through the public surface:

1. **Round-trip** — `decode(encode({sitt:{value:0.6,mastered:false}}))` equals the input map.
2. **Mastery survives** — a `{value:1.0, mastered:true}` entry round-trips and `TrickProgress.restore`
   re-latches `mastered` (re-practice still can't drop below MASTERY — assert via a follow-up
   `apply(MISS)` staying at 1.0).
3. **Corrupt / empty / missing** → `decode("")`, `decode("{garbage")`, and `load()` with no file
   each return `{}` — a clean zero state, **no crash**.
4. **Wrong schema version** → `decode` of a `version: 0` blob returns `{}` (forward-compat guard).
5. **Unknown trick id** in the saved map is ignored on restore; a known trick restores.
6. **Disk round-trip (headless `user://`)** — `save(map)` then a fresh `TrickStore.load()` returns
   the same map (proves the real file path works, not just the pure codec).
7. **Wiring (scene-level):** a mark that changes progress writes the file; constructing a fresh
   `main`/store reads it back into `_progress` and the learned bar shows the restored fill.

## Acceptance criteria

- [ ] **Red first:** `tests/test_trick_store.gd` written and failing before `trick_store.gd` exists.
- [ ] `scripts/trick_store.gd` implements pure `encode`/`decode` + `save`/`load` to `user://`;
  behaviors 1–6 pass green. `SAVE_PATH`, `SCHEMA_VERSION` are named constants.
- [ ] Corrupt / empty / missing / wrong-version saves all degrade to a clean zero state with **no
  crash** (behaviors 3, 4).
- [ ] `TrickProgress.to_dict()`/`restore()` round-trip the model; a restored `mastered: true`
  re-latches the safe checkpoint so re-practice can't drop below mastery (behavior 2).
- [ ] `main.gd` loads saved progress on boot into `_progress` + the learned bar, and saves after
  every progress change; per-trick keyed by a named `TRICK_ID_SITT` constant. Proven by the wiring
  test (behavior 7).
- [ ] **X-7 honored:** save is local (`user://` / IndexedDB on web), no backend, no account, no
  network — works offline. (Note in the task results.)
- [ ] **Placeholder check** clean on the diff.
- [ ] `nix develop -c bash verify.sh` green (import · boot · test · export).
