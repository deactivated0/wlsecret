{
  description = "wlsecret - Next-generation FreeDesktop Secret Service daemon & keyring library in pure Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = rec {
          wlsecret = pkgs.rustPlatform.buildRustPackage {
            pname = "wlsecret";
            version = "0.8.0-alpha";
            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              openssl
              dbus
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
            ];

            meta = with pkgs.lib; {
              description = "Next-generation FreeDesktop Secret Service daemon & keyring library in pure Rust";
              homepage = "https://github.com/deactivated0/wlsecret";
              license = licenses.mit;
              mainProgram = "wlsecret-daemon";
              platforms = platforms.unix ++ platforms.windows;
            };
          };

          oo7 = wlsecret;
          default = wlsecret;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          buildInputs = with pkgs; [
            cargo
            rustc
            clippy
            rustfmt
            pkg-config
            openssl
            dbus
          ];
        };
      }
    ) // {
      # NixOS system module
      nixosModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.wlsecret-daemon;
        in
        {
          options.services.wlsecret-daemon = {
            enable = lib.mkEnableOption "wlsecret Secret Service daemon";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The wlsecret package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            systemd.user.services.wlsecret-daemon = {
              description = "Secret Service Daemon (wlsecret)";
              documentation = [ "https://github.com/deactivated0/wlsecret" ];
              wantedBy = [ "graphical-session.target" ];
              partOf = [ "graphical-session.target" ];
              serviceConfig = {
                ExecStart = "${cfg.package}/bin/wlsecret-daemon";
                Restart = "on-failure";
                Slice = "session.slice";
              };
            };
          };
        };

      # Home Manager user module
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.services.wlsecret-daemon;
        in
        {
          options.services.wlsecret-daemon = {
            enable = lib.mkEnableOption "wlsecret Secret Service daemon";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The wlsecret package to use.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];

            systemd.user.services.wlsecret-daemon = {
              Unit = {
                Description = "Secret Service Daemon (wlsecret)";
                Documentation = "https://github.com/deactivated0/wlsecret";
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = "${cfg.package}/bin/wlsecret-daemon";
                Restart = "on-failure";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };
        };
    };
}
