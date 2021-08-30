use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "DocError"]
pub enum EditorEvent {
    #[event(input = "CreateDocRequest", output = "DocInfo")]
    CreateDoc   = 0,

    #[event(input = "UpdateDocRequest")]
    UpdateDoc   = 1,

    #[event(input = "QueryDocRequest", output = "DocInfo")]
    ReadDocInfo = 2,

    #[event(input = "QueryDocDataRequest", output = "DocData")]
    ReadDocData = 3,
}
