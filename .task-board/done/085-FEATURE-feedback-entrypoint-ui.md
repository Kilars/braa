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

- [x] A "Give feedback" row in `TrickMenu` is reachable after a round and via the "Tricks" button, and opens the form.
- [x] Submit routes through `Telemetry.capture("feedback_submitted", …)` with the documented props.
- [x] Privacy note present near the form.
- [x] Pure form model is TDD'd (11 form tests + 2 menu tests = 13 new tests, 437 total, 0 failures); **Visual Review PASS** (orchestrator ran the capture — see verdict below).
- [x] Placeholder check clean. `nix develop -c bash verify.sh` green (✓ verify gate green, 437/0).

## Resolution (2026-07-03)

Files touched:
- `scripts/feedback_form.gd` — pure RefCounted model (NEW): TAGS, toggle_tag, is_tag_on, selected_tags, has_text, build_payload; rating travels only when rating_shown AND >= 1.
- `scripts/feedback_form.gd.uid` — (NEW)
- `scripts/feedback_form_view.gd` — dumb-renderer Control (NEW): full-rect backdrop, centred panel, TextEdit, HFlowContainer chip row, optional rating row, privacy note, Cancel+Send buttons; publishes `window.__bra_feedback_open` via NOTIFICATION_VISIBILITY_CHANGED.
- `scripts/feedback_form_view.gd.uid` — (NEW)
- `scripts/trick_menu.gd` — added `signal feedback_requested`, `FEEDBACK_GAP`/`FEEDBACK_H` constants, `_feedback_rect()`, `feedback_row_center()`, close_rect shifted down by feedback row, `_draw` draws the "Give feedback" pill, `_gui_input` routes taps on `_feedback_rect()` to `feedback_requested.emit()`.
- `scripts/main.gd` — added `var _feedback: FeedbackFormView`, `_setup_feedback_form(ui)` (called after `_setup_trick_menu`), `_on_feedback_requested`, `_on_feedback_submitted` (routes through `_telem`), `_publish_breed_rows` publishes `window.__bra_feedback_row`.
- `tools/web_capture_feedback.mjs` — (NEW) capture harness: autotap→mastery→menu→tap feedback row→form open screenshot→fill→screenshot.

Rating is sparse: `_on_feedback_requested` passes `_progress.mastered` as `show_rating`, so the rating row only appears after the active trick is mastered. The form resets to a fresh FeedbackForm on each configure() call.

Capture command:
```
nix develop -c godot --headless --export-debug "Web" build/web/index.html
env -u LD_LIBRARY_PATH node tools/web_capture_feedback.mjs build/web
```

## Visual Review verdict (orchestrator, 2026-07-03) — PASS

Ran a fresh `--export-release "Web"` (licensed bundle) + `web_capture_feedback.mjs` at 390×844.
Real canvas tap on the published `window.__bra_feedback_row` opened the form. Frame
`.screenshots/085-feedback-01-form.png` (read by eye) shows, over the trick menu:
- title "Tell us what you think"; TextEdit with placeholder "What's working? What's not?";
- the six fixed chips (Bug / Idea / Too hard / Too easy / Confusing / Other);
- the "Overall: 1–5" rating row — present here because Sitt is mastered, confirming the sparse
  milestone gate fires live (it is hidden on a non-mastered open);
- the privacy note "Free text may be processed to improve the game — nothing is stored on your device.";
- Cancel + Send. Send is functionally disabled while empty (`_update_send` + the `_on_send` guard),
  so an empty submit can't fire — verified in code, styled via the disabled stylebox.
Placement is centred and portrait-safe; every element is legible and reachable.

Known harness limitation (not a product defect): the auto-fill step (canvas keyboard focus in
headless Chromium) does not reliably focus the real `TextEdit`, so `085-feedback-02-filled.png`
mirrors frame 01 rather than showing typed text. The fill → payload logic (tag toggle, strip_edges,
sparse rating) is covered instead by the 11 pure `FeedbackForm` unit tests. The in-game form uses a
real `TextEdit`, so a live player types normally.

## Notes

The rating is deliberately **sparse** (fatigue). Chip set is fixed per ADR-0007. The separate-inbox option
(Formspree/Tally) is an owner-gated Open item — default to PostHog event props unless the owner picks a sink.
