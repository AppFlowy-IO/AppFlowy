use crate::{
    entities::{
        app::{App, AppId, CreateAppParams, RepeatedApp, UpdateAppParams},
        trash::{RepeatedTrash, RepeatedTrashId},
        view::{CreateViewParams, RepeatedView, RepeatedViewId, UpdateViewParams, View, ViewId},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceId},
    },
    errors::FlowyError,
    services::server::WorkspaceServerAPI,
};
use lib_infra::{future::FutureResult, timestamp, uuid_string};

pub struct WorkspaceServerMock {}

impl WorkspaceServerAPI for WorkspaceServerMock {
    fn init(&self) {}

    fn create_workspace(&self, _token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError> {
        let time = timestamp();
        let workspace = Workspace {
            id: uuid_string(),
            name: params.name,
            desc: params.desc,
            apps: RepeatedApp::default(),
            modified_time: time,
            create_time: time,
        };

        FutureResult::new(async { Ok(workspace) })
    }

    fn read_workspace(&self, _token: &str, _params: WorkspaceId) -> FutureResult<RepeatedWorkspace, FlowyError> {
        FutureResult::new(async {
            let repeated_workspace = RepeatedWorkspace { items: vec![] };
            Ok(repeated_workspace)
        })
    }

    fn update_workspace(&self, _token: &str, _params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_workspace(&self, _token: &str, _params: WorkspaceId) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_view(&self, _token: &str, params: CreateViewParams) -> FutureResult<View, FlowyError> {
        let time = timestamp();
        let view = View {
            id: params.view_id,
            belong_to_id: params.belong_to_id,
            name: params.name,
            desc: params.desc,
            view_type: params.view_type,
            version: 0,
            belongings: RepeatedView::default(),
            modified_time: time,
            create_time: time,
        };
        FutureResult::new(async { Ok(view) })
    }

    fn read_view(&self, _token: &str, _params: ViewId) -> FutureResult<Option<View>, FlowyError> {
        FutureResult::new(async { Ok(None) })
    }

    fn delete_view(&self, _token: &str, _params: RepeatedViewId) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn update_view(&self, _token: &str, _params: UpdateViewParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_app(&self, _token: &str, params: CreateAppParams) -> FutureResult<App, FlowyError> {
        let time = timestamp();
        let app = App {
            id: uuid_string(),
            workspace_id: params.workspace_id,
            name: params.name,
            desc: params.desc,
            belongings: RepeatedView::default(),
            version: 0,
            modified_time: time,
            create_time: time,
        };
        FutureResult::new(async { Ok(app) })
    }

    fn read_app(&self, _token: &str, _params: AppId) -> FutureResult<Option<App>, FlowyError> {
        FutureResult::new(async { Ok(None) })
    }

    fn update_app(&self, _token: &str, _params: UpdateAppParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_app(&self, _token: &str, _params: AppId) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_trash(&self, _token: &str, _params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_trash(&self, _token: &str, _params: RepeatedTrashId) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn read_trash(&self, _token: &str) -> FutureResult<RepeatedTrash, FlowyError> {
        FutureResult::new(async {
            let repeated_trash = RepeatedTrash { items: vec![] };
            Ok(repeated_trash)
        })
    }
}
