use anyhow::Context;
use collab::preclude::Collab;
use collab_document::document::DocumentBody;
use collab_entity::CollabType;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use collab_plugins::local_storage::kv::KVTransactionDB;
use collab_plugins::CollabKVDB;
use flowy_ai_pub::entities::{UnindexedCollab, UnindexedData};
use flowy_ai_pub::persistence::{select_indexed_collab_ids, upsert_index_collab};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::FolderManager;
use flowy_server::af_cloud::define::LoggedUser;
use lib_infra::async_trait::async_trait;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;
use tracing::{info, trace, warn};
use uuid::Uuid;

#[async_trait]
pub trait IndexedDataConsumer: Send + Sync {
  fn consumer_id(&self) -> String;
  async fn consume_indexed_data(&self, uid: i64, data: &UnindexedCollab) -> FlowyResult<()>;
}

#[derive(Clone)]
pub struct IndexedDataProvider {
  folder_manager: Weak<FolderManager>,
  logged_user: Weak<dyn LoggedUser>,
  cancel_token: CancellationToken,
  consumers: Arc<RwLock<Vec<Box<dyn IndexedDataConsumer>>>>,
}

impl IndexedDataProvider {
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

  pub async fn register_consumer(&self, consumer: Box<dyn IndexedDataConsumer>) {
    let mut consumers = self.consumers.write().await;
    consumers.push(consumer);
  }

  pub fn cancel_indexing(&self) {
    self.cancel_token.cancel();
  }

  pub async fn full_index_unindexed_documents(&self) -> FlowyResult<()> {
    if self.consumers.read().await.is_empty() {
      warn!("Indexing cancelled: No consumers registered");
      return Ok(());
    }

    let logged_user = self.logged_user.upgrade().ok_or_else(|| {
      FlowyError::unauthorized().with_context("Failed to upgrade AuthenticateUser when indexing")
    })?;

    let uid = logged_user.user_id()?;
    let workspace_id = logged_user.workspace_id()?;
    let mut conn = logged_user.get_sqlite_db(uid)?;

    let folder_manager = self
      .folder_manager
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade FolderManager"))?;
    let document_ids = folder_manager.get_all_documents_ids().await?;
    drop(folder_manager);

    let indexed = select_indexed_collab_ids(&mut conn, workspace_id.to_string())?;
    let unindex_ids = document_ids
      .into_iter()
      .filter(|id| !indexed.contains(id))
      .collect::<Vec<_>>();

    if unindex_ids.is_empty() {
      info!("Indexing skip: No unindexed documents");
      return Ok(());
    }

    // chunk the unindex_ids into smaller chunks
    let chunk_size = 20;
    info!("Indexing {} unindexed documents", unindex_ids.len());
    let chunks = unindex_ids.chunks(chunk_size);
    for chunk in chunks.into_iter() {
      if let Ok(unindexed) = self.index_documents(uid, &workspace_id, chunk).await {
        if self.cancel_token.is_cancelled() {
          info!("Indexing cancelled");
          break;
        }

        for consumer in self.consumers.read().await.iter() {
          for data in unindexed.iter() {
            trace!("Indexing data for consumer: {}", consumer.consumer_id());
            consumer.consume_indexed_data(uid, data).await?;
          }
        }
      }

      if self.cancel_token.is_cancelled() {
        info!("Indexing cancelled");
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
    unindex_ids: &[String],
  ) -> FlowyResult<Vec<UnindexedCollab>> {
    let collab_db = self
      .logged_user
      .upgrade()
      .and_then(|u| u.get_collab_db(uid).ok())
      .and_then(|c| c.upgrade())
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade CollabKVDB"))?;

    // Move everything needed into the blocking closure
    let unindex_ids = unindex_ids.to_vec();
    let workspace_id = *workspace_id;
    let handle = tokio::task::spawn_blocking(move || -> FlowyResult<Vec<UnindexedCollab>> {
      let read_txn = collab_db.read_txn();
      let mut results = Vec::with_capacity(unindex_ids.len());

      for object_str in unindex_ids {
        // 1) Load into a Collab
        let mut collab = Collab::new(uid, &object_str, "", vec![], false);
        {
          let mut txn = collab.transact_mut();
          read_txn
            .load_doc_with_txn(uid, &workspace_id.to_string(), &object_str, &mut txn)
            .context("loading document into Collab")?;
        }
        // 2) Turn it into DocumentBody → paragraphs
        let document = DocumentBody::from_collab(&collab)
          .ok_or_else(|| FlowyError::internal().with_context("Collab→DocumentBody failed"))?;
        let paragraphs = document.paragraphs(collab.transact());
        // 3) Parse the UUID string
        let object_id = Uuid::parse_str(&object_str)?;
        // 4) Collect
        results.push(UnindexedCollab {
          workspace_id,
          object_id,
          collab_type: CollabType::Document,
          data: UnindexedData::Paragraphs(paragraphs),
        });
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
