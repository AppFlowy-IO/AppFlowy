use crate::ws_service::{entities::SessionId, WSClient, WSServer};
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
pub async fn start_connection(
    request: HttpRequest,
    payload: Payload,
    path: Path<String>,
    server: Data<Addr<WSServer>>,
) -> Result<HttpResponse, Error> {
    let client = WSClient::new(SessionId::new(path.clone()), server.get_ref().clone());
    let result = ws::start(client, &request, payload);

    match result {
        Ok(response) => Ok(response.into()),
        Err(e) => {
            log::error!("ws connection error: {:?}", e);
            Err(e)
        },
    }
}
