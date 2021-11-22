FROM rust:1.56.1
# Let's switch our working directory to `app` (equivalent to `cd app`)
# The `app` folder will be created for us by Docker in case it does not
# exist already.
WORKDIR /app

COPY . .

WORKDIR /app/backend
ENV SQLX_OFFLINE true
ENV APP_ENVIRONMENT production
RUN RUSTFLAGS="-C opt-level=2" cargo build --release

# When `docker run` is executed, launch the binary!
ENTRYPOINT ["./target/release/backend"]

#



## We use the latest Rust stable release as base image
#FROM lukemathwalker/cargo-chef:latest-rust-1.53.0 as planner
#WORKDIR /app
#COPY . .
#
#WORKDIR /app/backend
#RUN cargo chef prepare  --recipe-path recipe.json
#
#FROM lukemathwalker/cargo-chef:latest-rust-1.53.0 as cacher
#WORKDIR /app/backend
#COPY --from=planner /app/backend/recipe.json recipe.json
## Build our project dependencies, not our application!
#RUN cargo chef cook --release --recipe-path recipe.json
#
#FROM rust:1.53.0 AS builder
#WORKDIR /app/backend
## Copy over the cached dependencies
#COPY --from=cacher /app/backend/target target
#COPY --from=cacher /usr/local/cargo /usr/local/cargo
#COPY . .
#
#ENV SQLX_OFFLINE true
#RUN cargo build --release --bin backend
#
#
#FROM debian:buster-slim AS runtime
#WORKDIR /app/backend
#RUN apt-get update -y \
#    && apt-get install -y --no-install-recommends openssl \
#    # Clean up
#    && apt-get autoremove -y \
#    && apt-get clean -y \
#    && rm -rf /var/lib/apt/lists/*
#COPY --from=builder /app/backend/target/release/backend backend
##COPY configuration configuration
#ENV APP_ENVIRONMENT production
#ENTRYPOINT ["./backend"]
