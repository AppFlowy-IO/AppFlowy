use crate::{
    entities::logged_user::LoggedUser,
    services::core::{
        app::controller::{delete_app, read_app_table},
        trash::persistence::{TrashTable, TRASH_TABLE},
        view::{delete_view, read_view_table},
    },
    util::sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use ::protobuf::ProtobufEnum;
use backend_service::errors::ServerError;
use flowy_core_data_model::protobuf::{RepeatedTrash, Trash, TrashType};
use sqlx::{postgres::PgArguments, Postgres, Row};
use uuid::Uuid;

#[tracing::instrument(skip(transaction, user), err)]
pub(crate) async fn create_trash(
    transaction: &mut DBTransaction<'_>,
    records: Vec<(Uuid, i32)>,
    user: LoggedUser,
) -> Result<(), ServerError> {
    for (trash_id, ty) in records {
        let (sql, args) = SqlBuilder::create(TRASH_TABLE)
            .add_field_with_arg("id", trash_id)
            .add_field_with_arg("user_id", &user.user_id)
            .add_field_with_arg("ty", ty)
            .build()?;

        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
    }

    Ok(())
}

#[tracing::instrument(skip(transaction, user), fields(delete_rows), err)]
pub(crate) async fn delete_all_trash(
    transaction: &mut DBTransaction<'_>,
    user: &LoggedUser,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::select(TRASH_TABLE)
        .and_where_eq("user_id", &user.user_id)
        .build()?;
    let rows = sqlx::query_with(&sql, args)
        .fetch_all(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?
        .into_iter()
        .map(|row| (row.get("id"), row.get("ty")))
        .collect::<Vec<(Uuid, i32)>>();
    tracing::Span::current().record("delete_rows", &format!("{:?}", rows).as_str());
    let affected_row_count = rows.len();
    let _ = delete_trash_associate_targets(transaction as &mut DBTransaction<'_>, rows).await?;

    let (sql, args) = SqlBuilder::delete(TRASH_TABLE)
        .and_where_eq("user_id", &user.user_id)
        .build()?;
    let result = sqlx::query_with(&sql, args)
        .execute(transaction as &mut DBTransaction<'_>)
        .await
        .map_err(map_sqlx_error)?;
    tracing::Span::current().record("affected_row", &result.rows_affected());
    debug_assert_eq!(affected_row_count as u64, result.rows_affected());

    Ok(())
}

#[tracing::instrument(skip(transaction), err)]
pub(crate) async fn delete_trash(
    transaction: &mut DBTransaction<'_>,
    records: Vec<(Uuid, i32)>,
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

        let _ = delete_trash_associate_targets(
            transaction as &mut DBTransaction<'_>,
            vec![(trash_table.id, trash_table.ty)],
        )
        .await?;

        // Delete the trash table
        let (sql, args) = SqlBuilder::delete(TRASH_TABLE).and_where_eq("id", &trash_id).build()?;
        let _ = sqlx::query_with(&sql, args)
            .execute(transaction as &mut DBTransaction<'_>)
            .await
            .map_err(map_sqlx_error)?;
    }
    Ok(())
}

#[tracing::instrument(skip(transaction, targets), err)]
async fn delete_trash_associate_targets(
    transaction: &mut DBTransaction<'_>,
    targets: Vec<(Uuid, i32)>,
) -> Result<(), ServerError> {
    for (id, ty) in targets {
        match TrashType::from_i32(ty) {
            None => log::error!("Parser trash type with value: {} failed", ty),
            Some(ty) => match ty {
                TrashType::Unknown => {},
                TrashType::View => {
                    let _ = delete_view(transaction as &mut DBTransaction<'_>, vec![id]).await;
                },
                TrashType::App => {
                    let _ = delete_app(transaction as &mut DBTransaction<'_>, id).await;
                },
            },
        }
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

#[tracing::instrument(skip(transaction, user), err)]
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
                TrashType::App => {
                    trash.push(read_app_table(table.id, transaction).await?.into());
                },
            },
        }
    }

    let mut repeated_trash = RepeatedTrash::default();
    repeated_trash.set_items(trash.into());

    Ok(repeated_trash)
}
