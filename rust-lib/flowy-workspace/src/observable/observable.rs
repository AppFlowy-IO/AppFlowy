use flowy_derive::ProtoBuf_Enum;

use flowy_observable::ObservableBuilder;

const OBSERVABLE_CATEGORY: &'static str = "Workspace";

#[derive(ProtoBuf_Enum, Debug)]
pub(crate) enum WorkspaceObservable {
    Unknown              = 0,

    UserCreateWorkspace  = 10,
    UserDeleteWorkspace  = 11,

    WorkspaceUpdated     = 12,
    WorkspaceCreateApp   = 13,
    WorkspaceDeleteApp   = 14,
    WorkspaceListUpdated = 15,

    AppUpdated           = 21,
    AppCreateView        = 23,
    AppDeleteView        = 24,

    ViewUpdated          = 31,

    UserUnauthorized     = 100,
}

impl std::default::Default for WorkspaceObservable {
    fn default() -> Self { WorkspaceObservable::Unknown }
}

impl std::convert::Into<i32> for WorkspaceObservable {
    fn into(self) -> i32 { self as i32 }
}

pub(crate) fn observable(id: &str, ty: WorkspaceObservable) -> ObservableBuilder { ObservableBuilder::new(id, ty, OBSERVABLE_CATEGORY) }
