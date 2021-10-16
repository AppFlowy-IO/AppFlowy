use crate::{
    entities::workspace::{TrashTable, TRASH_TABLE},
    service::{user::LoggedUser, view::read_view_table},
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use ::protobuf::ProtobufEnum;
use flowy_net::{errors::ServerError, response::FlowyResponse};
use flowy_workspace::protobuf::{CreateTrashParams, RepeatedTrash, Trash, TrashIdentifiers, TrashType};
use sqlx::{postgres::PgArguments, Postgres};

pub(crate) async fn create_trash(
    transaction: &mut DBTransaction<'_>,
    trash_id: &str,
    ty: i32,
    user: LoggedUser,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::create(TRASH_TABLE)
        .add_arg("id", trash_id)
        .add_arg("user_id", &user.user_id)
        .add_arg("ty", ty)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

pub(crate) async fn delete_trash(
    transaction: &mut DBTransaction<'_>,
    trash_ids: Vec<String>,
) -> Result<(), ServerError> {
    for trash_id in trash_ids {
        let (sql, args) = SqlBuilder::delete(TRASH_TABLE).and_where_eq("id", &trash_id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
    }
    Ok(())
}

pub(crate) async fn read_trash_ids(
    _user: &LoggedUser,
    _transaction: &mut DBTransaction<'_>,
) -> Result<Vec<String>, ServerError> {
    Ok(vec![])
}

pub(crate) async fn read_trash(
    transaction: &mut DBTransaction<'_>,
    user: LoggedUser,
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
