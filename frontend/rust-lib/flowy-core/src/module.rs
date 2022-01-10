use crate::{
    context::CoreContext,
    entities::{
        app::{App, AppId, CreateAppParams, UpdateAppParams},
        trash::{RepeatedTrash, RepeatedTrashId},
        view::{CreateViewParams, RepeatedViewId, UpdateViewParams, View, ViewId},
        workspace::{CreateWorkspaceParams, RepeatedWorkspace, UpdateWorkspaceParams, Workspace, WorkspaceId},
    },
    errors::FlowyError,
    event::WorkspaceEvent,
    event_handler::*,
    services::{
        app::event_handler::*,
        trash::event_handler::*,
        view::event_handler::*,
        workspace::event_handler::*,
        AppController,
        TrashController,
        ViewController,
        WorkspaceController,
    },
};
use flowy_database::DBConnection;
use flowy_document::context::DocumentContext;
use lib_dispatch::prelude::*;
use lib_infra::future::FutureResult;
use lib_sqlite::ConnectionPool;
use std::sync::Arc;

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
    flowy_document: Arc<DocumentContext>,
    cloud_service: Arc<dyn CoreCloudService>,
) -> Arc<CoreContext> {
    let trash_controller = Arc::new(TrashController::new(
        database.clone(),
        cloud_service.clone(),
        user.clone(),
    ));

    let view_controller = Arc::new(ViewController::new(
        user.clone(),
        database.clone(),
        cloud_service.clone(),
        trash_controller.clone(),
        flowy_document,
    ));

    let app_controller = Arc::new(AppController::new(
        user.clone(),
        database.clone(),
        trash_controller.clone(),
        cloud_service.clone(),
    ));

    let workspace_controller = Arc::new(WorkspaceController::new(
        user.clone(),
        database.clone(),
        trash_controller.clone(),
        cloud_service.clone(),
    ));

    Arc::new(CoreContext::new(
        user,
        cloud_service,
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
        .event(WorkspaceEvent::ApplyDocDelta, document_delta_handler);

    module = module
        .event(WorkspaceEvent::ReadTrash, read_trash_handler)
        .event(WorkspaceEvent::PutbackTrash, putback_trash_handler)
        .event(WorkspaceEvent::DeleteTrash, delete_trash_handler)
        .event(WorkspaceEvent::RestoreAll, restore_all_handler)
        .event(WorkspaceEvent::DeleteAll, delete_all_handler);

    module = module.event(WorkspaceEvent::ExportDocument, export_handler);

    module
}

pub trait CoreCloudService: Send + Sync {
    fn init(&self);

    // Workspace
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> FutureResult<Workspace, FlowyError>;

    fn read_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<RepeatedWorkspace, FlowyError>;

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> FutureResult<(), FlowyError>;

    fn delete_workspace(&self, token: &str, params: WorkspaceId) -> FutureResult<(), FlowyError>;

    // View
    fn create_view(&self, token: &str, params: CreateViewParams) -> FutureResult<View, FlowyError>;

    fn read_view(&self, token: &str, params: ViewId) -> FutureResult<Option<View>, FlowyError>;

    fn delete_view(&self, token: &str, params: RepeatedViewId) -> FutureResult<(), FlowyError>;

    fn update_view(&self, token: &str, params: UpdateViewParams) -> FutureResult<(), FlowyError>;

    // App
    fn create_app(&self, token: &str, params: CreateAppParams) -> FutureResult<App, FlowyError>;

    fn read_app(&self, token: &str, params: AppId) -> FutureResult<Option<App>, FlowyError>;

    fn update_app(&self, token: &str, params: UpdateAppParams) -> FutureResult<(), FlowyError>;

    fn delete_app(&self, token: &str, params: AppId) -> FutureResult<(), FlowyError>;

    // Trash
    fn create_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError>;

    fn delete_trash(&self, token: &str, params: RepeatedTrashId) -> FutureResult<(), FlowyError>;

    fn read_trash(&self, token: &str) -> FutureResult<RepeatedTrash, FlowyError>;
}
