use crate::{
    errors::FlowyError,
    module::DocumentUser,
    services::{
        doc::{
            edit::{ClientDocEditor, EditDocWsHandler},
            revision::{RevisionCache, RevisionManager, RevisionServer},
        },
        server::Server,
        ws::WsDocumentManager,
    },
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::doc::{Doc, DocDelta, DocIdentifier};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub(crate) struct DocController {
    server: Server,
    ws_manager: Arc<WsDocumentManager>,
    open_cache: Arc<OpenDocCache>,
    user: Arc<dyn DocumentUser>,
}

impl DocController {
    pub(crate) fn new(server: Server, user: Arc<dyn DocumentUser>, ws: Arc<WsDocumentManager>) -> Self {
        let open_cache = Arc::new(OpenDocCache::new());
        Self {
            server,
            user,
            ws_manager: ws,
            open_cache,
        }
    }

    pub(crate) fn init(&self) -> FlowyResult<()> {
        self.ws_manager.init();
        Ok(())
    }

    pub(crate) async fn open(
        &self,
        params: DocIdentifier,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocEditor>, FlowyError> {
        if !self.open_cache.contains(&params.doc_id) {
            let edit_ctx = self.make_edit_context(&params.doc_id, pool.clone()).await?;
            return Ok(edit_ctx);
        }

        let edit_doc_ctx = self.open_cache.get(&params.doc_id)?;
        Ok(edit_doc_ctx)
    }

    pub(crate) fn close(&self, doc_id: &str) -> Result<(), FlowyError> {
        tracing::debug!("Close doc {}", doc_id);
        self.open_cache.remove(doc_id);
        self.ws_manager.remove_handler(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub(crate) fn delete(&self, params: DocIdentifier) -> Result<(), FlowyError> {
        let doc_id = &params.doc_id;
        self.open_cache.remove(doc_id);
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
    ) -> Result<DocDelta, FlowyError> {
        if !self.open_cache.contains(&delta.doc_id) {
            let doc_identifier: DocIdentifier = delta.doc_id.clone().into();
            let _ = self.open(doc_identifier, db_pool).await?;
        }

        let edit_doc_ctx = self.open_cache.get(&delta.doc_id)?;
        let _ = edit_doc_ctx.composing_local_delta(Bytes::from(delta.data)).await?;
        Ok(edit_doc_ctx.delta().await?)
    }
}

impl DocController {
    async fn make_edit_context(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocEditor>, FlowyError> {
        let user = self.user.clone();
        let rev_manager = self.make_rev_manager(doc_id, pool.clone())?;
        let edit_ctx = ClientDocEditor::new(doc_id, user, pool, rev_manager, self.ws_manager.ws()).await?;
        let ws_handler = Arc::new(EditDocWsHandler(edit_ctx.clone()));
        self.ws_manager.register_handler(doc_id, ws_handler);
        self.open_cache.set(edit_ctx.clone());
        Ok(edit_ctx)
    }

    fn make_rev_manager(&self, doc_id: &str, pool: Arc<ConnectionPool>) -> Result<RevisionManager, FlowyError> {
        // Opti: require upgradable_read lock and then upgrade to write lock using
        // RwLockUpgradableReadGuard::upgrade(xx) of ws
        // let doc = self.read_doc(doc_id, pool.clone()).await?;
        let ws_sender = self.ws_manager.ws();
        let token = self.user.token()?;
        let user_id = self.user.user_id()?;
        let server = Arc::new(RevisionServerImpl {
            token,
            server: self.server.clone(),
        });
        let cache = Arc::new(RevisionCache::new(&user_id, doc_id, pool, server));
        Ok(RevisionManager::new(&user_id, doc_id, cache, ws_sender))
    }
}

struct RevisionServerImpl {
    token: String,
    server: Server,
}

impl RevisionServer for RevisionServerImpl {
    #[tracing::instrument(level = "debug", skip(self))]
    fn fetch_document(&self, doc_id: &str) -> FutureResult<Doc, FlowyError> {
        let params = DocIdentifier {
            doc_id: doc_id.to_string(),
        };
        let server = self.server.clone();
        let token = self.token.clone();

        FutureResult::new(async move {
            match server.read_doc(&token, params).await? {
                None => Err(FlowyError::record_not_found().context("Remote doesn't have this document")),
                Some(doc) => Ok(doc),
            }
        })
    }
}

pub struct OpenDocCache {
    inner: DashMap<String, Arc<ClientDocEditor>>,
}

impl OpenDocCache {
    fn new() -> Self { Self { inner: DashMap::new() } }

    pub(crate) fn set(&self, doc: Arc<ClientDocEditor>) {
        let doc_id = doc.doc_id.clone();
        if self.inner.contains_key(&doc_id) {
            log::warn!("Doc:{} already exists in cache", &doc_id);
        }
        self.inner.insert(doc_id, doc);
    }

    pub(crate) fn contains(&self, doc_id: &str) -> bool { self.inner.get(doc_id).is_some() }

    pub(crate) fn get(&self, doc_id: &str) -> Result<Arc<ClientDocEditor>, FlowyError> {
        if !self.contains(&doc_id) {
            return Err(doc_not_found());
        }
        let opened_doc = self.inner.get(doc_id).unwrap();
        Ok(opened_doc.clone())
    }

    pub(crate) fn remove(&self, id: &str) {
        let doc_id = id.to_string();
        match self.get(id) {
            Ok(editor) => editor.stop_sync(),
            Err(e) => log::error!("{}", e),
        }
        self.inner.remove(&doc_id);
    }
}

fn doc_not_found() -> FlowyError {
    FlowyError::record_not_found().context("Doc is close or you should call open first")
}
