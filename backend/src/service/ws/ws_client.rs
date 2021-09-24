use crate::{
    config::{HEARTBEAT_INTERVAL, PING_TIMEOUT},
    service::ws::{
        entities::{Connect, Disconnect, SessionId, Socket},
        WsBizHandler,
        WsBizHandlers,
        WsMessageAdaptor,
        WsServer,
    },
};
use actix::*;
use actix_web::web::Data;
use actix_web_actors::{ws, ws::Message::Text};
use bytes::Bytes;
use flowy_ws::WsMessage;
use std::{convert::TryFrom, time::Instant};

pub struct WsClientData {
    pub(crate) socket: Socket,
    pub(crate) data: Bytes,
}

pub struct WsClient {
    session_id: SessionId,
    server: Addr<WsServer>,
    biz_handlers: Data<WsBizHandlers>,
    hb: Instant,
}

impl WsClient {
    pub fn new<T: Into<SessionId>>(
        session_id: T,
        server: Addr<WsServer>,
        biz_handlers: Data<WsBizHandlers>,
    ) -> Self {
        Self {
            session_id: session_id.into(),
            server,
            biz_handlers,
            hb: Instant::now(),
        }
    }

    fn hb(&self, ctx: &mut ws::WebsocketContext<Self>) {
        ctx.run_interval(HEARTBEAT_INTERVAL, |client, ctx| {
            if Instant::now().duration_since(client.hb) > PING_TIMEOUT {
                client.server.do_send(Disconnect {
                    sid: client.session_id.clone(),
                });
                ctx.stop();
            } else {
                ctx.ping(b"");
            }
        });
    }

    fn handle_binary_message(&self, bytes: Bytes, socket: Socket) {
        // TODO: ok to unwrap?
        let message: WsMessage = WsMessage::try_from(bytes).unwrap();
        match self.biz_handlers.get(&message.module) {
            None => {
                log::error!("Can't find the handler for {:?}", message.module);
            },
            Some(handler) => {
                let client_data = WsClientData {
                    socket,
                    data: Bytes::from(message.data),
                };
                handler.receive_data(client_data)
            },
        }
    }
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WsClient {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Ping(msg)) => {
                self.hb = Instant::now();
                ctx.pong(&msg);
            },
            Ok(ws::Message::Pong(_msg)) => {
                // log::debug!("Receive {} pong {:?}", &self.session_id, &msg);
                self.hb = Instant::now();
            },
            Ok(ws::Message::Binary(bytes)) => {
                log::debug!(" Receive {} binary", &self.session_id);
                let socket = ctx.address().recipient();
                self.handle_binary_message(bytes, socket);
            },
            Ok(Text(_)) => {
                log::warn!("Receive unexpected text message");
            },
            Ok(ws::Message::Close(reason)) => {
                ctx.close(reason);
                ctx.stop();
            },
            Ok(ws::Message::Continuation(_)) => {},
            Ok(ws::Message::Nop) => {},
            Err(e) => {
                log::error!(
                    "[{}]: WebSocketStream protocol error {:?}",
                    self.session_id,
                    e
                );
                ctx.stop();
            },
        }
    }
}

impl Handler<WsMessageAdaptor> for WsClient {
    type Result = ();

    fn handle(&mut self, msg: WsMessageAdaptor, ctx: &mut Self::Context) { ctx.binary(msg.0); }
}

impl Actor for WsClient {
    type Context = ws::WebsocketContext<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        self.hb(ctx);
        let socket = ctx.address().recipient();
        let connect = Connect {
            socket,
            sid: self.session_id.clone(),
        };
        self.server
            .send(connect)
            .into_actor(self)
            .then(|res, _client, _ctx| {
                match res {
                    Ok(Ok(_)) => log::trace!("Send connect message to server success"),
                    Ok(Err(e)) => log::error!("Send connect message to server failed: {:?}", e),
                    Err(e) => log::error!("Send connect message to server failed: {:?}", e),
                }
                fut::ready(())
            })
            .wait(ctx);
    }

    fn stopping(&mut self, _: &mut Self::Context) -> Running {
        self.server.do_send(Disconnect {
            sid: self.session_id.clone(),
        });

        Running::Stop
    }
}
