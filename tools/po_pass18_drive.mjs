import { chromium } from "playwright";
const base = process.argv[2];
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });

// 1) BRA button at rest (no autotap) + training page
{
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errs = [];
  page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });
  await page.goto(base, { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(3500);
  await page.screenshot({ path: ".screenshots/P18-01-training-rest.png" });
  console.log("rest errors:", JSON.stringify(errs));
  await page.close();
}

// 2) completion menu via autotap → check «Fortsett treningen» primary CTA
{
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errs = [];
  page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });
  await page.goto(base + "?bra_autotap=1", { waitUntil: "load", timeout: 90000 });
  await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });
  await page.waitForTimeout(6000);
  // try to open the menu (Triks pill top-left)
  await page.mouse.click(60, 40);
  await page.waitForTimeout(1500);
  const open = await page.evaluate(() => window.__bra_menu_open);
  const trick = await page.evaluate(() => window.__bra_current_trick);
  await page.screenshot({ path: ".screenshots/P18-02-menu.png" });
  console.log("menu_open:", open, "current_trick:", trick, "menu errors:", JSON.stringify(errs));
  await page.close();
}

await browser.close();
