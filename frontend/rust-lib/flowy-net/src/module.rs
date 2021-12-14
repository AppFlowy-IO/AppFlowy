use crate::{event::NetworkEvent, handlers::*, services::ws::WsManager};
use lib_dispatch::prelude::*;
use std::sync::Arc;

pub fn create(ws_manager: Arc<WsManager>) -> Module {
    Module::new()
        .name("Flowy-Network")
        .data(ws_manager)
        .event(NetworkEvent::UpdateNetworkType, update_network_ty)
}
