use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "WorkspaceError"]
pub enum WorkspaceEvent {
    #[display(fmt = "Create workspace")]
    #[event(input = "CreateWorkspaceRequest", output = "Workspace")]
    CreateWorkspace = 0,

    #[display(fmt = "Get user's current workspace")]
    #[event(output = "Workspace")]
    GetCurWorkspace = 1,

    #[display(fmt = "Get user's workspace")]
    #[event(input = "QueryWorkspaceRequest", output = "Workspace")]
    GetWorkspace    = 2,

    #[display(fmt = "Create app information")]
    #[event(input = "CreateAppRequest", output = "App")]
    CreateApp       = 101,

    #[display(fmt = "Get app information")]
    #[event(input = "QueryAppRequest", output = "App")]
    GetApp          = 102,

    #[display(fmt = "Create view")]
    #[event(input = "CreateViewRequest", output = "View")]
    CreateView      = 201,
}
