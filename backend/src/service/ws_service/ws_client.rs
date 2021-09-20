use crate::{
    config::{HEARTBEAT_INTERVAL, PING_TIMEOUT},
    service::ws_service::{
        entities::{Connect, Disconnect, SessionId},
        ClientMessage,
        MessageData,
        WSServer,
    },
};
use actix::*;
use actix_web_actors::{ws, ws::Message::Text};
use std::time::Instant;

//    Frontend          │                       Backend
//
//                      │
// ┌──────────┐   WsMessage   ┌───────────┐  ClientMessage    ┌──────────┐
// │  user 1  │─────────┼────▶│ws_client_1│──────────────────▶│ws_server │
// └──────────┘               └───────────┘                   └──────────┘
//                      │                                           │
//                WsMessage                                         ▼
// ┌──────────┐         │     ┌───────────┐    ClientMessage     Group
// │  user 2  │◀──────────────│ws_client_2│◀───────┐        ┌───────────────┐
// └──────────┘         │     └───────────┘        │        │  ws_user_1    │
//                                                 │        │               │
//                      │                          └────────│  ws_user_2    │
// ┌──────────┐               ┌───────────┐                 │               │
// │  user 3  │─────────┼────▶│ws_client_3│                 └───────────────┘
// └──────────┘               └───────────┘
//                      │
pub struct WSClient {
    session_id: SessionId,
    server: Addr<WSServer>,
    hb: Instant,
}

impl WSClient {
    pub fn new<T: Into<SessionId>>(session_id: T, server: Addr<WSServer>) -> Self {
        Self {
            session_id: session_id.into(),
            hb: Instant::now(),
            server,
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

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WSClient {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Ping(msg)) => {
                self.hb = Instant::now();
                ctx.pong(&msg);
            },
            Ok(ws::Message::Pong(msg)) => {
                log::debug!("Receive {} pong {:?}", &self.session_id, &msg);
                self.hb = Instant::now();
            },
            Ok(ws::Message::Binary(bin)) => {
                log::debug!(" Receive {} binary", &self.session_id);
                self.send(MessageData::Binary(bin));
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
