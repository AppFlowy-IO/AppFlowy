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
        let mut repeated_workspace = self
            .read_workspaces(Some(user_workspace.workspace_id.clone()))
            .await?;

        if repeated_workspace.is_empty() {
            return Err(ErrorBuilder::new(WsErrCode::RecordNotFound).build());
        }

        debug_assert_eq!(repeated_workspace.len(), 1);
        let workspace = repeated_workspace
            .drain(..1)
            .collect::<Vec<Workspace>>()
            .pop()
            .unwrap();
        Ok(workspace)
    }

    pub async fn read_cur_apps(&self) -> Result<Vec<App>, WorkspaceError> {
        let user_workspace = self.user.get_cur_workspace().await?;
        let apps = self.read_apps(&user_workspace.workspace_id).await?;
        Ok(apps)
    }

    pub async fn open_workspace(&self, workspace_id: &str) -> Result<Workspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let result = self
            .read_workspace_table(Some(workspace_id.to_owned()), user_id)
            .await?
            .first();

        match result {
            None => Err(ErrorBuilder::new(WsErrCode::RecordNotFound).build()),
            Some(workspace_table) => {
                let workspace: Workspace = workspace_table.into();
                Ok(workspace)
            },
        }
    }

    pub async fn read_workspaces(
        &self,
        workspace_id: Option<String>,
    ) -> Result<RepeatedWorkspace, WorkspaceError> {
        let user_id = self.user.user_id()?;
        let workspace_tables = self.read_workspace_table(workspace_id, user_id).await?;
        let mut workspaces = vec![];

        Ok(RepeatedWorkspace { items: workspaces })
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
        workspace_id: Option<String>,
        user_id: String,
    ) -> DispatchFuture<Result<Vec<WorkspaceTable>, WorkspaceError>> {
        let sql = self.sql.clone();
        let workspace_id = workspace_id.to_owned();
        DispatchFuture {
            fut: Box::pin(async move {
                let workspace = sql.read_workspaces(workspace_id, &user_id)?;
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

pub async fn read_workspaces_request(
    params: QueryWorkspaceParams,
    url: &str,
) -> Result<RepeatedWorkspace, WorkspaceError> {
    let result = HttpRequestBuilder::get(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response::<RepeatedWorkspace>()
        .await;

    match result {
        Ok(repeated_workspace) => Ok(repeated_workspace),
        Err(e) => Err(e.into()),
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
