use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    module::{DocumentDatabase, DocumentUser},
    services::server::Server,
    sql_tables::doc::{DocTable, DocTableChangeset, DocTableSql},
};
use std::sync::Arc;

pub struct DocController {
    server: Server,
    sql: Arc<DocTableSql>,
    user: Arc<dyn DocumentUser>,
    database: Arc<dyn DocumentDatabase>,
}

impl DocController {
    pub(crate) fn new(database: Arc<dyn DocumentDatabase>, server: Server, user: Arc<dyn DocumentUser>) -> Self {
        let sql = Arc::new(DocTableSql {});
        Self {
            sql,
            server,
            user,
            database,
        }
    }

    pub(crate) async fn create_doc(&self, params: CreateDocParams) -> Result<(), DocError> {
        let _ = self.create_doc_on_server(params.clone()).await?;
        let doc = Doc {
            id: params.id,
            data: params.data,
        };
        let conn = self.database.db_connection()?;
        let _ = self.sql.create_doc_table(DocTable::new(doc), &*conn)?;

        Ok(())
    }

    pub(crate) async fn update_doc(&self, params: UpdateDocParams) -> Result<(), DocError> {
        let changeset = DocTableChangeset::new(params.clone());
        let conn = self.database.db_connection()?;
        let _ = self.sql.update_doc_table(changeset, &*conn)?;
        let _ = self.update_doc_on_server(params)?;

        Ok(())
    }

    pub(crate) async fn read_doc(&self, params: QueryDocParams) -> Result<Doc, DocError> {
        let conn = self.database.db_connection()?;
        let doc: Doc = self.sql.read_doc_table(&params.doc_id, &*conn)?.into();

        let _ = self.read_doc_on_server(params)?;
        Ok(doc)
    }

    pub(crate) async fn delete_doc(&self, params: QueryDocParams) -> Result<(), DocError> {
        let conn = self.database.db_connection()?;
        let _ = self.sql.delete_doc(&params.doc_id, &*conn)?;

        let _ = self.delete_doc_on_server(params)?;
        Ok(())
    }
}

impl DocController {
    #[tracing::instrument(skip(self), err)]
    async fn create_doc_on_server(&self, params: CreateDocParams) -> Result<(), DocError> {
        let token = self.user.token()?;
        let _ = self.server.create_doc(&token, params).await?;
        Ok(())
    }

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
