use std::sync::Arc;
use std::sync::Weak;

use collab::core::collab::{DataSource, MutexCollab};
use collab::core::origin::CollabOrigin;
use collab::entity::EncodedCollab;
use collab::preclude::Collab;
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_document::document_awareness::DocumentAwarenessState;
use collab_document::document_awareness::DocumentAwarenessUser;
use collab_document::document_data::default_document_data;
use collab_entity::CollabType;
use collab_plugins::CollabKVDB;
use dashmap::DashMap;
use lib_infra::util::timestamp;
use tracing::trace;
use tracing::{event, instrument};

use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use flowy_document_pub::cloud::DocumentCloudService;
use flowy_error::{internal_error, ErrorCode, FlowyError, FlowyResult};
use flowy_storage_pub::storage::{CreatedUpload, StorageService};
use lib_dispatch::prelude::af_spawn;

use crate::document::MutexDocument;
use crate::entities::UpdateDocumentAwarenessStatePB;
use crate::entities::{
  DocumentSnapshotData, DocumentSnapshotMeta, DocumentSnapshotMetaPB, DocumentSnapshotPB,
};
use crate::reminder::DocumentReminderAction;

pub trait DocumentUserService: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn device_id(&self) -> Result<String, FlowyError>;
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
  documents: Arc<DashMap<String, Arc<MutexDocument>>>,
  removing_documents: Arc<DashMap<String, Arc<MutexDocument>>>,
  cloud_service: Arc<dyn DocumentCloudService>,
  storage_service: Weak<dyn StorageService>,
  snapshot_service: Arc<dyn DocumentSnapshotService>,
}

impl DocumentManager {
  pub fn new(
    user_service: Arc<dyn DocumentUserService>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DocumentCloudService>,
    storage_service: Weak<dyn StorageService>,
    snapshot_service: Arc<dyn DocumentSnapshotService>,
  ) -> Self {
    Self {
      user_service,
      collab_builder,
      documents: Arc::new(Default::default()),
      removing_documents: Arc::new(Default::default()),
      cloud_service,
      storage_service,
      snapshot_service,
    }
  }

  /// Get the encoded collab of the document.
  pub async fn get_encoded_collab_with_view_id(&self, doc_id: &str) -> FlowyResult<EncodedCollab> {
    let doc_state = DataSource::Disk;
    let uid = self.user_service.user_id()?;
    let collab = self
      .collab_for_document(uid, doc_id, doc_state, false)
      .await?;

    let collab = collab.lock();
    collab
      .encode_collab_v1(|collab| CollabType::Document.validate_require_data(collab))
      .map_err(internal_error)
  }

  pub async fn initialize(&self, _uid: i64) -> FlowyResult<()> {
    trace!("initialize document manager");
    self.documents.clear();
    self.removing_documents.clear();
    Ok(())
  }

  #[instrument(
    name = "document_initialize_with_new_user",
    level = "debug",
    skip_all,
    err
  )]
  pub async fn initialize_with_new_user(&self, uid: i64) -> FlowyResult<()> {
    self.initialize(uid).await?;
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
  ) -> FlowyResult<EncodedCollab> {
    if self.is_doc_exist(doc_id).await.unwrap_or(false) {
      Err(FlowyError::new(
        ErrorCode::RecordAlreadyExists,
        format!("document {} already exists", doc_id),
      ))
    } else {
      let encoded_collab = doc_state_from_document_data(
        doc_id,
        data.unwrap_or_else(|| default_document_data(doc_id)),
      )
      .await?;
      let doc_state = encoded_collab.doc_state.to_vec();
      let collab = self
        .collab_for_document(
          uid,
          doc_id,
          DataSource::DocStateV1(doc_state.clone()),
          false,
        )
        .await?;
      collab.lock().flush();

      Ok(encoded_collab)
    }
  }

  pub async fn get_document(&self, doc_id: &str) -> FlowyResult<Arc<MutexDocument>> {
    if let Some(doc) = self.documents.get(doc_id).map(|item| item.value().clone()) {
      return Ok(doc);
    }

    if let Some(doc) = self.restore_document_from_removing(doc_id) {
      return Ok(doc);
    }
    return Err(FlowyError::internal().with_context("Call open document first"));
  }

  /// Returns Document for given object id
  /// If the document does not exist in local disk, try get the doc state from the cloud.
  /// If the document exists, open the document and cache it
  #[tracing::instrument(level = "info", skip(self), err)]
  async fn create_document_instance(&self, doc_id: &str) -> FlowyResult<Arc<MutexDocument>> {
    if let Some(doc) = self.documents.get(doc_id).map(|item| item.value().clone()) {
      return Ok(doc);
    }

    let mut doc_state = DataSource::Disk;
    // If the document does not exist in local disk, try get the doc state from the cloud. This happens
    // When user_device_a create a document and user_device_b open the document.
    if !self.is_doc_exist(doc_id).await? {
      doc_state = DataSource::DocStateV1(
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
    event!(
      tracing::Level::DEBUG,
      "Initialize document: {}, workspace_id: {:?}",
      doc_id,
      self.user_service.workspace_id()
    );
    let collab = self
      .collab_for_document(uid, doc_id, doc_state, true)
      .await?;

    match MutexDocument::open(doc_id, collab) {
      Ok(document) => {
        let document = Arc::new(document);
        self.documents.insert(doc_id.to_string(), document.clone());
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
    let mut doc_state = DataSource::Disk;
    if !self.is_doc_exist(doc_id).await? {
      doc_state = DataSource::DocStateV1(
        self
          .cloud_service
          .get_document_doc_state(doc_id, &self.user_service.workspace_id()?)
          .await?,
      );
    }
    let uid = self.user_service.user_id()?;
    let collab = self
      .collab_for_document(uid, doc_id, doc_state, false)
      .await?;
    Document::open(collab)?
      .get_document_data()
      .map_err(internal_error)
  }

  pub async fn open_document(&self, doc_id: &str) -> FlowyResult<()> {
    if let Some(mutex_document) = self.restore_document_from_removing(doc_id) {
      mutex_document.start_init_sync();
    }

    let _ = self.create_document_instance(doc_id).await?;
    Ok(())
  }

  pub async fn close_document(&self, doc_id: &str) -> FlowyResult<()> {
    if let Some((doc_id, document)) = self.documents.remove(doc_id) {
      if let Some(doc) = document.try_lock() {
        // clear the awareness state when close the document
        doc.clean_awareness_local_state();
        let _ = doc.flush();
      }
      let clone_doc_id = doc_id.clone();
      trace!("move document to removing_documents: {}", doc_id);
      self.removing_documents.insert(doc_id, document);

      let weak_removing_documents = Arc::downgrade(&self.removing_documents);
      af_spawn(async move {
        tokio::time::sleep(std::time::Duration::from_secs(120)).await;
        if let Some(removing_documents) = weak_removing_documents.upgrade() {
          if removing_documents.remove(&clone_doc_id).is_some() {
            trace!("drop document from removing_documents: {}", clone_doc_id);
          }
        }
      });
    }

    Ok(())
  }

  pub async fn delete_document(&self, doc_id: &str) -> FlowyResult<()> {
    let uid = self.user_service.user_id()?;
    if let Some(db) = self.user_service.collab_db(uid)?.upgrade() {
      db.delete_doc(uid, doc_id).await?;
      // When deleting a document, we need to remove it from the cache.
      self.documents.remove(doc_id);
    }
    Ok(())
  }

  #[instrument(level = "debug", skip_all, err)]
  pub async fn set_document_awareness_local_state(
    &self,
    doc_id: &str,
    state: UpdateDocumentAwarenessStatePB,
  ) -> FlowyResult<bool> {
    let uid = self.user_service.user_id()?;
    let device_id = self.user_service.device_id()?;
    if let Ok(doc) = self.get_document(doc_id).await {
      if let Some(doc) = doc.try_lock() {
        let user = DocumentAwarenessUser { uid, device_id };
        let selection = state.selection.map(|s| s.into());
        let state = DocumentAwarenessState {
          version: 1,
          user,
          selection,
          metadata: state.metadata,
          timestamp: timestamp(),
        };
        doc.set_awareness_local_state(state);
        return Ok(true);
      }
    }
    Ok(false)
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

  #[instrument(level = "debug", skip_all, err)]
  pub async fn upload_file(
    &self,
    workspace_id: String,
    document_id: &str,
    local_file_path: &str,
  ) -> FlowyResult<CreatedUpload> {
    let storage_service = self.storage_service_upgrade()?;
    let upload = storage_service
      .create_upload(&workspace_id, document_id, local_file_path)
      .await?;
    Ok(upload)
  }

  pub async fn download_file(&self, local_file_path: String, url: String) -> FlowyResult<()> {
    let storage_service = self.storage_service_upgrade()?;
    storage_service.download_object(url, local_file_path)?;
    Ok(())
  }

  pub async fn delete_file(&self, local_file_path: String, url: String) -> FlowyResult<()> {
    let storage_service = self.storage_service_upgrade()?;
    storage_service.delete_object(url, local_file_path)?;
    Ok(())
  }

  async fn collab_for_document(
    &self,
    uid: i64,
    doc_id: &str,
    doc_state: DataSource,
    sync_enable: bool,
  ) -> FlowyResult<Arc<MutexCollab>> {
    let db = self.user_service.collab_db(uid)?;
    let workspace_id = self.user_service.workspace_id()?;
    let collab = self.collab_builder.build_with_config(
      &workspace_id,
      uid,
      doc_id,
      CollabType::Document,
      db,
      doc_state,
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

  fn storage_service_upgrade(&self) -> FlowyResult<Arc<dyn StorageService>> {
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
  pub fn get_file_storage_service(&self) -> &Weak<dyn StorageService> {
    &self.storage_service
  }

  fn restore_document_from_removing(&self, doc_id: &str) -> Option<Arc<MutexDocument>> {
    let (doc_id, doc) = self.removing_documents.remove(doc_id)?;
    trace!(
      "move document {} from removing_documents to documents",
      doc_id
    );
    self.documents.insert(doc_id, doc.clone());
    Some(doc)
  }
}

async fn doc_state_from_document_data(
  doc_id: &str,
  data: DocumentData,
) -> Result<EncodedCollab, FlowyError> {
  let doc_id = doc_id.to_string();
  // spawn_blocking is used to avoid blocking the tokio thread pool if the document is large.
  let encoded_collab = tokio::task::spawn_blocking(move || {
    let collab = Arc::new(MutexCollab::new(Collab::new_with_origin(
      CollabOrigin::Empty,
      doc_id,
      vec![],
      false,
    )));
    let document = Document::create_with_data(collab.clone(), data).map_err(internal_error)?;
    let encode_collab = document.encode_collab()?;
    Ok::<_, FlowyError>(encode_collab)
  })
  .await??;
  Ok(encoded_collab)
}
