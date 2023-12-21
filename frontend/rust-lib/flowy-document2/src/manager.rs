use std::num::NonZeroUsize;
use std::sync::Arc;
use std::sync::Weak;

use collab::core::collab::{CollabRawData, MutexCollab};
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_document::document_data::{default_document_collab_data, default_document_data};
use collab_document::YrsDocAction;
use collab_entity::CollabType;
use lru::LruCache;
use parking_lot::Mutex;
use tracing::{event, instrument};

use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::RocksCollabDB;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_storage::FileStorageService;

use crate::document::MutexDocument;
use crate::entities::DocumentSnapshotPB;
use crate::reminder::DocumentReminderAction;

pub trait DocumentUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>; // unused now.
  fn collab_db(&self, uid: i64) -> Result<Weak<RocksCollabDB>, FlowyError>;
}

pub struct DocumentManager {
  pub user: Arc<dyn DocumentUser>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  documents: Arc<Mutex<LruCache<String, Arc<MutexDocument>>>>,
  #[allow(dead_code)]
  cloud_service: Arc<dyn DocumentCloudService>,
  storage_service: Weak<dyn FileStorageService>,
}

impl DocumentManager {
  pub fn new(
    user: Arc<dyn DocumentUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DocumentCloudService>,
    storage_service: Weak<dyn FileStorageService>,
  ) -> Self {
    let documents = Arc::new(Mutex::new(LruCache::new(NonZeroUsize::new(10).unwrap())));
    Self {
      user,
      collab_builder,
      documents,
      cloud_service,
      storage_service,
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
  pub async fn create_document(
    &self,
    uid: i64,
    doc_id: &str,
    data: Option<DocumentData>,
  ) -> FlowyResult<Arc<MutexDocument>> {
    tracing::trace!("create a document: {:?}", doc_id);

    if self.is_doc_exist(doc_id).unwrap_or(false) {
      self.get_document(doc_id).await
    } else {
      let collab = self.collab_for_document(uid, doc_id, vec![]).await?;
      let data = data.unwrap_or_else(default_document_data);
      let document = Arc::new(MutexDocument::create_with_data(collab, data)?);
      Ok(document)
    }
  }

  /// Return the document
  #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn get_document(&self, doc_id: &str) -> FlowyResult<Arc<MutexDocument>> {
    if let Some(doc) = self.documents.lock().get(doc_id).cloned() {
      return Ok(doc);
    }

    let mut updates = vec![];
    if !self.is_doc_exist(doc_id)? {
      // Try to get the document from the cloud service
      let result: Result<CollabRawData, FlowyError> = self
        .cloud_service
        .get_document_updates(doc_id, &self.user.workspace_id()?)
        .await;

      updates = match result {
        Ok(data) => data,
        Err(err) => {
          if err.is_record_not_found() {
            // The document's ID exists in the cloud, but its content does not.
            // This occurs when user A's document hasn't finished syncing and user B tries to open it.
            // As a result, a blank document is created for user B.
            event!(
              tracing::Level::INFO,
              "can't find the document in the cloud, doc_id: {}",
              doc_id
            );
            vec![default_document_collab_data(doc_id).doc_state.to_vec()]
          } else {
            return Err(err);
          }
        },
      }
    }

    let uid = self.user.user_id()?;
    event!(tracing::Level::DEBUG, "Initialize document: {}", doc_id);
    let collab = self.collab_for_document(uid, doc_id, updates).await?;
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
        .get_document_updates(doc_id, &self.user.workspace_id()?)
        .await?;
    }
    let uid = self.user.user_id()?;
    let collab = self.collab_for_document(uid, doc_id, updates).await?;
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
    let uid = self.user.user_id()?;
    if let Some(db) = self.user.collab_db(uid)?.upgrade() {
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
  pub async fn get_document_snapshots(
    &self,
    document_id: &str,
    limit: usize,
  ) -> FlowyResult<Vec<DocumentSnapshotPB>> {
    let workspace_id = self.user.workspace_id()?;
    let snapshots = self
      .cloud_service
      .get_document_snapshots(document_id, limit, &workspace_id)
      .await?
      .into_iter()
      .map(|snapshot| DocumentSnapshotPB {
        snapshot_id: snapshot.snapshot_id,
        snapshot_desc: "".to_string(),
        created_at: snapshot.created_at,
        data: snapshot.data,
      })
      .collect::<Vec<_>>();

    Ok(snapshots)
  }

  async fn collab_for_document(
    &self,
    uid: i64,
    doc_id: &str,
    updates: Vec<Vec<u8>>,
  ) -> FlowyResult<Arc<MutexCollab>> {
    let db = self.user.collab_db(uid)?;
    let collab = self
      .collab_builder
      .build(uid, doc_id, CollabType::Document, updates, db)
      .await?;
    Ok(collab)
  }

  fn is_doc_exist(&self, doc_id: &str) -> FlowyResult<bool> {
    let uid = self.user.user_id()?;
    if let Some(collab_db) = self.user.collab_db(uid)?.upgrade() {
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
