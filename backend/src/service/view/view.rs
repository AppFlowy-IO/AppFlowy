use crate::{
    entities::workspace::{ViewTable, VIEW_TABLE},
    service::{
        doc::{create_doc, delete_doc},
        trash::read_trash_ids,
        user::LoggedUser,
        view::sql_builder::*,
    },
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use chrono::Utc;
use flowy_document_infra::protobuf::CreateDocParams;
use flowy_net::errors::{invalid_params, ServerError};
use flowy_workspace_infra::{
    parser::{
        app::AppId,
        view::{ViewDesc, ViewName, ViewThumbnail},
    },
    protobuf::{CreateViewParams, RepeatedView, View},
};
use sqlx::{postgres::PgArguments, Postgres};
use uuid::Uuid;

pub(crate) async fn update_view(
    transaction: &mut DBTransaction<'_>,
    view_id: Uuid,
    name: Option<String>,
    desc: Option<String>,
    thumbnail: Option<String>,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::update(VIEW_TABLE)
        .add_some_arg("name", name)
        .add_some_arg("description", desc)
        .add_some_arg("thumbnail", thumbnail)
        .add_some_arg("modified_time", Some(Utc::now()))
        .and_where_eq("id", view_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

#[tracing::instrument(skip(transaction), err)]
pub(crate) async fn delete_view(transaction: &mut DBTransaction<'_>, view_ids: Vec<Uuid>) -> Result<(), ServerError> {
    for view_id in view_ids {
        let (sql, args) = SqlBuilder::delete(VIEW_TABLE).and_where_eq("id", &view_id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        let _ = delete_doc(transaction, view_id).await?;
    }
    Ok(())
}

#[tracing::instrument(name = "create_view", level = "debug", skip(transaction), err)]
pub(crate) async fn create_view(
    transaction: &mut DBTransaction<'_>,
    params: CreateViewParams,
) -> Result<View, ServerError> {
    let name = ViewName::parse(params.name).map_err(invalid_params)?;
    let belong_to_id = AppId::parse(params.belong_to_id).map_err(invalid_params)?;
    let thumbnail = ViewThumbnail::parse(params.thumbnail).map_err(invalid_params)?;
    let desc = ViewDesc::parse(params.desc).map_err(invalid_params)?;

    let (sql, args, view) = NewViewSqlBuilder::new(belong_to_id.as_ref())
        .name(name.as_ref())
        .desc(desc.as_ref())
        .thumbnail(thumbnail.as_ref())
        .view_type(params.view_type)
        .build()?;

    let view = create_view_with_args(transaction, sql, args, view, params.data).await?;
    Ok(view)
}

pub(crate) async fn create_view_with_args(
    transaction: &mut DBTransaction<'_>,
    sql: String,
    args: PgArguments,
    view: View,
    view_data: String,
) -> Result<View, ServerError> {
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    let mut create_doc_params = CreateDocParams::new();
    create_doc_params.set_data(view_data);
    create_doc_params.set_id(view.id.clone());
    let _ = create_doc(transaction, create_doc_params).await?;
    Ok(view)
}

pub(crate) async fn read_view(
    user: &LoggedUser,
    view_id: Uuid,
    transaction: &mut DBTransaction<'_>,
) -> Result<View, ServerError> {
    let table = read_view_table(view_id, transaction as &mut DBTransaction<'_>).await?;

    let read_trash_ids = read_trash_ids(user, transaction).await?;
    if read_trash_ids.contains(&table.id.to_string()) {
        return Err(ServerError::record_not_found());
    }

    let mut views = RepeatedView::default();
    views.set_items(
        read_view_belong_to_id(&table.id.to_string(), &user, transaction)
            .await?
            .into(),
    );
    let mut view: View = table.into();
    view.set_belongings(views);
    Ok(view)
}

pub(crate) async fn read_view_table(
    view_id: Uuid,
    transaction: &mut DBTransaction<'_>,
) -> Result<ViewTable, ServerError> {
    let (sql, args) = SqlBuilder::select(VIEW_TABLE)
        .add_field("*")
        .and_where_eq("id", view_id)
        .build()?;

    let table = sqlx::query_as_with::<Postgres, ViewTable, PgArguments>(&sql, args)
        .fetch_one(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    Ok(table)
}

// transaction must be commit from caller
pub(crate) async fn read_view_belong_to_id<'c>(
    id: &str,
    user: &LoggedUser,
    transaction: &mut DBTransaction<'_>,
) -> Result<Vec<View>, ServerError> {
    // TODO: add index for app_table
    let (sql, args) = SqlBuilder::select(VIEW_TABLE)
        .add_field("*")
        .and_where_eq("belong_to_id", id)
        .build()?;

    let mut tables = sqlx::query_as_with::<Postgres, ViewTable, PgArguments>(&sql, args)
        .fetch_all(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    let read_trash_ids = read_trash_ids(user, transaction).await?;
    tables.retain(|table| !read_trash_ids.contains(&table.id.to_string()));

    let views = tables.into_iter().map(|table| table.into()).collect::<Vec<View>>();

    Ok(views)
}
