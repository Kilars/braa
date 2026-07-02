class_name JoyBeat
extends RefCounted
## The post-BRA joyful celebration beat (077, PO Note 7). PURE: a damped Transform3D offset from the
## dog's rest, driven each frame by main.gd on the dog ROOT (the same root the WanderField roam, the
## FaceTurn and the confused beat already move; the AnimationPlayer animates the skeleton, so this
## never fights the seated clip). It is the positive twin of main.gd's procedural confused beat.
##
## Why procedural, not the authored hop: the licensed pack's only in-place celebration clip is
## `Jump_Place_IP`, which ROTATES the dog rear-to-camera (tail straight up) and snaps through a side
## profile — exactly the "chaotic, unnatural" payoff the PO caught (frames B-react-016→022). There is
## no wag/tail celebration clip in the manifest to swap to. So the mark celebration is driven here as
## a small, coherent, FACING-PRESERVING bounce + gentle body waggle instead: it eases in and out, its
## yaw is hard-capped tiny (MAX_YAW) so it can NEVER spin the dog away, and it settles EXACTLY back to
## rest (no drift) — the same exact-restore invariant the confused beat holds. Amplitude scales with
## the reduced-motion factor (X-5): scale 0 ⇒ no beat at all.
##
## Determinism (no Node, no time source of its own) is why the contract is unit-tested headless while
## the node-driving glue is Visual-Review-gated — the same split as FaceTurn (061) and WanderField (050).

const DURATION := 0.55        ## seconds — one coherent celebration beat, then back to rest
const BOUNCES := 2.0          ## little hops / waggle cycles across the beat
const BOB_HEIGHT := 0.05      ## metres — a small upward bob at full motion (an excited lift)
const WAGGLE := 0.06          ## radians (~3.4°) — a gentle symmetric body waggle around the facing
const MAX_YAW := 0.12         ## radians (~6.9°) — hard cap the yaw can NEVER exceed (facing invariant)

## The celebration offset (relative to the dog's rest transform) at `age` seconds into the beat,
## scaled by the reduced-motion factor `motion` (0..1). Returns identity before the beat starts
## (age < 0), once it is over (age >= DURATION), or under full reduced motion (motion == 0) — so the
## dog is placed exactly at rest in every one of those cases (no drift). Between, a damped up-only bob
## (never sinks the dog into the grass) plus a symmetric, yaw-capped waggle: a happy wiggle that
## stays facing the player.
static func offset(age: float, motion: float) -> Transform3D:
	if age < 0.0 or age >= DURATION:
		return Transform3D.IDENTITY
	var t := age / DURATION
	var damp := 1.0 - t                                   # decays to nothing as it settles — no drift
	var m := clampf(motion, 0.0, 1.0)
	var bob := absf(sin(t * PI * BOUNCES)) * BOB_HEIGHT * damp * m        # up-only little hops
	var yaw := clampf(sin(t * TAU * BOUNCES) * WAGGLE * damp * m, -MAX_YAW, MAX_YAW)  # capped waggle
	return Transform3D(Basis(Vector3.UP, yaw), Vector3(0.0, bob, 0.0))
