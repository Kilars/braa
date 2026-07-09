// Task 194 self-review: master TWO tricks so the «Vanskelighet» section reveals (MenuReveal
// gates it at mastered_count>=2), then capture the completion menu to confirm the selectable
// Hard/Ekspert difficulty rows now carry a right-side blue «Bytt» badge like the word/breed
// switch rows. select_trick (via a trick-row tap) auto-closes the menu, so we switch trick
// between masteries without a fragile close dance.
import { chromium } from "playwright";
import { writeFile } from "fs/promises";
const base = "http://localhost:8099/index.html";
const P = ".screenshots/P194-";
const browser = await chromium.launch({ args: ["--no-sandbox", "--disable-dev-shm-usage", "--use-gl=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const errs = [];
page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });
const g = async k => page.evaluate(new Function("return window.__bra_" + k + " ?? null"));
async function tapVp(x, y) {
  const box = await page.locator("canvas").boundingBox();
  const vp = await g("viewport") || [720, 1280];
  await page.mouse.click(box.x + x * box.width / vp[0], box.y + y * box.height / vp[1]);
}
async function cap(n){ await page.screenshot({ path: `${P}${n}.png` }); }

await page.goto(base + "?bra_autotap=1&bra_coins=5000", { waitUntil: "load", timeout: 90000 });
await page.waitForFunction("window.__appReady === true", undefined, { timeout: 120000 });

// 1) Let the autotap master the starting trick (Sitt). Poll the menu until words reveal.
async function openMenu(){ await tapVp(70, 32); await page.waitForTimeout(1200); return await g("menu_open"); }
async function tryMasterAndOpen(maxMs){
  const t0 = Date.now();
  while (Date.now() - t0 < maxMs) {
    await page.waitForTimeout(6000);
    await openMenu();
    const diffs = await g("difficulty_rows") || [];
    const words = await g("word_rows") || [];
    if (diffs.length > 0) return { diffs, words, done: true };
    // not enough masteries yet — close menu by choosing the CURRENT trick is a no-op that
    // keeps it open, so instead switch to the next available trick to close + progress.
    return { diffs, words, done: false };
  }
  return { done: false };
}

// First mastery: wait, then open menu.
await page.waitForTimeout(62000);
let open = await openMenu();
console.log("after1 menu_open", open, "current", await g("current_trick"));
let diffs = await g("difficulty_rows") || [];
let tricks = await g("trick_rows") || [];
console.log("after1 diffs", diffs.length, "tricks", tricks.map(t=>t.id));
await cap("a-after-first-mastery");

// Switch to Ligg (auto-closes the menu) so a SECOND distinct trick can be mastered.
const ligg = tricks.find(t => t.id === "ligg");
if (ligg) { await tapVp(ligg.x, ligg.y); await page.waitForTimeout(1500); }
console.log("switched current", await g("current_trick"), "menu_open", await g("menu_open"));

// Second mastery: wait (uninterrupted — opening the menu pauses training), then open menu.
await page.waitForTimeout(95000);
open = await openMenu();
diffs = await g("difficulty_rows") || [];
console.log("after2 menu_open", open, "current", await g("current_trick"), "diffs", JSON.stringify(diffs));
await cap("b-menu-difficulty");

console.log("errors", errs.length, errs.slice(0, 6));
await browser.close();
