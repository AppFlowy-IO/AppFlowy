use crate::{
    errors::DocError,
    module::DocumentDatabase,
    sql_tables::doc::{DocTable, DocTableChangeset},
};
use flowy_database::{
    prelude::*,
    schema::{doc_table, doc_table::dsl},
};
use std::sync::Arc;

pub struct DocTableSql {
    pub database: Arc<dyn DocumentDatabase>,
}

impl DocTableSql {
    pub(crate) fn create_doc_table(&self, doc_table: DocTable) -> Result<(), DocError> {
        let conn = self.database.db_connection()?;
        let _ = diesel::insert_into(doc_table::table)
            .values(doc_table)
            .execute(&*conn)?;
        Ok(())
    }

    pub(crate) fn update_doc_table(&self, changeset: DocTableChangeset) -> Result<(), DocError> {
        let conn = self.database.db_connection()?;
        diesel_update_table!(doc_table, changeset, conn);
        Ok(())
    }

    pub(crate) fn read_doc_table(&self, doc_id: &str) -> Result<DocTable, DocError> {
        let doc_table = dsl::doc_table
            .filter(doc_table::id.eq(doc_id))
            .first::<DocTable>(&*(self.database.db_connection()?))?;

        Ok(doc_table)
    }

    #[allow(dead_code)]
    pub(crate) fn delete_doc(&self, _view_id: &str) -> Result<(), DocError> { unimplemented!() }
}
