use strum_macros::Display;

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;

use crate::event_handler::*;

pub fn init() -> AFPlugin {
  AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .event(ConfigEvent::SetKeyValue, set_key_value_handler)
    .event(ConfigEvent::GetKeyValue, get_key_value_handler)
    .event(ConfigEvent::RemoveKeyValue, remove_key_value_handler)
    .event(
      ConfigEvent::SetCollabPluginConfig,
      set_collab_plugin_config_handler,
    )
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

  #[event(input = "CollabPluginConfigPB")]
  SetCollabPluginConfig = 4,
}
