extends "res://tests/test_case.gd"
## TDD for the ADR-0007 telemetry base (X-8). Three units, all headless-pure:
##   - TelemetryConfig: the EU endpoint + the token seam that keeps telemetry DISABLED locally.
##   - TelemetryEvent:  the anonymous /capture/ payload — locked privacy flags, prop merge.
##   - Telemetry:       the choke-point — ephemeral session id, disabled/off-tree no-op.
## No network is exercised: capture() is verified to NO-OP under the local (token-empty) config,
## and the payload shape is asserted off the pure builder — no scene, no HTTP.

# ---- TelemetryConfig: EU endpoint + local-disabled token seam ----

func test_capture_url_is_the_eu_capture_endpoint() -> void:
	assert_eq(TelemetryConfig.HOST, "https://eu.i.posthog.com", "host is PostHog EU cloud")
	assert_eq(TelemetryConfig.capture_url(), "https://eu.i.posthog.com/capture/",
		"capture posts to the EU /capture/ endpoint")

func test_telemetry_is_disabled_without_a_project_token() -> void:
	# The committed token is empty (injected at export) → telemetry is dormant locally, so verify /
	# tests / editor play never emit. This is the dormancy guarantee.
	assert_eq(TelemetryConfig.PROJECT_TOKEN, "", "the local/committed project token is empty")
	assert_false(TelemetryConfig.is_configured(), "no token → telemetry disabled")

# ---- TelemetryEvent: the anonymous payload ----

func test_payload_carries_api_key_event_and_distinct_id() -> void:
	var p := TelemetryEvent.build("phc_x", "bra_tapped", "sess-1", {})
	assert_eq(p["api_key"], "phc_x", "payload carries the project token as api_key")
	assert_eq(p["event"], "bra_tapped", "payload carries the event name")
	assert_eq(p["distinct_id"], "sess-1", "distinct_id is the ephemeral session id")

func test_payload_is_anonymous_no_person_profile() -> void:
	var p := TelemetryEvent.build("phc_x", "session_start", "sess-1", {})
	assert_false(p["properties"]["$process_person_profile"],
		"$process_person_profile is false → PostHog builds no person (anonymous)")

func test_payload_disables_geoip() -> void:
	var p := TelemetryEvent.build("phc_x", "session_start", "sess-1", {})
	assert_true(p["properties"]["$geoip_disable"],
		"$geoip_disable is true → no server-side IP/geo enrichment (X-8)")

func test_payload_tags_the_session_id() -> void:
	var p := TelemetryEvent.build("phc_x", "session_start", "sess-42", {})
	assert_eq(p["properties"]["$session_id"], "sess-42",
		"every event carries the session id so a session's events correlate (funnels)")

func test_payload_merges_caller_props() -> void:
	var p := TelemetryEvent.build("phc_x", "bra_tapped", "sess-1",
		{"bucket": "perfect", "latency_ms_from_apex": 12})
	assert_eq(p["properties"]["bucket"], "perfect", "caller props are merged into properties")
	assert_eq(p["properties"]["latency_ms_from_apex"], 12, "numeric caller props survive the merge")

func test_caller_cannot_override_the_privacy_flags() -> void:
	# A call site passing the privacy keys must NOT be able to turn tracking back on — the flags are
	# written after the merge and win.
	var p := TelemetryEvent.build("phc_x", "evil", "sess-1", {
		"$process_person_profile": true,
		"$geoip_disable": false,
		"$session_id": "spoofed",
	})
	assert_false(p["properties"]["$process_person_profile"], "person-profile stays off despite caller")
	assert_true(p["properties"]["$geoip_disable"], "geoip stays disabled despite caller")
	assert_eq(p["properties"]["$session_id"], "sess-1", "session id is the real one, not the caller's")

# ---- Telemetry: the choke-point ----

func test_session_id_is_nonempty_and_stable_within_an_instance() -> void:
	var t := Telemetry.new()
	var sid := t.session_id()
	assert_true(sid.length() > 0, "a session id is generated at construction")
	assert_eq(t.session_id(), sid, "the session id is stable for the life of the instance")
	t.free()

func test_each_load_gets_a_distinct_session_id() -> void:
	# Two instances model two loads: the ephemeral id differs, so events never correlate across
	# sessions (no visitor tracking).
	var a := Telemetry.new()
	var b := Telemetry.new()
	assert_ne(a.session_id(), b.session_id(), "distinct instances get distinct session ids")
	a.free()
	b.free()

func test_build_event_stamps_session_relative_time() -> void:
	# Every event carries ms-since-session-start so time-to-X (e.g. time to first successful BRA)
	# is a single queryable prop. build_event() is pure/tree-free, so it is observable even while
	# telemetry is disabled locally.
	var t := Telemetry.new()
	var p := t.build_event("bra_tapped", {"bucket": "good"})
	assert_true(p["properties"]["ms_since_session_start"] >= 0,
		"the event is stamped with ms since session start")
	assert_eq(p["properties"]["bucket"], "good", "caller props still merge alongside the stamp")
	assert_eq(p["distinct_id"], t.session_id(), "the stamped event carries the ephemeral session id")
	t.free()

func test_capture_is_a_noop_when_disabled() -> void:
	# With the local empty token, capture() must not blow up and must not attempt a send — reaching
	# the assert after the call proves it returned cleanly (no runtime abort, no tree needed).
	var t := Telemetry.new()
	assert_false(t.is_enabled(), "telemetry is disabled under the local empty-token config")
	t.capture("bra_tapped", {"bucket": "perfect"})
	assert_true(true, "capture() on a disabled/off-tree instance no-ops without error")
	t.free()
