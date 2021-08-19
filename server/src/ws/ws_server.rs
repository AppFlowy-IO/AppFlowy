use crate::{
    errors::ServerError,
    ws::{
        entities::{Connect, Disconnect, SessionId},
        Packet,
        WSSession,
    },
};
use actix::{Actor, Context, Handler};
use dashmap::DashMap;

pub struct WSServer {
    session_map: DashMap<SessionId, WSSession>,
}

impl WSServer {
    pub fn new() -> Self {
        Self {
            session_map: DashMap::new(),
        }
    }

    pub fn send(&self, _packet: Packet) { unimplemented!() }
}

impl Actor for WSServer {
    type Context = Context<Self>;
    fn started(&mut self, _ctx: &mut Self::Context) {}
}

impl Handler<Connect> for WSServer {
    type Result = Result<(), ServerError>;
    fn handle(&mut self, _msg: Connect, _ctx: &mut Context<Self>) -> Self::Result {
        unimplemented!()
    }
}

impl Handler<Disconnect> for WSServer {
    type Result = Result<(), ServerError>;
    fn handle(&mut self, _msg: Disconnect, _: &mut Context<Self>) -> Self::Result {
        unimplemented!()
    }
}

impl Handler<Packet> for WSServer {
    type Result = ();

    fn handle(&mut self, _packet: Packet, _ctx: &mut Context<Self>) -> Self::Result {
        unimplemented!()
    }
}

impl actix::Supervised for WSServer {
    fn restarting(&mut self, _ctx: &mut Context<WSServer>) {
        log::warn!("restarting");
    }
}
