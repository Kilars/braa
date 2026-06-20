# RESEARCH: Source a rigged dog base model for the Pokémon-GO visuals pipeline

**Status**: Research + shortlist + **purchase + file-drop COMPLETE** (`Labrador_FBX.rar` at repo root). Remaining handoff: **convert FBX → glb** (tech-decisions §3c) — no longer owner-blocked.
**Created**: 2026-06-17

> **Update (2026-06-19):** RESOLVED. The research half (verified 3-candidate shortlist
> + two-track recommendation) is recorded in
> [`tech-decisions.md §3a`](../../.docs/tech-decisions.md). The owner then committed the
> Quaternius **CC0** placeholder, purchased the realistic Labrador (§3b), settled the
> web-PWA raw-`.glb` question (PWA-first + pack-on-web, §3d), and **dropped the asset**
> (`Labrador_FBX.rar` at repo root, §3c). The **one remaining step is converting the
> FBX → glb** and staging `public/models/dog.glb`; `078`'s pure decision core is already
> landed, so the loader is a drop-in once the converted asset exists.
**Priority**: High
**Labels**: research, assets, decision, render, epic:pokemon-go-visuals
**Estimated Effort**: Medium (research); purchase + file-drop now complete

## Context & Motivation

First task of the **[Pokémon-GO Visuals epic](../EPIC-pokemon-go-visuals.md)**.
The owner has chosen the sourcing route: **asset-store base model + shared-rig
retargeting** (tech-decisions §3). Everything downstream (loader, imported mesh,
animation, breed retargeting) needed a concrete, license-clear, mobile-suitable
rigged dog model on disk. This task selected it — now purchased + dropped
(`Labrador_FBX.rar`); the remaining handoff is the FBX → glb conversion (§3c).

The actual purchase/license is a **money + likeness/rights gate** — this task
produces a shortlist + recommendation; the owner approves the buy.

## Desired Outcome

A recorded decision naming **one** base model to build the Phase-1 slice on, with
its license, price, format, and tri/skeleton details captured in
`tech-decisions.md §3`, plus the file staged for `078`/`079`.

## Selection criteria (acceptance bar for a usable model)

- **Format**: glTF / `.glb` (Babylon-native), or trivially convertible to it.
- **Rigged**: ships with a skeleton suitable for quadruped locomotion + the pose
  channels we already drive (head tilt/lift/pitch/yaw, tail wag, body lean,
  sit/lie/spin/roll). A shared canine skeleton we can retarget across breeds is
  the goal — prefer one base dog reshaped to breeds over five bespoke rigs.
- **Topology/UVs**: clean, UV-unwrapped so coat **textures swap per breed**.
- **Mobile budget**: low/mid poly (target order ~10–30k tris with LODs), texture
  sizes sane for a PWA download.
- **License**: permits **commercial use + modification + redistribution inside a
  compiled app** (App Store / Play Store / web PWA). Royalty-free preferred; record
  attribution requirements. ⚠️ Avoid editorial-only / "no redistribution" / AI-
  training-tainted licenses.
- **Animations**: bonus if it ships idle/sit/walk clips we can reuse in Phase 2.

## Implementation Steps

1. **Survey** the realistic sources against the criteria: Sketchfab (filter:
   downloadable + license), CGTrader, TurboSquid, Unity Asset Store, Quaternius /
   Kenney / Poly Pizza (free stylized), and any reputable rigged-dog packs.
2. **Shortlist 2–3 candidates**, each with: link, price, exact license, format,
   tri count, rig/skeleton summary, included animations, and the breed-retarget
   story (can one model become Lab/Bulldog/Collie/Husky/Puddel via morph + texture,
   or do we need a couple of base body types?).
3. **Recommend one** with a one-paragraph rationale and a fallback.
4. **Escalate to owner** for purchase approval (batch with any cost/rights notes).
5. On approval: stage the `.glb` under a tracked assets location, record the
   decision + license in `tech-decisions.md §3`, and unblock `078`.

## Affected Components

- `.docs/tech-decisions.md §3` — record the chosen model + license + budget.
- New assets location (e.g. `public/models/` or `src/assets/`) — decide + document
  the convention here; **do not commit a paid asset until its license is recorded.**
- Unblocks `078-FEATURE-gltf-load-path-and-fallback`.

## Risks & Considerations

- **License trap**: "free" Sketchfab models are often CC-BY (attribution) or
  worse, non-commercial. Read the actual license, not the price.
- **Rig mismatch**: a model rigged only for walk cycles may not bend to sit/lie/
  roll cleanly — verify the skeleton supports our trick poses before buying.
- **Over-buying**: resist five breed-specific models; the epic's whole thesis is
  one shared rig + retargeting. Buy the base, prove the slice, then scale.

## Acceptance Criteria

- [x] 2–3 candidate models documented (link / license / format / rig / retarget
      story) against the criteria above — see `tech-decisions.md §3a`. (Exact
      price/tri-count deliberately left for point-of-purchase verification, not
      fabricated.)
- [x] One recommended with rationale + fallback (two-track: CC0 placeholder now,
      Royalty-Free purchase for the final look); cost/rights **escalated to owner**.
- [x] Assets-location convention documented (`public/models/<file>.glb`) in §3a.
- [x] Owner purchased the model + dropped it (`Labrador_FBX.rar`); license recorded §3b/§3c.
- [ ] **Remaining (convert FBX → glb):** stage the real `public/models/dog.glb`, then
      `078` can load it. 078's pure decision core is already landed; the asset
      conversion + loader/scene glue remain.

---

**Next Steps**: Move to `.task-board/in-progress/` when starting. Live source
research can be run with WebSearch/WebFetch; the purchase decision is the owner's.
