use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    module::DocumentUser,
    services::server::Server,
    sql_tables::doc::{DocTable, DocTableChangeset, DocTableSql},
};
use flowy_database::SqliteConnection;
use std::sync::Arc;

pub struct DocController {
    server: Server,
    sql: Arc<DocTableSql>,
    user: Arc<dyn DocumentUser>,
}

impl DocController {
    pub(crate) fn new(server: Server, user: Arc<dyn DocumentUser>) -> Self {
        let sql = Arc::new(DocTableSql {});
        Self { sql, server, user }
    }

    #[tracing::instrument(skip(self, conn), err)]
    pub fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let doc = Doc {
            id: params.id,
            data: params.data,
        };
        let _ = self.sql.create_doc_table(DocTable::new(doc), conn)?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub fn update(&self, params: UpdateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let changeset = DocTableChangeset::new(params.clone());
        let _ = self.sql.update_doc_table(changeset, &*conn)?;
        let _ = self.update_doc_on_server(params)?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub fn open(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<Doc, DocError> {
        let doc: Doc = self.sql.read_doc_table(&params.doc_id, conn)?.into();
        let _ = self.read_doc_on_server(params)?;
        Ok(doc)
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.sql.delete_doc(&params.doc_id, &*conn)?;
        let _ = self.delete_doc_on_server(params)?;
        Ok(())
    }
}

impl DocController {
    #[tracing::instrument(level = "debug", skip(self), err)]
    fn update_doc_on_server(&self, params: UpdateDocParams) -> Result<(), DocError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        tokio::spawn(async move {
            match server.update_doc(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Update doc failed: {}", e);
                },
            }
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn read_doc_on_server(&self, params: QueryDocParams) -> Result<(), DocError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        tokio::spawn(async move {
            // Opti: handle the error and retry?
            let _doc = server.read_doc(&token, params).await?;
            // save to disk
            // notify

            Result::<(), DocError>::Ok(())
        });
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn delete_doc_on_server(&self, params: QueryDocParams) -> Result<(), DocError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        tokio::spawn(async move {
            match server.delete_doc(&token, params).await {
                Ok(_) => {},
                Err(e) => {
                    // TODO: retry?
                    log::error!("Delete doc failed: {:?}", e);
                },
            }
        });
        Ok(())
    }
}
