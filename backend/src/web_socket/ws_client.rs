use crate::{
    config::{HEARTBEAT_INTERVAL, PING_TIMEOUT},
    services::user::LoggedUser,
    web_socket::{
        entities::{Connect, Disconnect, Socket},
        WsBizHandlers,
        WsMessageAdaptor,
        WsServer,
    },
};
use actix::*;
use actix_web::web::Data;
use actix_web_actors::{ws, ws::Message::Text};
use bytes::Bytes;
use lib_ws::WsMessage;
use std::{convert::TryFrom, sync::Arc, time::Instant};

#[derive(Debug)]
pub struct WsUser {
    inner: LoggedUser,
}

impl WsUser {
    pub fn new(inner: LoggedUser) -> Self { Self { inner } }

    pub fn id(&self) -> &str { &self.inner.user_id }
}

pub struct WsClientData {
    pub(crate) user: Arc<WsUser>,
    pub(crate) socket: Socket,
    pub(crate) data: Bytes,
}

pub struct WsClient {
    user: Arc<WsUser>,
    server: Addr<WsServer>,
    biz_handlers: Data<WsBizHandlers>,
    hb: Instant,
}

impl WsClient {
    pub fn new(user: WsUser, server: Addr<WsServer>, biz_handlers: Data<WsBizHandlers>) -> Self {
        Self {
            user: Arc::new(user),
            server,
            biz_handlers,
            hb: Instant::now(),
        }
    }

    fn hb(&self, ctx: &mut ws::WebsocketContext<Self>) {
        ctx.run_interval(HEARTBEAT_INTERVAL, |client, ctx| {
            if Instant::now().duration_since(client.hb) > PING_TIMEOUT {
                client.server.do_send(Disconnect {
                    sid: client.user.id().into(),
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
                    user: self.user.clone(),
                    socket,
                    data: Bytes::from(message.data),
                };
                handler.receive_data(client_data);
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
                // tracing::debug!("Receive {} pong {:?}", &self.session_id, &msg);
                self.hb = Instant::now();
            },
            Ok(ws::Message::Binary(bytes)) => {
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
                log::error!("[{}]: WebSocketStream protocol error {:?}", self.user.id(), e);
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
            sid: self.user.id().into(),
        };
        self.server
            .send(connect)
            .into_actor(self)
            .then(|res, _client, _ctx| {
                match res {
                    Ok(Ok(_)) => tracing::trace!("Send connect message to server success"),
                    Ok(Err(e)) => log::error!("Send connect message to server failed: {:?}", e),
                    Err(e) => log::error!("Send connect message to server failed: {:?}", e),
                }
                fut::ready(())
            })
            .wait(ctx);
    }

    fn stopping(&mut self, _: &mut Self::Context) -> Running {
        self.server.do_send(Disconnect {
            sid: self.user.id().into(),
        });

        Running::Stop
    }
}
