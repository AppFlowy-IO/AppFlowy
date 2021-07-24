use crate::{
    entities::doc::{CreateDocParams, DocData, DocInfo, QueryDocParams, UpdateDocParams},
    errors::EditorError,
    module::EditorDatabase,
    sql_tables::doc::{DocTable, DocTableChangeset, DocTableSql},
};
use std::sync::Arc;

pub struct DocController {
    sql: Arc<DocTableSql>,
}

impl DocController {
    pub(crate) fn new(database: Arc<dyn EditorDatabase>) -> Self {
        let sql = Arc::new(DocTableSql { database });
        Self { sql }
    }

    pub(crate) async fn create_doc(
        &self,
        params: CreateDocParams,
        path: &str,
    ) -> Result<DocInfo, EditorError> {
        let doc_table = DocTable::new(params, path);
        let doc: DocInfo = doc_table.clone().into();
        let _ = self.sql.create_doc_table(doc_table)?;

        Ok(doc)
    }

    pub(crate) async fn update_doc(&self, params: UpdateDocParams) -> Result<(), EditorError> {
        let changeset = DocTableChangeset::new(params);
        let _ = self.sql.update_doc_table(changeset)?;
        Ok(())
    }

    pub(crate) async fn read_doc(&self, doc_id: &str) -> Result<DocInfo, EditorError> {
        let doc_table = self.sql.read_doc_table(doc_id)?;
        let doc_desc: DocInfo = doc_table.into();
        Ok(doc_desc)
    }
}
