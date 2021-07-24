use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "EditorError"]
pub enum EditorEvent {
    #[display(fmt = "CreateDoc")]
    #[event(input = "CreateDocRequest", output = "DocInfo")]
    CreateDoc   = 0,

    #[display(fmt = "UpdateDoc")]
    #[event(input = "UpdateDocRequest")]
    UpdateDoc   = 1,

    #[display(fmt = "ReadDocInfo")]
    #[event(input = "QueryDocRequest", output = "DocInfo")]
    ReadDocInfo = 2,

    #[display(fmt = "ReadDocData")]
    #[event(input = "QueryDocDataRequest", output = "DocData")]
    ReadDocData = 3,
}
