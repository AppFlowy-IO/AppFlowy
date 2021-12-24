use crate::{
    entities::logged_user::LoggedUser,
    services::web_socket::{WSClient, WSServer, WSUser, WebSocketReceivers},
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

#[rustfmt::skip]
//                   WsClient
//                  ┌─────────────┐
//                  │ ┌────────┐  │
//  wss://xxx ─────▶│ │ WsUser │  │───┐
//                  │ └────────┘  │   │
//                  └─────────────┘   │
//                                    │
//                                    │    ┌──────────────────┐ 1 n ┌──────────────────┐
//                                    ├───▶│WebSocketReceivers│◆────│WebSocketReceiver │
//                                    │    └──────────────────┘     └──────────────────┘
//                   WsClient         │                                       △
//                  ┌─────────────┐   │                                       │
//                  │ ┌────────┐  │   │                                       │
//  wss://xxx ─────▶│ │ WsUser │  │───┘                                       │
//                  │ └────────┘  │                                   ┌───────────────┐
//                  └─────────────┘                                   │DocumentManager│
//                                                                    └───────────────┘
#[get("/{token}")]
pub async fn establish_ws_connection(
    request: HttpRequest,
    payload: Payload,
    token: Path<String>,
    server: Data<Addr<WSServer>>,
    ws_receivers: Data<WebSocketReceivers>,
) -> Result<HttpResponse, Error> {
    tracing::info!("establish_ws_connection");
    match LoggedUser::from_token(token.clone()) {
        Ok(user) => {
            let ws_user = WSUser::new(user);
            let client = WSClient::new(ws_user, server.get_ref().clone(), ws_receivers);
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
