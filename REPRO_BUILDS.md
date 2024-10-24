# Reproducible Builds
Notes on working with Nix and other tools to build teleport in a reproducible manner.

## Build with Docker
Using the Docker image [nixpkgs/nix-flakes](https://hub.docker.com/r/nixpkgs/nix-flakes)
from [nix-community/docker-nixpkgs](https://github.com/nix-community/docker-nixpkgs) as
a basis, which has nix flakes enabled by default.

```shell
docker build --tag nix-teleport --target nix-build .
```

## Development Environment with Nix
See https://docs.determinate.systems/getting-started

1. Installing nix

2. Configuring nix to use flakes

3. Development environment with `nix develop`
```
nix develop
cargo build --release
```

4. Building teleport with `nix`
```
nix build
```
Binary is under `result/bin/`



## Documentation
[Building Rust with Nix](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/rust.section.md#importing-a-cargolock-file-importing-a-cargolock-file)

[oxalica's Rust overlay](https://github.com/oxalica/rust-overlay)

## CI
https://github.com/DeterminateSystems/nix-installer-action?tab=readme-ov-file

## Troubleshooting
