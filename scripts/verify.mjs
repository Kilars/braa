/**
 * scripts/verify.mjs — compact "dots" verification gate.
 *
 * Runs the project's checks (typecheck → tests → build) as child processes and
 * prints ONE dot per passing step instead of streaming each tool's full output.
 * This keeps automated callers (subagents, CI, the ralph loop) from flooding
 * their context with vitest per-file lines and the vite build chunk table.
 *
 * - On success: prints a short row of dots + a one-line summary (e.g. test count).
 * - On failure: prints the failing step's FULL captured output, then exits 1.
 *
 * Usage:  node scripts/verify.mjs           (typecheck + tests + build)
 *         node scripts/verify.mjs --no-build (skip the build step)
 * Full per-test output when you actually need it:  bun run test:verbose
 */

import { spawn } from "node:child_process";

const skipBuild = process.argv.includes("--no-build");

/** Run a command, buffering output. Resolves { code, out }. Never rejects. */
function run(cmd, args) {
  return new Promise((resolve) => {
    const child = spawn(cmd, args, { shell: false });
    let out = "";
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (out += d));
    child.on("close", (code) => resolve({ code: code ?? 1, out }));
    child.on("error", (err) => resolve({ code: 1, out: String(err) }));
  });
}

const steps = [
  { name: "typecheck", cmd: "tsc", args: ["--noEmit"] },
  { name: "tests", cmd: "vitest", args: ["run"] },
];
if (!skipBuild) {
  steps.push({ name: "build", cmd: "vite", args: ["build", "--logLevel", "error"] });
}

process.stdout.write("verify ");
let summary = "";

for (const step of steps) {
  const { code, out } = await run(step.cmd, step.args);
  if (code !== 0) {
    // Surface the failing step in full — this is the moment context detail matters.
    process.stdout.write(` ✗ ${step.name}\n\n`);
    process.stdout.write(out.trimEnd() + "\n");
    process.exit(1);
  }
  process.stdout.write("●");
  if (step.name === "tests") {
    const m = out.match(/Tests\s+(\d+)\s+passed/);
    if (m) summary = `${m[1]} tests`;
  }
}

process.stdout.write(`  ✓ ${steps.map((s) => s.name).join(" + ")}${summary ? `  (${summary})` : ""}\n`);
