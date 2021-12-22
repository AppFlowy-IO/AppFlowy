use crate::{
    context::FlowyPersistence,
    services::{document::persistence::DocumentKVPersistence, kv_store::KVStore},
    util::sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use anyhow::Context;
use backend_service::errors::ServerError;
use flowy_collaboration::protobuf::{CreateDocParams, Doc, DocIdentifier, UpdateDocParams};
use protobuf::Message;
use sqlx::{postgres::PgArguments, PgPool, Postgres};
use std::sync::Arc;
use uuid::Uuid;

const DOC_TABLE: &str = "doc_table";

#[tracing::instrument(level = "debug", skip(transaction, kv_store), err)]
pub(crate) async fn create_doc_with_transaction(
    transaction: &mut DBTransaction<'_>,
    kv_store: Arc<DocumentKVPersistence>,
    params: CreateDocParams,
) -> Result<(), ServerError> {
    let uuid = Uuid::parse_str(&params.id)?;
    let (sql, args) = SqlBuilder::create(DOC_TABLE)
        .add_field_with_arg("id", uuid)
        .add_field_with_arg("rev_id", 0)
        .build()?;

    // TODO kv
    // kv_store.set_revision()
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

pub(crate) async fn create_doc(
    persistence: &Arc<FlowyPersistence>,
    params: CreateDocParams,
) -> Result<(), ServerError> {
    let pool = persistence.pg_pool();
    let kv_store = persistence.kv_store();
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create document")?;

    let _ = create_doc_with_transaction(&mut transaction, kv_store, params).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create document.")?;

    Ok(())
}

#[tracing::instrument(level = "debug", skip(persistence), err)]
pub(crate) async fn read_doc(persistence: &Arc<FlowyPersistence>, params: DocIdentifier) -> Result<Doc, ServerError> {
    let doc_id = Uuid::parse_str(&params.doc_id)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read document")?;

    let builder = SqlBuilder::select(DOC_TABLE).add_field("*").and_where_eq("id", &doc_id);

    let (sql, args) = builder.build()?;
    // TODO: benchmark the speed of different documents with different size
    let _table = sqlx::query_as_with::<Postgres, DocTable, PgArguments>(&sql, args)
        .fetch_one(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    // TODO: kv
    panic!("")

    // transaction
    //     .commit()
    //     .await
    //     .context("Failed to commit SQL transaction to read document.")?;
    //
    // Ok(doc)
}

#[tracing::instrument(level = "debug", skip(pool, params), fields(delta), err)]
pub async fn update_doc(pool: &PgPool, mut params: UpdateDocParams) -> Result<(), ServerError> {
    let doc_id = Uuid::parse_str(&params.doc_id)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to update document")?;

    let data = Some(params.take_data());

    tracing::Span::current().record("delta", &data.as_ref().unwrap_or(&"".to_owned()).as_str());

    let (sql, args) = SqlBuilder::update(DOC_TABLE)
        .add_some_arg("data", data)
        .add_field_with_arg("rev_id", params.rev_id)
        .and_where_eq("id", doc_id)
        .build()?;

    sqlx::query_with(&sql, args)
        .execute(&mut transaction)
        .await
        .map_err(map_sqlx_error)?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to update document.")?;

    Ok(())
}

#[tracing::instrument(level = "debug", skip(transaction), err)]
pub(crate) async fn delete_doc(transaction: &mut DBTransaction<'_>, doc_id: Uuid) -> Result<(), ServerError> {
    let (sql, args) = SqlBuilder::delete(DOC_TABLE).and_where_eq("id", doc_id).build()?;
    let _ = sqlx::query_with(&sql, args)
        .execute(transaction)
        .await
        .map_err(map_sqlx_error)?;

    Ok(())
}

#[derive(Debug, Clone, sqlx::FromRow)]
struct DocTable {
    id: uuid::Uuid,
    rev_id: i64,
}

// impl std::convert::From<DocTable> for Doc {
//     fn from(table: DocTable) -> Self {
//         let mut doc = Doc::new();
//         doc.set_id(table.id.to_string());
//         doc.set_rev_id(table.rev_id);
//         doc
//     }
// }
