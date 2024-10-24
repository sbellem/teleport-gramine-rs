# Use cachix to speed up repeated builds in same container (?)
# FROM  nixpkgs/cachix-flakes AS nix-build
FROM  nixpkgs/nix-flakes AS nix-build
WORKDIR /usr/src/app
COPY flake.lock flake.nix Cargo.lock Cargo.toml rust-toolchain .
COPY src src
RUN rm src/bin/redeem.rs
COPY abi abi
COPY templates templates
RUN nix build --show-trace

#FROM rust:1.75 as cargo-build
#RUN apt-get install -y pkg-config libssl-dev
## Build just the dependencies (shorcut)
#COPY Cargo.lock Cargo.toml ./
#RUN mkdir src && echo "fn main() {}" > src/main.rs
#RUN cargo build --release
#RUN rm -r src
# Now add our actual source
#COPY teleport.env Makefile ./
#COPY src ./src
#RUN rm src/bin/redeem.rs
#COPY abi ./abi
#COPY templates ./templates
## Build with rust
#RUN cargo build --release

FROM rust:1.79.0 AS chef
RUN cargo install cargo-chef 
WORKDIR /usr/src/app

FROM chef AS planner
RUN apt-get install -y pkg-config libssl-dev
COPY Cargo.lock Cargo.toml teleport.env .
COPY src src
RUN rm src/bin/redeem.rs
COPY abi abi
COPY templates templates
RUN cargo chef prepare  --recipe-path recipe.json

FROM chef AS cargo-build
COPY --from=planner /usr/src/app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release --recipe-path recipe.json
# Build application
COPY Cargo.lock Cargo.toml teleport.env .
COPY src src
RUN rm src/bin/redeem.rs
COPY abi abi
COPY templates templates
RUN cargo build --release


FROM gramineproject/gramine:1.7-jammy AS builder

RUN apt-get update && apt-get install -y jq build-essential libclang-dev

WORKDIR /workdir

COPY --from=nix-build /usr/src/app/result/bin/teleport target/release/teleport
COPY --from=cargo-build /usr/src/app/target/release/teleport target/cargo/teleport

# Make and sign the gramine manifest
RUN gramine-sgx-gen-private-key
COPY exex.manifest.template teleport.env Makefile ./
#RUN make SGX=1 RA_TYPE=dcap
RUN make SGX=0

CMD [ "gramine-sgx-sigstruct-view exex.sig" ]
