use crate::{
    entities::workspace::{TrashTable, TRASH_TABLE},
    service::{user::LoggedUser, view::read_view_with_transaction},
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use ::protobuf::ProtobufEnum;
use anyhow::Context;
use flowy_net::{
    errors::{invalid_params, ServerError},
    response::FlowyResponse,
};
use flowy_workspace::{
    entities::trash::parser::{TrashId, TrashIds, TrashTypeParser},
    protobuf::{CreateTrashParams, RepeatedTrash, Trash, TrashIdentifiers, TrashType},
};
use sqlx::{postgres::PgArguments, PgPool, Postgres};

pub(crate) async fn create_trash(
    pool: &PgPool,
    params: CreateTrashParams,
    user: LoggedUser,
) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create trash")?;

    let trash_id = TrashId::parse(params.id).map_err(invalid_params)?;
    let ty = TrashTypeParser::parse(params.ty.value()).map_err(invalid_params)?;

    let (sql, args) = SqlBuilder::create(TRASH_TABLE)
        .add_arg("id", trash_id.as_ref())
        .add_arg("user_id", &user.user_id)
        .add_arg("ty", ty)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to trash view.")?;

    Ok(FlowyResponse::success())
}

pub(crate) async fn delete_trash(pool: &PgPool, params: TrashIdentifiers) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to delete trash")?;

    let trash_ids = TrashIds::parse(params.ids.into_vec()).map_err(invalid_params)?;
    for trash_id in trash_ids.0 {
        let (sql, args) = SqlBuilder::delete(TRASH_TABLE).and_where_eq("id", &trash_id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(&mut transaction)
            .await
            .map_err(map_sqlx_error)?;
    }

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to delete view.")?;

    Ok(FlowyResponse::success())
}

pub(crate) async fn read_trash(pool: &PgPool, user: LoggedUser) -> Result<FlowyResponse, ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read trash")?;

    let (sql, args) = SqlBuilder::select(TRASH_TABLE)
        .add_field("*")
        .and_where_eq("user_id", &user.user_id)
        .build()?;

    let tables = sqlx::query_as_with::<Postgres, TrashTable, PgArguments>(&sql, args)
        .fetch_all(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    let mut trash: Vec<Trash> = vec![];
    for table in tables {
        match TrashType::from_i32(table.ty) {
            None => log::error!("Parser trash type with value: {} failed", table.ty),
            Some(ty) => match ty {
                TrashType::Unknown => {},
                TrashType::View => {
                    trash.push(read_view_with_transaction(table.id, &mut transaction).await?.into());
                },
            },
        }
    }

    let mut repeated_trash = RepeatedTrash::default();
    repeated_trash.set_items(trash.into());

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read view.")?;

    FlowyResponse::success().pb(repeated_trash)
}
