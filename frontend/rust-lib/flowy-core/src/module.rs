use std::sync::Arc;

use backend_service::configuration::ClientServerConfiguration;
use flowy_database::DBConnection;
use flowy_document::module::FlowyDocument;
use lib_dispatch::prelude::*;
use lib_sqlite::ConnectionPool;

use crate::{
    core::{event_handler::*, CoreContext},
    errors::FlowyError,
    event::WorkspaceEvent,
    services::{
        app::event_handler::*,
        server::construct_workspace_server,
        trash::event_handler::*,
        view::event_handler::*,
        workspace::event_handler::*,
        AppController,
        TrashController,
        ViewController,
        WorkspaceController,
    },
};

pub trait WorkspaceDeps: WorkspaceUser + WorkspaceDatabase {}

pub trait WorkspaceUser: Send + Sync {
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
}

pub trait WorkspaceDatabase: Send + Sync {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;

    fn db_connection(&self) -> Result<DBConnection, FlowyError> {
        let pool = self.db_pool()?;
        let conn = pool.get().map_err(|e| FlowyError::internal().context(e))?;
        Ok(conn)
    }
}

pub fn init_core(
    user: Arc<dyn WorkspaceUser>,
    database: Arc<dyn WorkspaceDatabase>,
    flowy_document: Arc<FlowyDocument>,
    server_config: &ClientServerConfiguration,
) -> Arc<CoreContext> {
    let server = construct_workspace_server(server_config);

    let trash_controller = Arc::new(TrashController::new(database.clone(), server.clone(), user.clone()));

    let view_controller = Arc::new(ViewController::new(
        user.clone(),
        database.clone(),
        server.clone(),
        trash_controller.clone(),
        flowy_document,
    ));

    let app_controller = Arc::new(AppController::new(
        user.clone(),
        database.clone(),
        trash_controller.clone(),
        server.clone(),
    ));

    let workspace_controller = Arc::new(WorkspaceController::new(
        user.clone(),
        database.clone(),
        trash_controller.clone(),
        server.clone(),
    ));

    Arc::new(CoreContext::new(
        user,
        server,
        database,
        workspace_controller,
        app_controller,
        view_controller,
        trash_controller,
    ))
}

pub fn create(core: Arc<CoreContext>) -> Module {
    let mut module = Module::new()
        .name("Flowy-Workspace")
        .data(core.workspace_controller.clone())
        .data(core.app_controller.clone())
        .data(core.view_controller.clone())
        .data(core.trash_controller.clone())
        .data(core.clone());

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
