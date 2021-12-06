use crate::{
    entities::workspace::{AppTable, APP_TABLE},
    services::{app::sql_builder::*, user::LoggedUser, view::read_view_belong_to_id},
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};

use crate::services::trash::read_trash_ids;
use backend_service::errors::{invalid_params, ServerError};
use chrono::Utc;
use flowy_workspace_infra::{
    parser::{
        app::{AppDesc, AppName},
        workspace::WorkspaceId,
    },
    protobuf::{App, CreateAppParams, RepeatedView},
};
use sqlx::{postgres::PgArguments, Postgres};
use uuid::Uuid;

pub(crate) async fn create_app(
    transaction: &mut DBTransaction<'_>,
    mut params: CreateAppParams,
    logged_user: LoggedUser,
) -> Result<App, ServerError> {
    let name = AppName::parse(params.take_name()).map_err(invalid_params)?;
    let workspace_id = WorkspaceId::parse(params.take_workspace_id()).map_err(invalid_params)?;
    let user_id = logged_user.as_uuid()?.to_string();
    let desc = AppDesc::parse(params.take_desc()).map_err(invalid_params)?;

    let (sql, args, app) = NewAppSqlBuilder::new(&user_id, workspace_id.as_ref())
        .name(name.as_ref())
        .desc(desc.as_ref())
        .color_style(params.take_color_style())
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;
    Ok(app)
}

pub(crate) async fn read_app(
    transaction: &mut DBTransaction<'_>,
    app_id: Uuid,
    user: &LoggedUser,
) -> Result<App, ServerError> {
    let table = read_app_table(app_id, transaction).await?;

    let read_trash_ids = read_trash_ids(user, transaction).await?;
    if read_trash_ids.contains(&table.id.to_string()) {
        return Err(ServerError::record_not_found());
    }

    let mut views = RepeatedView::default();
    views.set_items(
        read_view_belong_to_id(&table.id.to_string(), user, transaction as &mut DBTransaction<'_>)
            .await?
            .into(),
    );

    let mut app: App = table.into();
    app.set_belongings(views);
    Ok(app)
}

pub(crate) async fn read_app_table(app_id: Uuid, transaction: &mut DBTransaction<'_>) -> Result<AppTable, ServerError> {
    let (sql, args) = SqlBuilder::select(APP_TABLE)
        .add_field("*")
        .and_where_eq("id", app_id)
        .build()?;

    let table = sqlx::query_as_with::<Postgres, AppTable, PgArguments>(&sql, args)
        .fetch_one(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    Ok(table)
}

pub(crate) async fn update_app(
    transaction: &mut DBTransaction<'_>,
    app_id: Uuid,
    name: Option<String>,
    desc: Option<String>,
    color_style: Option<Vec<u8>>,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::update(APP_TABLE)
        .add_some_arg("name", name)
        .add_some_arg("color_style", color_style)
        .add_some_arg("description", desc)
        .add_some_arg("modified_time", Some(Utc::now()))
        .and_where_eq("id", app_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

#[tracing::instrument(skip(transaction), err)]
pub(crate) async fn delete_app(transaction: &mut DBTransaction<'_>, app_id: Uuid) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::delete(APP_TABLE).and_where_eq("id", app_id).build()?;
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}
