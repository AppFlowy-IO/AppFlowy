FROM rust:1.56.1 as builder
WORKDIR /app

COPY . .
WORKDIR /app/backend
ENV SQLX_OFFLINE true
RUN RUSTFLAGS="-C opt-level=2" cargo build --release --bin backend
# Size optimization
#RUN strip ./target/release/backend

FROM debian:bullseye-slim AS runtime
WORKDIR /app
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/backend/target/release/backend /usr/local/bin/backend
COPY --from=builder /app/backend/configuration configuration
ENV APP_ENVIRONMENT production
CMD ["backend"]
