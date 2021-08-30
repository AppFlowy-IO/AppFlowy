use derive_more::Display;
use flowy_derive::{Flowy_Event, ProtoBuf_Enum};

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "WorkspaceError"]
pub enum WorkspaceEvent {
    #[display(fmt = "CreateWorkspace")]
    #[event(input = "CreateWorkspaceRequest", output = "Workspace")]
    CreateWorkspace  = 0,

    #[display(fmt = "ReadCurWorkspace")]
    #[event(output = "Workspace")]
    ReadCurWorkspace = 1,

    #[display(fmt = "ReadWorkspaces")]
    #[event(input = "QueryWorkspaceRequest", output = "RepeatedWorkspace")]
    ReadWorkspaces   = 2,

    #[display(fmt = "DeleteWorkspace")]
    #[event(input = "DeleteWorkspaceRequest")]
    DeleteWorkspace  = 3,

    #[display(fmt = "OpenWorkspace")]
    #[event(input = "QueryWorkspaceRequest", output = "Workspace")]
    OpenWorkspace    = 4,

    #[display(fmt = "CreateApp")]
    #[event(input = "CreateAppRequest", output = "App")]
    CreateApp        = 101,

    #[display(fmt = "DeleteApp")]
    #[event(input = "DeleteAppRequest")]
    DeleteApp        = 102,

    #[display(fmt = "ReadApp")]
    #[event(input = "QueryAppRequest", output = "App")]
    ReadApp          = 103,

    #[display(fmt = "UpdateApp")]
    #[event(input = "UpdateAppRequest")]
    UpdateApp        = 104,

    #[display(fmt = "CreateView")]
    #[event(input = "CreateViewRequest", output = "View")]
    CreateView       = 201,

    #[display(fmt = "ReadView")]
    #[event(input = "QueryViewRequest", output = "View")]
    ReadView         = 202,

    #[display(fmt = "UpdateView")]
    #[event(input = "UpdateViewRequest")]
    UpdateView       = 203,

    #[display(fmt = "DeleteView")]
    #[event(input = "DeleteViewRequest")]
    DeleteView       = 204,
}
