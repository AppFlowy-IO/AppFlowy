use crate::{
    context::DocumentUser,
    errors::FlowyError,
    services::{
        doc::{
            edit::ClientDocumentEditor,
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
use flowy_collaboration::entities::{
    doc::{DocumentDelta, DocumentId, DocumentInfo},
    revision::RepeatedRevision,
};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub struct DocumentController {
    server: Server,
    ws_receivers: Arc<DocumentWSReceivers>,
    ws_sender: Arc<dyn DocumentWebSocket>,
    open_cache: Arc<OpenDocCache>,
    user: Arc<dyn DocumentUser>,
}

impl DocumentController {
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

    #[tracing::instrument(level = "debug", skip(self, doc_id), fields(doc_id), err)]
    pub async fn open<T: AsRef<str>>(&self, doc_id: T) -> Result<Arc<ClientDocumentEditor>, FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.get_editor(doc_id).await
    }

    #[tracing::instrument(level = "debug", skip(self, doc_id), fields(doc_id), err)]
    pub fn close<T: AsRef<str>>(&self, doc_id: T) -> Result<(), FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.open_cache.remove(doc_id);
        self.ws_receivers.remove(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, doc_id), fields(doc_id), err)]
    pub fn delete<T: AsRef<str>>(&self, doc_id: T) -> Result<(), FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.open_cache.remove(doc_id);
        self.ws_receivers.remove(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(doc_id = %delta.doc_id), err)]
    pub async fn apply_document_delta(&self, delta: DocumentDelta) -> Result<DocumentDelta, FlowyError> {
        let editor = self.get_editor(&delta.doc_id).await?;
        let _ = editor.compose_local_delta(Bytes::from(delta.delta_json)).await?;
        let document_json = editor.document_json().await?;
        Ok(DocumentDelta {
            doc_id: delta.doc_id.clone(),
            delta_json: document_json,
        })
    }

    pub async fn save_document<T: AsRef<str>>(&self, doc_id: T, revisions: RepeatedRevision) -> FlowyResult<()> {
        let doc_id = doc_id.as_ref().to_owned();
        let db_pool = self.user.db_pool()?;
        let rev_manager = self.make_rev_manager(&doc_id, db_pool)?;
        let _ = rev_manager.reset_document(revisions).await?;
        Ok(())
    }

    async fn get_editor(&self, doc_id: &str) -> FlowyResult<Arc<ClientDocumentEditor>> {
        match self.open_cache.get(doc_id) {
            None => {
                let db_pool = self.user.db_pool()?;
                self.make_editor(&doc_id, db_pool).await
            },
            Some(editor) => Ok(editor),
        }
    }
}

impl DocumentController {
    async fn make_editor(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocumentEditor>, FlowyError> {
        let user = self.user.clone();
        let token = self.user.token()?;
        let rev_manager = self.make_rev_manager(doc_id, pool.clone())?;
        let server = Arc::new(RevisionServerImpl {
            token,
            server: self.server.clone(),
        });
        let doc_editor =
            ClientDocumentEditor::new(doc_id, user, pool, rev_manager, self.ws_sender.clone(), server).await?;
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
        let params = DocumentId {
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
    inner: DashMap<String, Arc<ClientDocumentEditor>>,
}

impl OpenDocCache {
    fn new() -> Self { Self { inner: DashMap::new() } }

    pub(crate) fn insert(&self, doc_id: &str, doc: &Arc<ClientDocumentEditor>) {
        if self.inner.contains_key(doc_id) {
            log::warn!("Doc:{} already exists in cache", doc_id);
        }
        self.inner.insert(doc_id.to_string(), doc.clone());
    }

    pub(crate) fn contains(&self, doc_id: &str) -> bool { self.inner.get(doc_id).is_some() }

    pub(crate) fn get(&self, doc_id: &str) -> Option<Arc<ClientDocumentEditor>> {
        if !self.contains(&doc_id) {
            return None;
        }
        let opened_doc = self.inner.get(doc_id).unwrap();
        Some(opened_doc.clone())
    }

    pub(crate) fn remove(&self, id: &str) {
        let doc_id = id.to_string();
        if let Some(editor) = self.get(id) {
            editor.stop()
        }
        self.inner.remove(&doc_id);
    }
}

#[tracing::instrument(level = "debug", skip(state_receiver, receivers))]
fn listen_ws_state_changed(mut state_receiver: WSStateReceiver, receivers: Arc<DocumentWSReceivers>) {
    tokio::spawn(async move {
        while let Ok(state) = state_receiver.recv().await {
            receivers.ws_connect_state_changed(&state);
        }
    });
}
