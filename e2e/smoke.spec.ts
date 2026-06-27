import { expect, test } from "@playwright/test";

test("boots the app shell in portrait", async ({ page }) => {
  await page.goto("/");

  // The app signals readiness once the shell + render loop are mounted.
  await page.waitForFunction(() => window.__appReady === true);

  // The one verb is present, labelled, and reachable.
  const bra = page.getByTestId("bra-button");
  await expect(bra).toBeVisible();
  await expect(bra).toHaveText("BRA");

  // The scene canvas is mounted and has real (non-zero) layout size.
  const canvas = page.getByTestId("scene-canvas");
  await expect(canvas).toBeVisible();
  const box = await canvas.boundingBox();
  expect(box?.width ?? 0).toBeGreaterThan(0);
  expect(box?.height ?? 0).toBeGreaterThan(0);
});
