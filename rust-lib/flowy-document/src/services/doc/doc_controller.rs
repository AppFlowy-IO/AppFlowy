use crate::{
    entities::doc::{CreateDocParams, Doc, DocDelta, QueryDocParams, UpdateDocParams},
    errors::{internal_error, DocError},
    module::DocumentUser,
    services::{cache::DocCache, doc::edit_context::EditDocContext, server::Server, ws::WsDocumentManager},
    sql_tables::doc::{DocTable, DocTableSql, OpTableSql},
};
use bytes::Bytes;
use flowy_database::{ConnectionPool, SqliteConnection};

use parking_lot::RwLock;
use std::sync::Arc;

pub(crate) struct DocController {
    server: Server,
    doc_sql: Arc<DocTableSql>,
    op_sql: Arc<OpTableSql>,
    ws: Arc<RwLock<WsDocumentManager>>,
    cache: Arc<DocCache>,
    user: Arc<dyn DocumentUser>,
}

impl DocController {
    pub(crate) fn new(server: Server, user: Arc<dyn DocumentUser>, ws: Arc<RwLock<WsDocumentManager>>) -> Self {
        let doc_sql = Arc::new(DocTableSql {});
        let op_sql = Arc::new(OpTableSql {});
        let cache = Arc::new(DocCache::new());
        Self {
            server,
            doc_sql,
            op_sql,
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
        let _ = self.doc_sql.create_doc_table(DocTable::new(doc), conn)?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, pool), err)]
    pub(crate) async fn open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Arc<EditDocContext>, DocError> {
        if self.cache.is_opened(&params.doc_id) == false {
            return match self._open(params, pool).await {
                Ok(doc) => Ok(doc),
                Err(error) => Err(error),
            };
        }

        let edit_doc_ctx = self.cache.get(&params.doc_id)?;
        Ok(edit_doc_ctx)
    }

    pub(crate) fn close(&self, doc_id: &str) -> Result<(), DocError> {
        self.cache.remove(doc_id);
        self.ws.write().remove_handler(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, conn), err)]
    pub(crate) fn delete(&self, params: QueryDocParams, conn: &SqliteConnection) -> Result<(), DocError> {
        let doc_id = &params.doc_id;
        let _ = self.doc_sql.delete_doc(doc_id, &*conn)?;

        self.cache.remove(doc_id);
        self.ws.write().remove_handler(doc_id);
        let _ = self.delete_doc_on_server(params)?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta, pool), err)]
    pub(crate) fn edit_doc(&self, delta: DocDelta, pool: Arc<ConnectionPool>) -> Result<Doc, DocError> {
        let edit_doc_ctx = self.cache.get(&delta.doc_id)?;
        let _ = edit_doc_ctx.apply_delta(Bytes::from(delta.data), pool)?;
        Ok(edit_doc_ctx.doc())
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
    async fn read_doc_from_server(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Arc<EditDocContext>, DocError> {
        let token = self.user.token()?;
        match self.server.read_doc(&token, params).await? {
            None => Err(DocError::not_found()),
            Some(doc) => {
                let edit = self.make_edit_context(doc.clone())?;
                let conn = &*(pool.get().map_err(internal_error)?);
                let _ = self.doc_sql.create_doc_table(doc.into(), conn)?;
                Ok(edit)
            },
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

    async fn _open(&self, params: QueryDocParams, pool: Arc<ConnectionPool>) -> Result<Arc<EditDocContext>, DocError> {
        match self.doc_sql.read_doc_table(&params.doc_id, pool.clone()) {
            Ok(doc_table) => Ok(self.make_edit_context(doc_table.into())?),
            Err(error) => {
                if error.is_record_not_found() {
                    log::debug!("Doc:{} don't exist, reading from server", params.doc_id);
                    Ok(self.read_doc_from_server(params, pool.clone()).await?)
                } else {
                    return Err(error);
                }
            },
        }
    }

    fn make_edit_context(&self, doc: Doc) -> Result<Arc<EditDocContext>, DocError> {
        // Opti: require upgradable_read lock and then upgrade to write lock using
        // RwLockUpgradableReadGuard::upgrade(xx) of ws
        let ws = self.ws.read().sender();
        let edit_ctx = Arc::new(EditDocContext::new(doc, ws, self.op_sql.clone())?);
        self.ws.write().register_handler(edit_ctx.id.as_ref(), edit_ctx.clone());
        self.cache.set(edit_ctx.clone());
        Ok(edit_ctx)
    }
}
