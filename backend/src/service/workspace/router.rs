use crate::service::{
    user::LoggedUser,
    util::parse_from_payload,
    workspace::{
        create_workspace,
        delete_workspace,
        read_workspaces,
        sql_builder::check_workspace_id,
        update_workspace,
    },
};
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use anyhow::Context;
use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_workspace_infra::{
    parser::workspace::{WorkspaceDesc, WorkspaceName},
    protobuf::{CreateWorkspaceParams, UpdateWorkspaceParams, WorkspaceIdentifier},
};
use sqlx::PgPool;

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: CreateWorkspaceParams = parse_from_payload(payload).await?;
    let name = WorkspaceName::parse(params.get_name().to_owned()).map_err(invalid_params)?;
    let desc = WorkspaceDesc::parse(params.get_desc().to_owned()).map_err(invalid_params)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create workspace")?;
    let workspace = create_workspace(&mut transaction, name.as_ref(), desc.as_ref(), logged_user).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create workspace.")?;

    Ok(FlowyResponse::success().pb(workspace)?.into())
}

pub async fn read_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: WorkspaceIdentifier = parse_from_payload(payload).await?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read workspace")?;

    let workspace_id = if params.has_workspace_id() {
        Some(params.get_workspace_id().to_owned())
    } else {
        None
    };
    let repeated_workspace = read_workspaces(&mut transaction, workspace_id, logged_user).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read workspace.")?;

    Ok(FlowyResponse::success().pb(repeated_workspace)?.into())
}

pub async fn delete_handler(
    payload: Payload,
    pool: Data<PgPool>,
    _logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: WorkspaceIdentifier = parse_from_payload(payload).await?;
    let workspace_id = check_workspace_id(params.get_workspace_id().to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete workspace")?;

    let _ = delete_workspace(&mut transaction, workspace_id).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete workspace.")?;

    Ok(FlowyResponse::success().into())
}

pub async fn update_handler(
    payload: Payload,
    pool: Data<PgPool>,
    _logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: UpdateWorkspaceParams = parse_from_payload(payload).await?;
    let workspace_id = check_workspace_id(params.get_id().to_owned())?;
    let name = match params.has_name() {
        false => None,
        true => {
            let name = WorkspaceName::parse(params.get_name().to_owned())
                .map_err(invalid_params)?
                .0;
            Some(name)
        },
    };

    let desc = match params.has_desc() {
        false => None,
        true => {
            let desc = WorkspaceDesc::parse(params.get_desc().to_owned())
                .map_err(invalid_params)?
                .0;
            Some(desc)
        },
    };

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update workspace")?;

    let _ = update_workspace(&mut transaction, workspace_id, name, desc).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update workspace.")?;

    Ok(FlowyResponse::success().into())
}

pub async fn workspace_list(pool: Data<PgPool>, logged_user: LoggedUser) -> Result<HttpResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read workspaces")?;

    let repeated_workspace = read_workspaces(&mut transaction, None, logged_user).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read workspace.")?;

    Ok(FlowyResponse::success().pb(repeated_workspace)?.into())
}
