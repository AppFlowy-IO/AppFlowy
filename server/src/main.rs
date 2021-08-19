use server::startup::{init_app_context, run};
use std::net::TcpListener;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let app_ctx = init_app_context().await;
    let listener =
        TcpListener::bind(app_ctx.config.server_addr()).expect("Failed to bind server address");
    run(app_ctx, listener)?.await
}
