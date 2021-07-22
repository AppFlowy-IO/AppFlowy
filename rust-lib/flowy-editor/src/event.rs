use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "EditorError"]
pub enum EditorEvent {
    #[display(fmt = "CreateDoc")]
    #[event(input = "CreateDocRequest", output = "Doc")]
    CreateDoc = 0,
}
