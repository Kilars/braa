# Tech decisions & verified findings

Implementation notes that don't belong in the read-only spec or in an ADR.
Newest first.

---

## 2026-06-28 — ADR-0006 encrypted PCK: what the official templates can and can't do (task 025)

**Context:** ADR-0006 ships the licensed Labrador on the public web as an *encrypted*
Godot PCK so the model isn't trivially extractable. Before building the CI pipeline,
I spiked the encryption path locally with the pinned official templates (Godot 4.6.3,
`flake .#export-templates` = `godot_4-export-templates-bin`) to size exactly what is
owner-gated. Three experiments, all reproducible:

1. **Added a `Web Licensed` export preset** (`export_presets.cfg` `[preset.1]`): a copy
   of `Web` with `encrypt_pck=true`, `encrypt_directory=true`,
   `encryption_include_filters="*"`.

2. **Exported it with a throwaway key** —
   `GODOT_SCRIPT_ENCRYPTION_KEY=<64 hex> godot --headless --export-release "Web Licensed" …`
   → **exit 0, real encrypted PCK produced.** PCK header `pack_flags` bit 0
   (`PACK_DIR_ENCRYPTED`) is set: plain `Web` pck = `0x2`, licensed pck = `0x3`.
   ⇒ **The official export *tool* encrypts fine** using the env-var key at export time.

3. **Tried to boot the encrypted PCK with the official engine binary** (same family as
   the official web runtime template — built with the *default/empty* key):
   - `godot --headless --main-pack web-licensed/index.pck` → `ERROR: The MD5 sum of the
     decrypted file does not match … Can't open encrypted pack directory … Cannot open
     resource pack`.
   - **Same failure with `GODOT_SCRIPT_ENCRYPTION_KEY` set at runtime.**
   - Control: the plain `Web` pck boots clean (`[Bra!] scaffold ready`).

### Verified conclusions (these size the owner gate)

- **`GODOT_SCRIPT_ENCRYPTION_KEY` is export-time only.** Setting it at *runtime* does
  nothing — the runtime decrypts with the key **compiled into the template**, not an
  env var. Any plan that "passes the key to the running web build" is a dead end.
- **Official templates cannot decrypt a custom-key PCK.** ADR-0006's core requirement
  stands, now empirically: the licensed web build needs **custom Godot web/wasm export
  templates built from source with `SCRIPT_AES256_ENCRYPTION_KEY` baked in.**
- **The export-side config is done and verified** (the `Web Licensed` preset). What
  remains is purely the template build + secret injection + the publish flip.

### Precise owner-gated runbook (the real remainder of 025)

The local verify gate and the public CC0 deploy export **`Web`** (no key, official
templates) and stay green without any of this. The licensed profile is additive and
secret-gated:

1. **Secrets (owner-only, GitHub repo → Settings → Secrets):**
   - `GODOT_SCRIPT_ENCRYPTION_KEY` — 64 hex chars (AES-256). Generate once:
     `openssl rand -hex 32`. Used at **both** template-build time (baked in) and export
     time (must match).
   - `LICENSED_DOG_GLB_B64` (or a private artifact URL) — the gitignored licensed
     Labrador, base64'd. Never commit it; inject at CI time only (ADR-0005/0006).

2. **Custom web templates from source** (the heavy, slow, owner-gated step ADR-0006
   already flags as "from-source custom-template build in CI"):
   - Check out the Godot source at the **exact engine version** (4.6.3 — match
     `flake.lock`'s `godot_4`), with the emscripten version that release pins.
   - `export SCRIPT_AES256_ENCRYPTION_KEY=$GODOT_SCRIPT_ENCRYPTION_KEY`
   - `scons platform=web target=template_release production=yes` → install the produced
     `.zip`/templates into `~/.local/share/godot/export_templates/<ver>/`.
   - **Nix-native alternative** (preferred, keeps the version pin): add a flake output
     that overrides the godot template derivation to set `SCRIPT_AES256_ENCRYPTION_KEY`
     at build time (needs `--impure`/a build-arg to read the secret). Build it with
     `nix build .#export-templates-licensed`. *Not yet authored — needs the key to
     validate, so it's owner/CI work, not committed blind.*

3. **Export & gate (mirrors the existing CC0 job, different preset + key):**
   - Decode `LICENSED_DOG_GLB_B64` → `assets/models/dog_licensed.glb` (main.gd already
     auto-selects it via `ResourceLoader.exists`, see `_dog_path()`).
   - `godot --headless --import`
   - `GODOT_SCRIPT_ENCRYPTION_KEY=… godot --headless --export-release "Web Licensed" build/web-licensed/index.html`
   - Same bundle-exists gate as `verify.sh`/`deploy.yml`.

4. **Validate before publishing (ADR-0006 follow-up):** build the licensed bundle as a
   **CI artifact first**; the owner smoke-tests it on Chrome (installs as a PWA, plays
   offline, dog actually **Sitts**). Only after that passes does Pages get repointed
   from the CC0 bundle to the licensed one. Do **not** auto-publish the unvalidated
   encrypted build over the working CC0 deploy.

This sequencing keeps the public site live on CC0 throughout, and means a wrong template
build can never take down the deploy — it just produces a bad artifact the owner catches.

---

## 2026-06-28 — ADR-0006 pipeline AUTHORED: `.github/workflows/deploy-licensed.yml` (task 025)

The owner-gated runbook above is now an actual workflow. Concrete values pinned from the
flake + Godot source (not guessed):

- **Engine / template version match (load-bearing).** Export tool = flake-pinned Godot,
  which reports `4.6.3.stable` (`nix develop -c godot --version`). NOTE the floating
  `nixpkgs#godot_4` registry is already `4.7` — building the template from that would
  reproduce the MD5/decrypt failure. The template is built from `godotengine/godot` at tag
  **`4.6.3-stable`** (same source the pinned nixpkgs editor uses). The workflow asserts the
  engine `--version` prefix is `4.6.3.stable` before exporting and fails closed on drift.
- **Emscripten `4.0.11`**, via `emscripten-core/setup-emsdk@v16` — read from Godot's own
  `.github/workflows/web_builds.yml` (`EM_VERSION`) at the 4.6.3 tag. Not a guess.
- **Template build:** `scons platform=web target=template_release threads=no
  use_closure_compiler=no` with `SCRIPT_AES256_ENCRYPTION_KEY` in the env (baked into
  `core/script_encryption_key.gen.cpp`, a `uint8_t[32]` — hence the 64-hex key). Output
  `bin/godot.web.template_release.wasm32.nothreads.zip` → installed as
  `web_nothreads_release.zip` (the editor's name for the single-threaded release web
  template — `thread_support=false` in the preset; confirmed against the official `.tpz`
  layout). `production=yes`/closure intentionally OFF on the first cut (correctness over
  size; dodges LTO OOM/time on a runner) — enable once it's proven.
- **Template install:** overlay the custom `web_nothreads_release.zip` onto the official
  `.tpz` templates dir (which supplies `version.txt` + the other templates), so only the
  one template we ship carries the key.

### Secret-delivery correction (important)

`LICENSED_DOG_GLB_B64` **does not work** — GitHub Actions secrets are capped at **48 KB**
and the self-contained glb is ~19 MB (the glb embeds its 3 textures: `materials/extract=0`,
so a single file suffices, but it's still far too big for a secret). The workflow instead
fetches the glb from a **private URL**:

- `GODOT_SCRIPT_ENCRYPTION_KEY` — 64 hex (`openssl rand -hex 32`). **Keep a copy.**
- `LICENSED_DOG_URL` — private/presigned URL to the glb (presigned S3/GCS/Backblaze, or a
  private GitHub release-asset API URL). The URL itself is the secret.
- `LICENSED_DOG_AUTH` *(optional)* — an `Authorization` header value if the URL needs auth
  (e.g. `Bearer ghp_…` + the workflow adds `Accept: application/octet-stream` for GitHub
  release assets).

### Validation layering (why this isn't self-certified-blind)

- **Proven locally** (with a throwaway key, official templates): the `Web Licensed` preset
  exports all 6 bundle files; the resulting `index.pck` is genuinely encrypted (the
  empty-key linux runtime fails with `MD5 sum of the decrypted file does not match`,
  exactly obs-2429), while the plain `Web` pck boots — so the workflow's "is it encrypted"
  negative test discriminates correctly.
- **Proven only by the first CI run** (cannot be tested on a dev laptop — needs emscripten
  + the key): the from-source template build, and the **positive** proof — headless
  Chromium boots the encrypted web bundle (`tools/web_boot_check.mjs`), reaching
  `window.__appReady` (⇒ the custom-key template decrypted the pck) with console signals
  `dog_licensed.glb` + `dog can Sitt` (⇒ it loaded the licensed dog, which can Sitt).
- **Default = artifact only.** `deploy-licensed.yml` is `workflow_dispatch`; it uploads the
  bundle as an artifact and only publishes to Pages when dispatched with `publish=true`,
  after all the above pass. The live CC0 site stays up until the owner flips it.
