class_name FeedbackForm
extends RefCounted
## The pure, auditable core of the feedback entrypoint (085, X-8 / ADR-0007).
## Same discipline as TrickMenu.classify: all logic lives here, testable without any
## framebuffer, render, or scene tree. The form view (FeedbackFormView) is a dumb
## renderer that feeds user input in and reads the payload out.
##
## Rating is deliberately sparse (fatigue). It only travels when shown AND set (>= 1):
## the caller sets rating_shown = true on a milestone (e.g. first mastery) so the
## question surfaces infrequently, not every session.

## The six fixed feedback tags, per ADR-0007. Stable order: the payload always follows
## this order regardless of which order the player taps.
const TAGS := ["bug", "idea", "too_hard", "too_easy", "confusing", "other"]

## Player-facing labels for each tag, shown on the chip buttons in FeedbackFormView.
const TAG_LABELS := {
	"bug": "Feil",
	"idea": "Idé",
	"too_hard": "For vanskelig",
	"too_easy": "For lett",
	"confusing": "Forvirrende",
	"other": "Annet",
}

## The free-text field. strip_edges() is applied on build and has_text checks.
var text := ""
## The 1–5 star rating. 0 means unset. Only travels in the payload when rating_shown
## is true AND this is >= 1 — avoids "0 stars" noise (rating_shown=false → omit entirely).
var rating := 0
## Whether the rating row was shown to this player for this submit. The caller sets this
## true on a milestone (e.g. first trick mastered). When false, rating is ALWAYS omitted
## from the payload regardless of its value — the question was never asked.
var rating_shown := false

## Private tag set (present-or-absent, not an ordered list). TAGS drives order on read.
var _tags := {}

## Toggle a tag on/off. Unknown tags (not in TAGS) are silently ignored so no rogue
## key can leak into the payload.
func toggle_tag(tag: String) -> void:
	if not TAGS.has(tag):
		return
	if _tags.has(tag):
		_tags.erase(tag)
	else:
		_tags[tag] = true

## Whether a tag is currently toggled on.
func is_tag_on(tag: String) -> bool:
	return _tags.has(tag)

## The currently selected tags in stable TAGS order (not insertion order). Used both
## for chip rendering and as the payload value.
func selected_tags() -> Array:
	var out: Array = []
	for t in TAGS:
		if _tags.has(t):
			out.append(t)
	return out

## True when text contains non-whitespace content (strip_edges).
func has_text() -> bool:
	return not text.strip_edges().is_empty()

## Build the telemetry payload. screen_context is whatever the caller knows about the
## game state at open time (trick, menu_open, etc.) — passed through unchanged.
## "rating" is added ONLY when rating_shown is true AND rating >= 1. All other fields
## are always present, even when empty (predictable schema for PostHog).
func build_payload(screen_context: Dictionary) -> Dictionary:
	var p := {
		"text": text.strip_edges(),
		"tags": selected_tags(),
		"screen_context": screen_context,
	}
	if rating_shown and rating >= 1:
		p["rating"] = rating
	return p
