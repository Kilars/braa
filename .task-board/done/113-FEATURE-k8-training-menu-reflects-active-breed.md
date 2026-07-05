# 113 — FEATURE: the training trick menu reflects the ACTIVE breed's trick list (K-8)

**Type:** FEATURE (current-phase, Phase 8) — TDD
**Story:** K-8 "In the training scene a dog can only train its own breed's available
tricks; the trick menu reflects the active breed's list."
**Source:** Phase-8 construction audit (2026-07-05), **Finding 2**.

## What this addresses
`main.gd::_selectable_tricks()` derives the training menu from the **static** `KNOWN_TRICKS`
const, intersected with `_director.has_trick(id)`. It never consults the **active kennel
dog's** `trick_ids`. Today this is *observably* correct only by coincidence — every
`KennelDog` sets `trick_ids = core_tricks()` (`kennel_dog.gd:175`), which equals
`KNOWN_TRICKS`, because per-breed trick **divergence** is owner-gated on camera-facing
signature clips (open flag **P3-2**). But the K-8 acceptance bullet — the menu reflects the
*active breed's* list — is unmet at the code level: swap in a breed whose `trick_ids` differ
and the menu would ignore it. Make K-8 true **by construction**, so when an owner signature
clip eventually lands it is respected per-breed rather than offered to every dog.

This is NOT the owner-gated part. Per-breed *distinct* trick content stays gated under P3-2
(unchanged, no new flag). This task only fixes the source-of-truth of the menu.

## Approach (test-first)
Source the selectable tricks from the active kennel dog's `trick_ids`, still gated by what
the rig can actually perform (`_director.has_trick`) — never offer a trick the dog can't do
(the never-fake gate). Fall back to `KNOWN_TRICKS` when no kennel roster/active dog is
resolvable (e.g. legacy save, CC0 placeholder), so today's behavior is byte-identical.

Before (`scripts/main.gd`):
```gdscript
func _selectable_tricks() -> Array:
	var out: Array = []
	if _director == null:
		return out
	for id in KNOWN_TRICKS:
		if _director.has_trick(id):
			out.append(id)
	return out
```

After (shape — final names per the code):
```gdscript
func _selectable_tricks() -> Array:
	var out: Array = []
	if _director == null:
		return out
	# K-8: the ACTIVE breed's own list drives the menu; fall back to the shared core
	# when no kennel dog is resolvable. Still gated on what the rig can actually perform.
	var wanted: Array = _active_breed_trick_ids()  # active kennel dog's trick_ids, else KNOWN_TRICKS
	for id in wanted:
		if _director.has_trick(id):
			out.append(id)
	return out
```
with a small helper `_active_breed_trick_ids()` that reads
`KennelDog.by_id(_kennel_roster.active).trick_ids` when the roster + active id are valid,
else returns `KNOWN_TRICKS`.

## Tests (RED → GREEN, in a kennel/main test)
- With an active kennel dog whose `trick_ids == [sitt, ligg, legg_deg]`, the selectable set
  equals today's set (identity — no regression) when the rig can perform them.
- With an active dog whose `trick_ids` omits a trick, that trick is **not** offered even
  though the rig `has_trick` it (proves the active list, not the static const, is the
  source of truth).
- With no resolvable kennel roster/active dog, it falls back to `KNOWN_TRICKS` (legacy-safe).
- A trick in `trick_ids` the rig cannot perform is still filtered out (never-fake gate holds).

## Acceptance criteria
- [x] **TDD first:** the four cases above written RED, then GREEN.
- [x] `_selectable_tricks()` derives from the active kennel dog's `trick_ids`, gated by
      `_director.has_trick`, with a `KNOWN_TRICKS` fallback — no per-breed content faked.
- [x] Default fresh-player behavior is byte-identical to today (Bella/core = Sitt·Ligg·Legg
      deg), so the signed-off training loop is unaffected.
- [x] No new flag: per-breed trick DIVERGENCE stays under the existing owner-gated P3-2.
- [x] `nix develop -c bash verify.sh` green.
