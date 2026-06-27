import { describe, expect, it } from "vitest";
import { clamp01, lerp } from "./math";

describe("clamp01", () => {
  it("passes through values already in range", () => {
    expect(clamp01(0)).toBe(0);
    expect(clamp01(0.5)).toBe(0.5);
    expect(clamp01(1)).toBe(1);
  });

  it("clamps out-of-range values to the boundaries", () => {
    expect(clamp01(-2)).toBe(0);
    expect(clamp01(42)).toBe(1);
  });
});

describe("lerp", () => {
  it("returns the endpoints at t=0 and t=1", () => {
    expect(lerp(10, 20, 0)).toBe(10);
    expect(lerp(10, 20, 1)).toBe(20);
  });

  it("interpolates the midpoint and clamps t", () => {
    expect(lerp(0, 100, 0.5)).toBe(50);
    expect(lerp(0, 100, 5)).toBe(100);
  });
});
