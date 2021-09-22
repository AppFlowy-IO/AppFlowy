use crate::{
    entities::doc::{CreateDocParams, Doc, QueryDocParams, UpdateDocParams},
    errors::DocError,
    module::DocumentUser,
    services::server::Server,
    sql_tables::doc::{DocTable, DocTableChangeset, DocTableSql},
};
use flowy_database::{ConnectionPool, SqliteConnection};

use crate::{
    errors::internal_error,
    services::{
        cache::DocCache,
        open_doc::{DocId, OpenedDoc, OpenedDocPersistence},
        ws::WsManager,
    },
};
use parking_lot::RwLock;
use std::sync::Arc;
use tokio::task::JoinHandle;

pub(crate) struct DocController {
    server: Server,
    sql: Arc<DocTableSql>,
    ws: Arc<RwLock<WsManager>>,
    cache: Arc<DocCache>,
    user: Arc<dyn DocumentUser>,
}

impl DocController {
    pub(crate) fn new(server: Server, user: Arc<dyn DocumentUser>, ws: Arc<RwLock<WsManager>>) -> Self {
        let sql = Arc::new(DocTableSql {});
        let cache = Arc::new(DocCache::new());
        Self {
            sql,
            server,
            user,
            ws,
            cache,
        }
    }

    #[tracing::instrument(skip(self, conn), err)]
    pub(crate) fn create(&self, params: CreateDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let doc = Doc {
            id: params.id,
            data: params.data,
            revision: 0,
        };
        let _ = self.sql.create_doc_table(DocTable::new(doc), conn)?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, pool), err)]
    pub(crate) async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Arc<OpenedDoc>, DocError> {
        if self.cache.is_opened(&params.doc_id) == false {
            return match self._open(params.clone(), pool.clone()) {
                Ok(doc) => Ok(doc),
                Err(error) => Err(error),
            };
        }

        let doc = self.cache.get(&params.doc_id)?;
        Ok(doc)
    }

    pub(crate) fn close(&self, doc_id: &str) -> Result<(), DocError> {
        self.cache.remove(doc_id);
        self.ws.write().remove_handler(doc_id);
        Ok(())
    }

    // #[tracing::instrument(level = "debug", skip(self, changeset, pool), err)]
    // pub(crate) async fn apply_changeset<T>(&self, id: T, changeset: Bytes, pool:
    // Arc<ConnectionPool>) -> Result<(), DocError>     where
    //         T: Into<DocId> + Debug,
    // {
    //     let id = id.into();
    //     match self.doc_map.get(&id) {
    //         None => Err(doc_not_found()),
    //         Some(doc) => {
    //             let _ = doc.apply_delta(changeset, pool)?;
    //             Ok(())
    //         },
    //     }
    // }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub(crate) fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let doc_id = &params.doc_id;
        let _ = self.sql.delete_doc(doc_id, &*conn)?;

        self.cache.remove(doc_id);
        self.ws.write().remove_handler(doc_id);
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
                None => Err(DocError::not_found()),
                Some(doc) => {
                    let doc_table = DocTable::new(doc.clone());
                    let _ = sql.create_doc_table(doc_table, &*(pool.get().map_err(internal_error)?))?;
                    // TODO: notify
                    Ok(doc)
                },
            }
        }))
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

    fn _open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Arc<OpenedDoc>, DocError> {
        match self.sql.read_doc_table(&params.doc_id, &*(pool.get().map_err(internal_error)?)) {
            Ok(doc_table) => {
                let doc = Arc::new(OpenedDoc::new(doc_table.into(), self.ws.read().sender.clone())?);
                self.ws.write().register_handler(doc.id.as_ref(), doc.clone());
                self.cache.set(doc.clone());

                Ok(doc)
            },
            Err(error) => {
                if error.is_record_not_found() {
                    log::debug!("Doc:{} don't exist, reading from server", params.doc_id);
                    // TODO: notify doc update
                    let _ = self.read_doc_from_server(params, pool);
                }

                return Err(error);
            },
        }
    }
}

impl OpenedDocPersistence for DocController {
    fn save(&self, params: UpdateDocParams, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let changeset = DocTableChangeset::new(params.clone());
        let _ = self.sql.update_doc_table(changeset, &*(pool.get().map_err(internal_error)?))?;
        Ok(())
    }
}
