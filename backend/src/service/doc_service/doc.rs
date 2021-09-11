use super::sql_builder::*;
use crate::{
    entities::doc::{DocTable, DOC_TABLE},
    sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use anyhow::Context;
use flowy_document::protobuf::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams};
use flowy_net::{errors::ServerError, response::FlowyResponse};
use sqlx::{postgres::PgArguments, PgPool, Postgres};
use uuid::Uuid;

pub(crate) async fn create_doc(
    transaction: &mut DBTransaction<'_>,
    params: CreateDocParams,
) -> Result<(), ServerError> {
    let uuid = Uuid::parse_str(&params.id)?;
    let (sql, args) = NewDocSqlBuilder::new(uuid).data(params.data).build()?;
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

pub(crate) async fn read_doc(
    pool: &PgPool,
    params: QueryDocParams,
) -> Result<FlowyResponse, ServerError> {
    let doc_id = Uuid::parse_str(&params.doc_id)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read doc")?;

    let builder = SqlBuilder::select(DOC_TABLE)
        .add_field("*")
        .and_where_eq("id", &doc_id);

    let (sql, args) = builder.build()?;
    // TODO: benchmark the speed of different documents with different size
    let doc: Doc = sqlx::query_as_with::<Postgres, DocTable, PgArguments>(&sql, args)
        .fetch_one(&mut transaction)
        .await
        .map_err(map_sqlx_error)?
        .into();

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to read doc.")?;

    FlowyResponse::success().pb(doc)
}

pub(crate) async fn update_doc(
    pool: &PgPool,
    mut params: UpdateDocParams,
) -> Result<FlowyResponse, ServerError> {
    let doc_id = Uuid::parse_str(&params.id)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update doc")?;

    let data = match params.has_data() {
        true => Some(params.take_data()),
        false => None,
    };

    let (sql, args) = SqlBuilder::update(DOC_TABLE)
        .add_some_arg("data", data)
        .and_where_eq("id", doc_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update doc.")?;

    Ok(FlowyResponse::success())
}

pub(crate) async fn delete_doc(
    transaction: &mut DBTransaction<'_>,
    doc_id: Uuid,
) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::delete(DOC_TABLE)
        .and_where_eq("id", doc_id)
        .build()?;

    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}
