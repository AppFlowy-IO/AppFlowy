use crate::editor::{initial_document_content, AppFlowyDocumentEditor, DocumentRevisionCompress};
use crate::entities::{DocumentVersionPB, EditParams};
use crate::old_editor::editor::{DeltaDocumentEditor, DeltaDocumentRevisionCompress};
use crate::services::rev_sqlite::{SQLiteDeltaDocumentRevisionPersistence, SQLiteDocumentRevisionPersistence};
use crate::services::DocumentPersistence;
use crate::{errors::FlowyError, DocumentCloudService};
use bytes::Bytes;

use flowy_database::ConnectionPool;
use flowy_error::FlowyResult;
use flowy_http_model::util::md5;
use flowy_http_model::{document::DocumentIdPB, revision::Revision, ws_data::ServerRevisionWSData};
use flowy_revision::{
    RevisionCloudService, RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration, RevisionWebSocket,
    SQLiteRevisionSnapshotPersistence,
};
use flowy_sync::client_document::initial_delta_document_content;
use lib_infra::future::FutureResult;
use lib_infra::ref_map::{RefCountHashMap, RefCountValue};
use lib_ws::WSConnectState;
use std::any::Any;
use std::{convert::TryInto, sync::Arc};
use tokio::sync::RwLock;

pub trait DocumentUser: Send + Sync {
    fn user_dir(&self) -> Result<String, FlowyError>;
    fn user_id(&self) -> Result<String, FlowyError>;
    fn token(&self) -> Result<String, FlowyError>;
}

pub trait DocumentDatabase: Send + Sync {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub trait DocumentEditor: Send + Sync {
    /// Called when the document get closed
    fn close(&self);

    /// Exports the document content. The content is encoded in the corresponding
    /// editor data format.
    fn export(&self) -> FutureResult<String, FlowyError>;

    /// Duplicate the document inner data into String
    fn duplicate(&self) -> FutureResult<String, FlowyError>;

    fn receive_ws_data(&self, data: ServerRevisionWSData) -> FutureResult<(), FlowyError>;

    fn receive_ws_state(&self, state: &WSConnectState);

    /// Receives the local operations made by the user input. The operations are encoded
    /// in binary format.
    fn compose_local_operations(&self, data: Bytes) -> FutureResult<(), FlowyError>;

    /// Returns the `Any` reference that can be used to downcast back to the original,
    /// concrete type.
    ///
    /// The indirection through `as_any` is because using `downcast_ref`
    /// on `Box<A>` *directly* only lets us downcast back to `&A` again. You can take a look at [this](https://stackoverflow.com/questions/33687447/how-to-get-a-reference-to-a-concrete-type-from-a-trait-object)
    /// for more information.
    ///
    ///
    fn as_any(&self) -> &dyn Any;
}

#[derive(Clone, Debug)]
pub struct DocumentConfig {
    pub version: DocumentVersionPB,
}

impl std::default::Default for DocumentConfig {
    fn default() -> Self {
        Self {
            version: DocumentVersionPB::V1,
        }
    }
}

pub struct DocumentManager {
    cloud_service: Arc<dyn DocumentCloudService>,
    rev_web_socket: Arc<dyn RevisionWebSocket>,
    editor_map: Arc<RwLock<RefCountHashMap<RefCountDocumentHandler>>>,
    user: Arc<dyn DocumentUser>,
    persistence: Arc<DocumentPersistence>,
    #[allow(dead_code)]
    config: DocumentConfig,
}

impl DocumentManager {
    pub fn new(
        cloud_service: Arc<dyn DocumentCloudService>,
        document_user: Arc<dyn DocumentUser>,
        database: Arc<dyn DocumentDatabase>,
        rev_web_socket: Arc<dyn RevisionWebSocket>,
        config: DocumentConfig,
    ) -> Self {
        Self {
            cloud_service,
            rev_web_socket,
            editor_map: Arc::new(RwLock::new(RefCountHashMap::new())),
            user: document_user,
            persistence: Arc::new(DocumentPersistence::new(database)),
            config,
        }
    }

    /// Called immediately after the application launched with the user sign in/sign up.
    #[tracing::instrument(level = "trace", skip_all, err)]
    pub async fn initialize(&self, user_id: &str) -> FlowyResult<()> {
        let _ = self.persistence.initialize(user_id)?;
        listen_ws_state_changed(self.rev_web_socket.clone(), self.editor_map.clone());
        Ok(())
    }

    pub async fn initialize_with_new_user(&self, _user_id: &str, _token: &str) -> FlowyResult<()> {
        Ok(())
    }

    #[tracing::instrument(level = "trace", skip_all, fields(document_id), err)]
    pub async fn open_document_editor<T: AsRef<str>>(
        &self,
        document_id: T,
    ) -> Result<Arc<dyn DocumentEditor>, FlowyError> {
        let document_id = document_id.as_ref();
        tracing::Span::current().record("document_id", &document_id);
        self.init_document_editor(document_id).await
    }

    #[tracing::instrument(level = "trace", skip(self, editor_id), fields(editor_id), err)]
    pub async fn close_document_editor<T: AsRef<str>>(&self, editor_id: T) -> Result<(), FlowyError> {
        let editor_id = editor_id.as_ref();
        tracing::Span::current().record("editor_id", &editor_id);
        self.editor_map.write().await.remove(editor_id);
        Ok(())
    }

    pub async fn apply_edit(&self, params: EditParams) -> FlowyResult<()> {
        let editor = self.get_document_editor(&params.doc_id).await?;
        let _ = editor.compose_local_operations(Bytes::from(params.operations)).await?;
        Ok(())
    }

    pub async fn create_document<T: AsRef<str>>(&self, doc_id: T, revisions: Vec<Revision>) -> FlowyResult<()> {
        let doc_id = doc_id.as_ref().to_owned();
        let db_pool = self.persistence.database.db_pool()?;
        // Maybe we could save the document to disk without creating the RevisionManager
        let rev_manager = self.make_rev_manager(&doc_id, db_pool)?;
        let _ = rev_manager.reset_object(revisions).await?;
        Ok(())
    }

    pub async fn receive_ws_data(&self, data: Bytes) {
        let result: Result<ServerRevisionWSData, protobuf::ProtobufError> = data.try_into();
        match result {
            Ok(data) => match self.editor_map.read().await.get(&data.object_id) {
                None => tracing::error!("Can't find any source handler for {:?}-{:?}", data.object_id, data.ty),
                Some(handler) => match handler.0.receive_ws_data(data).await {
                    Ok(_) => {}
                    Err(e) => tracing::error!("{}", e),
                },
            },
            Err(e) => {
                tracing::error!("Document ws data parser failed: {:?}", e);
            }
        }
    }

    pub fn initial_document_content(&self) -> String {
        match self.config.version {
            DocumentVersionPB::V0 => initial_delta_document_content(),
            DocumentVersionPB::V1 => initial_document_content(),
        }
    }
}

impl DocumentManager {
    /// Returns the `DocumentEditor`
    ///
    /// # Arguments
    ///
    /// * `doc_id`: the id of the document
    ///
    /// returns: Result<Arc<DocumentEditor>, FlowyError>
    ///
    async fn get_document_editor(&self, doc_id: &str) -> FlowyResult<Arc<dyn DocumentEditor>> {
        match self.editor_map.read().await.get(doc_id) {
            None => {
                //
                tracing::warn!("Should call init_document_editor first");
                self.init_document_editor(doc_id).await
            }
            Some(handler) => Ok(handler.0.clone()),
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
    #[tracing::instrument(level = "trace", skip(self), err)]
    pub async fn init_document_editor(&self, doc_id: &str) -> Result<Arc<dyn DocumentEditor>, FlowyError> {
        let pool = self.persistence.database.db_pool()?;
        let user = self.user.clone();
        let token = self.user.token()?;
        let cloud_service = Arc::new(DocumentRevisionCloudService {
            token,
            server: self.cloud_service.clone(),
        });

        match self.config.version {
            DocumentVersionPB::V0 => {
                let rev_manager = self.make_delta_document_rev_manager(doc_id, pool.clone())?;
                let editor: Arc<dyn DocumentEditor> = Arc::new(
                    DeltaDocumentEditor::new(doc_id, user, rev_manager, self.rev_web_socket.clone(), cloud_service)
                        .await?,
                );
                self.editor_map
                    .write()
                    .await
                    .insert(doc_id.to_string(), RefCountDocumentHandler(editor.clone()));
                Ok(editor)
            }
            DocumentVersionPB::V1 => {
                let rev_manager = self.make_document_rev_manager(doc_id, pool.clone())?;
                let editor: Arc<dyn DocumentEditor> =
                    Arc::new(AppFlowyDocumentEditor::new(doc_id, user, rev_manager, cloud_service).await?);
                self.editor_map
                    .write()
                    .await
                    .insert(doc_id.to_string(), RefCountDocumentHandler(editor.clone()));
                Ok(editor)
            }
        }
    }

    fn make_rev_manager(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<RevisionManager<Arc<ConnectionPool>>, FlowyError> {
        match self.config.version {
            DocumentVersionPB::V0 => self.make_delta_document_rev_manager(doc_id, pool),
            DocumentVersionPB::V1 => self.make_document_rev_manager(doc_id, pool),
        }
    }

    fn make_document_rev_manager(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<RevisionManager<Arc<ConnectionPool>>, FlowyError> {
        let user_id = self.user.user_id()?;
        let disk_cache = SQLiteDocumentRevisionPersistence::new(&user_id, pool.clone());
        let configuration = RevisionPersistenceConfiguration::new(100, true);
        let rev_persistence = RevisionPersistence::new(&user_id, doc_id, disk_cache, configuration);
        // let history_persistence = SQLiteRevisionHistoryPersistence::new(doc_id, pool.clone());
        let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(doc_id, pool);
        Ok(RevisionManager::new(
            &user_id,
            doc_id,
            rev_persistence,
            DocumentRevisionCompress(),
            // history_persistence,
            snapshot_persistence,
        ))
    }

    fn make_delta_document_rev_manager(
        &self,
        doc_id: &str,
        pool: Arc<ConnectionPool>,
    ) -> Result<RevisionManager<Arc<ConnectionPool>>, FlowyError> {
        let user_id = self.user.user_id()?;
        let disk_cache = SQLiteDeltaDocumentRevisionPersistence::new(&user_id, pool.clone());
        let configuration = RevisionPersistenceConfiguration::new(100, true);
        let rev_persistence = RevisionPersistence::new(&user_id, doc_id, disk_cache, configuration);
        // let history_persistence = SQLiteRevisionHistoryPersistence::new(doc_id, pool.clone());
        let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(doc_id, pool);
        Ok(RevisionManager::new(
            &user_id,
            doc_id,
            rev_persistence,
            DeltaDocumentRevisionCompress(),
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

        FutureResult::new(async move {
            match server.fetch_document(&token, params).await? {
                None => Err(FlowyError::record_not_found().context("Remote doesn't have this document")),
                Some(payload) => {
                    let bytes = Bytes::from(payload.data.clone());
                    let doc_md5 = md5(&bytes);
                    let revision = Revision::new(&payload.doc_id, payload.base_rev_id, payload.rev_id, bytes, doc_md5);
                    Ok(vec![revision])
                }
            }
        })
    }
}

#[derive(Clone)]
struct RefCountDocumentHandler(Arc<dyn DocumentEditor>);

impl RefCountValue for RefCountDocumentHandler {
    fn did_remove(&self) {
        self.0.close();
    }
}

impl std::ops::Deref for RefCountDocumentHandler {
    type Target = Arc<dyn DocumentEditor>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[tracing::instrument(level = "trace", skip(web_socket, handlers))]
fn listen_ws_state_changed(
    web_socket: Arc<dyn RevisionWebSocket>,
    handlers: Arc<RwLock<RefCountHashMap<RefCountDocumentHandler>>>,
) {
    tokio::spawn(async move {
        let mut notify = web_socket.subscribe_state_changed().await;
        while let Ok(state) = notify.recv().await {
            handlers.read().await.values().iter().for_each(|handler| {
                handler.receive_ws_state(&state);
            })
        }
    });
}
