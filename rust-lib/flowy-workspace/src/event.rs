use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "WorkspaceError"]
pub enum WorkspaceEvent {
    #[display(fmt = "CreateWorkspace")]
    #[event(input = "CreateWorkspaceRequest", output = "Workspace")]
    CreateWorkspace = 0,

    #[display(fmt = "GetCurWorkspace")]
    #[event(output = "Workspace")]
    GetCurWorkspace = 1,

    #[display(fmt = "GetWorkspace")]
    #[event(input = "QueryWorkspaceRequest", output = "Workspace")]
    GetWorkspace    = 2,

    #[display(fmt = "CreateApp")]
    #[event(input = "CreateAppRequest", output = "App")]
    CreateApp       = 101,

    #[display(fmt = "GetApp")]
    #[event(input = "QueryAppRequest", output = "App")]
    GetApp          = 102,

    #[display(fmt = "CreateView")]
    #[event(input = "CreateViewRequest", output = "View")]
    CreateView      = 201,

    #[display(fmt = "ReadView")]
    #[event(input = "QueryViewRequest", output = "View")]
    ReadView        = 202,

    #[display(fmt = "UpdateView")]
    #[event(input = "UpdateViewRequest", output = "View")]
    UpdateView      = 203,
}
