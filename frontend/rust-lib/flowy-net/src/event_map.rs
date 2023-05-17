use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::*;

use crate::handlers::*;

pub fn init() -> AFPlugin {
  AFPlugin::new()
    .name("Flowy-Network")
    .event(NetworkEvent::UpdateNetworkType, update_network_ty)
}

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum NetworkEvent {
  #[event(input = "NetworkStatePB")]
  UpdateNetworkType = 0,
}
