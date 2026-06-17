# Project: Bra!

Mobile-only dog-training timing game. Player marks the instant a dog performs a
desired behavior by tapping a big **"BRA"** ("good") marker; precise timing
teaches the dog. A light grind/collection layer (currency, levels, breeds,
tricks, marker phrases, a kennel of upgrades) wraps the timing core.

**This file and [.docs/tech-decisions.md](../.docs/tech-decisions.md) hold the
technical decisions. The functional design — what the game is and how it plays —
lives in [.docs/specs.md](../.docs/specs.md). Keep that separation: gameplay/design
goes in specs.md, implementation goes here.**

# Architecture

Client-only **PWA**, no backend. The front end has two layers:

- **3D scene** — **Babylon.js** (WebGL) renders the dog + backdrop.
- **2D UI** — **DOM / HTML-CSS overlay** (BRA marker, bars, menus, economy).

Save state lives in **IndexedDB**. Shipped to iOS/Android by wrapping the web app
with **Capacitor** (also installable as a plain PWA on the web). Rationale and
the Godot fallback are in [tech-decisions.md](../.docs/tech-decisions.md).

# Tech Stack

- **Platform target:** Mobile only, portrait; semi-realistic 3D dogs.
- **Language:** TypeScript.
- **Build / runtime:** Vite; Bun as package manager / runtime.
- **3D:** Babylon.js (WebGL).
- **UI:** DOM / HTML-CSS overlay on the 3D canvas.
- **Persistence:** IndexedDB (client-side only; no backend).
- **Distribution:** PWA + Capacitor wrap for App Store / Play Store.
- **Testing:** TBD (Vitest suggested for game-logic units).
- Full functional spec in [.docs/specs.md](../.docs/specs.md).

# Developer Notes

- Always use tools over bash for simple tasks like copy, find, etc.
- Always write in English, even if the user writes in another language
- Readability-first; all conventions documented in specs.md

# TDD (required for all functional code)

All **functional / game-logic** code is written **test-first** using the
**`tdd`** skill (Matt Pocock's red-green-refactor, vendored at
[.claude/skills/tdd](skills/tdd/SKILL.md)). Invoke the skill before writing
functional code.

- **Vertical slices only:** one test → minimal implementation → repeat. Never
  write all tests then all code (no horizontal slicing).
- **Test behavior through public interfaces**, not implementation details — tests
  should survive refactors.
- **Test runner:** Vitest (see Tech Stack) for game-logic units.
- **Scope:** the timing/scoring loop, learned-bar, economy, difficulty maths,
  phrase cooldowns, idle/kennel calculations, save/load — anything with logic.
  Pure rendering / 3D / asset glue that can't be meaningfully unit-tested is
  exempt and is instead covered by **Visual Review** below.

# Visual Review (required after visual tasks)

This is a visual-first game; "it compiles / tests pass" is **not** done for
anything that changes how the app looks.

- After **any visual task** — UI, layout, styling, animation, the 3D scene/dog,
  the BRA marker feel — run the **`polish`** skill before calling it done.
- Then **spawn review agents** to actually look at the result (run the app, take
  screenshots, view the rendered UI) and confirm it genuinely looks and feels
  good: alignment, spacing, motion, readability on a phone-sized portrait screen,
  and that the mark moment feels satisfying.
- Treat their findings as blocking polish work, not optional suggestions. Iterate
  until it looks good, not just until it works.

# AI Autonomy (limited product owner)

The product owner has **limited availability** — do not block on them for things
you can reasonably decide.

- Default to **proceeding autonomously**: make reasonable calls from
  [specs.md](../.docs/specs.md), [tech-decisions.md](../.docs/tech-decisions.md),
  and sensible defaults, and keep work moving.
- When you make a non-trivial decision on your own, **document it** in specs.md or
  tech-decisions.md so the record stays current.
- **Escalate only genuine, high-impact forks** that can't be sensibly defaulted
  (irreversible choices, money/legal/likeness, or a real change to the product
  vision). Batch these; don't drip one-off questions.
- Prefer finishing a coherent slice and reporting outcomes over asking permission
  mid-stream.