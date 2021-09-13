use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::{DocError, ErrorBuilder, ErrorCode},
    module::DocumentUser,
    services::server::Server,
    sql_tables::doc::{DocTable, DocTableChangeset, DocTableSql},
};
use flowy_database::{ConnectionPool, SqliteConnection};

use std::sync::Arc;
use tokio::task::JoinHandle;

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

    #[tracing::instrument(level = "debug", skip(self, conn, params), err)]
    pub fn update(&self, params: UpdateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let changeset = DocTableChangeset::new(params.clone());
        let _ = self.sql.update_doc_table(changeset, &*conn)?;
        let _ = self.update_doc_on_server(params)?;

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, pool), err)]
    pub async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        match self._open(params.clone(), pool.clone()) {
            Ok(doc_table) => Ok(doc_table.into()),
            Err(error) => self.try_read_on_server(params, pool.clone(), error).await,
        }
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let _ = self.sql.delete_doc(&params.doc_id, &*conn)?;
        let _ = self.delete_doc_on_server(params)?;
        Ok(())
    }
}

impl DocController {
    #[tracing::instrument(level = "debug", skip(self, params), err)]
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

    #[tracing::instrument(level = "debug", skip(self, pool), err)]
    fn read_doc_from_server(
        &self,
        params: QueryDocParams,
        pool: Arc<ConnectionPool>,
    ) -> Result<JoinHandle<Result<Doc, DocError>>, DocError> {
        let token = self.user.token()?;
        let server = self.server.clone();
        let sql = self.sql.clone();

        Ok(tokio::spawn(async move {
            match server.read_doc(&token, params).await? {
                None => Err(ErrorBuilder::new(ErrorCode::DocNotfound).build()),
                Some(doc) => {
                    let doc_table = DocTable::new(doc.clone());
                    let _ = sql.create_doc_table(doc_table, &*(pool.get().unwrap()))?;
                    // TODO: notify
                    Ok(doc)
                },
            }
        }))
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    async fn sync_read_doc_from_server(&self, params: QueryDocParams) -> Result<Doc, DocError> {
        let token = self.user.token()?;
        match self.server.read_doc(&token, params).await? {
            None => Err(ErrorBuilder::new(ErrorCode::DocNotfound).build()),
            Some(doc) => Ok(doc),
        }
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

    fn _open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let doc_table = self.sql.read_doc_table(&params.doc_id, &*(pool.get().unwrap()))?;
        let doc: Doc = doc_table.into();
        let _ = self.read_doc_from_server(params, pool.clone())?;
        Ok(doc)
    }

    async fn try_read_on_server(&self, params: QueryDocParams, pool: Arc<ConnectionPool>, error: DocError) -> Result<Doc, DocError> {
        if error.is_record_not_found() {
            log::debug!("Doc:{} don't exist, reading from server", params.doc_id);
            self.read_doc_from_server(params, pool)?.await.map_err(internal_error)?
        } else {
            Err(error)
        }
    }
}

fn internal_error<T>(e: T) -> DocError
where
    T: std::fmt::Debug,
{
    ErrorBuilder::new(ErrorCode::InternalError).error(e).build()
}
