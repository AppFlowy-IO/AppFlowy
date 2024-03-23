use std::num::NonZeroUsize;
use std::sync::Arc;
use std::sync::Weak;

use collab::core::collab::{DocStateSource, MutexCollab};
use collab::core::collab_plugin::EncodedCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_entity::CollabType;
use collab_plugins::CollabKVDB;
use flowy_storage::object_from_disk;
use lru::LruCache;
use parking_lot::Mutex;
use tokio::io::AsyncWriteExt;
use tracing::{error, trace};
use tracing::{event, instrument};

use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_integrate::CollabPersistenceConfig;
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_storage::ObjectStorageService;
use lib_dispatch::prelude::af_spawn;

use crate::document::MutexDocument;
use crate::entities::{
  DocumentSnapshotData, DocumentSnapshotMeta, DocumentSnapshotMetaPB, DocumentSnapshotPB,
};
use crate::reminder::DocumentReminderAction;

pub trait DocumentUserService: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError>;
}

pub trait DocumentSnapshotService: Send + Sync {
  fn get_document_snapshot_metas(
    &self,
    document_id: &str,
  ) -> FlowyResult<Vec<DocumentSnapshotMeta>>;
  fn get_document_snapshot(&self, snapshot_id: &str) -> FlowyResult<DocumentSnapshotData>;
}

pub struct DocumentManager {
  pub user_service: Arc<dyn DocumentUserService>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  documents: Arc<Mutex<LruCache<String, Arc<MutexDocument>>>>,
  cloud_service: Arc<dyn DocumentCloudService>,
  storage_service: Weak<dyn ObjectStorageService>,
  snapshot_service: Arc<dyn DocumentSnapshotService>,
}

impl DocumentManager {
  pub fn new(
    user_service: Arc<dyn DocumentUserService>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DocumentCloudService>,
    storage_service: Weak<dyn ObjectStorageService>,
    snapshot_service: Arc<dyn DocumentSnapshotService>,
  ) -> Self {
    let documents = Arc::new(Mutex::new(LruCache::new(NonZeroUsize::new(10).unwrap())));
    Self {
      user_service,
      collab_builder,
      documents,
      cloud_service,
      storage_service,
      snapshot_service,
    }
  }

  pub async fn initialize(&self, _uid: i64, _workspace_id: String) -> FlowyResult<()> {
    self.documents.lock().clear();
    Ok(())
  }

  #[instrument(
    name = "document_initialize_with_new_user",
    level = "debug",
    skip_all,
    err
  )]
  pub async fn initialize_with_new_user(&self, uid: i64, workspace_id: String) -> FlowyResult<()> {
    self.initialize(uid, workspace_id).await?;
    Ok(())
  }

  pub async fn handle_reminder_action(&self, action: DocumentReminderAction) {
    match action {
      DocumentReminderAction::Add { reminder: _ } => {},
      DocumentReminderAction::Remove { reminder_id: _ } => {},
      DocumentReminderAction::Update { reminder: _ } => {},
    }
  }

  /// Create a new document.
  ///
  /// if the document already exists, return the existing document.
  /// if the data is None, will create a document with default data.
  #[instrument(level = "info", skip(self, data))]
  pub async fn create_document(
    &self,
    uid: i64,
    doc_id: &str,
    data: Option<DocumentData>,
  ) -> FlowyResult<()> {
    if self.is_doc_exist(doc_id).await.unwrap_or(false) {
      Err(FlowyError::new(
        ErrorCode::RecordAlreadyExists,
        format!("document {} already exists", doc_id),
      ))
    } else {
      let doc_state =
        doc_state_from_document_data(doc_id, data.unwrap_or_else(default_document_data))
          .await?
          .doc_state
          .to_vec();
      let collab = self
        .collab_for_document(uid, doc_id, DocStateSource::FromDocState(doc_state), false)
        .await?;
      collab.lock().flush();
      Ok(())
    }
  }

  /// Returns Document for given object id
  /// If the document does not exist in local disk, try get the doc state from the cloud.
  /// If the document exists, open the document and cache it
  #[tracing::instrument(level = "info", skip(self), err)]
  pub async fn get_document(&self, doc_id: &str) -> FlowyResult<Arc<MutexDocument>> {
    if let Some(doc) = self.documents.lock().get(doc_id).cloned() {
      return Ok(doc);
    }

    let mut doc_state = DocStateSource::FromDisk;
    // If the document does not exist in local disk, try get the doc state from the cloud. This happens
    // When user_device_a create a document and user_device_b open the document.
    if !self.is_doc_exist(doc_id).await? {
      doc_state = DocStateSource::FromDocState(
        self
          .cloud_service
          .get_document_doc_state(doc_id, &self.user_service.workspace_id()?)
          .await?,
      );

      // the doc_state should not be empty if remote return the doc state without error.
      if doc_state.is_empty() {
        return Err(FlowyError::new(
          ErrorCode::RecordNotFound,
          format!("document {} not found", doc_id),
        ));
      }
    }

    let uid = self.user_service.user_id()?;
    event!(tracing::Level::DEBUG, "Initialize document: {}", doc_id);
    let collab = self
      .collab_for_document(uid, doc_id, doc_state, true)
      .await?;

    match MutexDocument::open(doc_id, collab) {
      Ok(document) => {
        let document = Arc::new(document);
        self
          .documents
          .lock()
          .put(doc_id.to_string(), document.clone());
        Ok(document)
      },
      Err(err) => {
        if err.is_invalid_data() {
          if let Some(db) = self.user_service.collab_db(uid)?.upgrade() {
            db.delete_doc(uid, doc_id).await?;
          }
        }
        return Err(err);
      },
    }
  }

  pub async fn get_document_data(&self, doc_id: &str) -> FlowyResult<DocumentData> {
    let mut doc_state = vec![];
    if !self.is_doc_exist(doc_id).await? {
      doc_state = self
        .cloud_service
        .get_document_doc_state(doc_id, &self.user_service.workspace_id()?)
        .await?;
    }
    let uid = self.user_service.user_id()?;
    let collab = self
      .collab_for_document(uid, doc_id, DocStateSource::FromDocState(doc_state), false)
      .await?;
    Document::open(collab)?
      .get_document_data()
      .map_err(internal_error)
  }

  pub async fn close_document(&self, doc_id: &str) -> FlowyResult<()> {
    // The lru will pop the least recently used document when the cache is full.
    if let Ok(doc) = self.get_document(doc_id).await {
      trace!("close document: {}", doc_id);
      if let Some(doc) = doc.try_lock() {
        let _ = doc.flush();
      }
    }

    Ok(())
  }

  pub async fn delete_document(&self, doc_id: &str) -> FlowyResult<()> {
    let uid = self.user_service.user_id()?;
    if let Some(db) = self.user_service.collab_db(uid)?.upgrade() {
      db.delete_doc(uid, doc_id).await?;

      // When deleting a document, we need to remove it from the cache.
      self.documents.lock().pop(doc_id);
    }
    Ok(())
  }

  /// Return the list of snapshots of the document.
  pub async fn get_document_snapshot_meta(
    &self,
    document_id: &str,
    _limit: usize,
  ) -> FlowyResult<Vec<DocumentSnapshotMetaPB>> {
    let metas = self
      .snapshot_service
      .get_document_snapshot_metas(document_id)?
      .into_iter()
      .map(|meta| DocumentSnapshotMetaPB {
        snapshot_id: meta.snapshot_id,
        object_id: meta.object_id,
        created_at: meta.created_at,
      })
      .collect::<Vec<_>>();

    Ok(metas)
  }

  pub async fn get_document_snapshot(&self, snapshot_id: &str) -> FlowyResult<DocumentSnapshotPB> {
    let snapshot = self
      .snapshot_service
      .get_document_snapshot(snapshot_id)
      .map(|snapshot| DocumentSnapshotPB {
        object_id: snapshot.object_id,
        encoded_v1: snapshot.encoded_v1,
      })?;
    Ok(snapshot)
  }

  pub async fn upload_file(
    &self,
    workspace_id: String,
    local_file_path: &str,
    is_async: bool,
  ) -> FlowyResult<String> {
    let (object_identity, object_value) = object_from_disk(&workspace_id, local_file_path).await?;
    let storage_service = self.storage_service_upgrade()?;
    let url = storage_service.get_object_url(object_identity).await?;

    let clone_url = url.clone();

    match is_async {
      false => storage_service.put_object(clone_url, object_value).await?,
      true => {
        // let the upload happen in the background
        af_spawn(async move {
          if let Err(e) = storage_service.put_object(clone_url, object_value).await {
            error!("upload file failed: {}", e);
          }
        });
      },
    }
    Ok(url)
  }

  pub async fn download_file(&self, local_file_path: String, url: String) -> FlowyResult<()> {
    // TODO(nathan): save file when the current target is wasm
    #[cfg(not(target_arch = "wasm32"))]
    {
      if tokio::fs::metadata(&local_file_path).await.is_ok() {
        tracing::warn!("file already exist in user local disk: {}", local_file_path);
        return Ok(());
      }

      let storage_service = self.storage_service_upgrade()?;
      let object_value = storage_service.get_object(url).await?;
      // create file if not exist
      let mut file = tokio::fs::OpenOptions::new()
        .create(true)
        .write(true)
        .open(&local_file_path)
        .await?;

      let n = file.write(&object_value.raw).await?;
      tracing::info!("downloaded {} bytes to file: {}", n, local_file_path);
    }
    Ok(())
  }

  pub async fn delete_file(&self, local_file_path: String, url: String) -> FlowyResult<()> {
    // TODO(nathan): delete file when the current target is wasm
    #[cfg(not(target_arch = "wasm32"))]
    // delete file from local
    tokio::fs::remove_file(local_file_path).await?;

    // delete from cloud
    let storage_service = self.storage_service_upgrade()?;
    af_spawn(async move {
      if let Err(e) = storage_service.delete_object(url).await {
        // TODO: add WAL to log the delete operation.
        // keep a list of files to be deleted, and retry later
        error!("delete file failed: {}", e);
      }
    });

    Ok(())
  }

  async fn collab_for_document(
    &self,
    uid: i64,
    doc_id: &str,
    doc_state: DocStateSource,
    sync_enable: bool,
  ) -> FlowyResult<Arc<MutexCollab>> {
    let db = self.user_service.collab_db(uid)?;
    let collab = self.collab_builder.build_with_config(
      uid,
      doc_id,
      CollabType::Document,
      db,
      doc_state,
      CollabPersistenceConfig::default().snapshot_per_update(1000),
      CollabBuilderConfig::default().sync_enable(sync_enable),
    )?;
    Ok(collab)
  }

  async fn is_doc_exist(&self, doc_id: &str) -> FlowyResult<bool> {
    let uid = self.user_service.user_id()?;
    if let Some(collab_db) = self.user_service.collab_db(uid)?.upgrade() {
      let is_exist = collab_db.is_exist(uid, doc_id).await?;
      Ok(is_exist)
    } else {
      Ok(false)
    }
  }

  fn storage_service_upgrade(&self) -> FlowyResult<Arc<dyn ObjectStorageService>> {
    let storage_service = self.storage_service.upgrade().ok_or_else(|| {
      FlowyError::internal().with_context("The file storage service is already dropped")
    })?;
    Ok(storage_service)
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_cloud_service(&self) -> &Arc<dyn DocumentCloudService> {
    &self.cloud_service
  }
  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_file_storage_service(&self) -> &Weak<dyn ObjectStorageService> {
    &self.storage_service
  }
}

async fn doc_state_from_document_data(
  doc_id: &str,
  data: DocumentData,
) -> Result<EncodedCollab, FlowyError> {
  let doc_id = doc_id.to_string();
  // spawn_blocking is used to avoid blocking the tokio thread pool if the document is large.
  let encoded_collab = tokio::task::spawn_blocking(move || {
    let collab = Arc::new(MutexCollab::from_collab(Collab::new_with_origin(
      CollabOrigin::Empty,
      doc_id,
      vec![],
      false,
    )));
    let _ = Document::create_with_data(collab.clone(), data).map_err(internal_error)?;
    Ok::<_, FlowyError>(collab.encode_collab_v1())
  })
  .await??;
  Ok(encoded_collab)
}
