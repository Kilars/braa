# 074 — BUST: can a Chocolate Labrador ship as a recolor (2nd breed, no new owner model)?

**Type:** BUST (flag-bust — research only, NO product code, NO TDD) · **Phase:** 3 (current) ·
**Source:** PO Review 2026-07-02 `po-review.md` **Actionable note 4** ("Do a flag bust for
deciding if we can make a chocolate labrador available.") · **Priority:** P2 for this phase —
cheap research that could unblock the **Phase-3 headline** (a real *second breed*) with **no owner
asset**.

## What it addresses

Phase 3 is "dog breeds," and the standing gate (`FLAGS.md` → the 2026-07-01 breed flag, busted to
BUST-068) narrowed the genuinely owner-gated residual to *additional breed **models*** (Border
Collie / French Bulldog / Husky) + the P3-D1/D2/D4 decisions. **But a Chocolate Labrador is not a
new model — it is the *same rig* with a different coat colour.** The PO is asking, correctly, for a
**flag bust**: does a second, visually-distinct breed build **without the owner** by recolouring the
already-licensed Labrador (yellow/black → chocolate)? If yes, Phase 3 gets its first *real* second
breed from assets already in the repo.

This is a **flag bust**, per `mother_prompt.md`: research only. Refute-not-confirm — try to prove
the recolour is *not* clean, and only conclude "buildable" if a genuine, honest recolour path
survives. Deliverables: **findings + routing** (a build task if buildable, an informed flag if
genuinely owner-gated). No shippable product code, no tests.

## Investigation plan (research subagent — read/inspect only)

Inspect the **raw asset**, not the running game (behavior ≠ inventory):

1. **How is the coat coloured today?** Read `scripts/coat_opaque.gd`, `scripts/dog_director.gd`,
   and how `dog_licensed.glb` surfaces/materials are set up (the CC0 `dog.glb` is the local
   stand-in; the licensed coat is the real target). Determine whether coat colour comes from:
   - a **solid/near-solid albedo** on a named coat material (→ a runtime `albedo_color` /
     `albedo_mix` tint is a clean recolour → **buildable, no owner**), or
   - a **baked albedo texture atlas** with the yellow/black coat painted in (→ a naive tint muddies
     it; assess whether a hue/multiply tint, or a desaturate-then-tint, yields a *convincing*
     chocolate without the owner re-painting the texture).
2. **Is the coat surface identifiable and isolable?** Confirm the coat mesh/material can be targeted
   without tinting eyes/nose/claws/mouth/tongue (grep the manifest / dump the glb material names).
   Note the coat-seam caveat on record (UV/tangent seam in the licensed asset) — a recolour must not
   make the seam worse.
3. **Chocolate target colour + honesty check.** A real chocolate Lab is a warm dark brown
   (~`#5A3A22`-ish) coat with matching nose/eye trims. Judge whether a runtime material tint reads
   as *"that real breed"* (P3-1's bar) or as an obviously-cheap wash. Refute-first: if the honest
   answer is "reads fake," say so.
4. **What the recolour is NOT.** It does not need a new glb, a new rig, new clips, or the owner —
   or it does. Land on one verdict with evidence.

## Routing (the deliverable)

- **If a clean recolour is buildable without the owner** → write a follow-up **build task** (e.g.
  `075+`: "Chocolate Labrador breed via runtime coat tint") describing the exact material/surface to
  tint, the target colour, and how it slots into the (buildable) roster/personality spine as breed
  **#2**. Then **narrow** the `FLAGS.md` breed flag to exclude "chocolate recolor" and stamp the
  investigated line `busted <date>`. Record findings in this task file.
- **If it is genuinely owner-gated** (e.g. the coat is a hand-painted atlas no runtime tint can turn
  convincingly chocolate, needing an owner re-paint / re-export) → record precisely *what* the owner
  must supply, **raise/append a `FLAGS.md` flag** (orchestrator only), and stamp it. Do NOT ship a
  muddy tint as a self-certified "chocolate" — that is the placeholder anti-pattern.

## Acceptance criteria

- [ ] Coat-colour mechanism identified from the **raw asset** (material vs baked atlas), with file
      + surface/material names as evidence — not inferred from the running game.
- [ ] A refute-first verdict: **buildable-without-owner** OR **genuinely-owner-gated**, with the
      evidence that decides it (does a runtime tint read as a convincing chocolate coat?).
- [ ] Routed: either a follow-up **build task** created (buildable) **or** a precise `FLAGS.md`
      entry naming the owner deliverable (gated) — never a stubbed/muddy recolor shipped as done.
- [ ] The `FLAGS.md` breed flag updated (narrowed + `busted <date>` on the chocolate line) to reflect
      the finding, so the flag-bust sweep doesn't re-open it absent new information.
- [ ] Findings written into this task file's Completion note. (No `verify.sh` run required — this is
      research only, no code change — but if a build task is spun up, it runs the gate itself.)

## Notes

Per `mother_prompt.md`, a flag bust is the backward-looking twin of a spike: it asks whether an
asserted owner-gate is *real or broader than it needs to be*. A recolour of an owned rig is the
textbook "slice that builds without the owner." Keep the investigation honest: a chocolate Lab that
looks like a mud-washed yellow Lab is **not** the deliverable — the bar is "reads as that real
breed." Subagents never write `FLAGS.md`; the orchestrator applies the flag change.
