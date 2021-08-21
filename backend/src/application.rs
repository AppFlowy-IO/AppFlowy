use crate::{
    config::{get_configuration, DatabaseSettings, Settings},
    context::AppContext,
    routers::*,
    user_service::Auth,
    ws_service::WSServer,
};
use actix::Actor;
use actix_web::{dev::Server, middleware, web, web::Data, App, HttpServer, Scope};
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::{net::TcpListener, sync::Arc};

pub struct Application {
    port: u16,
    server: Server,
    app_ctx: Arc<AppContext>,
}

impl Application {
    pub async fn build(configuration: Settings) -> Result<Self, std::io::Error> {
        let app_ctx = init_app_context(&configuration).await;
        let address = format!(
            "{}:{}",
            configuration.application.host, configuration.application.port
        );
        let listener = TcpListener::bind(&address)?;
        let port = listener.local_addr().unwrap().port();
        let server = run(listener, app_ctx.clone())?;
        Ok(Self {
            port,
            server,
            app_ctx,
        })
    }

    pub async fn run_until_stopped(self) -> Result<(), std::io::Error> { self.server.await }
}

pub fn run(listener: TcpListener, app_ctx: Arc<AppContext>) -> Result<Server, std::io::Error> {
    let server = HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .app_data(web::JsonConfig::default().limit(4096))
            .service(ws_scope())
            .service(user_scope())
            .app_data(Data::new(app_ctx.ws_server.clone()))
            .app_data(Data::new(app_ctx.db_pool.clone()))
            .app_data(Data::new(app_ctx.auth.clone()))
    })
    .listen(listener)?
    .run();
    Ok(server)
}

fn ws_scope() -> Scope { web::scope("/ws").service(ws::start_connection) }

fn user_scope() -> Scope {
    web::scope("/user").service(web::resource("/register").route(web::post().to(user::register)))
}

async fn init_app_context(configuration: &Settings) -> Arc<AppContext> {
    let _ = flowy_log::Builder::new("flowy").env_filter("Debug").build();
    let pg_pool = Arc::new(
        get_connection_pool(&configuration.database)
            .await
            .expect("Failed to connect to Postgres."),
    );

    let ws_server = WSServer::new().start();

    let auth = Arc::new(Auth::new(pg_pool.clone()));

    let ctx = AppContext::new(ws_server, pg_pool, auth);

    Arc::new(ctx)
}

pub async fn get_connection_pool(configuration: &DatabaseSettings) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .connect_timeout(std::time::Duration::from_secs(2))
        .connect_with(configuration.with_db())
        .await
}
