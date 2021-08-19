use crate::{
    config::{HEARTBEAT_INTERVAL, PING_TIMEOUT},
    ws_service::{
        entities::{Connect, Disconnect, SessionId},
        ClientMessage,
        MessageData,
        WSServer,
    },
};
use actix::{
    fut,
    Actor,
    ActorContext,
    ActorFuture,
    Addr,
    AsyncContext,
    ContextFutureSpawner,
    Handler,
    Recipient,
    Running,
    StreamHandler,
    WrapFuture,
};

use actix_web_actors::{ws, ws::Message::Text};
use std::time::Instant;

pub struct WSClient {
    sid: SessionId,
    server: Addr<WSServer>,
    hb: Instant,
}

impl WSClient {
    pub fn new(sid: SessionId, server: Addr<WSServer>) -> Self {
        Self {
            sid,
            hb: Instant::now(),
            server,
        }
    }

    fn hb(&self, ctx: &mut ws::WebsocketContext<Self>) {
        ctx.run_interval(HEARTBEAT_INTERVAL, |ws_session, ctx| {
            if Instant::now().duration_since(ws_session.hb) > PING_TIMEOUT {
                ws_session.server.do_send(Disconnect {
                    sid: ws_session.sid.clone(),
                });
                ctx.stop();
                return;
            }
            ctx.ping(b"");
        });
    }

    fn send(&self, data: MessageData) {
        let msg = ClientMessage::new(self.sid.clone(), data);
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
            sid: self.sid.clone(),
        };
        self.server
            .send(connect)
            .into_actor(self)
            .then(|res, _ws_session, _ctx| {
                match res {
                    Ok(Ok(_)) => {},
                    Ok(Err(_e)) => {
                        unimplemented!()
                    },
                    Err(_e) => unimplemented!(),
                }
                fut::ready(())
            })
            .wait(ctx);
    }

    fn stopping(&mut self, _: &mut Self::Context) -> Running {
        self.server.do_send(Disconnect {
            sid: self.sid.clone(),
        });

        Running::Stop
    }
}

impl StreamHandler<Result<ws::Message, ws::ProtocolError>> for WSClient {
    fn handle(&mut self, msg: Result<ws::Message, ws::ProtocolError>, ctx: &mut Self::Context) {
        match msg {
            Ok(ws::Message::Ping(msg)) => {
                log::debug!("Receive {} ping {:?}", &self.sid, &msg);
                self.hb = Instant::now();
                ctx.pong(&msg);
            },
            Ok(ws::Message::Pong(msg)) => {
                log::debug!("Receive {} pong {:?}", &self.sid, &msg);
                self.send(MessageData::Connect(self.sid.clone()));
                self.hb = Instant::now();
            },
            Ok(ws::Message::Binary(bin)) => {
                log::debug!(" Receive {} binary", &self.sid);
                self.send(MessageData::Binary(bin));
            },
            Ok(ws::Message::Close(reason)) => {
                log::debug!("Receive {} close {:?}", &self.sid, &reason);
                ctx.close(reason);
                ctx.stop();
            },
            Ok(ws::Message::Continuation(c)) => {
                log::debug!("Receive {} continues message {:?}", &self.sid, &c);
            },
            Ok(ws::Message::Nop) => {
                log::debug!("Receive Nop message");
            },
            Ok(Text(s)) => {
                log::debug!("Receive {} text {:?}", &self.sid, &s);
                self.send(MessageData::Text(s));
            },

            Err(e) => {
                let msg = format!("{} error: {:?}", &self.sid, e);
                ctx.text(&msg);
                log::error!("stream {}", msg);
                ctx.stop();
            },
        }
    }
}

impl Handler<ClientMessage> for WSClient {
    type Result = ();

    fn handle(&mut self, msg: ClientMessage, ctx: &mut Self::Context) {
        match msg.data {
            MessageData::Text(text) => {
                ctx.text(text);
            },
            MessageData::Binary(binary) => {
                ctx.binary(binary);
            },
            MessageData::Connect(sid) => {
                let connect_msg = format!("{} connect", &sid);
                ctx.text(connect_msg);
            },
            MessageData::Disconnect(text) => {
                log::debug!("Session start disconnecting {}", self.sid);
                ctx.text(text);
                ctx.stop();
            },
        }
    }
}
