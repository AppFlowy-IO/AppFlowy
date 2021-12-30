use crate::{
    context::DocumentUser,
    errors::FlowyError,
    services::{
        doc::{
            edit::ClientDocEditor,
            revision::{RevisionCache, RevisionManager, RevisionServer},
            DocumentWSReceivers,
            DocumentWebSocket,
            WSStateReceiver,
        },
        server::Server,
    },
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::doc::{DocIdentifier, DocumentDelta, DocumentInfo};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct DocController {
    server: Server,
    ws_receivers: Arc<DocumentWSReceivers>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    open_cache: Arc<OpenDocCache>,
    user: Arc<dyn DocumentUser>,
}

impl DocController {
    pub(crate) fn new(
        server: Server,
        user: Arc<dyn DocumentUser>,
        ws_receivers: Arc<DocumentWSReceivers>,
        ws_sender: Arc<dyn DocumentWebSocket>,
    ) -> Self {
        let open_cache = Arc::new(OpenDocCache::new());
        Self {
            server,
            ws_receivers,
            ws_sender,
            open_cache,
            user,
        }
    }

    pub(crate) fn init(&self) -> FlowyResult<()> {
        let notify = self.ws_sender.subscribe_state_changed();
        listen_ws_state_changed(notify, self.ws_receivers.clone());

        Ok(())
    }

    pub async fn open(
        &self,
        params: DocIdentifier,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocEditor>, FlowyError> {
        if !self.open_cache.contains(&params.doc_id) {
            let editor = self.make_editor(&params.doc_id, pool.clone()).await?;
            return Ok(editor);
        }
        self.open_cache.get(&params.doc_id)
    }

    pub fn close(&self, doc_id: &str) -> Result<(), FlowyError> {
        tracing::debug!("Close document {}", doc_id);
        self.open_cache.remove(doc_id);
        self.ws_receivers.remove(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    pub fn delete(&self, params: DocIdentifier) -> Result<(), FlowyError> {
        let doc_id = &params.doc_id;
        self.open_cache.remove(doc_id);
        self.ws_receivers.remove(doc_id);
        Ok(())
    }

    // the delta's data that contains attributes with null value will be considered
    // as None e.g.
    // json : {"retain":7,"attributes":{"bold":null}}
    // deserialize delta: [ {retain: 7, attributes: {Bold: AttributeValue(None)}} ]
    #[tracing::instrument(level = "debug", skip(self, delta, db_pool), fields(doc_id = %delta.doc_id), err)]
    pub async fn apply_local_delta(
        &self,
        delta: DocumentDelta,
        db_pool: Arc<ConnectionPool>,
    ) -> Result<DocumentDelta, FlowyError> {
        if !self.open_cache.contains(&delta.doc_id) {
            let doc_identifier: DocIdentifier = delta.doc_id.clone().into();
            let _ = self.open(doc_identifier, db_pool).await?;
        }

        let edit_doc_ctx = self.open_cache.get(&delta.doc_id)?;
        let _ = edit_doc_ctx.composing_local_delta(Bytes::from(delta.text)).await?;
        Ok(edit_doc_ctx.delta().await?)
    }
}

impl DocController {
    async fn make_editor(&self, doc_id: &str, pool: Arc<ConnectionPool>) -> Result<Arc<ClientDocEditor>, FlowyError> {
        let user = self.user.clone();
        let token = self.user.token()?;
        let rev_manager = self.make_rev_manager(doc_id, pool.clone())?;
        let server = Arc::new(RevisionServerImpl {
            token,
            server: self.server.clone(),
        });
        let doc_editor = ClientDocEditor::new(doc_id, user, pool, rev_manager, self.ws_sender.clone(), server).await?;
        self.ws_receivers.add(doc_id, doc_editor.ws_handler());
        self.open_cache.insert(&doc_id, &doc_editor);
        Ok(doc_editor)
    }

    fn make_rev_manager(&self, doc_id: &str, pool: Arc<ConnectionPool>) -> Result<RevisionManager, FlowyError> {
        let user_id = self.user.user_id()?;
        let cache = Arc::new(RevisionCache::new(&user_id, doc_id, pool));
        Ok(RevisionManager::new(&user_id, doc_id, cache))
    }
}

struct RevisionServerImpl {
    token: String,
    server: Server,
}

impl RevisionServer for RevisionServerImpl {
    #[tracing::instrument(level = "debug", skip(self))]
    fn fetch_document(&self, doc_id: &str) -> FutureResult<DocumentInfo, FlowyError> {
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

    pub(crate) fn insert(&self, doc_id: &str, doc: &Arc<ClientDocEditor>) {
        if self.inner.contains_key(doc_id) {
            log::warn!("Doc:{} already exists in cache", doc_id);
        }
        self.inner.insert(doc_id.to_string(), doc.clone());
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
            Ok(editor) => editor.stop(),
            Err(e) => log::error!("{}", e),
        }
        self.inner.remove(&doc_id);
    }
}

fn doc_not_found() -> FlowyError {
    FlowyError::record_not_found().context("Doc is close or you should call open first")
}

#[tracing::instrument(level = "debug", skip(state_receiver, receivers))]
fn listen_ws_state_changed(mut state_receiver: WSStateReceiver, receivers: Arc<DocumentWSReceivers>) {
    tokio::spawn(async move {
        while let Ok(state) = state_receiver.recv().await {
            receivers.ws_connect_state_changed(&state);
        }
    });
}
