use crate::service::ws::{
    entities::{Connect, Disconnect, Session, SessionId},
    WsMessageAdaptor,
};
use actix::{Actor, Context, Handler};
use dashmap::DashMap;
use flowy_net::errors::ServerError;

pub struct WsServer {
    sessions: DashMap<SessionId, Session>,
}

impl WsServer {
    pub fn new() -> Self {
        Self {
            sessions: DashMap::new(),
        }
    }

    pub fn send(&self, _msg: WsMessageAdaptor) { unimplemented!() }
}

impl Actor for WsServer {
    type Context = Context<Self>;
    fn started(&mut self, _ctx: &mut Self::Context) {}
}

impl Handler<Connect> for WsServer {
    type Result = Result<(), ServerError>;
    fn handle(&mut self, msg: Connect, _ctx: &mut Context<Self>) -> Self::Result {
        let session: Session = msg.into();
        self.sessions.insert(session.id.clone(), session);

        Ok(())
    }
}

impl Handler<Disconnect> for WsServer {
    type Result = Result<(), ServerError>;
    fn handle(&mut self, msg: Disconnect, _: &mut Context<Self>) -> Self::Result {
        self.sessions.remove(&msg.sid);
        Ok(())
    }
}

impl Handler<WsMessageAdaptor> for WsServer {
    type Result = ();

    fn handle(&mut self, _msg: WsMessageAdaptor, _ctx: &mut Context<Self>) -> Self::Result {
        unimplemented!()
    }
}

impl actix::Supervised for WsServer {
    fn restarting(&mut self, _ctx: &mut Context<WsServer>) {
        log::warn!("restarting");
    }
}
