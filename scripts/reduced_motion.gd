class_name ReducedMotion
extends RefCounted
## Reduced-motion policy (specs2.md P1-8), task 024g.
##
## One place that answers "how hard should the authored motion cues pulse?" given the
## player's prefers-reduced-motion preference. The whole rule of P1-8 is **dampened,
## not removed**: with reduced motion on, the apex tell (and any other authored cue
## routed through main._motion_scale) still pulses so the apex stays readable — just
## softer. The pose-driven cues (the sit, the apex pose, the happy reaction) are never
## scaled at all, so they always read by pose; this factor only touches the added
## visual intensity on top. Keeping the policy pure (a bool → factor) is what makes
## the "never zero" contract test-first (test_reduced_motion.gd); the actual browser
## media-query read lives in query() and is exercised on the live web build.

## The dampened intensity factor when reduced motion is requested. Strictly inside
## (0, 1): below 1 so the cue is visibly calmer, above 0 so it is never removed — the
## apex tell still pulses and stays distinguishable. (test_reduced_motion locks this.)
const DAMPED := 0.35

## Map prefers-reduced-motion → the motion-scale factor every authored cue routes
## through (main._motion_scale). false → 1.0 (full), true → DAMPED (calmer, never off).
static func scale_for(reduced: bool) -> float:
	return DAMPED if reduced else 1.0

## Read the OS / browser prefers-reduced-motion preference. On the web export this is
## the live CSS media query via JavaScriptBridge; off-web (headless, desktop) there's
## no such query, so default to full motion (false). main calls this once at _ready and
## feeds the result through scale_for() into set_motion_scale() before the tell builds.
static func query() -> bool:
	if not OS.has_feature("web"):
		return false
	# matchMedia returns a MediaQueryList; .matches is the live boolean. Eval a STRING
	# sentinel ("1"/"0"), NOT the bare boolean: JavaScriptBridge marshals string results
	# reliably (cf. main._query_force_tell, which reads window.location.search as a String),
	# but a bare JS-boolean result comes back as a null Variant on the Web export — which,
	# fed through scale_for(), silently collapsed the motion scale to 0 and made the apex
	# tell permanently invisible in live play (the carried-over P1-4 blocker). The ternary
	# keeps the result a plain "1"/"0" even when matchMedia is absent, so the read can never
	# yield null again.
	var matched: Variant = JavaScriptBridge.eval(
		"(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) ? '1' : '0'",
		true)
	return matched == "1"
