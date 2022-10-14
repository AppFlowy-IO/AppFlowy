use crate::editor::DocumentRevisionCompactor;
use crate::entities::EditParams;
use crate::{editor::DocumentEditor, errors::FlowyError, DocumentCloudService};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_revision::disk::SQLiteDocumentRevisionPersistence;
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionPersistence, RevisionWebSocket, SQLiteRevisionSnapshotPersistence,
};
use flowy_sync::entities::{
    document::{DocumentIdPB, DocumentOperationsPB},
    revision::{md5, RepeatedRevision, Revision},
    ws_data::ServerRevisionWSData,
};
use lib_infra::future::FutureResult;
use std::{convert::TryInto, sync::Arc};

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct DocumentManager {
    cloud_service: Arc<dyn DocumentCloudService>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
    editor_map: Arc<DocumentEditorMap>,
    user: Arc<dyn DocumentUser>,
}

impl DocumentManager {
    pub fn new(
        cloud_service: Arc<dyn DocumentCloudService>,
        document_user: Arc<dyn DocumentUser>,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        Self {
            cloud_service,
            rev_web_socket,
            editor_map: Arc::new(DocumentEditorMap::new()),
            user: document_user,
        }
    }

    pub fn init(&self) -> FlowyResult<()> {
        listen_ws_state_changed(self.rev_web_socket.clone(), self.editor_map.clone());

        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self, editor_id), fields(editor_id), err)]
    pub async fn open_document_editor<T: AsRef<str>>(&self, editor_id: T) -> Result<Arc<DocumentEditor>, FlowyError> {
        let editor_id = editor_id.as_ref();
        tracing::Span::current().record("editor_id", &editor_id);
        self.get_document_editor(editor_id).await
    }

    #[tracing::instrument(level = "trace", skip(self, editor_id), fields(editor_id), err)]
    pub fn close_document_editor<T: AsRef<str>>(&self, editor_id: T) -> Result<(), FlowyError> {
        let editor_id = editor_id.as_ref();
        tracing::Span::current().record("editor_id", &editor_id);
        self.editor_map.remove(editor_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, payload), err)]
    pub async fn receive_local_operations(
        &self,
        payload: DocumentOperationsPB,
    ) -> Result<DocumentOperationsPB, FlowyError> {
        let editor = self.get_document_editor(&payload.doc_id).await?;
        let _ = editor
            .compose_local_operations(Bytes::from(payload.operations_str))
            .await?;
        let operations_str = editor.get_operation_str().await?;
        Ok(DocumentOperationsPB {
            doc_id: payload.doc_id.clone(),
            operations_str,
        })
    }

    pub async fn apply_edit(&self, params: EditParams) -> FlowyResult<()> {
        let editor = self.get_document_editor(&params.doc_id).await?;
        let _ = editor
            .compose_local_operations(Bytes::from(params.operations_str))
            .await?;
        Ok(())
    }

    pub async fn create_document<T: AsRef<str>>(&self, doc_id: T, revisions: RepeatedRevision) -> FlowyResult<()> {
        let doc_id = doc_id.as_ref().to_owned();
        let db_pool = self.user.db_pool()?;
        // Maybe we could save the document to disk without creating the RevisionManager
        let rev_manager = self.make_document_rev_manager(&doc_id, db_pool)?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    pub async fn receive_ws_data(&self, data: Bytes) {
        let result: Result<ServerRevisionWSData, protobuf::ProtobufError> = data.try_into();
        match result {
            Ok(data) => match self.editor_map.get(&data.object_id) {
                None => tracing::error!("Can't find any source handler for {:?}-{:?}", data.object_id, data.ty),
                Some(editor) => match editor.receive_ws_data(data).await {
                    Ok(_) => {}
                    Err(e) => tracing::error!("{}", e),
                },
            },
            Err(e) => {
                tracing::error!("Document ws data parser failed: {:?}", e);
            }
        }
    }
}

impl DocumentManager {
    /// Returns the `DocumentEditor`
    /// Initializes the document editor if it's not initialized yet. Otherwise, returns the opened
    /// editor.
    ///
    /// # Arguments
    ///
    /// * `doc_id`: the id of the document
    ///
    /// returns: Result<Arc<DocumentEditor>, FlowyError>
    ///
    async fn get_document_editor(&self, doc_id: &str) -> FlowyResult<Arc<DocumentEditor>> {
        match self.editor_map.get(doc_id) {
            None => {
                let db_pool = self.user.db_pool()?;
                self.init_document_editor(doc_id, db_pool).await
            }
            Some(editor) => Ok(editor),
        }
    }

    /// Initializes a document editor with the doc_id
    ///
    /// # Arguments
    ///
    /// * `doc_id`: the id of the document
    /// * `pool`: sqlite connection pool
    ///
    /// returns: Result<Arc<DocumentEditor>, FlowyError>
    ///
    #[tracing::instrument(level = "trace", skip(self, pool), err)]
    async fn init_document_editor(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<DocumentEditor>, FlowyError> {
        let user = self.user.clone();
        let token = self.user.token()?;
        let rev_manager = self.make_document_rev_manager(doc_id, pool.clone())?;
        let cloud_service = Arc::new(DocumentRevisionCloudService {
            token,
            server: self.cloud_service.clone(),
        });
        let editor = DocumentEditor::new(doc_id, user, rev_manager, self.rev_web_socket.clone(), cloud_service).await?;
        self.editor_map.insert(doc_id, &editor);
        Ok(editor)
    }

    fn make_document_rev_manager(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<RevisionManager, FlowyError> {
        let user_id = self.user.user_id()?;
        let disk_cache = SQLiteDocumentRevisionPersistence::new(&user_id, pool.clone());
        let rev_persistence = RevisionPersistence::new(&user_id, doc_id, disk_cache);
        // let history_persistence = SQLiteRevisionHistoryPersistence::new(doc_id, pool.clone());
        let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(doc_id, pool);
        let rev_compactor = DocumentRevisionCompactor();

        Ok(RevisionManager::new(
            &user_id,
            doc_id,
            rev_persistence,
            rev_compactor,
            // history_persistence,
            snapshot_persistence,
        ))
    }
}

struct DocumentRevisionCloudService {
    token: String,
    server: Arc<dyn DocumentCloudService>,
}

impl RevisionCloudService for DocumentRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        let params: DocumentIdPB = object_id.to_string().into();
        let server = self.server.clone();
        let token = self.token.clone();
        let user_id = user_id.to_string();

        FutureResult::new(async move {
            match server.fetch_document(&token, params).await? {
                None => Err(FlowyError::record_not_found().context("Remote doesn't have this document")),
                Some(payload) => {
                    let bytes = Bytes::from(payload.content.clone());
                    let doc_md5 = md5(&bytes);
                    let revision = Revision::new(
                        &payload.doc_id,
                        payload.base_rev_id,
                        payload.rev_id,
                        bytes,
                        &user_id,
                        doc_md5,
                    );
                    Ok(vec![revision])
                }
            }
        })
    }
}

pub struct DocumentEditorMap {
    inner: DashMap<String, Arc<DocumentEditor>>,
}

impl DocumentEditorMap {
    fn new() -> Self {
        Self { inner: DashMap::new() }
    }

    pub(crate) fn insert(&self, editor_id: &str, doc: &Arc<DocumentEditor>) {
        if self.inner.contains_key(editor_id) {
            log::warn!("Doc:{} already exists in cache", editor_id);
        }
        self.inner.insert(editor_id.to_string(), doc.clone());
    }

    pub(crate) fn get(&self, editor_id: &str) -> Option<Arc<DocumentEditor>> {
        Some(self.inner.get(editor_id)?.clone())
    }

    pub(crate) fn remove(&self, editor_id: &str) {
        if let Some(editor) = self.get(editor_id) {
            editor.stop()
        }
        self.inner.remove(editor_id);
    }
}

#[tracing::instrument(level = "trace", skip(web_socket, handlers))]
fn listen_ws_state_changed(web_socket: Arc<dyn RevisionWebSocket>, handlers: Arc<DocumentEditorMap>) {
    tokio::spawn(async move {
        let mut notify = web_socket.subscribe_state_changed().await;
        while let Ok(state) = notify.recv().await {
            handlers.inner.iter().for_each(|handler| {
                handler.receive_ws_state(&state);
            })
        }
    });
}
