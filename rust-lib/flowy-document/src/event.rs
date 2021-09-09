use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "DocError"]
pub enum EditorEvent {
    #[event(input = "CreateDocRequest", output = "Doc")]
    CreateDoc = 0,

    #[event(input = "UpdateDocRequest")]
    UpdateDoc = 1,

    #[event(input = "QueryDocRequest", output = "Doc")]
    ReadDoc   = 2,

    #[event(input = "QueryDocRequest")]
    DeleteDoc = 3,
}
