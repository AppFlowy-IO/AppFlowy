use crate::{core::ClientDocumentEditor, errors::FlowyError, DocumentCloudService};
use async_trait::async_trait;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::{
    document_info::{DocumentDelta, DocumentId},
    revision::{md5, RepeatedRevision, Revision},
    ws_data::ServerRevisionWSData,
};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_sync::{RevisionCache, RevisionCloudService, RevisionManager, RevisionWebSocket};
use lib_infra::future::FutureResult;
use lib_ws::WSConnectState;
use std::{convert::TryInto, sync::Arc};

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

#[async_trait]
pub(crate) trait DocumentWSReceiver: Send + Sync {
    async fn receive_ws_data(&self, data: ServerRevisionWSData) -> Result<(), FlowyError>;
    fn connect_state_changed(&self, state: WSConnectState);
}
type WebSocketDataReceivers = Arc<DashMap<String, Arc<dyn DocumentWSReceiver>>>;
pub struct FlowyDocumentManager {
    cloud_service: Arc<dyn DocumentCloudService>,
    ws_receivers: WebSocketDataReceivers,
    web_socket: Arc<dyn RevisionWebSocket>,
    open_cache: Arc<OpenDocCache>,
    user: Arc<dyn DocumentUser>,
}

impl FlowyDocumentManager {
    pub fn new(
        cloud_service: Arc<dyn DocumentCloudService>,
        user: Arc<dyn DocumentUser>,
        web_socket: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        let ws_receivers = Arc::new(DashMap::new());
        let open_cache = Arc::new(OpenDocCache::new());
        Self {
            cloud_service,
            ws_receivers,
            web_socket,
            open_cache,
            user,
        }
    }

    pub fn init(&self) -> FlowyResult<()> {
        listen_ws_state_changed(self.web_socket.clone(), self.ws_receivers.clone());

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, doc_id), fields(doc_id), err)]
    pub async fn open_document<T: AsRef<str>>(&self, doc_id: T) -> Result<Arc<ClientDocumentEditor>, FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.get_editor(doc_id).await
    }

    #[tracing::instrument(level = "trace", skip(self, doc_id), fields(doc_id), err)]
    pub fn close_document<T: AsRef<str>>(&self, doc_id: T) -> Result<(), FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.open_cache.remove(doc_id);
        self.remove_ws_receiver(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, doc_id), fields(doc_id), err)]
    pub fn delete<T: AsRef<str>>(&self, doc_id: T) -> Result<(), FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.open_cache.remove(doc_id);
        self.remove_ws_receiver(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(doc_id = %delta.doc_id), err)]
    pub async fn receive_local_delta(&self, delta: DocumentDelta) -> Result<DocumentDelta, FlowyError> {
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
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    pub async fn did_receive_ws_data(&self, data: Bytes) {
        let result: Result<ServerRevisionWSData, protobuf::ProtobufError> = data.try_into();
        match result {
            Ok(data) => match self.ws_receivers.get(&data.object_id) {
                None => tracing::error!("Can't find any source handler for {:?}-{:?}", data.object_id, data.ty),
                Some(handler) => match handler.receive_ws_data(data).await {
                    Ok(_) => {},
                    Err(e) => tracing::error!("{}", e),
                },
            },
            Err(e) => {
                tracing::error!("Document ws data parser failed: {:?}", e);
            },
        }
    }

    pub async fn ws_connect_state_changed(&self, state: &WSConnectState) {
        for receiver in self.ws_receivers.iter() {
            receiver.value().connect_state_changed(state.clone());
        }
    }
}

impl FlowyDocumentManager {
    async fn get_editor(&self, doc_id: &str) -> FlowyResult<Arc<ClientDocumentEditor>> {
        match self.open_cache.get(doc_id) {
            None => {
                let db_pool = self.user.db_pool()?;
                self.make_editor(&doc_id, db_pool).await
            },
            Some(editor) => Ok(editor),
        }
    }

    async fn make_editor(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientDocumentEditor>, FlowyError> {
        let user = self.user.clone();
        let token = self.user.token()?;
        let rev_manager = self.make_rev_manager(doc_id, pool.clone())?;
        let server = Arc::new(DocumentRevisionCloudServiceImpl {
            token,
            server: self.cloud_service.clone(),
        });
        let doc_editor = ClientDocumentEditor::new(doc_id, user, rev_manager, self.web_socket.clone(), server).await?;
        self.add_ws_receiver(doc_id, doc_editor.ws_handler());
        self.open_cache.insert(&doc_id, &doc_editor);
        Ok(doc_editor)
    }

    fn make_rev_manager(&self, doc_id: &str, pool: Arc<ConnectionPool>) -> Result<RevisionManager, FlowyError> {
        let user_id = self.user.user_id()?;
        let cache = Arc::new(RevisionCache::new(&user_id, doc_id, pool));
        Ok(RevisionManager::new(&user_id, doc_id, cache))
    }

    fn add_ws_receiver(&self, object_id: &str, receiver: Arc<dyn DocumentWSReceiver>) {
        if self.ws_receivers.contains_key(object_id) {
            log::error!("Duplicate handler registered for {:?}", object_id);
        }
        self.ws_receivers.insert(object_id.to_string(), receiver);
    }

    fn remove_ws_receiver(&self, id: &str) { self.ws_receivers.remove(id); }
}

struct DocumentRevisionCloudServiceImpl {
    token: String,
    server: Arc<dyn DocumentCloudService>,
}

impl RevisionCloudService for DocumentRevisionCloudServiceImpl {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, user_id: &str, doc_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        let params = DocumentId {
            doc_id: doc_id.to_string(),
        };
        let server = self.server.clone();
        let token = self.token.clone();
        let user_id = user_id.to_string();

        FutureResult::new(async move {
            match server.read_document(&token, params).await? {
                None => Err(FlowyError::record_not_found().context("Remote doesn't have this document")),
                Some(doc) => {
                    let delta_data = Bytes::from(doc.text.clone());
                    let doc_md5 = md5(&delta_data);
                    let revision =
                        Revision::new(&doc.doc_id, doc.base_rev_id, doc.rev_id, delta_data, &user_id, doc_md5);
                    Ok(vec![revision])
                },
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

#[tracing::instrument(level = "trace", skip(web_socket, receivers))]
fn listen_ws_state_changed(web_socket: Arc<dyn RevisionWebSocket>, receivers: WebSocketDataReceivers) {
    tokio::spawn(async move {
        let mut notify = web_socket.subscribe_state_changed().await;
        while let Ok(state) = notify.recv().await {
            for receiver in receivers.iter() {
                receiver.value().connect_state_changed(state.clone());
            }
        }
    });
}
