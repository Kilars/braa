#!/usr/bin/env bash
# Bra! verify gate — Godot 4 headless (task 023; replaces the bun four:
# typecheck / test / build / e2e). Four fail-closed legs, in order:
#
#   1. import   glTF dog → .scn, textures → .ctex          (must exit 0)
#   2. boot     run main.tscn headless, assert it's clean  (no script/scene error)
#   3. test     headless GDScript runner                   (exit 1 on any failure)
#   4. export   Web/PWA build + bundle-exists gate         (the build gate)
#
# Run inside the project devshell so `godot` (pinned 4.6.3) is on PATH:
#   nix develop -c bash verify.sh
# Green output ends with "verify gate green"; any failing leg aborts (set -e).
set -euo pipefail
cd "$(dirname "$0")"

step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }

# 1. Import — generates .godot/imported/* so scenes/resources are loadable.
step "1/4 import resources"
godot --headless --import

# 2. Boot — run the main scene for a few frames. Headless boot returns 0 even on
#    a logged script error, so we GATE on the output: any script/scene error or a
#    failed model load fails the leg, and the readiness print must appear.
step "2/4 boot main scene"
boot_log="$(mktemp)"
godot --headless --quit-after 60 2>&1 | tee "$boot_log"
if grep -qE 'SCRIPT ERROR|SCENE ERROR|dog model failed to load|Failed to (load|instantiate)|is_inside_tree' "$boot_log"; then
	echo "::error:: boot produced a script/scene/load error (incl. look_at-before-add_child / out-of-tree)"; exit 1
fi
grep -q '\[Bra!\] scaffold ready' "$boot_log" || { echo "::error:: readiness signal '[Bra!] scaffold ready' missing"; exit 1; }

# 3. Unit tests — discovers res://tests/test_*.gd, exits 1 on any failed assertion.
step "3/4 unit tests"
godot --headless --script res://tests/test_runner.gd

# 4. Web export — the build gate; then assert the bundle is real (mirrors the
#    deploy.yml export gate, so a green-but-empty publish can't slip through).
step "4/4 web export"
rm -rf build/web && mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html
for f in index.html index.js index.wasm index.pck \
         index.manifest.json index.service.worker.js; do
	test -s "build/web/$f" || { echo "::error:: export missing build/web/$f"; exit 1; }
done

printf '\n\033[1;32m✓ verify gate green\033[0m  (import · boot · test · export)\n'
