use crate::{
    config::Config,
    context::AppContext,
    routers::*,
    user_service::Auth,
    ws_service::WSServer,
};
use actix::Actor;
use actix_web::{dev::Server, middleware, web, App, HttpServer, Scope};
use sqlx::PgPool;
use std::{net::TcpListener, sync::Arc};

pub fn run(app_ctx: Arc<AppContext>, listener: TcpListener) -> Result<Server, std::io::Error> {
    let server = HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .data(web::JsonConfig::default().limit(4096))
            .service(ws_scope())
            .service(user_scope())
            .data(app_ctx.ws_server.clone())
            .data(app_ctx.db_pool.clone())
            .data(app_ctx.auth.clone())
    })
    .listen(listener)?
    .run();
    Ok(server)
}

fn ws_scope() -> Scope { web::scope("/ws").service(ws::start_connection) }

fn user_scope() -> Scope {
    web::scope("/user").service(web::resource("/register").route(web::post().to(user::register)))
}

pub async fn init_app_context() -> Arc<AppContext> {
    let _ = flowy_log::Builder::new("flowy").env_filter("Debug").build();
    let config = Arc::new(Config::new());

    // TODO: what happened when PgPool connect fail?
    let db_pool = Arc::new(
        PgPool::connect(&config.database.connect_url())
            .await
            .expect("Failed to connect to Postgres."),
    );
    let ws_server = WSServer::new().start();
    let auth = Arc::new(Auth::new(db_pool.clone()));

    let ctx = AppContext::new(config, ws_server, db_pool, auth);
    Arc::new(ctx)
}
