use crate::{config::HEADER_TOKEN, errors::ServerError, request::HttpRequestBuilder};
use flowy_workspace_infra::entities::prelude::*;

pub(crate) fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new().middleware(crate::middleware::BACKEND_API_MIDDLEWARE.clone())
}

pub async fn create_workspace_request(
    token: &str,
    params: CreateWorkspaceParams,
    url: &str,
) -> Result<Workspace, ServerError> {
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
    params: WorkspaceIdentifier,
    url: &str,
) -> Result<RepeatedWorkspace, ServerError> {
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
) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_workspace_request(token: &str, params: WorkspaceIdentifier, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(url)
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

// App
pub async fn create_app_request(token: &str, params: CreateAppParams, url: &str) -> Result<App, ServerError> {
    let app = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(app)
}

pub async fn read_app_request(token: &str, params: AppIdentifier, url: &str) -> Result<Option<App>, ServerError> {
    let app = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(app)
}

pub async fn update_app_request(token: &str, params: UpdateAppParams, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_app_request(token: &str, params: AppIdentifier, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

// View
pub async fn create_view_request(token: &str, params: CreateViewParams, url: &str) -> Result<View, ServerError> {
    let view = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .response()
        .await?;
    Ok(view)
}

pub async fn read_view_request(token: &str, params: ViewIdentifier, url: &str) -> Result<Option<View>, ServerError> {
    let view = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .option_response()
        .await?;

    Ok(view)
}

pub async fn update_view_request(token: &str, params: UpdateViewParams, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_view_request(token: &str, params: ViewIdentifiers, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn create_trash_request(token: &str, params: TrashIdentifiers, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .post(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn delete_trash_request(token: &str, params: TrashIdentifiers, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn read_trash_request(token: &str, url: &str) -> Result<RepeatedTrash, ServerError> {
    let repeated_trash = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .response::<RepeatedTrash>()
        .await?;
    Ok(repeated_trash)
}
