use crate::{
    entities::{
        app::{App, AppIdentifier, CreateAppParams, RepeatedApp, UpdateAppParams},
        trash::{RepeatedTrash, TrashIdentifiers},
        view::{CreateViewParams, RepeatedView, UpdateViewParams, View, ViewIdentifier, ViewIdentifiers},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceIdentifier},
    },
    errors::WorkspaceError,
    services::server::WorkspaceServerAPI,
};
use lib_infra::{future::FutureResult, timestamp, uuid};

pub struct WorkspaceServerMock {}

impl WorkspaceServerAPI for WorkspaceServerMock {
    fn init(&self) {}

    fn create_workspace(&self, _token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, WorkspaceError> {
        let time = timestamp();
        let workspace = Workspace {
            id: uuid(),
            name: params.name,
            desc: params.desc,
            apps: RepeatedApp::default(),
            modified_time: time,
            create_time: time,
        };

        FutureResult::new(async { Ok(workspace) })
    }

    fn read_workspace(
        &self,
        _token: &str,
        _params: WorkspaceIdentifier,
    ) -> FutureResult<RepeatedWorkspace, WorkspaceError> {
        FutureResult::new(async {
            let repeated_workspace = RepeatedWorkspace { items: vec![] };
            Ok(repeated_workspace)
        })
    }

    fn update_workspace(&self, _token: &str, _params: UpdateWorkspaceParams) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_workspace(&self, _token: &str, _params: WorkspaceIdentifier) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_view(&self, _token: &str, params: CreateViewParams) -> FutureResult<View, WorkspaceError> {
        let time = timestamp();
        let view = View {
            id: uuid(),
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

    fn read_view(&self, _token: &str, _params: ViewIdentifier) -> FutureResult<Option<View>, WorkspaceError> {
        FutureResult::new(async { Ok(None) })
    }

    fn delete_view(&self, _token: &str, _params: ViewIdentifiers) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn update_view(&self, _token: &str, _params: UpdateViewParams) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_app(&self, _token: &str, params: CreateAppParams) -> FutureResult<App, WorkspaceError> {
        let time = timestamp();
        let app = App {
            id: uuid(),
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

    fn read_app(&self, _token: &str, _params: AppIdentifier) -> FutureResult<Option<App>, WorkspaceError> {
        FutureResult::new(async { Ok(None) })
    }

    fn update_app(&self, _token: &str, _params: UpdateAppParams) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_app(&self, _token: &str, _params: AppIdentifier) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_trash(&self, _token: &str, _params: TrashIdentifiers) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn delete_trash(&self, _token: &str, _params: TrashIdentifiers) -> FutureResult<(), WorkspaceError> {
        FutureResult::new(async { Ok(()) })
    }

    fn read_trash(&self, _token: &str) -> FutureResult<RepeatedTrash, WorkspaceError> {
        FutureResult::new(async {
            let repeated_trash = RepeatedTrash { items: vec![] };
            Ok(repeated_trash)
        })
    }
}
