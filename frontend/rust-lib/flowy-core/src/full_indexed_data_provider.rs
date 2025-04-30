use collab::preclude::Collab;
use collab_document::document::DocumentBody;
use collab_entity::CollabType;
use collab_folder::View;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_ai_pub::entities::{UnindexedCollab, UnindexedCollabMetadata, UnindexedData};
use flowy_ai_pub::persistence::{
  batch_upsert_index_collab, select_indexed_collab_ids, IndexCollabRecordTable,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::FolderManager;
use flowy_server::af_cloud::define::LoggedUser;
use lib_infra::async_trait::async_trait;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;
use tracing::{error, info, trace, warn};
use uuid::Uuid;

#[async_trait]
pub trait FullIndexedDataConsumer: Send + Sync {
  fn consumer_id(&self) -> String;
  async fn consume_indexed_data(&self, uid: i64, data: &UnindexedCollab) -> FlowyResult<()>;
}

#[derive(Clone)]
pub struct FullIndexedDataProvider {
  folder_manager: Weak<FolderManager>,
  logged_user: Weak<dyn LoggedUser>,
  cancel_token: CancellationToken,
  consumers: Arc<RwLock<Vec<Box<dyn FullIndexedDataConsumer>>>>,
}

impl FullIndexedDataProvider {
  pub fn new(folder_manager: Weak<FolderManager>, logged_user: Weak<dyn LoggedUser>) -> Self {
    let cancel_token = CancellationToken::new();
    let consumers = Arc::new(RwLock::new(Vec::new()));
    Self {
      folder_manager,
      cancel_token,
      logged_user,
      consumers,
    }
  }

  pub async fn num_consumers(&self) -> usize {
    let consumers = self.consumers.read().await;
    consumers.len()
  }

  pub async fn register_full_indexed_consumer(&self, consumer: Box<dyn FullIndexedDataConsumer>) {
    info!(
      "[Indexing] Registering full index consumer: {}",
      consumer.consumer_id()
    );
    let mut consumers = self.consumers.write().await;
    consumers.push(consumer);
  }

  pub fn cancel_indexing(&self) {
    self.cancel_token.cancel();
  }

  async fn is_workspace_changed(&self, expected_workspace_id: &Uuid) -> bool {
    if let Some(logged_user) = self.logged_user.upgrade() {
      if let Ok(current_workspace_id) = logged_user.workspace_id() {
        return current_workspace_id != *expected_workspace_id;
      }
    }
    // If we can't determine, assume it changed to be safe
    true
  }

  pub async fn full_index_unindexed_documents(&self) -> FlowyResult<()> {
    if self.consumers.read().await.is_empty() {
      warn!("[Indexing] Indexing cancelled: No consumers registered");
      return Ok(());
    }

    let logged_user = self.logged_user.upgrade().ok_or_else(|| {
      FlowyError::unauthorized()
        .with_context("[Indexing] Failed to upgrade AuthenticateUser when indexing")
    })?;

    let uid = logged_user.user_id()?;
    let workspace_id = logged_user.workspace_id()?;
    let mut conn = logged_user.get_sqlite_db(uid)?;

    let folder_manager = self
      .folder_manager
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade FolderManager"))?;
    let views = folder_manager.get_all_documents().await?;
    let view_ids = views.iter().map(|v| v.id.clone()).collect::<Vec<_>>();
    let view_by_view_id = Arc::new(
      views
        .into_iter()
        .map(|v| (v.id.clone(), v))
        .collect::<HashMap<_, _>>(),
    );
    drop(folder_manager);

    let indexed = select_indexed_collab_ids(&mut conn, workspace_id.to_string())?;
    let unindex_ids = view_ids
      .into_iter()
      .filter(|id| !indexed.contains(id))
      .collect::<Vec<_>>();

    if unindex_ids.is_empty() {
      info!("[Indexing] skip: No unindexed documents");
      return Ok(());
    }

    // chunk the unindex_ids into smaller chunks
    let chunk_size = 20;
    info!("[Indexing] {} unindexed documents", unindex_ids.len());
    let chunks = unindex_ids.chunks(chunk_size);
    for chunk in chunks.into_iter() {
      if self.is_workspace_changed(&workspace_id).await {
        info!("[Indexing] cancelled: Workspace changed");
        break;
      }

      match self
        .index_documents(uid, &workspace_id, chunk.to_vec(), view_by_view_id.clone())
        .await
      {
        Ok(unindexed) => {
          if self.cancel_token.is_cancelled() {
            info!("[Indexing] cancelled");
            break;
          }

          for consumer in self.consumers.read().await.iter() {
            for data in &unindexed {
              trace!(
                "[Indexing] {} consume unindexed data",
                consumer.consumer_id()
              );
              consumer.consume_indexed_data(uid, data).await?;
            }
          }
          if let Some(mut db) = self
            .logged_user
            .upgrade()
            .and_then(|v| v.get_sqlite_db(uid).ok())
          {
            let rows = unindexed
              .into_iter()
              .map(|v| IndexCollabRecordTable {
                oid: v.object_id.to_string(),
                workspace_id: v.workspace_id.to_string(),
                content_hash: v.data.content_hash(),
              })
              .collect::<Vec<_>>();

            batch_upsert_index_collab(&mut db, rows)?;
          }
        },
        Err(err) => {
          error!("[Indexing] Failed to index documents: {:?}", err);
        },
      }

      if self.cancel_token.is_cancelled() {
        info!("[Indexing] Indexing cancelled");
        break;
      }

      // Check if workspace has changed before sleep
      if self.is_workspace_changed(&workspace_id).await {
        info!("[Indexing] Indexing cancelled: Workspace changed");
        break;
      }

      tokio::time::sleep(std::time::Duration::from_secs(5)).await;
    }
    Ok(())
  }

  pub async fn index_documents(
    &self,
    uid: i64,
    workspace_id: &Uuid,
    unindex_ids: Vec<String>,
    view_by_id: Arc<HashMap<String, Arc<View>>>,
  ) -> FlowyResult<Vec<UnindexedCollab>> {
    let collab_db = self
      .logged_user
      .upgrade()
      .and_then(|u| u.get_collab_db(uid).ok())
      .and_then(|c| c.upgrade())
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade CollabKVDB"))?;

    // Move everything needed into the blocking closure
    let workspace_id = *workspace_id;
    let handle = tokio::task::spawn_blocking(move || -> FlowyResult<Vec<UnindexedCollab>> {
      let read_txn = collab_db.read_txn();
      let mut results = Vec::with_capacity(unindex_ids.len());

      for object_str in unindex_ids {
        // 1) Load into a Collab
        let mut collab = Collab::new(uid, &object_str, "indexing_device", vec![], false);
        {
          let mut txn = collab.transact_mut();
          if read_txn
            .load_doc_with_txn(uid, &workspace_id.to_string(), &object_str, &mut txn)
            .is_err()
          {
            continue;
          }
        }

        if let Some(view) = view_by_id.get(&object_str) {
          let metadata = UnindexedCollabMetadata {
            name: view.name.clone(),
            icon: None,
          };
          if let Some(document) = DocumentBody::from_collab(&collab) {
            let paragraphs = document.paragraphs(collab.transact());
            // 3) Parse the UUID string
            let object_id = Uuid::parse_str(&object_str)?;
            // 4) Collect
            results.push(UnindexedCollab {
              workspace_id,
              object_id,
              collab_type: CollabType::Document,
              data: UnindexedData::Paragraphs(paragraphs),
              metadata,
            });
          }
        }
      }

      Ok(results)
    });

    // Now await the blocking task, handling both join‐errors and your domain errors
    let unindexed = handle
      .await
      .map_err(|e| FlowyError::internal().with_context(format!("join error: {}", e)))??;

    Ok(unindexed)
  }
}
