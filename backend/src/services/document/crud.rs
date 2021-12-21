use crate::{
    entities::doc::{DocTable, DOC_TABLE},
    util::sqlx_ext::{map_sqlx_error, DBTransaction, SqlBuilder},
};
use anyhow::Context;
use backend_service::errors::ServerError;
use flowy_collaboration::protobuf::{CreateDocParams, Doc, DocIdentifier, UpdateDocParams};
use sqlx::{postgres::PgArguments, PgPool, Postgres};
use uuid::Uuid;

#[tracing::instrument(level = "debug", skip(transaction), err)]
pub(crate) async fn create_doc_with_transaction(
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

pub(crate) async fn create_doc(pool: &PgPool, params: CreateDocParams) -> Result<(), ServerError> {
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to create document")?;

    let _ = create_doc_with_transaction(&mut transaction, params).await?;

    transaction
        .commit()
        .await
        .context("Failed to commit SQL transaction to create document.")?;

    Ok(())
}

#[tracing::instrument(level = "debug", skip(pool), err)]
pub(crate) async fn read_doc(pool: &PgPool, params: DocIdentifier) -> Result<Doc, ServerError> {
    let doc_id = Uuid::parse_str(&params.doc_id)?;
    let mut transaction = pool
        .begin()
        .await
        .context("Failed to acquire a Postgres connection to read document")?;

    let builder = SqlBuilder::select(DOC_TABLE).add_field("*").and_where_eq("id", &doc_id);

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
        .context("Failed to commit SQL transaction to read document.")?;

    Ok(doc)
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

pub struct NewDocSqlBuilder {
    table: DocTable,
}

impl NewDocSqlBuilder {
    pub fn new(id: Uuid) -> Self {
        let table = DocTable {
            id,
            data: "".to_owned(),
            rev_id: 0,
        };
        Self { table }
    }

    pub fn data(mut self, data: String) -> Self {
        self.table.data = data;
        self
    }

    pub fn build(self) -> Result<(String, PgArguments), ServerError> {
        let (sql, args) = SqlBuilder::create(DOC_TABLE)
            .add_field_with_arg("id", self.table.id)
            .add_field_with_arg("data", self.table.data)
            .add_field_with_arg("rev_id", self.table.rev_id)
            .build()?;

        Ok((sql, args))
    }
}
