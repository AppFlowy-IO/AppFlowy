use crate::services::web_socket::{
    entities::{Connect, Disconnect, Session, SessionId},
    WSMessageAdaptor,
};
use actix::{Actor, Context, Handler};
use backend_service::errors::ServerError;
use dashmap::DashMap;

pub struct WSServer {
    sessions: DashMap<SessionId, Session>,
}

impl std::default::Default for WSServer {
    fn default() -> Self {
        Self {
            sessions: DashMap::new(),
        }
    }
}
impl WSServer {
    pub fn new() -> Self { WSServer::default() }

    pub fn send(&self, _msg: WSMessageAdaptor) { unimplemented!() }
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

impl Handler<WSMessageAdaptor> for WSServer {
    type Result = ();

    fn handle(&mut self, _msg: WSMessageAdaptor, _ctx: &mut Context<Self>) -> Self::Result { unimplemented!() }
}

impl actix::Supervised for WSServer {
    fn restarting(&mut self, _ctx: &mut Context<WSServer>) {
        log::warn!("restarting");
    }
}
