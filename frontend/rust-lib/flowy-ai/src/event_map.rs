use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use lib_dispatch::prelude::AFPlugin;
use strum_macros::Display;

use crate::event_handler::request_text_completion;

pub fn init() -> AFPlugin {
  AFPlugin::new()
    .name(env!("CARGO_PKG_NAME"))
    .event(OpenAIEvent::RequestTextCompletion, request_text_completion)
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Display, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum OpenAIEvent {
  #[event(input = "TextCompletionPayloadPB", output = "TextCompletionDataPB")]
  RequestTextCompletion = 0,
}
