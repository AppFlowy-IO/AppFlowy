use crate::{event::NetworkEvent, handlers::*, ws::connection::FlowyWebSocketConnect};
use lib_dispatch::prelude::*;
use std::sync::Arc;

pub fn create(ws_conn: Arc<FlowyWebSocketConnect>) -> Module {
    Module::new()
        .name("Flowy-Network")
        .data(ws_conn)
        .event(NetworkEvent::UpdateNetworkType, update_network_ty)
}
