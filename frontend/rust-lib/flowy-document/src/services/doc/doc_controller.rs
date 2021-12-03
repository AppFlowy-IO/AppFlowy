use crate::{
    errors::{DocError, DocResult},
    module::DocumentUser,
    services::{
        cache::DocCache,
        doc::{
            edit::{ClientDocEditor, EditDocWsHandler},
            revision::RevisionServer,
        },
        server::Server,
        ws::WsDocumentManager,
    },
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_document_infra::entities::doc::{Doc, DocDelta, DocIdentifier};
use lib_infra::future::{wrap_future, FnFuture, ResultFuture};
use std::sync::Arc;
use tokio::time::{interval, Duration};

pub(crate) struct DocController {
    server: Server,
    ws_manager: Arc<WsDocumentManager>,
    cache: Arc<DocCache>,
    user: Arc<dyn DocumentUser>,
}

impl DocController {
    pub(crate) fn new(server: Server, user: Arc<dyn DocumentUser>, ws: Arc<WsDocumentManager>) -> Self {
        let cache = Arc::new(DocCache::new());
        Self {
            server,
            user,
            ws_manager: ws,
            cache,
        }
    }

    pub(crate) fn init(&self) -> DocResult<()> {
        self.ws_manager.init();
        Ok(())
    }

    pub(crate) async fn open(
        &self,
        params: DocIdentifier,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocEditor>, DocError> {
        if !self.cache.contains(&params.doc_id) {
            let edit_ctx = self.make_edit_context(&params.doc_id, pool.clone()).await?;
            return Ok(edit_ctx);
        }

        let edit_doc_ctx = self.cache.get(&params.doc_id)?;
        Ok(edit_doc_ctx)
    }

    pub(crate) fn close(&self, doc_id: &str) -> Result<(), DocError> {
        self.cache.remove(doc_id);
        self.ws_manager.remove_handler(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) fn delete(&self, params: DocIdentifier) -> Result<(), DocError> {
        let doc_id = &params.doc_id;
        self.cache.remove(doc_id);
        self.ws_manager.remove_handler(doc_id);
        Ok(())
    }

    // the delta's data that contains attributes with null value will be considered
    // as None e.g.
    // json : {"retain":7,"attributes":{"bold":null}}
    // deserialize delta: [ {retain: 7, attributes: {Bold: AttributeValue(None)}} ]
    #[tracing::instrument(level = "debug", skip(self, delta, db_pool), fields(doc_id = %delta.doc_id), err)]
    pub(crate) async fn apply_local_delta(
        &self,
        delta: DocDelta,
        db_pool: Arc<ConnectionPool>,
    ) -> Result<DocDelta, DocError> {
        if !self.cache.contains(&delta.doc_id) {
            let doc_identifier: DocIdentifier = delta.doc_id.clone().into();
            let _ = self.open(doc_identifier, db_pool).await?;
        }

        let edit_doc_ctx = self.cache.get(&delta.doc_id)?;
        let _ = edit_doc_ctx.composing_local_delta(Bytes::from(delta.data)).await?;
        Ok(edit_doc_ctx.delta().await?)
    }
}

impl DocController {
    async fn make_edit_context(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocEditor>, DocError> {
        // Opti: require upgradable_read lock and then upgrade to write lock using
        // RwLockUpgradableReadGuard::upgrade(xx) of ws
        // let doc = self.read_doc(doc_id, pool.clone()).await?;
        let ws = self.ws_manager.ws();
        let token = self.user.token()?;
        let user = self.user.clone();
        let server = Arc::new(RevisionServerImpl {
            token,
            server: self.server.clone(),
        });

        let edit_ctx = Arc::new(ClientDocEditor::new(doc_id, pool, ws, server, user).await?);
        let ws_handler = Arc::new(EditDocWsHandler(edit_ctx.clone()));
        self.ws_manager.register_handler(doc_id, ws_handler);
        self.cache.set(edit_ctx.clone());
        Ok(edit_ctx)
    }
}

struct RevisionServerImpl {
    token: String,
    server: Server,
}

impl RevisionServer for RevisionServerImpl {
    #[tracing::instrument(level = "debug", skip(self))]
    fn fetch_document_from_remote(&self, doc_id: &str) -> ResultFuture<Doc, DocError> {
        let params = DocIdentifier {
            doc_id: doc_id.to_string(),
        };
        let server = self.server.clone();
        let token = self.token.clone();

        ResultFuture::new(async move {
            match server.read_doc(&token, params).await? {
                None => Err(DocError::record_not_found().context("Remote doesn't have this document")),
                Some(doc) => Ok(doc),
            }
        })
    }
}

#[allow(dead_code)]
fn event_loop(_cache: Arc<DocCache>) -> FnFuture<()> {
    let mut i = interval(Duration::from_secs(3));
    wrap_future(async move {
        loop {
            // cache.all_docs().iter().for_each(|doc| doc.tick());
            i.tick().await;
        }
    })
}
