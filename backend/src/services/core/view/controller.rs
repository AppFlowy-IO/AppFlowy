use crate::{
    entities::logged_user::LoggedUser,
    services::{
        core::{trash::read_trash_ids, view::persistence::*},
        document::persistence::{create_document, delete_document, DocumentKVPersistence},
    },
    util::sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use backend_service::errors::{invalid_params, ServerError};
use bytes::Bytes;
use chrono::Utc;
use flowy_collaboration::{
    entities::revision::{RepeatedRevision, Revision},
<<<<<<< HEAD
<<<<<<< HEAD
    protobuf::CreateDocParams,
=======
    protobuf::CreateDocParams as CreateDocParamsPB,
>>>>>>> upstream/main
=======
    protobuf::CreateDocParams as CreateDocParamsPB,
>>>>>>> upstream/main
};
use flowy_core_data_model::{
    parser::{
        app::AppIdentify,
        view::{ViewDesc, ViewName, ViewThumbnail},
    },
    protobuf::{CreateViewParams as CreateViewParamsPB, RepeatedView as RepeatedViewPB, View as ViewPB},
};
use sqlx::{postgres::PgArguments, Postgres};
use std::{convert::TryInto, sync::Arc};
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

#[tracing::instrument(skip(transaction, kv_store), err)]
pub(crate) async fn delete_view(
    transaction: &mut DBTransaction<'_>,
    kv_store: &Arc<DocumentKVPersistence>,
    view_ids: Vec<Uuid>,
) -> Result<(), ServerError> {
    for view_id in view_ids {
        let (sql, args) = SqlBuilder::delete(VIEW_TABLE).and_where_eq("id", &view_id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        let _ = delete_document(kv_store, view_id).await?;
    }
    Ok(())
}

#[tracing::instrument(name = "create_view", level = "debug", skip(transaction, kv_store), err)]
pub(crate) async fn create_view(
    transaction: &mut DBTransaction<'_>,
    kv_store: Arc<DocumentKVPersistence>,
<<<<<<< HEAD
<<<<<<< HEAD
    params: CreateViewParams,
    user_id: &str,
) -> Result<View, ServerError> {
=======
    params: CreateViewParamsPB,
    user_id: &str,
) -> Result<ViewPB, ServerError> {
>>>>>>> upstream/main
=======
    params: CreateViewParamsPB,
    user_id: &str,
) -> Result<ViewPB, ServerError> {
>>>>>>> upstream/main
    let view_id = check_view_id(params.view_id.clone())?;
    let name = ViewName::parse(params.name).map_err(invalid_params)?;
    let belong_to_id = AppIdentify::parse(params.belong_to_id).map_err(invalid_params)?;
    let thumbnail = ViewThumbnail::parse(params.thumbnail).map_err(invalid_params)?;
    let desc = ViewDesc::parse(params.desc).map_err(invalid_params)?;

    let (sql, args, view) = NewViewSqlBuilder::new(view_id, belong_to_id.as_ref())
        .name(name.as_ref())
        .desc(desc.as_ref())
        .thumbnail(thumbnail.as_ref())
        .view_type(params.view_type)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    let delta_data = Bytes::from(params.view_data);
    let md5 = format!("{:x}", md5::compute(&delta_data));
    let revision = Revision::new(&view.id, 0, 0, delta_data, user_id, md5);
    let repeated_revision = RepeatedRevision::new(vec![revision]);
<<<<<<< HEAD
<<<<<<< HEAD
    let mut create_doc_params = CreateDocParams::new();
=======
    let mut create_doc_params = CreateDocParamsPB::new();
>>>>>>> upstream/main
=======
    let mut create_doc_params = CreateDocParamsPB::new();
>>>>>>> upstream/main
    create_doc_params.set_revisions(repeated_revision.try_into().unwrap());
    create_doc_params.set_id(view.id.clone());
    let _ = create_document(&kv_store, create_doc_params).await?;

    Ok(view)
}

pub(crate) async fn read_view(
    user: &LoggedUser,
    view_id: Uuid,
    transaction: &mut DBTransaction<'_>,
) -> Result<ViewPB, ServerError> {
    let table = read_view_table(view_id, transaction as &mut DBTransaction<'_>).await?;

    let read_trash_ids = read_trash_ids(user, transaction).await?;
    if read_trash_ids.contains(&table.id.to_string()) {
        return Err(ServerError::record_not_found());
    }

    let mut views = RepeatedViewPB::default();
    views.set_items(
        read_view_belong_to_id(&table.id.to_string(), &user, transaction)
            .await?
            .into(),
    );
    let mut view: ViewPB = table.into();
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
) -> Result<Vec<ViewPB>, ServerError> {
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

    let views = tables.into_iter().map(|table| table.into()).collect::<Vec<ViewPB>>();

    Ok(views)
}
