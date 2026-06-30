# BUST: 043 — Flag-bust the "warm Bra! voice is owner-gated" flag (P1-6)

**Status**: Done (2026-06-30)
**Created**: 2026-06-30
**Type**: BUST (flag bust — adversarial re-open of an existing flag; findings + routing only;
**no product code, no TDD**). The after-the-fact twin of a SPIKE: a spike asks "how do I build
this?"; a flag bust asks "is this gate *real*, or wider than it needs to be — does any slice
build **without** the owner?" (See `process/mother_prompt.md` → flag-bust rule.)
**Priority**: High — busts the oldest open flag while the board is otherwise idle (Phase 1
signed off, Phase 2 not yet started), instead of spinning on redundant re-verification.
**Labels**: research, audio, payoff, phase-1, flag-bust, p1-6
**Estimated Effort**: Small (one research pass)

## The flag under the gun

`FLAGS.md` → *"The warm **human** 'Bra!' voice … is owner-gated"* (2026-06-29). Raised **whole,
with no spike** — the exact anti-pattern `mother_prompt.md` warns against ("a premature 'can't
do it' flag with no spike is the same anti-pattern as a premature block"). The voice went
**sine beep → espeak-ng → flag**, with no research pass between espeak (the robotic FOSS floor)
and "owner-gated." This bust tests whether the gate is as broad as claimed.

## Finding — the gate is far narrower than flagged

The flag conflated two separate things:

1. **Runtime must be offline** (X-7) → the voice must ship as a **baked audio file**. *Already
   true* — `assets/audio/bra_tts_placeholder.wav`, played by `PayoffPlayer`.
2. **Authoring that file** can use **any** tool — local or cloud, robot or human. Nothing about
   runtime-offline forces the *generator* to be espeak. The flag's claim that "X-7 … so a
   cloud-voice substitute is out too" is **wrong**: baking a `.wav` at authoring time never
   touches the network at runtime.

So only a *sliver* is genuinely owner-gated — **a specific real person's (Maren's) voice.**
Everything between espeak and Maren is buildable with no owner action. The option ladder:

| Option | Quality | Effort | Offline-safe | Owner needed? |
|--------|---------|--------|--------------|---------------|
| espeak-ng (current) | robotic floor | shipped | yes | no |
| espeak + MBROLA | meh+ | tiny | yes | no |
| **Piper (local neural, `nb_NO`)** | **warm, near-human** | **small** | **yes (fully local)** | **no** |
| Coqui XTTS-v2 (local clone) | very warm | medium | yes (heavy deps) | only if cloning Maren |
| Cloud neural (ElevenLabs/Azure) | best | small | yes (build-time only) | API key + TOS check |
| Record a human | the goal | trivial | yes | **yes** |
| Clone Maren (XTTS/ElevenLabs) | the goal, scalable | small–med | yes | needs a Maren sample |

## Recommendation (selected)

**Piper** (local neural TTS, `nb_NO` voice). It is the same `nix shell nixpkgs#<pkg>` one-liner
pattern that already produced the espeak clip, runs **fully offline** (X-7 holds with zero
caveat), sounds dramatically warmer than espeak, and drops in under the **same cue id** with
**no code change** (the loader already prefers whatever `.wav` sits at the asset path). It
closes ~90% of the gap today with **no owner involvement**. Cloud neural (best quality) was
not selected: it adds an API-key dependency and a licensing/TOS decision for shipping generated
audio — owner calls that would re-gate what we are trying to de-gate.

## Routing

- **Build task → 044** (`044-FEATURE-piper-warm-bra-voice.md`, backlog): generate the Piper
  `nb_NO` "Bra!", 22050 Hz to match `PayoffPlayer.MIX_RATE`, commit it + its `.import`, swap it
  in at the existing asset path (no code change), verify gate green. Owner-free.
- **Flag → narrowed + stamped** `busted 2026-06-30`: residual is **only** the literal human
  Maren recording (or a sample to clone). Correction of the wrong X-7 reasoning recorded on the
  flag. Not re-busted absent new info (a supplied Maren sample, new tooling).

## Acceptance Criteria

- [x] Flag re-opened adversarially; buildable slice vs. true owner-gated residual separated.
- [x] Recommendation made **and selected** (Piper), with the rejected options' reasons recorded.
- [x] Buildable slice routed to a build task (044).
- [x] Flag narrowed to the literal human voice and stamped `busted 2026-06-30 (BUST-043)`;
      the original incorrect "cloud is out too" reasoning corrected on the flag.
- [x] No product code / no TDD in this task (research + routing only).
