use crate::{
    config::{
        env::{domain, secret, use_https},
        get_configuration,
        DatabaseSettings,
        Settings,
    },
    context::AppContext,
    routers::*,
    ws_service::WSServer,
};
use actix::Actor;
use actix_identity::{CookieIdentityPolicy, IdentityService};
use actix_web::{dev::Server, middleware, web, web::Data, App, HttpServer, Scope};
use sqlx::{postgres::PgPoolOptions, PgPool};
use std::{net::TcpListener, sync::Arc};

pub struct Application {
    port: u16,
    server: Server,
}

impl Application {
    pub async fn build(configuration: Settings) -> Result<Self, std::io::Error> {
        let address = format!(
            "{}:{}",
            configuration.application.host, configuration.application.port
        );
        let listener = TcpListener::bind(&address)?;
        let port = listener.local_addr().unwrap().port();
        let app_ctx = init_app_context(&configuration).await;
        let server = run(listener, app_ctx)?;
        Ok(Self { port, server })
    }

    pub async fn run_until_stopped(self) -> Result<(), std::io::Error> { self.server.await }
}

pub fn run(listener: TcpListener, app_ctx: AppContext) -> Result<Server, std::io::Error> {
    let AppContext { ws_server, pg_pool } = app_ctx;
    let ws_server = Data::new(ws_server);
    let pg_pool = Data::new(pg_pool);
    let domain = domain();
    let secret: String = secret();

    let server = HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .wrap(identify_service(&domain, &secret))
            .app_data(web::JsonConfig::default().limit(4096))
            .service(ws_scope())
            .service(user_scope())
            .app_data(ws_server.clone())
            .app_data(pg_pool.clone())
    })
    .listen(listener)?
    .run();
    Ok(server)
}

fn ws_scope() -> Scope { web::scope("/ws").service(ws_router::start_connection) }

fn user_scope() -> Scope {
    web::scope("/api")
        // authentication
        .service(web::resource("/auth")
            .route(web::post().to(user_router::login_handler))
            .route(web::delete().to(user_router::logout_handler))
            .route(web::get().to(user_router::user_profile))
        )
        // password
        .service(web::resource("/password_change")
            .route(web::post().to(user_router::change_password))
        )
        // register
        .service(web::resource("/register")
            .route(web::post().to(user_router::register_handler))
        )
}

async fn init_app_context(configuration: &Settings) -> AppContext {
    let _ = flowy_log::Builder::new("flowy").env_filter("Debug").build();
    let pg_pool = get_connection_pool(&configuration.database)
        .await
        .expect(&format!(
            "Failed to connect to Postgres at {:?}.",
            configuration.database
        ));

    let ws_server = WSServer::new().start();

    AppContext::new(ws_server, pg_pool)
}

pub fn identify_service(domain: &str, secret: &str) -> IdentityService<CookieIdentityPolicy> {
    IdentityService::new(
        CookieIdentityPolicy::new(secret.as_bytes())
            .name("auth")
            .path("/")
            .domain(domain)
            .max_age_secs(24 * 3600)
            .secure(use_https()),
    )
}

pub async fn get_connection_pool(configuration: &DatabaseSettings) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .connect_timeout(std::time::Duration::from_secs(5))
        .connect_with(configuration.with_db())
        .await
}
