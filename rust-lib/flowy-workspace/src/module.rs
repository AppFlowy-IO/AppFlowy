use flowy_dispatch::prelude::*;

use crate::{
    errors::WorkspaceError,
    event::WorkspaceEvent,
    services::{AppController, WorkspaceController},
};
use flowy_database::DBConnection;

use crate::handlers::*;
use std::sync::Arc;

pub trait WorkspaceUser: Send + Sync {
    fn set_workspace(&self, id: &str) -> DispatchFuture<Result<(), WorkspaceError>>;
    fn get_workspace(&self) -> Result<String, WorkspaceError>;
    fn db_connection(&self) -> Result<DBConnection, WorkspaceError>;
}

pub fn create(user: Arc<dyn WorkspaceUser>) -> Module {
    let workspace_controller = Arc::new(WorkspaceController::new(user.clone()));
    let app_controller = Arc::new(AppController::new(user.clone()));

    Module::new()
        .name("Flowy-Workspace")
        .data(workspace_controller)
        .data(app_controller)
        .event(WorkspaceEvent::CreateWorkspace, create_workspace)
        .event(WorkspaceEvent::GetWorkspaceUserDetail, workspace_user)
}
