FROM rust:1.73.0
WORKDIR /usr/src
COPY . .

RUN cargo build --release --manifest-path /usr/src/edge-modules/edgehub-proxy/Cargo.toml
