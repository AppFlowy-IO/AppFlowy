use std::num::NonZeroUsize;
use std::sync::Arc;
use std::sync::Weak;

use collab::core::collab::{CollabDocState, MutexCollab};
use collab::core::collab_plugin::EncodedCollab;
use collab::core::origin::CollabOrigin;
use collab::preclude::Collab;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_document::document_data::default_document_data;
use collab_entity::CollabType;
use lru::LruCache;
use parking_lot::Mutex;
use tracing::{event, instrument};

use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_integrate::{CollabKVAction, CollabKVDB, CollabPersistenceConfig};
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_storage::FileStorageService;

use crate::document::MutexDocument;
use crate::entities::{
  DocumentSnapshotData, DocumentSnapshotMeta, DocumentSnapshotMetaPB, DocumentSnapshotPB,
};
use crate::reminder::DocumentReminderAction;

pub trait DocumentUserService: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>; // unused now.
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
  storage_service: Weak<dyn FileStorageService>,
  snapshot_service: Arc<dyn DocumentSnapshotService>,
}

impl DocumentManager {
  pub fn new(
    user_service: Arc<dyn DocumentUserService>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DocumentCloudService>,
    storage_service: Weak<dyn FileStorageService>,
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
    if self.is_doc_exist(doc_id).unwrap_or(false) {
      Err(FlowyError::new(
        ErrorCode::RecordAlreadyExists,
        format!("document {} already exists", doc_id),
      ))
    } else {
      let result: Result<CollabDocState, FlowyError> = self
        .cloud_service
        .get_document_doc_state(doc_id, &self.user_service.workspace_id()?)
        .await;

      match result {
        Ok(data) => {
          let collab = self.collab_for_document(uid, doc_id, data, false).await?;
          collab.lock().flush();
        },
        Err(err) => {
          if err.is_record_not_found() {
            let doc_state =
              doc_state_from_document_data(doc_id, data.unwrap_or_else(default_document_data))?
                .doc_state
                .to_vec();
            let collab = self
              .collab_for_document(uid, doc_id, doc_state, false)
              .await?;
            collab.lock().flush();
          } else {
            return Err(err);
          }
        },
      }

      Ok(())
    }
  }

  /// Return the document
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn get_document(&self, doc_id: &str) -> FlowyResult<Arc<MutexDocument>> {
    if let Some(doc) = self.documents.lock().get(doc_id).cloned() {
      return Ok(doc);
    }

    let mut doc_state = vec![];
    if !self.is_doc_exist(doc_id)? {
      // Try to get the document from the cloud service
      doc_state = self
        .cloud_service
        .get_document_doc_state(doc_id, &self.user_service.workspace_id()?)
        .await?;
    }

    let uid = self.user_service.user_id()?;
    event!(tracing::Level::DEBUG, "Initialize document: {}", doc_id);
    let collab = self
      .collab_for_document(uid, doc_id, doc_state, true)
      .await?;
    let document = Arc::new(MutexDocument::open(doc_id, collab)?);

    // save the document to the memory and read it from the memory if we open the same document again.
    // and we don't want to subscribe to the document changes if we open the same document again.
    self
      .documents
      .lock()
      .put(doc_id.to_string(), document.clone());
    Ok(document)
  }

  pub async fn get_document_data(&self, doc_id: &str) -> FlowyResult<DocumentData> {
    let mut updates = vec![];
    if !self.is_doc_exist(doc_id)? {
      updates = self
        .cloud_service
        .get_document_doc_state(doc_id, &self.user_service.workspace_id()?)
        .await?;
    }
    let uid = self.user_service.user_id()?;
    let collab = self
      .collab_for_document(uid, doc_id, updates, false)
      .await?;
    Document::open(collab)?
      .get_document_data()
      .map_err(internal_error)
  }

  #[instrument(level = "debug", skip(self), err)]
  pub async fn close_document(&self, doc_id: &str) -> FlowyResult<()> {
    // The lru will pop the least recently used document when the cache is full.
    if let Ok(doc) = self.get_document(doc_id).await {
      if let Some(doc) = doc.try_lock() {
        let _ = doc.flush();
      }
    }

    Ok(())
  }

  pub fn delete_document(&self, doc_id: &str) -> FlowyResult<()> {
    let uid = self.user_service.user_id()?;
    if let Some(db) = self.user_service.collab_db(uid)?.upgrade() {
      let _ = db.with_write_txn(|txn| {
        txn.delete_doc(uid, &doc_id)?;
        Ok(())
      });

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

    // let snapshots = self
    //   .cloud_service
    //   .get_document_snapshots(document_id, limit, &workspace_id)
    //   .await?
    //   .into_iter()
    //   .map(|snapshot| DocumentSnapshotPB {
    //     snapshot_id: snapshot.snapshot_id,
    //     snapshot_desc: "".to_string(),
    //     created_at: snapshot.created_at,
    //   })
    //   .collect::<Vec<_>>();

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

  async fn collab_for_document(
    &self,
    uid: i64,
    doc_id: &str,
    doc_state: CollabDocState,
    sync_enable: bool,
  ) -> FlowyResult<Arc<MutexCollab>> {
    let db = self.user_service.collab_db(uid)?;
    let collab = self
      .collab_builder
      .build_with_config(
        uid,
        doc_id,
        CollabType::Document,
        db,
        doc_state,
        CollabPersistenceConfig::default().snapshot_per_update(100),
        CollabBuilderConfig::default().sync_enable(sync_enable),
      )
      .await?;
    Ok(collab)
  }

  fn is_doc_exist(&self, doc_id: &str) -> FlowyResult<bool> {
    let uid = self.user_service.user_id()?;
    if let Some(collab_db) = self.user_service.collab_db(uid)?.upgrade() {
      let read_txn = collab_db.read_txn();
      Ok(read_txn.is_exist(uid, doc_id))
    } else {
      Ok(false)
    }
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_cloud_service(&self) -> &Arc<dyn DocumentCloudService> {
    &self.cloud_service
  }
  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_file_storage_service(&self) -> &Weak<dyn FileStorageService> {
    &self.storage_service
  }
}

fn doc_state_from_document_data(
  doc_id: &str,
  data: DocumentData,
) -> Result<EncodedCollab, FlowyError> {
  let collab = Arc::new(MutexCollab::from_collab(Collab::new_with_origin(
    CollabOrigin::Empty,
    doc_id,
    vec![],
  )));
  let _ = Document::create_with_data(collab.clone(), data).map_err(internal_error)?;
  Ok(collab.encode_collab_v1())
}
