use crate::{context::AppContext, routers::*, ws::WSServer};
use actix::Actor;
use actix_web::{dev::Server, middleware, web, App, HttpServer, Scope};
use std::{net::TcpListener, sync::Arc};

pub fn run(app_ctx: Arc<AppContext>, listener: TcpListener) -> Result<Server, std::io::Error> {
    let server = HttpServer::new(move || {
        App::new()
            .wrap(middleware::Logger::default())
            .data(web::JsonConfig::default().limit(4096))
            .service(ws_scope())
            .data(app_ctx.ws_server())
    })
    .listen(listener)?
    .run();
    Ok(server)
}

fn ws_scope() -> Scope { web::scope("/ws").service(ws::start_connection) }

pub async fn init_app_context() -> Arc<AppContext> {
    let ws_server = WSServer::new().start();
    let ctx = AppContext::new(ws_server);
    Arc::new(ctx)
}
