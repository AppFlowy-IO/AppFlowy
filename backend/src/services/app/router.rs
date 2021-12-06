use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use backend_service::errors::{invalid_params, ServerError};
use flowy_workspace_infra::protobuf::{AppIdentifier, CreateAppParams, UpdateAppParams};
use protobuf::Message;
use sqlx::PgPool;

use crate::services::{
    app::{
        app::{create_app, delete_app, read_app, update_app},
        sql_builder::check_app_id,
    },
    user::LoggedUser,
    util::parse_from_payload,
};
use anyhow::Context;
use backend_service::response::FlowyResponse;
use flowy_workspace_infra::parser::app::{AppDesc, AppName};

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: CreateAppParams = parse_from_payload(payload).await?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create app")?;

    let app = create_app(&mut transaction, params, logged_user).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create app.")?;

    Ok(FlowyResponse::success().pb(app)?.into())
}

pub async fn read_handler(payload: Payload, pool: Data<PgPool>, user: LoggedUser) -> Result<HttpResponse, ServerError> {
    let params: AppIdentifier = parse_from_payload(payload).await?;
    let app_id = check_app_id(params.app_id)?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read app")?;
    let app = read_app(&mut transaction, app_id, &user).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read app.")?;

    Ok(FlowyResponse::success().pb(app)?.into())
}

pub async fn update_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: UpdateAppParams = parse_from_payload(payload).await?;
    let app_id = check_app_id(params.get_app_id().to_string())?;
    let name = match params.has_name() {
        false => None,
        true => Some(AppName::parse(params.get_name().to_owned()).map_err(invalid_params)?.0),
    };

    let color_style = match params.has_color_style() {
        false => None,
        true => {
            let color_bytes = params.get_color_style().write_to_bytes()?;
            Some(color_bytes)
        },
    };

    let desc = match params.has_desc() {
        false => None,
        true => Some(AppDesc::parse(params.get_desc().to_owned()).map_err(invalid_params)?.0),
    };

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update app")?;

    let _ = update_app(&mut transaction, app_id, name, desc, color_style).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update app.")?;
    Ok(FlowyResponse::success().into())
}

pub async fn delete_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: AppIdentifier = parse_from_payload(payload).await?;
    let app_id = check_app_id(params.app_id.to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete app")?;

    let _ = delete_app(&mut transaction, app_id).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete app.")?;

    Ok(FlowyResponse::success().into())
}
