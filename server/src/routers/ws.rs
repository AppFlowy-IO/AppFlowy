use crate::ws::{entities::SessionId, WSServer, WSSession};
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
    Path(token): Path<String>,
    server: Data<Addr<WSServer>>,
) -> Result<HttpResponse, Error> {
    let ws = WSSession::new(SessionId::new(token), server.get_ref().clone());
    let response = ws::start(ws, &request, payload)?;
    Ok(response.into())
}
