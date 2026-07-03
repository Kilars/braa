class_name Telemetry
extends Node
## The ADR-0007 telemetry choke-point (X-8): the ONLY node that talks to PostHog. Every capture
## in the game routes through Telemetry.capture() — a single audit point for what is collected and
## the only place the transport lives (direct HTTP, no JS SDK, no JavaScriptBridge).
##
## Anonymous + cookieless: the session id is generated in memory at construction and NEVER
## persisted — it dies on reload, so events correlate WITHIN a session (funnels) but never ACROSS
## sessions (no visitor tracking). See TelemetryEvent for the locked privacy flags.
##
## Fire-and-forget: capture() never blocks and never surfaces an error to gameplay (X-7 holds
## offline — a dropped event is fine, a stalled frame is not). Disabled builds (no project token)
## and off-tree instances no-op. The model lands dormant — its event call-sites + feedback UI are
## wired as their surfaces ship (X-8), the same way the difficulty stack shipped ahead of its HUD.

var _session_id: String
var _session_start_us: int

func _init() -> void:
	_session_id = _new_session_id()
	_session_start_us = Time.get_ticks_usec()

## The ephemeral, memory-only session id shared by every event this load. Never persisted.
func session_id() -> String:
	return _session_id

## Milliseconds elapsed since this session began — a session-relative clock (anonymous: no wall
## time leaves the device). Stamped on every event so "time to first successful BRA" and every
## other time-to-X metric is a single queryable property, not server-side timestamp arithmetic.
func ms_since_session_start() -> int:
	return int((Time.get_ticks_usec() - _session_start_us) / 1000)

## True when a project token is present (a real web export). Local/editor builds are disabled.
func is_enabled() -> bool:
	return TelemetryConfig.is_configured()

## Build the anonymous payload for one event, stamped with the session-relative clock. Pure and
## tree-free (no network) so the whole envelope stays testable even while telemetry is disabled.
func build_event(event: String, props := {}) -> Dictionary:
	var stamped := props.duplicate()
	stamped["ms_since_session_start"] = ms_since_session_start()
	return TelemetryEvent.build(TelemetryConfig.PROJECT_TOKEN, event, _session_id, stamped)

## Route one event to PostHog. No-op when disabled or off-tree. Fire-and-forget.
func capture(event: String, props := {}) -> void:
	if not is_enabled():
		return
	if not is_inside_tree():
		return
	_send(build_event(event, props))

func _send(payload: Dictionary) -> void:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result, _code, _headers, _body): req.queue_free())
	var err := req.request(
		TelemetryConfig.capture_url(),
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(payload))
	if err != OK:
		req.queue_free()

## A fresh, memory-only session id: wall-clock millis + a random suffix. Regenerated every load,
## written nowhere (no user://, no cookie) — the anonymity guarantee.
func _new_session_id() -> String:
	return "%d-%08x" % [int(Time.get_unix_time_from_system() * 1000.0), randi()]
