use crate::{
    config::{HEARTBEAT_INTERVAL, PING_TIMEOUT},
    service::ws::{
        entities::{Connect, Disconnect, SessionId},
        ClientMessage,
        MessageData,
        WSServer,
        WsBizHandler,
        WsBizHandlers,
    },
};
use actix::*;
use actix_web::web::Data;
use actix_web_actors::{ws, ws::Message::Text};
use bytes::Bytes;
use flowy_ws::WsMessage;
use std::{convert::TryFrom, time::Instant};

pub struct WSClient {
    session_id: SessionId,
    server: Addr<WSServer>,
    biz_handlers: Data<WsBizHandlers>,
    hb: Instant,
}

impl WSClient {
    pub fn new<T: Into<SessionId>>(
        session_id: T,
        server: Addr<WSServer>,
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

    fn send(&self, data: MessageData) {
        let msg = ClientMessage::new(self.session_id.clone(), data);
        self.server.do_send(msg);
    }

    fn handle_binary_message(&self, bytes: Bytes) {
        // TODO: ok to unwrap?
        let message: WsMessage = WsMessage::try_from(bytes).unwrap();
        match self.biz_handlers.get(&message.module) {
            None => {
                log::error!("Can't find the handler for {:?}", message.module);
            },
            Some(handler) => handler.receive_data(Bytes::from(message.data)),
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
                // log::debug!("Receive {} pong {:?}", &self.session_id, &msg);
                self.hb = Instant::now();
            },
            Ok(ws::Message::Binary(bytes)) => {
                log::debug!(" Receive {} binary", &self.session_id);
                self.handle_binary_message(bytes);
            },
            Ok(Text(_)) => {
                log::warn!("Receive unexpected text message");
            },
            Ok(ws::Message::Close(reason)) => {
                self.send(MessageData::Disconnect(self.session_id.clone()));
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

impl Handler<ClientMessage> for WSClient {
    type Result = ();

    fn handle(&mut self, msg: ClientMessage, ctx: &mut Self::Context) {
        match msg.data {
            MessageData::Binary(binary) => {
                ctx.binary(binary);
            },
            MessageData::Connect(_) => {},
            MessageData::Disconnect(_) => {},
        }
    }
}

impl Actor for WSClient {
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
