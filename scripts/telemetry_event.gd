class_name TelemetryEvent
extends RefCounted
## Pure builder for the PostHog /capture/ payload — the auditable core of ADR-0007.
## Every captured event is ANONYMOUS and cookieless by construction:
##   - distinct_id is the ephemeral, memory-only session id (never a persisted visitor id);
##   - $process_person_profile = false → PostHog creates NO person profile (no identity graph);
##   - $geoip_disable = true → server-side IP/geo enrichment is off (X-8: "anonymous" is literal).
## These three privacy flags are LOCKED — written after the caller's props are merged, so a call
## site can never (accidentally or otherwise) clobber them back on. Pure and tree-free so the whole
## envelope is unit-testable without a network or a scene.

## Build the capture payload for `event` with `props`, tagged to the ephemeral `session_id`.
static func build(token: String, event: String, session_id: String, props := {}) -> Dictionary:
	var properties := {}
	for k in props:
		properties[k] = props[k]
	# Privacy invariants — written LAST so caller props can never override them.
	properties["$session_id"] = session_id
	properties["$process_person_profile"] = false
	properties["$geoip_disable"] = true
	return {
		"api_key": token,
		"event": event,
		"distinct_id": session_id,
		"properties": properties,
	}
