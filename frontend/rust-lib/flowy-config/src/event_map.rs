use std::sync::Weak;

use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use flowy_sqlite::kv::KVStorePreferences;
use lib_dispatch::prelude::AFPlugin;

use crate::event_handler::*;

pub fn init(store_preferences: Weak<KVStorePreferences>) -> AFPlugin {
  AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .state(store_preferences)
    .event(ConfigEvent::SetKeyValue, set_key_value_handler)
    .event(ConfigEvent::GetKeyValue, get_key_value_handler)
    .event(ConfigEvent::RemoveKeyValue, remove_key_value_handler)
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Display, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum ConfigEvent {
  #[event(input = "KeyValuePB")]
  SetKeyValue = 0,

  #[event(input = "KeyPB", output = "KeyValuePB")]
  GetKeyValue = 1,

  #[event(input = "KeyPB")]
  RemoveKeyValue = 2,
}
