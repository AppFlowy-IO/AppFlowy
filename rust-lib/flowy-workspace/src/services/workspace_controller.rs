use crate::{
    entities::{app::App, workspace::*},
    errors::*,
    module::{WorkspaceDatabase, WorkspaceUser},
    observable::{send_observable, WorkspaceObservable},
    services::AppController,
    sql_tables::workspace::{WorkspaceSql, WorkspaceTable, WorkspaceTableChangeset},
};
use flowy_dispatch::prelude::DispatchFuture;
use flowy_net::request::HttpRequestBuilder;
use std::sync::Arc;

pub struct WorkspaceController {
    pub user: Arc<dyn WorkspaceUser>,
    pub sql: Arc<WorkspaceSql>,
    pub app_controller: Arc<AppController>,
}

impl WorkspaceController {
    pub fn new(
        user: Arc<dyn WorkspaceUser>,
        database: Arc<dyn WorkspaceDatabase>,
        app_controller: Arc<AppController>,
    ) -> Self {
        let sql = Arc::new(WorkspaceSql { database });
        Self {
            user,
            sql,
            app_controller,
        }
    }

    pub async fn create_workspace(
        &self,
        mut params: CreateWorkspaceParams,
    ) -> Result<Workspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        params.user_id = user_id.clone();

        // TODO: server

        let workspace_table = WorkspaceTable::new(params, &user_id);
        let workspace: Workspace = workspace_table.clone().into();
        let _ = self.sql.create_workspace(workspace_table)?;
        send_observable(&user_id, WorkspaceObservable::UserCreateWorkspace);
        Ok(workspace)
    }

    pub fn update_workspace(&self, params: UpdateWorkspaceParams) -> Result<(), WorkspaceError> {
        let changeset = WorkspaceTableChangeset::new(params);
        let workspace_id = changeset.id.clone();
        let _ = self.sql.update_workspace(changeset)?;

        send_observable(&workspace_id, WorkspaceObservable::WorkspaceUpdated);
        Ok(())
    }

    pub fn delete_workspace(&self, workspace_id: &str) -> Result<(), WorkspaceError> {
        let user_id = self.user.user_id()?;
        let _ = self.sql.delete_workspace(workspace_id)?;
        send_observable(&user_id, WorkspaceObservable::UserDeleteWorkspace);
        Ok(())
    }

    pub async fn read_cur_workspace(&self) -> Result<Workspace, WorkspaceError> {
        let user_workspace = self.user.get_cur_workspace().await?;
        let workspace = self.read_workspace(&user_workspace.workspace_id).await?;
        Ok(workspace)
    }

    pub async fn read_cur_apps(&self) -> Result<Vec<App>, WorkspaceError> {
        let user_workspace = self.user.get_cur_workspace().await?;
        let apps = self.read_apps(&user_workspace.workspace_id).await?;
        Ok(apps)
    }

    pub async fn read_workspace(&self, workspace_id: &str) -> Result<Workspace, WorkspaceError> {
        let workspace_table = self.read_workspace_table(workspace_id).await?;
        Ok(workspace_table.into())
    }

    pub async fn read_workspaces_belong_to_user(&self) -> Result<Vec<Workspace>, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let workspace = self
            .sql
            .read_workspaces_belong_to_user(&user_id)?
            .into_iter()
            .map(|workspace_table| workspace_table.into())
            .collect::<Vec<Workspace>>();

        Ok(workspace)
    }

    pub async fn read_apps(&self, workspace_id: &str) -> Result<Vec<App>, WorkspaceError> {
        let apps = self
            .sql
            .read_apps_belong_to_workspace(workspace_id)?
            .into_iter()
            .map(|app_table| app_table.into())
            .collect::<Vec<App>>();

        Ok(apps)
    }

    fn read_workspace_table(
        &self,
        workspace_id: &str,
    ) -> DispatchFuture<Result<WorkspaceTable, WorkspaceError>> {
        let sql = self.sql.clone();
        let workspace_id = workspace_id.to_owned();
        DispatchFuture {
            fut: Box::pin(async move {
                let workspace = sql.read_workspace(&workspace_id)?;
                // TODO: fetch workspace from remote server
                Ok(workspace)
            }),
        }
    }
}

pub async fn create_workspace_request(
    params: CreateWorkspaceParams,
    url: &str,
) -> Result<Workspace, WorkspaceError> {
    let workspace = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(workspace)
}

pub async fn read_workspace_request(
    params: QueryWorkspaceParams,
    url: &str,
) -> Result<Option<Workspace>, WorkspaceError> {
    let result = HttpRequestBuilder::get(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response::<Workspace>()
        .await;

    match result {
        Ok(workspace) => Ok(Some(workspace)),
        Err(e) => {
            if e.is_not_found() {
                Ok(None)
            } else {
                Err(e.into())
            }
        },
    }
}

pub async fn update_workspace_request(
    params: UpdateWorkspaceParams,
    url: &str,
) -> Result<(), WorkspaceError> {
    let _ = HttpRequestBuilder::patch(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_workspace_request(
    params: DeleteWorkspaceParams,
    url: &str,
) -> Result<(), WorkspaceError> {
    let _ = HttpRequestBuilder::delete(url)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_workspace_list_request(url: &str) -> Result<RepeatedWorkspace, WorkspaceError> {
    let workspaces = HttpRequestBuilder::get(url)
        .send()
        .await?
        .response::<RepeatedWorkspace>()
        .await?;
    Ok(workspaces)
}
