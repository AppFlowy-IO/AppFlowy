use crate::{
    errors::WorkspaceError,
    event::WorkspaceEvent,
    handlers::*,
    services::{server::construct_workspace_server, AppController, TrashCan, ViewController, WorkspaceController},
};
use backend_service::config::ServerConfig;
use flowy_database::DBConnection;
use flowy_document::module::FlowyDocument;
use lib_dispatch::prelude::*;
use lib_sqlite::ConnectionPool;
use std::sync::Arc;

pub trait WorkspaceDeps: WorkspaceUser + WorkspaceDatabase {}

pub trait WorkspaceUser: Send + Sync {
    fn user_id(&self) -> Result<String, WorkspaceError>;
    fn token(&self) -> Result<String, WorkspaceError>;
}

pub trait WorkspaceDatabase: Send + Sync {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, WorkspaceError>;

    fn db_connection(&self) -> Result<DBConnection, WorkspaceError> {
        let pool = self.db_pool()?;
        let conn = pool.get().map_err(|e| WorkspaceError::internal().context(e))?;
        Ok(conn)
    }
}

pub fn mk_workspace(
    user: Arc<dyn WorkspaceUser>,
    database: Arc<dyn WorkspaceDatabase>,
    flowy_document: Arc<FlowyDocument>,
    server_config: &ServerConfig,
) -> Arc<WorkspaceController> {
    let server = construct_workspace_server(server_config);

    let trash_can = Arc::new(TrashCan::new(database.clone(), server.clone(), user.clone()));

    let view_controller = Arc::new(ViewController::new(
        user.clone(),
        database.clone(),
        server.clone(),
        trash_can.clone(),
        flowy_document,
    ));

    let app_controller = Arc::new(AppController::new(
        user.clone(),
        database.clone(),
        trash_can.clone(),
        server.clone(),
    ));

    let workspace_controller = Arc::new(WorkspaceController::new(
        user.clone(),
        database.clone(),
        app_controller.clone(),
        view_controller.clone(),
        trash_can.clone(),
        server.clone(),
    ));
    workspace_controller
}

pub fn create(workspace: Arc<WorkspaceController>) -> Module {
    let mut module = Module::new()
        .name("Flowy-Workspace")
        .data(workspace.clone())
        .data(workspace.app_controller.clone())
        .data(workspace.view_controller.clone())
        .data(workspace.trash_can.clone());

    module = module
        .event(WorkspaceEvent::CreateWorkspace, create_workspace_handler)
        .event(WorkspaceEvent::ReadCurWorkspace, read_cur_workspace_handler)
        .event(WorkspaceEvent::ReadWorkspaces, read_workspaces_handler)
        .event(WorkspaceEvent::OpenWorkspace, open_workspace_handler)
        .event(WorkspaceEvent::ReadWorkspaceApps, read_workspace_apps_handler);

    module = module
        .event(WorkspaceEvent::CreateApp, create_app_handler)
        .event(WorkspaceEvent::ReadApp, read_app_handler)
        .event(WorkspaceEvent::UpdateApp, update_app_handler)
        .event(WorkspaceEvent::DeleteApp, delete_app_handler);

    module = module
        .event(WorkspaceEvent::CreateView, create_view_handler)
        .event(WorkspaceEvent::ReadView, read_view_handler)
        .event(WorkspaceEvent::UpdateView, update_view_handler)
        .event(WorkspaceEvent::DeleteView, delete_view_handler)
        .event(WorkspaceEvent::DuplicateView, duplicate_view_handler)
        .event(WorkspaceEvent::OpenView, open_view_handler)
        .event(WorkspaceEvent::CloseView, close_view_handler)
        .event(WorkspaceEvent::ApplyDocDelta, apply_doc_delta_handler);

    module = module
        .event(WorkspaceEvent::ReadTrash, read_trash_handler)
        .event(WorkspaceEvent::PutbackTrash, putback_trash_handler)
        .event(WorkspaceEvent::DeleteTrash, delete_trash_handler)
        .event(WorkspaceEvent::RestoreAll, restore_all_handler)
        .event(WorkspaceEvent::DeleteAll, delete_all_handler);

    module = module.event(WorkspaceEvent::ExportDocument, export_handler);

    module
}
