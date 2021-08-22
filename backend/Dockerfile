# We use the latest Rust stable release as base image
FROM rust:1.53.0
# Let's switch our working directory to `app` (equivalent to `cd app`)
# The `app` folder will be created for us by Docker in case it does not
# exist already.
WORKDIR /app
# Copy all files from our working environment to our Docker image

COPY . .
# Let's build our binary!
# We'll use the release profile to make it fast
WORKDIR /app/backend
RUN cargo build --release
# When `docker run` is executed, launch the binary!
ENTRYPOINT ["./target/release/backend"]
