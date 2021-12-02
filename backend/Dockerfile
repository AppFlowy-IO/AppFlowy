FROM rust:1.56.1
WORKDIR /app
COPY . .

ENV SQLX_OFFLINE true
WORKDIR /app/backend
RUN RUSTFLAGS="-C opt-level=2" cargo build --release --bin backend
RUN cp target/release/backend backend
ENV APP_ENVIRONMENT production
EXPOSE 8000
ENTRYPOINT ["./backend"]