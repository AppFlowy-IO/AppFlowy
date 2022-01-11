use crate::{
    errors::*,
    module::{WorkspaceCloudService, WorkspaceDatabase, WorkspaceUser},
    notify::*,
    services::{
        read_local_workspace_apps,
        workspace::sql::{WorkspaceTable, WorkspaceTableChangeset, WorkspaceTableSql},
        TrashController,
    },
};
use flowy_core_data_model::entities::{app::RepeatedApp, workspace::*};
use flowy_database::{kv::KV, SqliteConnection};
use std::sync::Arc;

pub struct WorkspaceController {
    pub user: Arc<dyn WorkspaceUser>,
    pub(crate) database: Arc<dyn WorkspaceDatabase>,
    pub(crate) trash_controller: Arc<TrashController>,
    cloud_service: Arc<dyn WorkspaceCloudService>,
}

impl WorkspaceController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        trash_can: Arc<TrashController>,
        cloud_service: Arc<dyn WorkspaceCloudService>,
    ) -> Self {
        Self {
            user,
            database,
            trash_controller: trash_can,
            cloud_service,
        }
    }

    pub(crate) fn init(&self) -> Result<(), FlowyError> { Ok(()) }

    pub(crate) async fn create_workspace_from_params(
        &self,
        params: CreateWorkspaceParams,
    ) -> Result<Workspace, FlowyError> {
        let workspace = self.create_workspace_on_server(params.clone()).await?;
        self.create_workspace_on_local(workspace).await
    }

    pub(crate) async fn create_workspace_on_local(&self, workspace: Workspace) -> Result<Workspace, FlowyError> {
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let workspace_table = WorkspaceTable::new(workspace.clone(), &user_id);
        let conn = &*self.database.db_connection()?;
        //[[immediate_transaction]]
        // https://sqlite.org/lang_transaction.html
        // IMMEDIATE cause the database connection to start a new write immediately,
        // without waiting for a write statement. The BEGIN IMMEDIATE might fail
        // with SQLITE_BUSY if another write transaction is already active on another
        // database connection.
        //
        // EXCLUSIVE is similar to IMMEDIATE in that a write transaction is started
        // immediately. EXCLUSIVE and IMMEDIATE are the same in WAL mode, but in
        // other journaling modes, EXCLUSIVE prevents other database connections from
        // reading the database while the transaction is underway.
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            WorkspaceTableSql::create_workspace(workspace_table, conn)?;
            let repeated_workspace = self.read_local_workspaces(None, &user_id, conn)?;
            send_dart_notification(&token, WorkspaceNotification::UserCreateWorkspace)
                .payload(repeated_workspace)
                .send();

            Ok(())
        })?;

        set_current_workspace(&workspace.id);

        Ok(workspace)
    }

    #[allow(dead_code)]
    pub(crate) async fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), FlowyError> {
        let changeset = WorkspaceTableChangeset::new(params.clone());
        let workspace_id = changeset.id.clone();
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let _ = WorkspaceTableSql::update_workspace(changeset, conn)?;
            let user_id = self.user.user_id()?;
            let workspace = self.read_local_workspace(workspace_id.clone(), &user_id, conn)?;
            send_dart_notification(&workspace_id, WorkspaceNotification::WorkspaceUpdated)
                .payload(workspace)
                .send();

            Ok(())
        })?;

        let _ = self.update_workspace_on_server(params)?;

        Ok(())
    }

    #[allow(dead_code)]
    pub(crate) async fn delete_workspace(&self, workspace_id: &str) -> Result<(), FlowyError> {
        let user_id = self.user.user_id()?;
        let token = self.user.token()?;
        let conn = &*self.database.db_connection()?;
        conn.immediate_transaction::<_, FlowyError, _>(|| {
            let _ = WorkspaceTableSql::delete_workspace(workspace_id, conn)?;
            let repeated_workspace = self.read_local_workspaces(None, &user_id, conn)?;
            send_dart_notification(&token, WorkspaceNotification::UserDeleteWorkspace)
                .payload(repeated_workspace)
                .send();

            Ok(())
        })?;

        let _ = self.delete_workspace_on_server(workspace_id)?;
        Ok(())
    }

    pub(crate) async fn open_workspace(&self, params: WorkspaceId) -> Result<Workspace, FlowyError> {
        let user_id = self.user.user_id()?;
        let conn = self.database.db_connection()?;
        if let Some(workspace_id) = params.workspace_id {
            let workspace = self.read_local_workspace(workspace_id, &user_id, &*conn)?;
            set_current_workspace(&workspace.id);
            Ok(workspace)
        } else {
            return Err(FlowyError::workspace_id().context("Opened workspace id should not be empty"));
        }
    }

    pub(crate) async fn read_current_workspace_apps(&self) -> Result<RepeatedApp, FlowyError> {
        let workspace_id = get_current_workspace()?;
        let conn = self.database.db_connection()?;
        let repeated_app = self.read_local_apps(&workspace_id, &*conn)?;
        // TODO: read from server
        Ok(repeated_app)
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub(crate) fn read_local_workspaces(
        &self,
        workspace_id: Option<String>,
        user_id: &str,
        conn: &SqliteConnection,
    ) -> Result<RepeatedWorkspace, FlowyError> {
        let workspace_id = workspace_id.to_owned();
        let workspace_tables = WorkspaceTableSql::read_workspaces(workspace_id, user_id, conn)?;

        let mut workspaces = vec![];
        for table in workspace_tables {
            let workspace: Workspace = table.into();
            workspaces.push(workspace);
        }
        Ok(RepeatedWorkspace { items: workspaces })
    }

    pub(crate) fn read_local_workspace(
        &self,
        workspace_id: String,
        user_id: &str,
        conn: &SqliteConnection,
    ) -> Result<Workspace, FlowyError> {
        // Opti: fetch single workspace from local db
        let mut repeated_workspace = self.read_local_workspaces(Some(workspace_id.clone()), user_id, conn)?;
        if repeated_workspace.is_empty() {
            return Err(FlowyError::record_not_found().context(format!("{} workspace not found", workspace_id)));
        }

        debug_assert_eq!(repeated_workspace.len(), 1);
        let workspace = repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop().unwrap();
        Ok(workspace)
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    fn read_local_apps(&self, workspace_id: &str, conn: &SqliteConnection) -> Result<RepeatedApp, FlowyError> {
        let repeated_app = read_local_workspace_apps(workspace_id, self.trash_controller.clone(), conn)?;
        Ok(repeated_app)
    }
}

impl WorkspaceController {
    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn create_workspace_on_server(&self, params: CreateWorkspaceParams) -> Result<Workspace, FlowyError> {
        let token = self.user.token()?;
        let workspace = self.cloud_service.create_workspace(&token, params).await?;
        Ok(workspace)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn update_workspace_on_server(&self, params: UpdateWorkspaceParams) -> Result<(), FlowyError> {
        let (token, server) = (self.user.token()?, self.cloud_service.clone());
        tokio::spawn(async move {
            match server.update_workspace(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update workspace failed: {:?}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn delete_workspace_on_server(&self, workspace_id: &str) -> Result<(), FlowyError> {
        let params = WorkspaceId {
            workspace_id: Some(workspace_id.to_string()),
        };
        let (token, server) = (self.user.token()?, self.cloud_service.clone());
        tokio::spawn(async move {
            match server.delete_workspace(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete workspace failed: {:?}", e);
                },
            }
        });
        Ok(())
    }
}

const CURRENT_WORKSPACE_ID: &str = "current_workspace_id";

fn set_current_workspace(workspace_id: &str) { KV::set_str(CURRENT_WORKSPACE_ID, workspace_id.to_owned()); }

pub fn get_current_workspace() -> Result<String, FlowyError> {
    match KV::get_str(CURRENT_WORKSPACE_ID) {
        None => {
            Err(FlowyError::record_not_found()
                .context("Current workspace not found or should call open workspace first"))
        },
        Some(workspace_id) => Ok(workspace_id),
    }
}
