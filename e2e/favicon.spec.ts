import { expect, test } from "@playwright/test";

// PO Review B1 / P1-9 ("it just works"): a clean load must log no errors. The
// browser 404s on /favicon.ico whenever the document declares no icon — it falls
// back to that well-known path and the Vite server has no such file (verified:
// GET /favicon.ico -> 404). Declaring an inline data-URI <link rel="icon"> removes
// the fallback entirely, so no request fires and no 404 is logged.
//
// Note (harness discrepancy, recorded in task 010): headless Chrome in this
// Playwright harness does not emit the implicit /favicon.ico request, so a pure
// network-404 listener cannot reproduce the bug. The faithful, red-able invariant
// is the declarative one below — the page must carry an inline icon. A secondary
// 404 listener still guards against any other missing asset on load.
test("declares an inline icon so the browser never 404s on /favicon.ico", async ({ page }) => {
  const notFound: string[] = [];
  page.on("response", (r) => {
    if (r.status() === 404) notFound.push(r.url());
  });

  await page.goto("/");
  await page.waitForFunction(() => window.__appReady === true);

  // Without this link Chromium falls back to /favicon.ico -> 404 (PO B1).
  const icon = page.locator('link[rel~="icon"]');
  await expect(icon).toHaveCount(1);

  const href = await icon.getAttribute("href");
  expect(href, "icon link must have an href").toBeTruthy();
  // Inline data-URI: zero network cost and offline-safe (X-7) — no file fetch.
  expect(href?.startsWith("data:"), "icon should be an inline data: URI").toBe(true);

  await page.waitForTimeout(200);
  expect(notFound, `unexpected 404s on load: ${notFound.join(", ")}`).toHaveLength(0);
});
