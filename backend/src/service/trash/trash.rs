use crate::{
    entities::workspace::{TrashTable, TRASH_TABLE},
    service::{
        user::LoggedUser,
        view::{delete_view, read_view_table},
    },
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use ::protobuf::ProtobufEnum;
use flowy_net::errors::ServerError;
use flowy_workspace::protobuf::{RepeatedTrash, Trash, TrashType};
use sqlx::{postgres::PgArguments, Postgres};
use uuid::Uuid;

pub(crate) async fn create_trash(
    transaction: &mut DBTransaction<'_>,
    records: Vec<(Uuid, i32)>,
    user: LoggedUser,
) -> Result<(), ServerError> {
    for (trash_id, ty) in records {
        let (sql, args) = SqlBuilder::create(TRASH_TABLE)
            .add_arg("id", trash_id)
            .add_arg("user_id", &user.user_id)
            .add_arg("ty", ty)
            .build()?;

        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
    }

    Ok(())
}

pub(crate) async fn delete_trash(
    transaction: &mut DBTransaction<'_>,
    records: Vec<(Uuid, i32)>,
    _user: &LoggedUser,
) -> Result<(), ServerError> {
    for (trash_id, _) in records {
        // Read the trash_table and delete the original table according to the TrashType
        let (sql, args) = SqlBuilder::select(TRASH_TABLE)
            .add_field("*")
            .and_where_eq("id", trash_id)
            .build()?;

        let trash_table = sqlx::query_as_with::<Postgres, TrashTable, PgArguments>(&sql, args)
            .fetch_one(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;

        match TrashType::from_i32(trash_table.ty) {
            None => log::error!("Parser trash type with value: {} failed", trash_table.ty),
            Some(ty) => match ty {
                TrashType::Unknown => {},
                TrashType::View => {
                    let _ = delete_view(transaction as &mut DBTransaction<'_>, vec![trash_table.id]).await;
                },
            },
        }

        // Delete the trash table
        let (sql, args) = SqlBuilder::delete(TRASH_TABLE).and_where_eq("id", &trash_id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
    }
    Ok(())
}

pub(crate) async fn read_trash_ids(
    user: &LoggedUser,
    transaction: &mut DBTransaction<'_>,
) -> Result<Vec<String>, ServerError> {
    let repeated_trash = read_trash(transaction, user).await?.take_items().into_vec();
    let ids = repeated_trash
        .into_iter()
        .map(|trash| trash.id)
        .collect::<Vec<String>>();

    Ok(ids)
}

pub(crate) async fn read_trash(
    transaction: &mut DBTransaction<'_>,
    user: &LoggedUser,
) -> Result<RepeatedTrash, ServerError> {
    let (sql, args) = SqlBuilder::select(TRASH_TABLE)
        .add_field("*")
        .and_where_eq("user_id", &user.user_id)
        .build()?;

    let tables = sqlx::query_as_with::<Postgres, TrashTable, PgArguments>(&sql, args)
        .fetch_all(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;

    let mut trash: Vec<Trash> = vec![];
    for table in tables {
        match TrashType::from_i32(table.ty) {
            None => log::error!("Parser trash type with value: {} failed", table.ty),
            Some(ty) => match ty {
                TrashType::Unknown => {},
                TrashType::View => {
                    trash.push(read_view_table(table.id, transaction).await?.into());
                },
            },
        }
    }

    let mut repeated_trash = RepeatedTrash::default();
    repeated_trash.set_items(trash.into());

    Ok(repeated_trash)
}
