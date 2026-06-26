# Bra! — Content Catalog (Breeds · Tricks · Scenarios)

> The **nouns** of the game. [specs2.md](specs2.md) holds the **behavior** (user
> stories); this file holds the concrete **content** those stories operate on:
> which breeds, which tricks, which scenarios/props exist. It is the
> human-readable **source of truth** that mirrors the data-driven config tables
> (tech-decisions §6 — "define them as data, not hardcoded"). Tuning values
> (window ms, costs, multipliers) live in `src/core/tuning.ts` and may differ;
> this file fixes *what exists and how it maps*, not the balance numbers.

## Conventions

- **IDs are stable kebab-case strings** (`border-collie`, `legg-deg`). Stories,
  config tables, save data, and tests all reference these IDs — never display
  names. Renaming a display name must never change an ID.
- **Status** column: `live` (built), `planned` (next), `deferred` (captured, not
  scheduled — see the matching parked item in specs2.md).
- **One row = one catalog entry = one eventual config record.** Adding content =
  adding a row here + a config row, no code change (data-driven).
- **Traceability:** the "Story" column links each entity back to the specs2 story
  that introduces it.

---

## 1. Breeds

Breeds **unlock via a light economy** (specs2 P3-D3): a trainer-level gate makes a
breed *available*, coins *buy* it. Personality drives the difficulty levers
(specs2 P3-3). Starter set = the four the licensed pack covers; **no Poodle**.

| ID | Display | Status | Personality (levers) | Unlock level | Coin cost | Signature trick(s) | Story |
|----|---------|--------|----------------------|--------------|-----------|--------------------|-------|
| `labrador` | Labrador | live | Balanced, beginner-friendly (steady windows, average energy) | 1 (starter) | 0 (owned) | — | P1, P3-1 |
| `border-collie` | Border Collie | planned | Fast learner, distractible (high ceiling, jittery focus) | TBD | TBD | TBD | P3-2 |
| `french-bulldog` | French Bulldog | planned | Slow but steady (wide stable windows, low energy) | TBD | TBD | TBD | P3-2 |
| `husky` | Husky | planned | High energy, chaotic (jittery windows, rewarding) | TBD | TBD | TBD | P3-2 |

> **Open (P3-D1 / P3-D4):** confirm the level/cost values and confirm each breed
> has clean clips for every trick it's assigned before locking its trick list.

---

## 2. Tricks

Norwegian command names (matching the marker-word flavor). **Type** drives whether
shaping applies later: `atomic` = single pose; `positional`/`compound` = candidate
for steps (shaping is **deferred** — specs2 §6a / B-5). Every trick must have a
**distinct, legible pose** at the apex (specs2 P2-2, D11).

| ID | Command | English | Type | Distinct apex pose | Status | Shaping (deferred) | Story |
|----|---------|---------|------|--------------------|--------|--------------------|-------|
| `sitt` | Sitt | sit | atomic | upright sit | live | no | P1-3, P2-2 |
| `ligg` | Ligg | lie down / hold down | positional | clearly *down*, distinct from sit | planned | candidate | P2-2 |
| `legg-deg` | Legg deg | settle on the spot | positional | settled down, distinct from sit & ligg | planned | candidate (bed scenario) | P2-2 |
| `gi-labb` | Gi labb | shake / give paw | atomic | paw raised | planned | no | P2-2 |
| `rull` | Rull | roll over | compound | mid-roll, unmistakable | planned | candidate | P2-2 |
| `snurr` | Snurr | spin | atomic | mid-spin | planned | no | P2-2 |
| `dau` | Dau | play dead | positional | flat-on-side | deferred | candidate | (later) |

> **Open (P3-D2):** which of these is **universal** (every breed) vs.
> **breed-signature**. Proposed default: `sitt` / `ligg` / `legg-deg` universal;
> 1–2 signature tricks per breed drawn from the rest.

---

## 3. Scenarios / Props  🚩 DEFERRED (shaping, specs2 §6a / B-5)

Scenarios pair a trick step with an environment object. **Not scheduled** — captured
so the design isn't lost. Each row will become a prop placed in the scene for that
trick's step(s).

| ID | Prop | Used by trick | Step(s) it appears in | Status | Story |
|----|------|---------------|-----------------------|--------|-------|
| `dog-bed` | Bed / mat | `legg-deg` | step 1 *step onto bed* → … → full settle | deferred | P6-1, P6-2 |
| `target-stick` | Target | (TBD) | luring/targeting steps | deferred | P6-2 |
| `cone` | Cone | (TBD) | positional marker | deferred | P6-2 |

### Shaping steps (deferred reference)

When un-parked, a positional trick decomposes into ordered, individually-markable
steps (specs2 P6-1, max 2–3 to start). Example:

| Trick | Step | Behavior | Prop |
|-------|------|----------|------|
| `legg-deg` | 1 | step onto the bed (not down yet) | `dog-bed` |
| `legg-deg` | 2 | lower the front | `dog-bed` |
| `legg-deg` | 3 | full settle (down) | `dog-bed` |

> Each step needs a **clean clip** (specs2 P6-D1 — the main cost/risk). Confirm rig
> coverage before un-parking.

---

## 4. Breed × Trick matrix

Which breed knows which trick. `core` = universal; `sig` = breed-signature;
blank = not taught. (Fill once P3-D2 is locked.)

| Trick \ Breed | labrador | border-collie | french-bulldog | husky |
|---------------|:--------:|:-------------:|:--------------:|:-----:|
| `sitt` | core | core | core | core |
| `ligg` | core | core | core | core |
| `legg-deg` | core | core | core | core |
| `gi-labb` | TBD | TBD | TBD | TBD |
| `rull` | TBD | TBD | TBD | TBD |
| `snurr` | TBD | TBD | TBD | TBD |

---

## Maintenance

- Adding content: add the row(s) here **and** the config row; reference the ID from
  the relevant specs2 story. No code change for pure content.
- Changing balance numbers: edit `src/core/tuning.ts`, not this file.
- Promoting `deferred` → `planned`: un-park the matching specs2 item (e.g. B-5 for
  shaping) at the same time so behavior and content stay in sync.
