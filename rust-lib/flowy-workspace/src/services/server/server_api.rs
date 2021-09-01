use crate::{
    entities::{
        app::{CreateAppParams, DeleteAppParams, QueryAppParams, UpdateAppParams},
        view::{CreateViewParams, DeleteViewParams, QueryViewParams, UpdateViewParams},
        workspace::{CreateWorkspaceParams, DeleteWorkspaceParams, QueryWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams},
    },
    errors::WorkspaceError,
    services::server::WorkspaceServerAPI,
};
use flowy_infra::future::ResultFuture;

pub struct WorkspaceServer {}

impl WorkspaceServerAPI for WorkspaceServer {
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn read_workspace(&self, token: &str, params: QueryWorkspaceParams) -> ResultFuture<RepeatedWorkspace, WorkspaceError> { unimplemented!() }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn delete_workspace(&self, token: &str, params: DeleteWorkspaceParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn create_view(&self, token: &str, params: CreateViewParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn read_view(&self, token: &str, params: QueryViewParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn delete_view(&self, token: &str, params: DeleteViewParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn create_app(&self, token: &str, params: CreateAppParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn read_app(&self, token: &str, params: QueryAppParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }

    fn delete_app(&self, token: &str, params: DeleteAppParams) -> ResultFuture<(), WorkspaceError> { unimplemented!() }
}
