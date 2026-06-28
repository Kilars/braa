{
  description = "Bra! — Godot 4 (GDScript) PWA dog-training game (v2)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      # Web/PWA export templates, sourced from the SAME pinned nixpkgs (flake.lock)
      # as the `godot_4` engine in the devShell below. CI builds this
      # (`nix build .#export-templates`) and symlinks it into
      # ~/.local/share/godot/export_templates/<ver>/ before exporting — so the engine
      # that packs the .pck and the wasm runtime template are ALWAYS the same version.
      # (Using `nixpkgs#…` from the floating registry instead could drift out of sync
      # with the pinned engine; this output designs that mismatch out.)
      packages = forAllSystems (pkgs: {
        export-templates = pkgs.godot_4-export-templates-bin;
      });

      # Project-level toolchain. `nix develop` (or direnv) puts the Godot 4
      # editor on PATH — no home-manager / global profile changes.
      #   nix develop          # enter a shell with `godot`
      #   nix develop -c godot  # launch the editor directly
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.godot_4 # GDScript editor + headless runtime (4.6.x). NOT -mono (that's C#).

            # Web/PWA export templates. Needed only to produce the exported
            # PWA build (Godot's web export has a first-class PWA toggle —
            # ADR-0004). Uncomment when we wire the export → GitHub Pages deploy;
            # left out of the default shell so the first `nix develop` stays lean.
            # pkgs.godot_4-export-templates-bin
          ];

          shellHook = ''
            echo "braa devshell — $(godot --version 2>/dev/null || echo 'godot unavailable')"
          '';
        };
      });
    };
}
