# flake.nix
# ─────────────────────────────────────────────────────────────
# REGEXP — Flake-basierte NixOS Konfiguration
# MSI B850 TOMAHAWK / 9800X3D / RTX 5070 Ti / 64 GB DDR5
# ─────────────────────────────────────────────────────────────
#
# Befehle:
#   sudo nixos-rebuild switch --flake .#regexp     System bauen + aktivieren
#   sudo nixos-rebuild boot --flake .#regexp       Nur in Bootloader eintragen
#   sudo nixos-rebuild test --flake .#regexp       Testen ohne Boot-Eintrag
#   nix flake update                               Alle Inputs aktualisieren
#   nix flake lock --update-input nixpkgs          Nur nixpkgs updaten
#   nix develop                                    DevShell starten

{
  description = "REGEXP — NixOS Gaming/Dev Workstation";

  inputs = {
    # ── Core ──
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Unstable für bleeding-edge Pakete (NVIDIA, Mesa, Kernel, etc.)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # ── Home Manager — User-Level Config (Shell, Dotfiles, Apps) ──
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Hardware-spezifische Optimierungen ──
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, ... }:
    let
      system = "x86_64-linux";

      # Unstable Overlay — einzelne Pakete von unstable nutzen
      # Zugriff in Config: pkgs.unstable.paketname
      unstable-overlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations.regexp = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Unstable Overlay verfügbar machen
          { nixpkgs.overlays = [ unstable-overlay ]; }

          # System Config
          ./hardware-configuration.nix
          ./configuration.nix

          # Home Manager als NixOS Modul
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;       # System-nixpkgs verwenden
              useUserPackages = true;      # Pakete in /etc/profiles statt ~/.nix-profile
              users.liche = import ./home.nix;
              # Extra Args an Home-Manager Module durchreichen
              extraSpecialArgs = { inherit nixpkgs-unstable; };
            };
          }
        ];
      };

      # DevShell — `nix develop` für schnelle Entwicklungsumgebung
      devShells.${system}.default = let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in pkgs.mkShell {
        buildInputs = with pkgs; [
          rustup
          dotnetCorePackages.sdk_10_0
          nodejs_24
          python3
          gcc
          cmake
          pkg-config
          openssl
        ];
        shellHook = ''
          echo "🔧 REGEXP Dev Shell aktiv"
          echo "   Rust: $(rustc --version 2>/dev/null || echo 'rustup toolchain installieren')"
          echo "   .NET: $(dotnet --version 2>/dev/null || echo 'nicht verfügbar')"
          echo "   Node: $(node --version 2>/dev/null || echo 'nicht verfügbar')"
        '';
      };
    };
}
