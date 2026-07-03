# 085 — FEATURE: feedback entrypoint UI → `feedback_submitted` (X-8 / ADR-0007)

**Type:** FEATURE (UI — **Visual Review gated**, X-6) · **Phase:** 3 — Dog breeds (**current-phase**, part
of the Phase-3 done bar per phase3.md Instrumentation) · **Source:** `.docs/specs/index.md` **X-8**,
`adr/0007-telemetry-and-feedback.md` (Feedback entrypoint) · **Priority:** the qualitative half of ADR-0007;
raw free-text is the higher-priority "why" signal over aggregate numbers. Depends on **084** (the choke-point
wiring) for the `capture` path.

## What it addresses

A low-friction feedback entrypoint so players can tell us *why*. ADR-0007 treats raw quotes as the primary
qualitative signal — the reporting step reads them verbatim.

**Placement (owner call, 2026-07-03):** a **"Give feedback" row inside the existing `TrickMenu`** — the
post-game / post-mastery menu that already pops after a round and is reopenable any time via the top-left
"Tricks" button. This lands it "in the menu after a game" *and* keeps it always-reachable (not just on quit),
and it reuses the menu we already have rather than adding a floating corner icon.

## Technical approach

- Add a **"Give feedback"** row to `TrickMenu` (portrait-safe, X-1) that opens a form:
  - **Free text** box (primary signal, required-ish).
  - Optional **quick-tag chips:** Bug / Idea / Too hard / Too easy / Confusing / Other.
  - Optional **1–5 rating**, shown **sparingly** (e.g. after a milestone, not every session — avoid fatigue).
  - A short **privacy note** link near the form: free text may contain PII → processing (not device
    storage); no cookie banner, but be honest about retention (ADR-0007 Open items).
- On submit → `_telemetry.capture("feedback_submitted", {text, tags, rating, screen_context, session_id})`.
  (session_id is stamped by the choke-point; screen_context = current trick/menu state.)
- Keep the form a **dumb renderer** fed by a pure form model (same discipline as `TrickMenu`/`CoinReadout`):
  the chip-set, validation, and the built payload are pure and unit-tested; layout/placement is Visual Review.

### TDD (RED first) + Visual Review

- Pure form-model tests: tag toggle, the assembled `feedback_submitted` payload carries text + tags +
  optional rating + screen_context; rating omitted when not shown; empty text handled.
- Visual Review: the "Give feedback" row is reachable in the menu (after a round and via the "Tricks"
  button); the form opens/closes over the menu; nothing collides with the menu rows / HUD / coin line.
  Capture frames via a `tools/web_capture_*.mjs` real-tap flow (open menu → Give feedback → submit).

## Acceptance criteria

- [ ] A "Give feedback" row in `TrickMenu` is reachable after a round and via the "Tricks" button, and opens the form.
- [ ] Submit routes through `Telemetry.capture("feedback_submitted", …)` with the documented props.
- [ ] Privacy note present near the form.
- [ ] Pure form model is TDD'd; **Visual Review PASS** on placement/interaction (real canvas taps).
- [ ] Placeholder check clean. `nix develop -c bash verify.sh` green.

## Notes

The rating is deliberately **sparse** (fatigue). Chip set is fixed per ADR-0007. The separate-inbox option
(Formspree/Tally) is an owner-gated Open item — default to PostHog event props unless the owner picks a sink.
