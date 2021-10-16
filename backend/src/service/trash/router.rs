use crate::service::{
    trash::{create_trash, delete_trash, read_trash},
    user::LoggedUser,
    util::parse_from_payload,
};
use ::protobuf::ProtobufEnum;
use actix_web::{
    web::{Data, Payload},
    HttpResponse,
};
use anyhow::Context;
use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_workspace::{
    entities::trash::parser::{TrashId, TrashTypeParser},
    protobuf::{CreateTrashParams, TrashIdentifiers},
};
use sqlx::PgPool;
use uuid::Uuid;

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: CreateTrashParams = parse_from_payload(payload).await?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create trash")?;

    let trash_id = check_trash_id(params.id)?;
    let ty = TrashTypeParser::parse(params.ty.value()).map_err(invalid_params)?;
    let _ = create_trash(&mut transaction, trash_id, ty, logged_user).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create trash.")?;

    Ok(FlowyResponse::success().into())
}

pub async fn delete_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: TrashIdentifiers = parse_from_payload(payload).await?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete trash")?;

    let trash_ids = check_trash_ids(params.ids.into_vec())?;
    let _ = delete_trash(&mut transaction, trash_ids, &logged_user).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete trash.")?;

    Ok(FlowyResponse::success().into())
}

pub async fn read_handler(pool: Data<PgPool>, logged_user: LoggedUser) -> Result<HttpResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read trash")?;

    let repeated_trash = read_trash(&mut transaction, &logged_user).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read view.")?;

    Ok(FlowyResponse::success().pb(repeated_trash)?.into())
}

fn check_trash_id(id: String) -> Result<Uuid, ServerError> {
    let trash_id = TrashId::parse(id).map_err(invalid_params)?;
    let trash_id = Uuid::parse_str(trash_id.as_ref())?;
    Ok(trash_id)
}

fn check_trash_ids(ids: Vec<String>) -> Result<Vec<Uuid>, ServerError> {
    let mut trash_ids = vec![];
    for id in ids {
        trash_ids.push(check_trash_id(id)?)
    }
    Ok(trash_ids)
}
