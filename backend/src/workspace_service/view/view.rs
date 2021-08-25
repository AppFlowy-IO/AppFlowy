use crate::{
    entities::workspace::ViewTable,
    sqlx_ext::{map_sqlx_error, SqlBuilder},
};
use anyhow::Context;
use chrono::Utc;
use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_workspace::{
    entities::{
        app::parser::AppId,
        view::{
            parser::{ViewDesc, ViewId, ViewName, ViewThumbnail},
            RepeatedView,
            View,
            ViewType,
        },
    },
    protobuf::{CreateViewParams, QueryViewParams, UpdateViewParams},
};
use protobuf::ProtobufEnum;
use sqlx::{postgres::PgArguments, PgPool, Postgres};
use uuid::Uuid;

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

    let uuid = uuid::Uuid::new_v4();
    let time = Utc::now();

    let (sql, args) = SqlBuilder::create("view_table")
        .add_arg("id", uuid)
        .add_arg("belong_to_id", belong_to_id.as_ref())
        .add_arg("name", name.as_ref())
        .add_arg("description", desc.as_ref())
        .add_arg("modified_time", &time)
        .add_arg("create_time", &time)
        .add_arg("thumbnail", thumbnail.as_ref())
        .add_arg("view_type", params.view_type.value())
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create view.")?;

    // a little confused here, different type with the same name in different crate
    // let view_type = match params.view_type {
    //     flowy_workspace::protobuf::ViewType::Blank => ViewType::Doc,
    //     flowy_workspace::protobuf::ViewType::Doc => ViewType::Doc,
    // };

    let view = View {
        id: uuid.to_string(),
        belong_to_id: belong_to_id.as_ref().to_owned(),
        name: name.as_ref().to_owned(),
        desc: desc.as_ref().to_owned(),
        view_type: params.view_type.value().into(),
        version: 0,
        belongings: RepeatedView::default(),
    };

    FlowyResponse::success().data(view)
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

    let (sql, args) = SqlBuilder::select("view_table")
        .add_field("*")
        .and_where_eq("id", view_id)
        .build()?;

    let table = sqlx::query_as_with::<Postgres, ViewTable, PgArguments>(&sql, args)
        .fetch_one(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read view.")?;

    let view = View {
        id: table.id.to_string(),
        belong_to_id: table.belong_to_id,
        name: table.name,
        desc: table.description,
        view_type: ViewType::from(table.view_type),
        version: 0,
        belongings: RepeatedView::default(),
    };

    if params.read_belongings {
        // TODO: read belongings
    }
    FlowyResponse::success().data(view)
}

pub(crate) async fn update_view(
    pool: &PgPool,
    params: UpdateViewParams,
) -> Result<FlowyResponse, ServerError> {
    let view_id = check_view_id(params.view_id.clone())?;
    // #[pb(index = 1)]
    // pub view_id: String,
    //
    // #[pb(index = 2, one_of)]
    // pub name: Option<String>,
    //
    // #[pb(index = 3, one_of)]
    // pub desc: Option<String>,
    //
    // #[pb(index = 4, one_of)]
    // pub thumbnail: Option<String>,
    //
    // #[pb(index = 5, one_of)]
    // pub is_trash: Option<bool>,

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

    let (sql, args) = SqlBuilder::update("view_table")
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

    let (sql, args) = SqlBuilder::delete("view_table")
        .and_where_eq("id", view_id)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete view.")?;

    Ok(FlowyResponse::success())
}

fn check_view_id(id: String) -> Result<Uuid, ServerError> {
    let view_id = ViewId::parse(id).map_err(invalid_params)?;
    let view_id = Uuid::parse_str(view_id.as_ref())?;
    Ok(view_id)
}
