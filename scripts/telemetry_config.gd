class_name TelemetryConfig
extends RefCounted
## ADR-0007 telemetry config: the ONE place the PostHog endpoint + client token live.
## Region is EU (the owner's project is on eu.posthog.com) — data resident in the EU.
##
## PROJECT_TOKEN is the PostHog *project* key (phc_...): public by design (it ships in every
## client bundle regardless), so it is not sensitive — but it is injected at export from the
## POSTHOG_TOKEN GitHub secret rather than committed, to keep it out of the public repo. In
## local/editor builds it is EMPTY, which makes telemetry DISABLED (dormant): the choke-point
## no-ops, so verify / tests / local play send nothing. The live web export substitutes the real
## token. Mirrors how the licensed encryption key is CI-injected, never in the tree (ADR-0006).

## PostHog EU cloud ingestion host. Capture posts to HOST + "/capture/".
const HOST := "https://eu.i.posthog.com"

## Project token (phc_...). Empty here → telemetry disabled; injected at export in CI.
const PROJECT_TOKEN := ""

## The single-event capture endpoint.
static func capture_url() -> String:
	return HOST + "/capture/"

## True once a project token is present (a real web export). Empty token → disabled.
static func is_configured() -> bool:
	return not PROJECT_TOKEN.is_empty()
