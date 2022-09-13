use crate::entities::{EditParams, EditPayloadPB};
use crate::queue::TextBlockRevisionCompactor;
use crate::{editor::TextBlockEditor, errors::FlowyError, TextEditorCloudService};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_revision::disk::SQLiteTextBlockRevisionPersistence;
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionPersistence, RevisionWebSocket, SQLiteRevisionSnapshotPersistence,
};
use flowy_sync::entities::{
    revision::{md5, RepeatedRevision, Revision},
    text_block::{TextBlockDeltaPB, TextBlockIdPB},
    ws_data::ServerRevisionWSData,
};
use lib_infra::future::FutureResult;
use std::{convert::TryInto, sync::Arc};

pub trait TextEditorUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct TextEditorManager {
    cloud_service: Arc<dyn TextEditorCloudService>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
    editor_map: Arc<TextEditorMap>,
    user: Arc<dyn TextEditorUser>,
}

impl TextEditorManager {
    pub fn new(
        cloud_service: Arc<dyn TextEditorCloudService>,
        text_block_user: Arc<dyn TextEditorUser>,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
    ) -> Self {
        Self {
            cloud_service,
            rev_web_socket,
            editor_map: Arc::new(TextEditorMap::new()),
            user: text_block_user,
        }
    }

    pub fn init(&self) -> FlowyResult<()> {
        listen_ws_state_changed(self.rev_web_socket.clone(), self.editor_map.clone());

        Ok(())
    }

    #[tracing::instrument(level = "trace", skip(self, editor_id), fields(editor_id), err)]
    pub async fn open_text_editor<T: AsRef<str>>(&self, editor_id: T) -> Result<Arc<TextBlockEditor>, FlowyError> {
        let editor_id = editor_id.as_ref();
        tracing::Span::current().record("editor_id", &editor_id);
        self.get_text_editor(editor_id).await
    }

    #[tracing::instrument(level = "trace", skip(self, editor_id), fields(editor_id), err)]
    pub fn close_text_editor<T: AsRef<str>>(&self, editor_id: T) -> Result<(), FlowyError> {
        let editor_id = editor_id.as_ref();
        tracing::Span::current().record("editor_id", &editor_id);
        self.editor_map.remove(editor_id);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, delta), err)]
    pub async fn receive_local_delta(&self, delta: TextBlockDeltaPB) -> Result<TextBlockDeltaPB, FlowyError> {
        let editor = self.get_text_editor(&delta.text_block_id).await?;
        let _ = editor.compose_local_delta(Bytes::from(delta.delta_str)).await?;
        let delta_str = editor.delta_str().await?;
        Ok(TextBlockDeltaPB {
            text_block_id: delta.text_block_id.clone(),
            delta_str,
        })
    }

    pub async fn apply_edit(&self, params: EditParams) -> FlowyResult<()> {
        let editor = self.get_text_editor(&params.text_block_id).await?;
        let _ = editor.compose_local_delta(Bytes::from(params.delta)).await?;
        Ok(())
    }

    pub async fn create_text_block<T: AsRef<str>>(
        &self,
        text_block_id: T,
        revisions: RepeatedRevision,
    ) -> FlowyResult<()> {
        let doc_id = text_block_id.as_ref().to_owned();
        let db_pool = self.user.db_pool()?;
        // Maybe we could save the block to disk without creating the RevisionManager
        let rev_manager = self.make_text_block_rev_manager(&doc_id, db_pool)?;
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

impl TextEditorManager {
    async fn get_text_editor(&self, block_id: &str) -> FlowyResult<Arc<TextBlockEditor>> {
        match self.editor_map.get(block_id) {
            None => {
                let db_pool = self.user.db_pool()?;
                self.make_text_editor(block_id, db_pool).await
            }
            Some(editor) => Ok(editor),
        }
    }

    #[tracing::instrument(level = "trace", skip(self, pool), err)]
    async fn make_text_editor(
        &self,
        block_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<Arc<TextBlockEditor>, FlowyError> {
        let user = self.user.clone();
        let token = self.user.token()?;
        let rev_manager = self.make_text_block_rev_manager(block_id, pool.clone())?;
        let cloud_service = Arc::new(TextBlockRevisionCloudService {
            token,
            server: self.cloud_service.clone(),
        });
        let doc_editor =
            TextBlockEditor::new(block_id, user, rev_manager, self.rev_web_socket.clone(), cloud_service).await?;
        self.editor_map.insert(block_id, &doc_editor);
        Ok(doc_editor)
    }

    fn make_text_block_rev_manager(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<RevisionManager, FlowyError> {
        let user_id = self.user.user_id()?;
        let disk_cache = SQLiteTextBlockRevisionPersistence::new(&user_id, pool.clone());
        let rev_persistence = RevisionPersistence::new(&user_id, doc_id, disk_cache);
        // let history_persistence = SQLiteRevisionHistoryPersistence::new(doc_id, pool.clone());
        let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(doc_id, pool);
        let rev_compactor = TextBlockRevisionCompactor();

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

struct TextBlockRevisionCloudService {
    token: String,
    server: Arc<dyn TextEditorCloudService>,
}

impl RevisionCloudService for TextBlockRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, user_id: &str, object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        let params: TextBlockIdPB = object_id.to_string().into();
        let server = self.server.clone();
        let token = self.token.clone();
        let user_id = user_id.to_string();

        FutureResult::new(async move {
            match server.read_text_block(&token, params).await? {
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

pub struct TextEditorMap {
    inner: DashMap<String, Arc<TextBlockEditor>>,
}

impl TextEditorMap {
    fn new() -> Self {
        Self { inner: DashMap::new() }
    }

    pub(crate) fn insert(&self, editor_id: &str, doc: &Arc<TextBlockEditor>) {
        if self.inner.contains_key(editor_id) {
            log::warn!("Doc:{} already exists in cache", editor_id);
        }
        self.inner.insert(editor_id.to_string(), doc.clone());
    }

    pub(crate) fn get(&self, editor_id: &str) -> Option<Arc<TextBlockEditor>> {
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
fn listen_ws_state_changed(web_socket: Arc<dyn RevisionWebSocket>, handlers: Arc<TextEditorMap>) {
    tokio::spawn(async move {
        let mut notify = web_socket.subscribe_state_changed().await;
        while let Ok(state) = notify.recv().await {
            handlers.inner.iter().for_each(|handler| {
                handler.receive_ws_state(&state);
            })
        }
    });
}
