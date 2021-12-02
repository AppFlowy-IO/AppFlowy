use crate::service::{
    user::LoggedUser,
    ws::{WsBizHandlers, WsClient, WsServer, WsUser},
};
use actix::Addr;
use actix_web::{
    get,
    web::{Data, Path, Payload},
    Error,
    HttpRequest,
    HttpResponse,
};
use actix_web_actors::ws;

#[get("/{token}")]
pub async fn establish_ws_connection(
    request: HttpRequest,
    payload: Payload,
    token: Path<String>,
    server: Data<Addr<WsServer>>,
    biz_handlers: Data<WsBizHandlers>,
) -> Result<HttpResponse, Error> {
    tracing::info!("establish_ws_connection");
    match LoggedUser::from_token(token.clone()) {
        Ok(user) => {
            let ws_user = WsUser::new(user);
            let client = WsClient::new(ws_user, server.get_ref().clone(), biz_handlers);
            let result = ws::start(client, &request, payload);
            match result {
                Ok(response) => Ok(response),
                Err(e) => {
                    log::error!("ws connection error: {:?}", e);
                    Err(e)
                },
            }
        },
        Err(e) => {
            if e.is_unauthorized() {
                Ok(HttpResponse::Unauthorized().json(e))
            } else {
                Ok(HttpResponse::BadRequest().json(e))
            }
        },
    }
}
