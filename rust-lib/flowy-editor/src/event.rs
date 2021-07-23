use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "EditorError"]
pub enum EditorEvent {
    #[display(fmt = "CreateDoc")]
    #[event(input = "CreateDocRequest", output = "DocDescription")]
    CreateDoc = 0,

    #[display(fmt = "UpdateDoc")]
    #[event(input = "UpdateDocRequest")]
    UpdateDoc = 1,

    #[display(fmt = "ReadDoc")]
    #[event(input = "QueryDocRequest", output = "Doc")]
    ReadDoc   = 2,
}
