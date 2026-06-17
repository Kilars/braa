# Bra!

**Bra!** is a mobile-only dog-training timing game. You play a trainer watching a dog from a first-person viewpoint: the dog cycles through behaviors, and the moment the correct one hits its apex you tap the big **"BRA"** ("good" in Norwegian) marker. Precise timing teaches the dog; sloppy timing confuses it. On top of this single-verb timing core sits a light collection layer — earn coins and XP, adopt new breeds, buy kennel upgrades, unlock marker phrases — in the spirit of a gentle idle-progression loop. The feel is inspired by a Norwegian dog-training TV show where the trainer says *bra* constantly: repetitive, a little annoying, and weirdly addictive.

---

## Quick start

```bash
bun install
```

| Command | Description |
|---------|-------------|
| `bun run dev` | Start the Vite dev server |
| `bun run build` | Production bundle via Vite |
| `bun run test` | Run the full Vitest suite (440 tests) |
| `bun run typecheck` | Type-check with `tsc --noEmit` |
| `bun run e2e` | End-to-end smoke test (Playwright, headless Chrome required) |
| `bun run cap:sync` | Sync web build into native projects (after `cap add`) |

---

## Tech stack

| Layer | Choice |
|-------|--------|
| Language | TypeScript |
| Build | Vite |
| Package manager / runtime | Bun |
| 3D rendering | Babylon.js (WebGL, lazy-loaded) |
| 2D UI | DOM / HTML-CSS overlay on the canvas |
| Persistence | IndexedDB (client-side only; no backend) |
| Distribution | Installable PWA (`vite-plugin-pwa`); wrappable for app stores via Capacitor |
| Tests | Vitest (unit) + Playwright (e2e smoke) |
| CI | GitHub Actions (`.github/workflows/ci.yml`) |

The architecture is a client-only PWA: the Babylon.js scene renders the dog and backdrop; a DOM HUD sits on top for the BRA marker, progress bars, and menus; save state lives in IndexedDB. Babylon.js is lazy-loaded (dynamic import) so the initial bundle stays under 30 KB.

Full rationale — why Babylon over Godot, the 3D-on-mobile cost model, persistence decisions, and tuning constants — is in [`.docs/tech-decisions.md`](.docs/tech-decisions.md).

---

## Features

### Timing core
- **Apex tell**: a subtle visual pulse/ring at the peak of each correct behavior — fainter and faster on harder difficulties
- **Four tap outcomes**: PERFECT (on-apex), OK (inside window off-peak), MISS (just outside window on a genuine attempt — no penalty), FALSE MARK (tap with no window open — bar penalty + confuse debuff)
- **Confuse debuff**: ~3 s narrowed window + more distractors after a false mark; refreshes but does not stack
- **Combos**: consecutive PERFECT/OK hits compound a fill multiplier up to 2× (reached at 11-hit streak)

### Tricks
Commands use their Norwegian names. The full implemented catalog:

| Trick | Type | Notes |
|-------|------|-------|
| Sitt | Starter | Easiest; baseline window and learn speed |
| Ligg | Starter | Medium; 25% slower fill, 20% tighter window |
| Legg deg | Starter | Hardest starter; 50% slower fill, 40% tighter window |
| Ikke hopp | Untraining | Mark the *absence* of a bad habit (dog jumping); the untraining variant of the one-verb loop |
| Rull | Signature (Border Collie) | Roll over |
| Ul | Signature (Husky) | Howl |
| Sov | Signature (Bulldog) | Play dead / sleep |
| Snurr | Signature (Puddel) | Spin |

### Breeds (5)
Each breed has distinct personality stats (learn speed, distractibility) that drive the difficulty levers:

| Breed | Intrinsic difficulty | Adopt cost | Signature trick |
|-------|---------------------|-----------|----------------|
| Labrador | 1.0 (neutral) | Free (starter) | — |
| Border Collie | 1.5 (harder) | 200 coins | Rull |
| Bulldog | 1.3 | 150 coins | Sov |
| Husky | 1.8 (most challenging) | 300 coins | Ul |
| Puddel | 1.4 | 225 coins | Snurr |

Effective difficulty = global mode × breed-intrinsic. Mastered tricks are re-practiceable for a reduced payout, so no soft-lock is possible.

### Economy
- **Coins + XP** on every mastery; both scale with difficulty mode × kennel multiplier × prestige multiplier
- **Trainer levels** (1–5) gate content tiers; XP comes from active play only (idle is coins, never XP)
- **Idle income**: capped coin trickle while away (cap: 110 coins ≈ ~2 minutes idle); never replaces active play
- **Kennel shop**: three upgrade tiers (Treats Pouch 100c / Pro Clicker 250c / Training Dummy 500c) each multiplying mastery payout
- **Adopt shop**: buy any of the four non-starter breeds once the level gate is met
- **Prestige**: graduate a fully-trained dog for a prestige point; multiplier `min(2.5, 1 + points × 0.1)` on all future payouts

### Marker phrases
Collectible Norwegian affirmation words — each is a loadout for the BRA tap:

| Phrase | Window bonus | Reward bonus | Cooldown | Unlock |
|--------|-------------|-------------|---------|--------|
| bra | — | — | none | always |
| flink | +150 ms | +10% | 8 s | 50 coins, level 1 |
| super | +250 ms | +20% | 12 s | 275 coins, level 3 |
| dyktig | — | +15% | 6 s | available in catalog |
| kjempebra | +100 ms | +25% | 15 s | available in catalog |

### Difficulty modes
Three global settings (Normal / Hard / Expert) each adjusting window width, peak radius, distractor rate, tell intensity, and reward multiplier. Hard and Expert tighten the challenge but raise the payout — each is the rational choice at a different skill level. Balance-audited in iteration 11; six constants tuned in iteration 12.

### Audio
- **Per-mark SFX**: distinct sound per tap result, mute-aware
- **Mastery jingle**: arpeggio (C–E–G) on trick completion
- **Tap SFX**: tactile UI click
- **Ambient audio**: light training-ground background pad (lazy AudioContext, mute-aware)
The marker voice ("Maren") is deferred — see [`.docs/tech-decisions.md §3`](.docs/tech-decisions.md).

### Progression & meta
- **Achievements**: 6 tracked milestones visible in the settings panel
- **Daily streak**: 🔥 counter with date-logic tracking, displayed in settings
- **Onboarding drip**: systems revealed in stages (distractors → economy → phrases → kennel/difficulty) keyed to mastery count — no tutorial dump
- **Help overlay**: "?" how-to-play panel accessible at any time
- **Mastery celebration**: radial gold burst + confetti on trick completion (reduced-motion: fade variant)
- **Graduation / prestige**: graduate a dog once its full repertoire is mastered; earns prestige points
- **Settings panel**: mute toggle, stats view, reset, achievement list

### Accessibility & performance
- ARIA labels, `aria-pressed`, `role="dialog"` on all interactive elements and panels
- `:focus-visible` keyboard rings throughout
- Contrast-compliant color choices; dark pill labels on bright backgrounds
- `prefers-reduced-motion` respected (celebration uses fade, not burst)
- Babylon.js lazy-loaded: initial JS bundle ~29 KB; Babylon chunk loads only when the training scene opens

---

## Building native apps (iOS / Android)

Bra! ships as an installable PWA and can also be wrapped for the App Store /
Play Store via [Capacitor](https://capacitorjs.com/). The config is in
`capacitor.config.ts`. Building native binaries requires Android Studio (Android)
or Xcode (iOS, macOS only) — neither is available in headless/CI environments.

Full step-by-step instructions (prerequisites, one-time setup, `cap add`,
`cap sync`, opening in the IDE): [`.docs/native-build.md`](.docs/native-build.md)

---

## Project structure

```
src/
  core/          Pure game logic — fully unit-tested
                 (mark, session, scheduler, round, economy, breeds,
                  tricks, phrases, combo, prestige, kennel, roster,
                  achievements, streak, onboarding, markWithPhrase, …)
  state/         IndexedDB save/load (save.ts, storage.ts)
  render/        Babylon.js scene + dog state (scene.ts, dogState.ts)
  ui/            DOM HUD — hud.ts, viewModel.ts, hud.css
  audio/         Mark audio + ambient (markAudio.ts)
  app/           Cross-cutting helpers (gameHelpers.ts)
  main.ts        Entry point

.docs/
  specs.md           Full functional game design
  tech-decisions.md  Architecture choices, tuning constants, open questions
  native-build.md    Step-by-step iOS / Android build instructions
  status.md          Autonomous build summary and metrics

.github/
  workflows/ci.yml   CI: typecheck + test + build on push/PR

.task-board/
  in-progress/   Active tasks
  backlog/
  done/          54 completed tasks
  RALPH-LOOP.md  Per-iteration autonomous build log

e2e/
  smoke.mjs      End-to-end smoke: select → train → mark (Playwright)
```

---

## Status

- **Full spec implemented** — the complete v1 design plus all "Future / Post-v1" branches from the spec: combos, untraining ("Ikke hopp"), multiple breeds with signature tricks, full economy, idle income, kennel + adopt shops, marker phrase collection, difficulty modes, achievements, daily streak, graduation/prestige, onboarding drip, help overlay, mastery celebration, settings panel.
- **440 unit tests** across 25 test files + an **e2e smoke test** (`bun run e2e`); typecheck and build are clean.
- CI runs typecheck, tests, and build on every push (`.github/workflows/ci.yml`).
- Art is placeholder; the 3D dog is a sphere stand-in — the semi-realistic breed-recognizable pipeline remains the main content risk (see [`.docs/tech-decisions.md §2`](.docs/tech-decisions.md)).
- The marker voice ("Maren") is deferred pending sourcing decisions (see [`.docs/tech-decisions.md §3`](.docs/tech-decisions.md)).
