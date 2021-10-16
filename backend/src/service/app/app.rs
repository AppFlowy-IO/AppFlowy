use crate::{
    entities::workspace::{AppTable, APP_TABLE},
    service::{app::sql_builder::*, user::LoggedUser, view::read_view_belong_to_id},
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};

use chrono::Utc;
use flowy_net::errors::{invalid_params, ServerError};
use flowy_workspace::{
    entities::{
        app::parser::{AppDesc, AppName},
        workspace::parser::WorkspaceId,
    },
    protobuf::{App, CreateAppParams, RepeatedView},
};
use protobuf::Message;
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
    let (sql, args) = SqlBuilder::select(APP_TABLE)
        .add_field("*")
        .and_where_eq("id", app_id)
        .build()?;

    let table = sqlx::query_as_with::<Postgres, AppTable, PgArguments>(&sql, args)
        .fetch_one(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    let mut views = RepeatedView::default();
    views.set_items(
        read_view_belong_to_id(user, transaction as &mut DBTransaction<'_>, &table.id.to_string())
            .await?
            .into(),
    );

    let mut app: App = table.into();
    app.set_belongings(views);
    Ok(app)
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

pub(crate) async fn delete_app(transaction: &mut DBTransaction<'_>, app_id: Uuid) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::delete(APP_TABLE).and_where_eq("id", app_id).build()?;
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}
