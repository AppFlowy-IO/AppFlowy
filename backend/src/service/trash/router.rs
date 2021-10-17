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
    protobuf::TrashIdentifiers,
};
use sqlx::PgPool;
use uuid::Uuid;

#[tracing::instrument(skip(payload, pool, logged_user), err)]
pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    logged_user: LoggedUser,
) -> Result<HttpResponse, ServerError> {
    let params: TrashIdentifiers = parse_from_payload(payload).await?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create trash")?;
    log::error!("😁create handler: {:?}", params);
    let _ = create_trash(&mut transaction, make_records(params)?, logged_user).await?;

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

    let _ = delete_trash(&mut transaction, make_records(params)?, &logged_user).await?;
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

fn make_records(identifiers: TrashIdentifiers) -> Result<Vec<(Uuid, i32)>, ServerError> {
    let mut records = vec![];
    for identifier in identifiers.items {
        let ty = TrashTypeParser::parse(identifier.ty.value()).map_err(invalid_params)?;
        records.push((check_trash_id(identifier.id.to_owned())?, ty));
    }
    Ok(records)
}
