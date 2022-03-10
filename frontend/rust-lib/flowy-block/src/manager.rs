use crate::{editor::ClientTextBlockEditor, errors::FlowyError, BlockCloudService};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::{
    revision::{md5, RepeatedRevision, Revision},
    text_block_info::{TextBlockDelta, TextBlockId},
    ws_data::ServerRevisionWSData,
};
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_sync::{RevisionCloudService, RevisionManager, RevisionPersistence, RevisionWebSocket};
use lib_infra::future::FutureResult;
use std::{convert::TryInto, sync::Arc};

pub trait TextBlockUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct TextBlockManager {
    cloud_service: Arc<dyn BlockCloudService>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
    editor_map: Arc<TextBlockEditorMap>,
    user: Arc<dyn TextBlockUser>,
}

impl TextBlockManager {
    pub fn new(
        cloud_service: Arc<dyn BlockCloudService>,
        text_block_user: Arc<dyn TextBlockUser>,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        Self {
            cloud_service,
            rev_web_socket,
            editor_map: Arc::new(TextBlockEditorMap::new()),
            user: text_block_user,
        }
    }

    pub fn init(&self) -> FlowyResult<()> {
        listen_ws_state_changed(self.rev_web_socket.clone(), self.editor_map.clone());

        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, block_id), fields(block_id), err)]
    pub async fn open_block<T: AsRef<str>>(&self, block_id: T) -> Result<Arc<ClientTextBlockEditor>, FlowyError> {
        let block_id = block_id.as_ref();
        tracing::Span::current().record("block_id", &block_id);
        self.get_block_editor(block_id).await
    }

    #[tracing::instrument(level = "trace", skip(self, block_id), fields(block_id), err)]
    pub fn close_block<T: AsRef<str>>(&self, block_id: T) -> Result<(), FlowyError> {
        let block_id = block_id.as_ref();
        tracing::Span::current().record("block_id", &block_id);
        self.editor_map.remove(block_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, doc_id), fields(doc_id), err)]
    pub fn delete_block<T: AsRef<str>>(&self, doc_id: T) -> Result<(), FlowyError> {
        let doc_id = doc_id.as_ref();
        tracing::Span::current().record("doc_id", &doc_id);
        self.editor_map.remove(doc_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), fields(doc_id = %delta.block_id), err)]
    pub async fn receive_local_delta(&self, delta: TextBlockDelta) -> Result<TextBlockDelta, FlowyError> {
        let editor = self.get_block_editor(&delta.block_id).await?;
        let _ = editor.compose_local_delta(Bytes::from(delta.delta_str)).await?;
        let document_json = editor.delta_str().await?;
        Ok(TextBlockDelta {
            block_id: delta.block_id.clone(),
            delta_str: document_json,
        })
    }

    pub async fn create_block<T: AsRef<str>>(&self, doc_id: T, revisions: RepeatedRevision) -> FlowyResult<()> {
        let doc_id = doc_id.as_ref().to_owned();
        let db_pool = self.user.db_pool()?;
        // Maybe we could save the block to disk without creating the RevisionManager
        let rev_manager = self.make_block_rev_manager(&doc_id, db_pool)?;
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

impl TextBlockManager {
    async fn get_block_editor(&self, block_id: &str) -> FlowyResult<Arc<ClientTextBlockEditor>> {
        match self.editor_map.get(block_id) {
            None => {
                let db_pool = self.user.db_pool()?;
                self.make_block_editor(block_id, db_pool).await
            }
            Some(editor) => Ok(editor),
        }
    }

    async fn make_block_editor(
        &self,
        block_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<ClientTextBlockEditor>, FlowyError> {
        let user = self.user.clone();
        let token = self.user.token()?;
        let rev_manager = self.make_block_rev_manager(block_id, pool.clone())?;
        let cloud_service = Arc::new(TextBlockRevisionCloudService {
            token,
            server: self.cloud_service.clone(),
        });
        let doc_editor =
            ClientTextBlockEditor::new(block_id, user, rev_manager, self.rev_web_socket.clone(), cloud_service).await?;
        self.editor_map.insert(block_id, &doc_editor);
        Ok(doc_editor)
    }

    fn make_block_rev_manager(&self, doc_id: &str, pool: Arc<ConnectionPool>) -> Result<RevisionManager, FlowyError> {
        let user_id = self.user.user_id()?;
        let rev_persistence = Arc::new(RevisionPersistence::new(&user_id, doc_id, pool));
        Ok(RevisionManager::new(&user_id, doc_id, rev_persistence))
    }
}

struct TextBlockRevisionCloudService {
    token: String,
    server: Arc<dyn BlockCloudService>,
}

impl RevisionCloudService for TextBlockRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        let params: TextBlockId = object_id.to_string().into();
        let server = self.server.clone();
        let token = self.token.clone();
        let user_id = user_id.to_string();

        FutureResult::new(async move {
            match server.read_block(&token, params).await? {
                None => Err(FlowyError::record_not_found().context("Remote doesn't have this document")),
                Some(doc) => {
                    let delta_data = Bytes::from(doc.text.clone());
                    let doc_md5 = md5(&delta_data);
                    let revision = Revision::new(
                        &doc.block_id,
                        doc.base_rev_id,
                        doc.rev_id,
                        delta_data,
                        &user_id,
                        doc_md5,
                    );
                    Ok(vec![revision])
                }
            }
        })
    }
}

pub struct TextBlockEditorMap {
    inner: DashMap<String, Arc<ClientTextBlockEditor>>,
}

impl TextBlockEditorMap {
    fn new() -> Self {
        Self { inner: DashMap::new() }
    }

    pub(crate) fn insert(&self, block_id: &str, doc: &Arc<ClientTextBlockEditor>) {
        if self.inner.contains_key(block_id) {
            log::warn!("Doc:{} already exists in cache", block_id);
        }
        self.inner.insert(block_id.to_string(), doc.clone());
    }

    pub(crate) fn get(&self, block_id: &str) -> Option<Arc<ClientTextBlockEditor>> {
        Some(self.inner.get(block_id)?.clone())
    }

    pub(crate) fn remove(&self, block_id: &str) {
        if let Some(editor) = self.get(block_id) {
            editor.stop()
        }
        self.inner.remove(block_id);
    }
}

#[tracing::instrument(level = "trace", skip(web_socket, handlers))]
fn listen_ws_state_changed(web_socket: Arc<dyn RevisionWebSocket>, handlers: Arc<TextBlockEditorMap>) {
    tokio::spawn(async move {
        let mut notify = web_socket.subscribe_state_changed().await;
        while let Ok(state) = notify.recv().await {
            handlers.inner.iter().for_each(|handler| {
                handler.receive_ws_state(&state);
            })
        }
    });
}
