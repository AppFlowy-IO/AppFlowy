use crate::service::{
    doc::doc::DocBiz,
    user::LoggedUser,
    util::parse_from_payload,
    view::{create_view, delete_view, read_view, sql_builder::check_view_ids, update_view},
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
use flowy_workspace::{
    entities::view::parser::{ViewDesc, ViewName, ViewThumbnail},
    protobuf::{CreateViewParams, QueryViewRequest, UpdateViewParams, ViewIdentifier},
};
use sqlx::PgPool;
use std::sync::Arc;

pub async fn create_handler(
    payload: Payload,
    pool: Data<PgPool>,
    _doc_biz: Data<Arc<DocBiz>>,
) -> Result<HttpResponse, ServerError> {
    let params: CreateViewParams = parse_from_payload(payload).await?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create view")?;

    let view = create_view(&mut transaction, params).await?;
    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create view.")?;

    let resp = FlowyResponse::success().pb(view)?;
    Ok(resp.into())
}

pub async fn read_handler(payload: Payload, pool: Data<PgPool>, user: LoggedUser) -> Result<HttpResponse, ServerError> {
    let params: ViewIdentifier = parse_from_payload(payload).await?;
    let view_id = check_view_ids(vec![params.view_id])?.pop().unwrap();
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read view")?;
    let view = read_view(&user, view_id, &mut transaction).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read view.")?;

    Ok(FlowyResponse::success().pb(view)?.into())
}

pub async fn update_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: UpdateViewParams = parse_from_payload(payload).await?;
    let view_id = check_view_ids(vec![params.view_id.clone()])?.pop().unwrap();
    let name = match params.has_name() {
        false => None,
        true => Some(ViewName::parse(params.get_name().to_owned()).map_err(invalid_params)?.0),
    };

    let desc = match params.has_desc() {
        false => None,
        true => Some(ViewDesc::parse(params.get_desc().to_owned()).map_err(invalid_params)?.0),
    };

    let thumbnail = match params.has_thumbnail() {
        false => None,
        true => Some(
            ViewThumbnail::parse(params.get_thumbnail().to_owned())
                .map_err(invalid_params)?
                .0,
        ),
    };

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update app")?;

    let _ = update_view(&mut transaction, view_id, name, desc, thumbnail).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update view.")?;

    Ok(FlowyResponse::success().into())
}

pub async fn delete_handler(payload: Payload, pool: Data<PgPool>) -> Result<HttpResponse, ServerError> {
    let params: QueryViewRequest = parse_from_payload(payload).await?;
    let view_ids = check_view_ids(params.view_ids.to_vec())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete view")?;

    let _ = delete_view(&mut transaction, view_ids).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete view.")?;

    Ok(FlowyResponse::success().into())
}
