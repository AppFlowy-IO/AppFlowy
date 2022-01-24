use crate::{
    config::{HEARTBEAT_INTERVAL, PING_TIMEOUT},
    entities::logged_user::LoggedUser,
    services::web_socket::{
        entities::{Connect, Disconnect, Socket},
        WSServer,
        WebSocketMessage,
    },
};
use actix::*;
use actix_web::web::Data;
use actix_web_actors::{ws, ws::Message::Text};
use bytes::Bytes;
use lib_ws::{WSChannel, WebSocketRawMessage};
use std::{collections::HashMap, convert::TryFrom, sync::Arc, time::Instant};

pub trait WebSocketReceiver: Send + Sync {
    fn receive(&self, data: WSClientData);
}

pub struct WebSocketReceivers {
    inner: HashMap<WSChannel, Arc<dyn WebSocketReceiver>>,
}

impl std::default::Default for WebSocketReceivers {
    fn default() -> Self { Self { inner: HashMap::new() } }
}

impl WebSocketReceivers {
    pub fn new() -> Self { WebSocketReceivers::default() }

    pub fn set(&mut self, channel: WSChannel, receiver: Arc<dyn WebSocketReceiver>) {
        tracing::trace!("Add {:?} receiver", channel);
        self.inner.insert(channel, receiver);
    }

    pub fn get(&self, source: &WSChannel) -> Option<Arc<dyn WebSocketReceiver>> { self.inner.get(source).cloned() }
}

#[derive(Debug)]
pub struct WSUser {
    inner: LoggedUser,
}

impl WSUser {
    pub fn new(inner: LoggedUser) -> Self { Self { inner } }

    pub fn id(&self) -> &str { &self.inner.user_id }
}

pub struct WSClientData {
    pub(crate) user: Arc<WSUser>,
    pub(crate) socket: Socket,
    pub(crate) data: Bytes,
}

pub struct WSClient {
    user: Arc<WSUser>,
    server: Addr<WSServer>,
    ws_receivers: Data<WebSocketReceivers>,
    hb: Instant,
}

impl WSClient {
    pub fn new(user: WSUser, server: Addr<WSServer>, ws_receivers: Data<WebSocketReceivers>) -> Self {
        Self {
            user: Arc::new(user),
            server,
            ws_receivers,
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
        let message: WebSocketRawMessage = WebSocketRawMessage::try_from(bytes).unwrap();
        match self.ws_receivers.get(&message.channel) {
            None => {
                log::error!("Can't find the receiver for {:?}", message.channel);
            },
            Some(handler) => {
                let client_data = WSClientData {
                    user: self.user.clone(),
                    socket,
                    data: Bytes::from(message.data),
                };
                handler.receive(client_data);
            },
        }
    }
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WSClient {
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

impl Handler<WebSocketMessage> for WSClient {
    type Result = ();

    fn handle(&mut self, msg: WebSocketMessage, ctx: &mut Self::Context) { ctx.binary(msg.0); }
}

impl Actor for WSClient {
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
