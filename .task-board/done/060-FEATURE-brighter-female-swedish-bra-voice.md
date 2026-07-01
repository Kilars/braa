# FEATURE: 060 — Brighter, lighter, female "Bra!" — native Swedish Piper voice (P1-6 improvement)

**Status**: Backlog
**Priority**: High — direct **owner directive** (larssski, 2026-07-01): the current voice
(`no_NO-talesyntese-medium`, task 044) is too neutral/dark; make the "Bra!" **brighter, lighter,
and female**. Owner picked the **Swedish** route and said **deploy it without asking for
confirmation** — ship the best-guess and let the on-device listen drive any follow-up.
**Labels**: audio, payoff, phase-1, p1-6, owner-directive, voice
**Estimated Effort**: Small

## Why Swedish

"**Bra**" is the **same word, same meaning, near-identical "brah" pronunciation** in Swedish as
in Norwegian — so a **native Swedish female** voice says the cue correctly *and* gives the
brighter/lighter female timbre the owner asked for, with **no owner action** and **fully offline**
(same runtime contract as 044 — a baked `.wav`, X-7 intact). This is the buildable slice the voice
flag was already narrowed to (only the literal human Maren recording stays owner-gated).

## Technical Approach (asset swap only — **no game-code change**)

Same drop-in path as 044: overwrite `assets/audio/bra_tts_placeholder.wav`; the loader already
prefers whatever `.wav` is at `PayoffPlayer.VOICE_ASSET`
(`scripts/payoff_player.gd:27`), so no GDScript change and the existing voice test stays green.

1. **Pick a bright female Nordic Piper voice** (devshell has net + nix, like 044). Audition, in
   preference order, rendering "Bra!" from each candidate:
   - a **female Swedish** Piper voice (start with `sv_SE-nst-medium`; if that speaker isn't
     female, check the piper-voices index for any female `sv_SE` speaker / multi-speaker id);
   - failing a clearly-female Swedish voice, take the best Swedish voice and **formant + pitch
     shift up** to a bright female timbre (`rubberband`/`sox`: raise pitch ~+3–5 semitones with
     **formant preservation off** so formants rise too → feminises, not chipmunk);
   - Danish `da_DK` ("bra" also reads as good) is an acceptable fallback if Swedish disappoints.
   Since headless can't *hear*, choose by measurable proxy for "bright + female": higher
   fundamental (f0 ≈ 180–250 Hz) and higher spectral centroid than the current NO clip. **Pin
   the exact voice id + any shift in Results** (provenance, like 044/035 did).
2. **Brighten** if still dull: a touch of high-shelf lift and light gain normalization
   (`ffmpeg`/`sox`) — keep it a clean single word, ~0.5–0.9 s, no long silence tail.
3. **Render to mono, 16-bit, 22050 Hz** (== `PayoffPlayer.MIX_RATE`) and **overwrite**
   `assets/audio/bra_tts_placeholder.wav`. Commit the regenerated `.import` sidecar so it rides
   the Web export. (Filename stays — allowlisted by the open voice flag; a synth voice is still a
   stand-in for the human Maren recording.)
4. **Commit a reusable `tools/gen_bra_voice.sh`** pinning the winning invocation end-to-end
   (voice download + render + shift + resample), so the voice is reproducible and the next tweak
   is a one-liner.

## Keep unchanged (no regression)

- Success gate (silent on MISS / dead tap) and PERFECT-brighter-than-OK via `MarkPayoff.brightness`.
- Stable cue id + `VOICE_ASSET` path — the human Maren recording is still a no-code-change drop-in.
- `_voice_blip()` stays as the absent-asset fallback.

## Verification

- `nix develop -c bash verify.sh` green (import → boot → test → export); `.wav` imports cleanly.
- Audio can't be heard headless → judged **wired + a brighter/female native-Swedish spoken asset
  loaded under the cue**; the **on-device listen is the owner's** (they chose "just deploy" and
  will judge brightness/gender on the live site). Note in Results that the timbre call rides that
  listen, and the human Maren voice remains the narrowed-flag endgame.
- Update the voice flag's "Assumption while building" line: the shipped stand-in is now a
  **bright female Swedish** Piper "Bra!" (name the voice), replacing the 044 NO clip.

## Acceptance Criteria

- [x] `assets/audio/bra_tts_placeholder.wav` is a **bright, female** native-**Swedish**
      Piper "Bra!", mono / 16-bit / 22050 Hz; brighter + higher-f0 than the 044 NO clip.
- [x] No GDScript change; the voice-asset test stays green (verify test leg green).
- [x] Gate intact: silent on MISS/dead; PERFECT louder + slightly higher than OK (untouched —
      asset swap only, `payoff_player.gd` unchanged).
- [x] `verify.sh` green; `.wav` + `.import` (byte-identical, see Results) + `tools/gen_bra_voice.sh` committed.
- [x] Exact voice id recorded in Results (provenance); no pitch/formant shift needed (native female).
- [x] Voice flag note updated; narrowed human-Maren flag left open (this task does not close it).

## Results (2026-07-01)

**What shipped:** the neutral `no_NO-talesyntese-medium` clip (task 044) at
`assets/audio/bra_tts_placeholder.wav` is replaced by a **bright, light, female native-Swedish**
Piper "Bra!". Same path, same cue id → **zero GDScript change** (`payoff_player.gd:27`
`VOICE_ASSET` unchanged), verify gate green (import · boot · test · export), voice-asset test
green. No pitch/formant DSP was needed — a native female voice was found.

**Voice chosen: `sv_SE-alma-medium`** (rhasspy/piper-voices, `sv/sv_SE/alma/medium`) — single
**female** speaker, 22050 Hz native. Swedish "bra" is the same word / meaning / ~identical
/brɑː/ as Norwegian, so the cue stays correct while gaining the brighter female timbre.

**Audition sweep (headless "bright + female" proxy — measured f0 + spectral centroid, since
headless can't hear):**

| voice | f0 | centroid | verdict |
|-------|----|----|----|
| 044 `no_NO-talesyntese-medium` (old) | 149 Hz | 811 Hz | neutral/dark (baseline) |
| `sv_SE-nst-medium` | **90 Hz** | 685 Hz | **male** — rejected |
| `sv_SE-lisa-medium` | 208 Hz | 1035 Hz | female, good |
| **`sv_SE-alma-medium`** (shipped) | **223–227 Hz** | **1030–1116 Hz** | **female + brightest — chosen** |

**Shipped clip:** f0 ≈ **223 Hz** (female range 180–250), spectral centroid ≈ **1116 Hz** (vs 811
— +38% brighter), 0.43 s, mono 16-bit 22050 Hz, peak **−5.0 dBFS** (matches the 044/espeak
headroom so the swap changes *timbre, not loudness* — the layered click + PERFECT/OK gate are
unaffected). A gentle **+3 dB high-shelf @ 3.5 kHz** adds the "brighter/lighter" air on top of the
native female timbre; 5 ms/15 ms declick fades; leading/trailing silence trimmed.

**Reproducibility:** `tools/gen_bra_voice.sh` pins the whole pipeline (fetch alma model → piper
render `--length-scale 1.0` → trim → high-shelf → fades → peak-normalise → 22050 Hz mono/16-bit).
Run inside the devshell: `nix develop -c bash tools/gen_bra_voice.sh`. **Note:** Piper's VITS model
is mildly stochastic, so exact bytes vary per run, but every render lands in-target (f0 ~220–235,
centroid ~1030–1116) — the metrics, not the bytes, are the contract. The `.import` sidecar is
**byte-identical** (wav importer stores no source hash; UID + params unchanged), so only the `.wav`
content changed on the export.

**On-device timbre call is the owner's** — they said "just deploy without asking," so this shipped
to the live site; the brightness/gender judgement rides their live-site listen, and the warm
**human Maren** recording remains the narrowed-flag endgame (this task does **not** close it).
