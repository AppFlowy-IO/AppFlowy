use crate::{
    entities::{app::App, workspace::*},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::{send_observable, WorkspaceObservable},
    services::{helper::spawn, server::Server, AppController},
    sql_tables::workspace::{WorkspaceSql, WorkspaceTable, WorkspaceTableChangeset},
};
use flowy_dispatch::prelude::DispatchFuture;
use flowy_infra::kv::KV;

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
        let sql = Arc::new(WorkspaceSql { database });
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
        send_observable(&user_id, WorkspaceObservable::UserCreateWorkspace);
        Ok(workspace)
    }

    pub(crate) async fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let changeset = WorkspaceTableChangeset::new(params.clone());
        let workspace_id = changeset.id.clone();
        let _ = self.sql.update_workspace(changeset)?;
        let _ = self.update_workspace_on_server(params).await?;
        send_observable(&workspace_id, WorkspaceObservable::WorkspaceUpdated);
        Ok(())
    }

    pub(crate) async fn delete_workspace(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let user_id = self.user.user_id()?;
        let _ = self.sql.delete_workspace(workspace_id)?;
        let _ = self.delete_workspace_on_server(workspace_id).await?;
        send_observable(&user_id, WorkspaceObservable::UserDeleteWorkspace);
        Ok(())
    }

    pub(crate) async fn open_workspace(&self, params: QueryWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        if let Some(workspace_id) = params.workspace_id.clone() {
            self.read_workspaces_on_server(params.clone());
            let result = self.read_workspace_table(Some(workspace_id), user_id)?;
            match result.first() {
                None => Err(ErrorBuilder::new(ErrorCode::RecordNotFound).build()),
                Some(workspace_table) => {
                    let workspace: Workspace = workspace_table.clone().into();
                    set_current_workspace(&workspace.id);
                    Ok(workspace)
                },
            }
        } else {
            return Err(ErrorBuilder::new(ErrorCode::WorkspaceIdInvalid)
                .msg("Opened workspace id should not be empty")
                .build());
        }
    }

    pub(crate) async fn read_workspaces(&self, params: QueryWorkspaceParams) -> Result<RepeatedWorkspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let workspace_tables = self.read_workspace_table(params.workspace_id.clone(), user_id)?;
        let mut workspaces = vec![];
        for table in workspace_tables {
            let apps = self.read_apps(&table.id).await?;
            let mut workspace: Workspace = table.into();
            workspace.apps.items = apps;
            workspaces.push(workspace);
        }

        let _ = self.read_workspaces_on_server(params).await?;
        Ok(RepeatedWorkspace { items: workspaces })
    }

    pub(crate) async fn read_cur_workspace(&self) -> Result<Workspace, WorkspaceError> {
        let params = QueryWorkspaceParams {
            workspace_id: Some(get_current_workspace()?),
        };
        let mut repeated_workspace = self.read_workspaces(params).await?;

        if repeated_workspace.is_empty() {
            return Err(ErrorBuilder::new(ErrorCode::RecordNotFound).build());
        }

        debug_assert_eq!(repeated_workspace.len(), 1);
        let workspace = repeated_workspace.drain(..1).collect::<Vec<Workspace>>().pop().unwrap();
        Ok(workspace)
    }

    pub(crate) async fn read_cur_apps(&self) -> Result<Vec<App>, WorkspaceError> {
        let workspace_id = get_current_workspace()?;
        let apps = self.read_apps(&workspace_id).await?;
        Ok(apps)
    }

    pub(crate) async fn read_apps(&self, workspace_id: &str) -> Result<Vec<App>, WorkspaceError> {
        let apps = self
            .sql
            .read_apps_belong_to_workspace(workspace_id)?
            .into_iter()
            .map(|app_table| app_table.into())
            .collect::<Vec<App>>();

        Ok(apps)
    }

    fn read_workspace_table(&self, workspace_id: Option<String>, user_id: String) -> Result<Vec<WorkspaceTable>, WorkspaceError> {
        let sql = self.sql.clone();
        let workspace_id = workspace_id.to_owned();
        let workspace = sql.read_workspaces(workspace_id, &user_id)?;
        Ok(workspace)
    }
}

impl WorkspaceController {
    fn token_with_server(&self) -> Result<(String, Server), WorkspaceError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        Ok((token, server))
    }

    async fn create_workspace_on_server(&self, params: CreateWorkspaceParams) -> Result<Workspace, WorkspaceError> {
        let token = self.user.token()?;
        let workspace = self.server.create_workspace(&token, params).await?;
        Ok(workspace)
    }

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

    async fn read_workspaces_on_server(&self, params: QueryWorkspaceParams) -> Result<(), WorkspaceError> {
        let (token, server) = self.token_with_server()?;
        spawn(async move {
            match server.read_workspace(&token, params).await {
                Ok(_workspaces) => {
                    // TODO: notify
                },
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

fn set_current_workspace(workspace: &str) { KV::set_str(CURRENT_WORKSPACE_ID, workspace.to_owned()); }

fn get_current_workspace() -> Result<String, WorkspaceError> {
    match KV::get_str(CURRENT_WORKSPACE_ID) {
        None => Err(ErrorBuilder::new(ErrorCode::CurrentWorkspaceNotFound).build()),
        Some(workspace_id) => Ok(workspace_id),
    }
}
