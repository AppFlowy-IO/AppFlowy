use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "WorkspaceError"]
pub enum WorkspaceEvent {
    #[display(fmt = "Create workspace")]
    #[event(input = "CreateSpaceRequest", output = "WorkspaceDetail")]
    CreateWorkspace    = 0,

    #[display(fmt = "Get user's workspace detail")]
    #[event(output = "UserWorkspaceDetail")]
    GetWorkspaceDetail = 1,
}
