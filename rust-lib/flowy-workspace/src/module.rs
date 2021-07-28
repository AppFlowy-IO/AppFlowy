use flowy_dispatch::prelude::*;

use crate::{
    errors::WorkspaceError,
    event::WorkspaceEvent,
    services::{AppController, WorkspaceController},
};
use flowy_database::DBConnection;

use crate::{entities::workspace::CurrentWorkspace, handlers::*, services::ViewController};
use std::sync::Arc;

pub trait WorkspaceDeps: WorkspaceUser + WorkspaceDatabase {}

pub trait WorkspaceUser: Send + Sync {
    fn user_id(&self) -> Result<String, WorkspaceError>;
    fn set_cur_workspace_id(&self, id: &str) -> DispatchFuture<Result<(), WorkspaceError>>;
    fn get_cur_workspace(&self) -> DispatchFuture<Result<CurrentWorkspace, WorkspaceError>>;
}

pub trait WorkspaceDatabase: Send + Sync {
    fn db_connection(&self) -> Result<DBConnection, WorkspaceError>;
}

pub fn create(user: Arc<dyn WorkspaceUser>, database: Arc<dyn WorkspaceDatabase>) -> Module {
    let view_controller = Arc::new(ViewController::new(database.clone()));

    let app_controller = Arc::new(AppController::new(
        user.clone(),
        database.clone(),
        view_controller.clone(),
    ));

    let workspace_controller = Arc::new(WorkspaceController::new(
        user.clone(),
        database.clone(),
        app_controller.clone(),
    ));

    Module::new()
        .name("Flowy-Workspace")
        .data(workspace_controller)
        .data(app_controller)
        .data(view_controller)
        .event(WorkspaceEvent::ReadAllWorkspace, read_all_workspaces)
        .event(WorkspaceEvent::CreateWorkspace, create_workspace)
        .event(WorkspaceEvent::GetCurWorkspace, get_cur_workspace)
        .event(WorkspaceEvent::GetWorkspace, get_workspace)
        .event(WorkspaceEvent::CreateApp, create_app)
        .event(WorkspaceEvent::GetApp, get_app)
        .event(WorkspaceEvent::CreateView, create_view)
        .event(WorkspaceEvent::ReadView, read_view)
        .event(WorkspaceEvent::UpdateView, update_view)
}
