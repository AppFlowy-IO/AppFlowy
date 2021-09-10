use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use sqlx::PgPool;

use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{
    CreateWorkspaceParams,
    DeleteWorkspaceParams,
    QueryWorkspaceParams,
    UpdateWorkspaceParams,
};

use crate::{
    routers::utils::parse_from_payload,
    service::{
        user_service::LoggedUser,
        workspace_service::workspace::{
            create_workspace,
            delete_workspace,
            read_workspaces,
            update_workspace,
        },
    },
};

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: CreateWorkspaceParams = parse_from_payload(payload).await?;
    let resp = create_workspace(pool.get_ref(), params, logged_user).await?;
    Ok(resp.into())
}

pub async fn read_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: QueryWorkspaceParams = parse_from_payload(payload).await?;
    let workspace_id = if params.has_workspace_id() {
        Some(params.get_workspace_id().to_owned())
    } else {
        None
    };
    let resp = read_workspaces(pool.get_ref(), workspace_id, logged_user).await?;
    Ok(resp.into())
}

pub async fn delete_handler(
    payload: Payload,
    pool: Data<PgPool>,
    _logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: DeleteWorkspaceParams = parse_from_payload(payload).await?;
    let resp = delete_workspace(pool.get_ref(), params.get_workspace_id()).await?;
    Ok(resp.into())
}

pub async fn update_handler(
    payload: Payload,
    pool: Data<PgPool>,
    _logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: UpdateWorkspaceParams = parse_from_payload(payload).await?;
    let resp = update_workspace(pool.get_ref(), params).await?;
    Ok(resp.into())
}

pub async fn workspace_list(
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let resp = read_workspaces(pool.get_ref(), None, logged_user).await?;
    Ok(resp.into())
}
