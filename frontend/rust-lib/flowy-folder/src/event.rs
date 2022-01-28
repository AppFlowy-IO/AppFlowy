use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum FolderEvent {
    #[event(input = "CreateWorkspaceRequest", output = "Workspace")]
    CreateWorkspace = 0,

    #[event(output = "CurrentWorkspaceSetting")]
    ReadCurWorkspace = 1,

    #[event(input = "QueryWorkspaceRequest", output = "RepeatedWorkspace")]
    ReadWorkspaces = 2,

    #[event(input = "QueryWorkspaceRequest")]
    DeleteWorkspace = 3,

    #[event(input = "QueryWorkspaceRequest", output = "Workspace")]
    OpenWorkspace = 4,

    #[event(input = "QueryWorkspaceRequest", output = "RepeatedApp")]
    ReadWorkspaceApps = 5,

    #[event(input = "CreateAppRequest", output = "App")]
    CreateApp = 101,

    #[event(input = "QueryAppRequest")]
    DeleteApp = 102,

    #[event(input = "QueryAppRequest", output = "App")]
    ReadApp = 103,

    #[event(input = "UpdateAppRequest")]
    UpdateApp = 104,

    #[event(input = "CreateViewRequest", output = "View")]
    CreateView = 201,

    #[event(input = "QueryViewRequest", output = "View")]
    ReadView = 202,

    #[event(input = "UpdateViewRequest", output = "View")]
    UpdateView = 203,

    #[event(input = "QueryViewRequest")]
    DeleteView = 204,

    #[event(input = "QueryViewRequest")]
    DuplicateView = 205,

    #[event()]
    CopyLink = 206,

    #[event(input = "QueryViewRequest", output = "DocumentDelta")]
    OpenDocument = 207,

    #[event(input = "QueryViewRequest")]
    CloseView = 208,

    #[event(output = "RepeatedTrash")]
    ReadTrash = 300,

    #[event(input = "TrashId")]
    PutbackTrash = 301,

    #[event(input = "RepeatedTrashId")]
    DeleteTrash = 302,

    #[event()]
    RestoreAllTrash = 303,

    #[event()]
    DeleteAllTrash = 304,

    #[event(input = "DocumentDelta", output = "DocumentDelta")]
    ApplyDocDelta = 400,

    #[event(input = "ExportRequest", output = "ExportData")]
    ExportDocument = 500,
}
