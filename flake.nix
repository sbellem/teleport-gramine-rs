{
  description = "teleport";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
            self.overlays.default
          ];
        };
      });
    in
    {
      overlays.default = final: prev: {
        rustToolchain = final.rust-bin.stable.latest.default;
        #rustToolchain = final.rust-bin.fromRustupToolchainFile ./rust-toolchain;
      };

      packages = forAllSystems ({ pkgs }: {
        default =
          let
            rustPlatform = pkgs.makeRustPlatform {
              cargo = pkgs.rustToolchain;
              rustc = pkgs.rustToolchain;
            };
          in
          rustPlatform.buildRustPackage {
            name = "teleport";
            version = "0.1.0";
            #src = gitignoreSource extraIgnores ./.;
            src = ./.;
            doCheck = false;
            cargoLock = {
              lockFile = ./Cargo.lock;
              # NOTE for git deps, the outputhash must be specified
              #
              #outputHashes = {
              #  "alloy-0.4.2" = lib.fakeSha256;
              #};
              #
              # OR set:
              #
              allowBuiltinFetchGit = true;
              #
              # see https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#importing-a-cargolock-file-importing-a-cargolock-file
            };

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            buildInputs = with pkgs; [
              openssl
            ];

          };
        });

      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (with pkgs; [
            rustToolchain
          ]);
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          buildInputs = with pkgs; [
            openssl
          ];
        };
      });

    };
}
