use crate::{
    entities::{
        app::{App, CreateAppParams, DeleteAppParams, QueryAppParams, UpdateAppParams},
        view::{CreateViewParams, DeleteViewParams, QueryViewParams, UpdateViewParams, View},
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
use flowy_infra::future::ResultFuture;
use flowy_net::{config::*, request::HttpRequestBuilder};

pub struct WorkspaceServer {}

impl WorkspaceServerAPI for WorkspaceServer {
    fn create_workspace(&self, token: &str, params: CreateWorkspaceParams) -> ResultFuture<Workspace, WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { create_workspace_request(&token, params, WORKSPACE_URL.as_ref()).await })
    }

    fn read_workspace(&self, token: &str, params: QueryWorkspaceParams) -> ResultFuture<RepeatedWorkspace, WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { read_workspaces_request(&token, params, WORKSPACE_URL.as_ref()).await })
    }

    fn update_workspace(&self, token: &str, params: UpdateWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { update_workspace_request(&token, params, WORKSPACE_URL.as_ref()).await })
    }

    fn delete_workspace(&self, token: &str, params: DeleteWorkspaceParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { delete_workspace_request(&token, params, WORKSPACE_URL.as_ref()).await })
    }

    fn create_view(&self, token: &str, params: CreateViewParams) -> ResultFuture<View, WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { create_view_request(&token, params, VIEW_URL.as_ref()).await })
    }

    fn read_view(&self, token: &str, params: QueryViewParams) -> ResultFuture<Option<View>, WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { read_view_request(&token, params, VIEW_URL.as_ref()).await })
    }

    fn delete_view(&self, token: &str, params: DeleteViewParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { delete_view_request(&token, params, VIEW_URL.as_ref()).await })
    }

    fn update_view(&self, token: &str, params: UpdateViewParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { update_view_request(&token, params, VIEW_URL.as_ref()).await })
    }

    fn create_app(&self, token: &str, params: CreateAppParams) -> ResultFuture<App, WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { create_app_request(&token, params, APP_URL.as_ref()).await })
    }

    fn read_app(&self, token: &str, params: QueryAppParams) -> ResultFuture<Option<App>, WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { read_app_request(&token, params, APP_URL.as_ref()).await })
    }

    fn update_app(&self, token: &str, params: UpdateAppParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { update_app_request(&token, params, APP_URL.as_ref()).await })
    }

    fn delete_app(&self, token: &str, params: DeleteAppParams) -> ResultFuture<(), WorkspaceError> {
        let token = token.to_owned();
        ResultFuture::new(async move { delete_app_request(&token, params, APP_URL.as_ref()).await })
    }
}

pub(crate) fn request_builder() -> HttpRequestBuilder { HttpRequestBuilder::new().middleware(super::middleware::MIDDLEWARE.clone()) }
pub async fn create_workspace_request(token: &str, params: CreateWorkspaceParams, url: &str) -> Result<Workspace, WorkspaceError> {
    let workspace = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(workspace)
}

pub async fn read_workspaces_request(token: &str, params: QueryWorkspaceParams, url: &str) -> Result<RepeatedWorkspace, WorkspaceError> {
    let repeated_workspace = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response::<RepeatedWorkspace>()
        .await?;

    Ok(repeated_workspace)
}

pub async fn update_workspace_request(token: &str, params: UpdateWorkspaceParams, url: &str) -> Result<(), WorkspaceError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_workspace_request(token: &str, params: DeleteWorkspaceParams, url: &str) -> Result<(), WorkspaceError> {
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

pub async fn read_app_request(token: &str, params: QueryAppParams, url: &str) -> Result<Option<App>, WorkspaceError> {
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

pub async fn read_view_request(token: &str, params: QueryViewParams, url: &str) -> Result<Option<View>, WorkspaceError> {
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
