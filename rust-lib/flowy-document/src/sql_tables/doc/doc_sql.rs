use crate::{
    errors::DocError,
    sql_tables::doc::{DocTable, DocTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{doc_table, doc_table::dsl},
    SqliteConnection,
};

pub struct DocTableSql {}

impl DocTableSql {
    pub(crate) fn create_doc_table(&self, doc_table: DocTable, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = diesel::insert_into(doc_table::table).values(doc_table).execute(conn)?;
        Ok(())
    }

    pub(crate) fn update_doc_table(&self, changeset: DocTableChangeset, conn: &SqliteConnection) -> Result<(), DocError> {
        diesel_update_table!(doc_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn read_doc_table(&self, doc_id: &str, conn: &SqliteConnection) -> Result<DocTable, DocError> {
        let doc_table = dsl::doc_table.filter(doc_table::id.eq(doc_id)).first::<DocTable>(conn)?;

        Ok(doc_table)
    }

    #[allow(dead_code)]
    pub(crate) fn delete_doc(&self, doc_id: &str, conn: &SqliteConnection) -> Result<DocTable, DocError> {
        let doc_table = dsl::doc_table.filter(doc_table::id.eq(doc_id)).first::<DocTable>(conn)?;
        diesel_delete_table!(doc_table, doc_id, conn);
        Ok(doc_table)
    }
}
