use crate::{
    entities::{app::App, workspace::*},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::WorkspaceObservable,
    services::{helper::spawn, server::Server, AppController},
    sql_tables::workspace::{WorkspaceSql, WorkspaceTable, WorkspaceTableChangeset},
};

use flowy_infra::kv::KV;

use crate::{entities::app::RepeatedApp, observable::ObservableBuilder};
use std::sync::Arc;

pub(crate) struct WorkspaceController {
    pub user: Arc<dyn WorkspaceUser>,
    pub sql: Arc<WorkspaceSql>,
    pub app_controller: Arc<AppController>,
    server: Server,
}

impl WorkspaceController {
    pub(crate) fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        app_controller: Arc<AppController>,
        server: Server,
    ) -> Self {
        let sql = Arc::new(WorkspaceSql::new(database));
        Self {
            user,
            sql,
            app_controller,
            server,
        }
    }

    pub(crate) async fn create_workspace(&self, params: CreateWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let workspace = self.create_workspace_on_server(params.clone()).await?;
        let user_id = self.user.user_id()?;
        let workspace_table = WorkspaceTable::new(workspace.clone(), &user_id);
        let _ = self.sql.create_workspace(workspace_table)?;

        // Opti: read all local workspaces may cause performance issues
        let repeated_workspace = self.read_local_workspaces(None, &user_id)?;
        ObservableBuilder::new(&user_id, WorkspaceObservable::UserCreateWorkspace)
            .payload(repeated_workspace)
            .build();
        Ok(workspace)
    }

    pub(crate) async fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let changeset = WorkspaceTableChangeset::new(params.clone());
        let workspace_id = changeset.id.clone();
        let _ = self.sql.update_workspace(changeset)?;
        let _ = self.update_workspace_on_server(params).await?;

        // Opti: transaction
        let user_id = self.user.user_id()?;
        let workspace = self.read_local_workspace(workspace_id.clone(), &user_id)?;
        ObservableBuilder::new(&workspace_id, WorkspaceObservable::WorkspaceUpdated)
            .payload(workspace)
            .build();
        Ok(())
    }

    pub(crate) async fn delete_workspace(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let user_id = self.user.user_id()?;
        let _ = self.sql.delete_workspace(workspace_id)?;
        let _ = self.delete_workspace_on_server(workspace_id).await?;

        // Opti: read all local workspaces may cause performance issues
        let repeated_workspace = self.read_local_workspaces(None, &user_id)?;
        ObservableBuilder::new(&user_id, WorkspaceObservable::UserDeleteWorkspace)
            .payload(repeated_workspace)
            .build();
        Ok(())
    }

    pub(crate) async fn open_workspace(&self, params: QueryWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        if let Some(workspace_id) = params.workspace_id.clone() {
            let workspace = self.read_local_workspace(workspace_id, &user_id)?;
            set_current_workspace(&workspace.id);
            Ok(workspace)
        } else {
            return Err(ErrorBuilder::new(ErrorCode::WorkspaceIdInvalid)
                .msg("Opened workspace id should not be empty")
                .build());
        }
    }

    pub(crate) async fn read_workspaces(&self, params: QueryWorkspaceParams) -> Result<RepeatedWorkspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let workspaces = self.read_local_workspaces(params.workspace_id.clone(), &user_id)?;
        let _ = self.read_workspaces_on_server(user_id, params).await?;
        Ok(workspaces)
    }

    pub(crate) async fn read_cur_workspace(&self) -> Result<Workspace, WorkspaceError> {
        let workspace_id = get_current_workspace()?;
        let user_id = self.user.user_id()?;
        let workspace = self.read_local_workspace(workspace_id, &user_id)?;
        Ok(workspace)
    }

    pub(crate) async fn read_workspace_apps(&self) -> Result<RepeatedApp, WorkspaceError> {
        let workspace_id = get_current_workspace()?;
        let apps = self.read_local_apps(&workspace_id)?;
        // TODO: read from server
        Ok(RepeatedApp { items: apps })
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn read_local_workspaces(&self, workspace_id: Option<String>, user_id: &str) -> Result<RepeatedWorkspace, WorkspaceError> {
        let sql = self.sql.clone();
        let workspace_id = workspace_id.to_owned();
        let workspace_tables = sql.read_workspaces(workspace_id, user_id)?;

        let mut workspaces = vec![];
        for table in workspace_tables {
            let apps = self.read_local_apps(&table.id)?;
            let mut workspace: Workspace = table.into();
            workspace.apps.items = apps;
            workspaces.push(workspace);
        }
        Ok(RepeatedWorkspace { items: workspaces })
    }

    fn read_local_workspace(&self, workspace_id: String, user_id: &str) -> Result<Workspace, WorkspaceError> {
        // Opti: fetch single workspace from local db
        let mut repeated_workspace = self.read_local_workspaces(Some(workspace_id), user_id)?;
        if repeated_workspace.is_empty() {
            return Err(ErrorBuilder::new(ErrorCode::RecordNotFound).build());
        }

        debug_assert_eq!(repeated_workspace.len(), 1);
        let workspace = repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop().unwrap();
        Ok(workspace)
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn read_local_apps(&self, workspace_id: &str) -> Result<Vec<App>, WorkspaceError> {
        let apps = self
            .sql
            .read_apps_belong_to_workspace(workspace_id)?
            .into_iter()
            .map(|app_table| app_table.into())
            .collect::<Vec<App>>();

        Ok(apps)
    }
}

impl WorkspaceController {
    fn token_with_server(&self) -> Result<(String, Server), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        Ok((token, server))
    }

    #[tracing::instrument(skip(self), err)]
    async fn create_workspace_on_server(&self, params: CreateWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let token = self.user.token()?;
        let workspace = self.server.create_workspace(&token, params).await?;
        Ok(workspace)
    }

    #[tracing::instrument(skip(self), err)]
    async fn update_workspace_on_server(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let (token, server) = self.token_with_server()?;
        spawn(async move {
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

    #[tracing::instrument(skip(self), err)]
    async fn delete_workspace_on_server(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let params = DeleteWorkspaceParams {
            workspace_id: workspace_id.to_string(),
        };
        let (token, server) = self.token_with_server()?;
        spawn(async move {
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

    #[tracing::instrument(skip(self), err)]
    async fn read_workspaces_on_server(&self, user_id: String, params: QueryWorkspaceParams) -> Result<(), WorkspaceError> {
        let (token, server) = self.token_with_server()?;
        let sql = self.sql.clone();
        let conn = self.sql.get_db_conn()?;
        spawn(async move {
            // Opti: retry?
            let workspaces = server.read_workspace(&token, params).await?;
            let _ = (&*conn).immediate_transaction::<_, WorkspaceError, _>(|| {
                for workspace in &workspaces.items {
                    let mut m_workspace = workspace.clone();
                    let repeated_app = m_workspace.apps.take_items();
                    let workspace_table = WorkspaceTable::new(m_workspace, &user_id);
                    log::debug!("Save workspace: {} to disk", &workspace.id);
                    let _ = sql.create_workspace_with(workspace_table, &*conn)?;
                    log::debug!("Save workspace: {} apps to disk", &workspace.id);
                    let _ = sql.create_apps(repeated_app, &*conn)?;
                }
                Ok(())
            })?;
            ObservableBuilder::new(&user_id, WorkspaceObservable::WorkspaceListUpdated)
                .payload(workspaces)
                .build();
            Result::<(), WorkspaceError>::Ok(())
        });

        Ok(())
    }
}

const CURRENT_WORKSPACE_ID: &str = "current_workspace_id";

fn set_current_workspace(workspace: &str) { KV::set_str(CURRENT_WORKSPACE_ID, workspace.to_owned()); }

fn get_current_workspace() -> Result<String, WorkspaceError> {
    match KV::get_str(CURRENT_WORKSPACE_ID) {
        None => Err(ErrorBuilder::new(ErrorCode::CurrentWorkspaceNotFound).build()),
        Some(workspace_id) => Ok(workspace_id),
    }
}
