use crate::{
    errors::EditorError,
    module::EditorDatabase,
    sql_tables::doc::{DocTable, DocTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{doc_table, doc_table::dsl},
};
use std::sync::Arc;

pub struct DocTableSql {
    pub database: Arc<dyn EditorDatabase>,
}

impl DocTableSql {
    pub(crate) fn create_doc_table(&self, doc_table: DocTable) -> Result<(), EditorError> {
        let conn = self.database.db_connection()?;
        let _ = diesel::insert_into(doc_table::table)
            .values(doc_table)
            .execute(&*conn)?;
        Ok(())
    }

    pub(crate) fn update_doc_table(&self, changeset: DocTableChangeset) -> Result<(), EditorError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(doc_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn read_doc_table(&self, doc_id: &str) -> Result<DocTable, EditorError> {
        let doc_table = dsl::doc_table
            .filter(doc_table::id.eq(doc_id))
            .first::<DocTable>(&*(self.database.db_connection()?))?;

        Ok(doc_table)
    }

    pub(crate) fn delete_doc(&self, view_id: &str) -> Result<(), EditorError> { unimplemented!() }
}
