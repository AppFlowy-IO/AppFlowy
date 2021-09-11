use anyhow::Context;
use chrono::Utc;
use sqlx::{postgres::PgArguments, PgPool, Postgres};

use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_workspace::{
    entities::{
        app::parser::AppId,
        view::parser::{ViewDesc, ViewName, ViewThumbnail},
    },
    protobuf::{CreateViewParams, QueryViewParams, RepeatedView, UpdateViewParams, View},
};

use crate::{
    entities::workspace::{ViewTable, VIEW_TABLE},
    service::{
        doc_service::{create_doc, delete_doc},
        workspace_service::view::sql_builder::*,
    },
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use flowy_document::protobuf::CreateDocParams;

pub(crate) async fn create_view(
    pool: &PgPool,
    params: CreateViewParams,
) -> Result<FlowyResponse, ServerError> {
    let name = ViewName::parse(params.name).map_err(invalid_params)?;
    let belong_to_id = AppId::parse(params.belong_to_id).map_err(invalid_params)?;
    let thumbnail = ViewThumbnail::parse(params.thumbnail).map_err(invalid_params)?;
    let desc = ViewDesc::parse(params.desc).map_err(invalid_params)?;

    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create view")?;

    let (sql, args, view) = NewViewSqlBuilder::new(belong_to_id.as_ref())
        .name(name.as_ref())
        .desc(desc.as_ref())
        .thumbnail(thumbnail.as_ref())
        .view_type(params.view_type)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    let mut create_doc_params = CreateDocParams::new();
    create_doc_params.set_data(params.data);
    create_doc_params.set_id(view.id.clone());
    let _ = create_doc(&mut transaction, create_doc_params).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create view.")?;

    FlowyResponse::success().pb(view)
}

pub(crate) async fn read_view(
    pool: &PgPool,
    params: QueryViewParams,
) -> Result<FlowyResponse, ServerError> {
    let view_id = check_view_id(params.view_id)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read view")?;

    let (sql, args) = SqlBuilder::select(VIEW_TABLE)
        .add_field("*")
        .and_where_eq("id", view_id)
        .build()?;

    let table = sqlx::query_as_with::<Postgres, ViewTable, PgArguments>(&sql, args)
        .fetch_one(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    let mut views = RepeatedView::default();
    if params.read_belongings {
        views.set_items(
            read_views_belong_to_id(&mut transaction, &table.id.to_string())
                .await?
                .into(),
        )
    }

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read view.")?;

    let mut view: View = table.into();
    view.set_belongings(views);

    FlowyResponse::success().pb(view)
}

pub(crate) async fn update_view(
    pool: &PgPool,
    params: UpdateViewParams,
) -> Result<FlowyResponse, ServerError> {
    let view_id = check_view_id(params.view_id.clone())?;

    let name = match params.has_name() {
        false => None,
        true => Some(
            ViewName::parse(params.get_name().to_owned())
                .map_err(invalid_params)?
                .0,
        ),
    };

    let desc = match params.has_desc() {
        false => None,
        true => Some(
            ViewDesc::parse(params.get_desc().to_owned())
                .map_err(invalid_params)?
                .0,
        ),
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

    let (sql, args) = SqlBuilder::update(VIEW_TABLE)
        .add_some_arg("name", name)
        .add_some_arg("description", desc)
        .add_some_arg("thumbnail", thumbnail)
        .add_some_arg("modified_time", Some(Utc::now()))
        .add_arg_if(params.has_is_trash(), "is_trash", params.get_is_trash())
        .and_where_eq("id", view_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update view.")?;

    Ok(FlowyResponse::success())
}

pub(crate) async fn delete_view(
    pool: &PgPool,
    view_id: &str,
) -> Result<FlowyResponse, ServerError> {
    let view_id = check_view_id(view_id.to_owned())?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete view")?;

    let (sql, args) = SqlBuilder::delete(VIEW_TABLE)
        .and_where_eq("id", &view_id)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    let _ = delete_doc(&mut transaction, view_id).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete view.")?;

    Ok(FlowyResponse::success())
}

// transaction must be commit from caller
pub(crate) async fn read_views_belong_to_id<'c>(
    transaction: &mut DBTransaction<'_>,
    id: &str,
) -> Result<Vec<View>, ServerError> {
    // TODO: add index for app_table
    let (sql, args) = SqlBuilder::select(VIEW_TABLE)
        .add_field("*")
        .and_where_eq("belong_to_id", id)
        .and_where_eq("is_trash", false)
        .build()?;

    let tables = sqlx::query_as_with::<Postgres, ViewTable, PgArguments>(&sql, args)
        .fetch_all(transaction)
        .await
        .map_err(map_sqlx_error)?;

    let views = tables
        .into_iter()
        .map(|table| table.into())
        .collect::<Vec<View>>();

    Ok(views)
}
