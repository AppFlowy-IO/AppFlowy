use crate::{handlers::*, ws::connection::FlowyWebSocketConnect};
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;
use std::sync::Arc;
use strum_macros::Display;

pub fn init(ws_conn: Arc<FlowyWebSocketConnect>) -> AFPlugin {
    AFPlugin::new()
        .name("Flowy-Network")
        .state(ws_conn)
        .event(NetworkEvent::UpdateNetworkType, update_network_ty)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum NetworkEvent {
    #[event(input = "NetworkState")]
    UpdateNetworkType = 0,
}
