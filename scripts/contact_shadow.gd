class_name ContactShadow
extends RefCounted
## Pure placement for the dog's blob contact shadow (031, P1-1): a soft dark disc on the
## ground under the feet so the dog reads as standing ON something, not floating (the PO
## play-test found the paws meeting flat blue with nothing beneath in every pose). Sized
## and placed off the SAME DogBounds AABB the camera frames from, so it's model-agnostic
## (CC0 placeholder + licensed Labrador) and needs no per-model tuning — the same principle
## as DogFraming. Pure + unit-tested, no scene needed; main wires the actual flat mesh.

## The disc is a little wider than the bare footprint so its soft edge falls off OUTSIDE
## the paws rather than cutting them at the silhouette — a tight disc reads as a coaster,
## a slightly-overhanging one reads as a shadow.
const FOOTPRINT_SCALE := 1.15

## World position of the blob: under the dog's footprint centre (x/z) at the foot plane
## (the AABB's minimum Y — where the feet meet the floor), so it sits exactly beneath the
## paws whichever dog ships.
static func position(box: AABB) -> Vector3:
	var c := box.get_center()
	return Vector3(c.x, box.position.y, c.z)

## Radius of the soft disc, from the LARGER horizontal half-extent of the footprint so a
## long dog still gets a shadow that spans its stance (never a coaster under the chest),
## scaled out past the bare footprint by FOOTPRINT_SCALE.
static func radius(box: AABB) -> float:
	return maxf(box.size.x, box.size.z) * 0.5 * FOOTPRINT_SCALE
