use crate::{
    entities::{
        app::{App, AppIdentifier, CreateAppParams, RepeatedApp, UpdateAppParams},
        trash::{RepeatedTrash, TrashIdentifiers},
        view::{CreateViewParams, RepeatedView, UpdateViewParams, View, ViewIdentifier, ViewIdentifiers},
        workspace::{
            CreateWorkspaceParams,
            DeleteWorkspaceParams,
            QueryWorkspaceParams,
            RepeatedWorkspace,
            UpdateWorkspaceParams,
            Workspace,
        },
    },
    errors::WorkspaceError,
    services::server::WorkspaceServerAPI,
};
use flowy_infra::{future::ResultFuture, timestamp, uuid};

pub struct WorkspaceServerMock {}

impl WorkspaceServerAPI for WorkspaceServerMock {
    fn init(&self) {}

    fn create_workspace(&self, _token: &str, params: CreateWorkspaceParams) -> ResultFuture<Workspace, WorkspaceError> {
        let time = timestamp();
        let workspace = Workspace {
            id: uuid(),
            name: params.name,
            desc: params.desc,
            apps: RepeatedApp::default(),
            modified_time: time,
            create_time: time,
        };

        ResultFuture::new(async { Ok(workspace) })
    }

    fn read_workspace(
        &self,
        _token: &str,
        _params: QueryWorkspaceParams,
    ) -> ResultFuture<RepeatedWorkspace, WorkspaceError> {
        ResultFuture::new(async {
            let repeated_workspace = RepeatedWorkspace { items: vec![] };
            Ok(repeated_workspace)
        })
    }

    fn update_workspace(&self, _token: &str, _params: UpdateWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn delete_workspace(&self, _token: &str, _params: DeleteWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn create_view(&self, _token: &str, params: CreateViewParams) -> ResultFuture<View, WorkspaceError> {
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
        ResultFuture::new(async { Ok(view) })
    }

    fn read_view(&self, _token: &str, _params: ViewIdentifier) -> ResultFuture<Option<View>, WorkspaceError> {
        ResultFuture::new(async { Ok(None) })
    }

    fn delete_view(&self, _token: &str, _params: ViewIdentifiers) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn update_view(&self, _token: &str, _params: UpdateViewParams) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn create_app(&self, _token: &str, params: CreateAppParams) -> ResultFuture<App, WorkspaceError> {
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
        ResultFuture::new(async { Ok(app) })
    }

    fn read_app(&self, _token: &str, _params: AppIdentifier) -> ResultFuture<Option<App>, WorkspaceError> {
        ResultFuture::new(async { Ok(None) })
    }

    fn update_app(&self, _token: &str, _params: UpdateAppParams) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn delete_app(&self, _token: &str, _params: AppIdentifier) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn create_trash(&self, _token: &str, _params: TrashIdentifiers) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn delete_trash(&self, _token: &str, _params: TrashIdentifiers) -> ResultFuture<(), WorkspaceError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn read_trash(&self, _token: &str) -> ResultFuture<RepeatedTrash, WorkspaceError> {
        ResultFuture::new(async {
            let repeated_trash = RepeatedTrash { items: vec![] };
            Ok(repeated_trash)
        })
    }
}
