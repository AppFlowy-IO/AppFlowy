use crate::ws_service::{
    entities::{Connect, Disconnect, Session, SessionId},
    ClientMessage,
};
use actix::{Actor, Context, Handler};
use dashmap::DashMap;
use flowy_net::errors::ServerError;

pub struct WSServer {
    sessions: DashMap<SessionId, Session>,
}

impl WSServer {
    pub fn new() -> Self {
        Self {
            sessions: DashMap::new(),
        }
    }

    pub fn send(&self, _msg: ClientMessage) { unimplemented!() }
}

impl Actor for WSServer {
    type Context = Context<Self>;
    fn started(&mut self, _ctx: &mut Self::Context) {}
}

impl Handler<Connect> for WSServer {
    type Result = Result<(), ServerError>;
    fn handle(&mut self, msg: Connect, _ctx: &mut Context<Self>) -> Self::Result {
        let session: Session = msg.into();
        self.sessions.insert(session.id.clone(), session);

        Ok(())
    }
}

impl Handler<Disconnect> for WSServer {
    type Result = Result<(), ServerError>;
    fn handle(&mut self, msg: Disconnect, _: &mut Context<Self>) -> Self::Result {
        self.sessions.remove(&msg.sid);
        Ok(())
    }
}

impl Handler<ClientMessage> for WSServer {
    type Result = ();

    fn handle(&mut self, msg: ClientMessage, _ctx: &mut Context<Self>) -> Self::Result {}
}

impl actix::Supervised for WSServer {
    fn restarting(&mut self, _ctx: &mut Context<WSServer>) {
        log::warn!("restarting");
    }
}
