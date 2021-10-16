use crate::{
    entities::{
        app::{App, AppIdentifier, CreateAppParams, DeleteAppParams, UpdateAppParams},
        trash::CreateTrashParams,
        view::{CreateViewParams, DeleteViewParams, UpdateViewParams, View, ViewIdentifier},
        workspace::{
            CreateWorkspaceParams,
            DeleteWorkspaceParams,
            QueryWorkspaceParams,
            RepeatedWorkspace,
            UpdateWorkspaceParams,
            Workspace,
        },
    },
    errors::WorkspaceError,
    services::server::WorkspaceServerAPI,
};

use crate::entities::trash::{RepeatedTrash, TrashIdentifiers};
use flowy_infra::future::ResultFuture;
use flowy_net::{config::*, request::HttpRequestBuilder};

pub struct WorkspaceServer {
    config: ServerConfig,
}

impl WorkspaceServer {
    pub fn new(config: ServerConfig) -> WorkspaceServer { Self { config } }
}

impl WorkspaceServerAPI for WorkspaceServer {
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> ResultFuture<Workspace, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move { create_workspace_request(&token, params, &url).await })
    }

    fn read_workspace(
        &self,
        token: &str,
        params: QueryWorkspaceParams,
    ) -> ResultFuture<RepeatedWorkspace, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move { read_workspaces_request(&token, params, &url).await })
    }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move { update_workspace_request(&token, params, &url).await })
    }

    fn delete_workspace(&self, token: &str, params: DeleteWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.workspace_url();
        ResultFuture::new(async move { delete_workspace_request(&token, params, &url).await })
    }

    fn create_view(&self, token: &str, params: CreateViewParams) -> ResultFuture<View, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move { create_view_request(&token, params, &url).await })
    }

    fn read_view(&self, token: &str, params: ViewIdentifier) -> ResultFuture<Option<View>, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move { read_view_request(&token, params, &url).await })
    }

    fn delete_view(&self, token: &str, params: DeleteViewParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move { delete_view_request(&token, params, &url).await })
    }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.view_url();
        ResultFuture::new(async move { update_view_request(&token, params, &url).await })
    }

    fn create_app(&self, token: &str, params: CreateAppParams) -> ResultFuture<App, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move { create_app_request(&token, params, &url).await })
    }

    fn read_app(&self, token: &str, params: AppIdentifier) -> ResultFuture<Option<App>, WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move { read_app_request(&token, params, &url).await })
    }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move { update_app_request(&token, params, &url).await })
    }

    fn delete_app(&self, token: &str, params: DeleteAppParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        let url = self.config.app_url();
        ResultFuture::new(async move { delete_app_request(&token, params, &url).await })
    }
}

pub(crate) fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new().middleware(super::middleware::MIDDLEWARE.clone())
}
pub async fn create_workspace_request(
    token: &str,
    params: CreateWorkspaceParams,
    url: &str,
) -> Result<Workspace, WorkspaceError> {
    let workspace = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(workspace)
}

pub async fn read_workspaces_request(
    token: &str,
    params: QueryWorkspaceParams,
    url: &str,
) -> Result<RepeatedWorkspace, WorkspaceError> {
    let repeated_workspace = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response::<RepeatedWorkspace>()
        .await?;

    Ok(repeated_workspace)
}

pub async fn update_workspace_request(
    token: &str,
    params: UpdateWorkspaceParams,
    url: &str,
) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_workspace_request(
    token: &str,
    params: DeleteWorkspaceParams,
    url: &str,
) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .delete(url)
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

// App
pub async fn create_app_request(token: &str, params: CreateAppParams, url: &str) -> Result<App, WorkspaceError> {
    let app = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(app)
}

pub async fn read_app_request(token: &str, params: AppIdentifier, url: &str) -> Result<Option<App>, WorkspaceError> {
    let app = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(app)
}

pub async fn update_app_request(token: &str, params: UpdateAppParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_app_request(token: &str, params: DeleteAppParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

// View
pub async fn create_view_request(token: &str, params: CreateViewParams, url: &str) -> Result<View, WorkspaceError> {
    let view = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(view)
}

pub async fn read_view_request(token: &str, params: ViewIdentifier, url: &str) -> Result<Option<View>, WorkspaceError> {
    let view = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(view)
}

pub async fn update_view_request(token: &str, params: UpdateViewParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_view_request(token: &str, params: DeleteViewParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn create_trash_request(token: &str, params: CreateTrashParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_trash_request(token: &str, params: TrashIdentifiers, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_trash_request(token: &str, url: &str) -> Result<RepeatedTrash, WorkspaceError> {
    let repeated_trash = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .response::<RepeatedTrash>()
        .await?;
    Ok(repeated_trash)
}
