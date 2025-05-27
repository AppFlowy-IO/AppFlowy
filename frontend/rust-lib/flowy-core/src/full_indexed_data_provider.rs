use crate::indexed_data_consumer::index_views_from_folder;
use client_api::entity::workspace_dto::ViewIcon;
use collab::preclude::Collab;
use collab_entity::CollabType;
use collab_folder::{View, ViewLayout};
use collab_integrate::instant_indexed_data_provider::unindexed_data_form_collab;
use collab_plugins::local_storage::kv::doc::CollabKVAction;
use collab_plugins::local_storage::kv::KVTransactionDB;
use flowy_ai_pub::entities::{UnindexedCollab, UnindexedCollabMetadata};
use flowy_ai_pub::persistence::{
  batch_upsert_index_collab, select_indexed_collab_ids, IndexCollabRecordTable,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::FolderManager;
use flowy_server::af_cloud::define::LoggedUser;
use flowy_server_pub::workspace_dto::IconType;
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
pub struct FullIndexedDataWriter {
  workspace_id: Uuid,
  folder_manager: Weak<FolderManager>,
  logged_user: Weak<dyn LoggedUser>,
  cancel_token: CancellationToken,
  consumers: Arc<RwLock<Vec<Box<dyn FullIndexedDataConsumer>>>>,
}

impl FullIndexedDataWriter {
  pub fn new(
    workspace_id: Uuid,
    folder_manager: Weak<FolderManager>,
    logged_user: Weak<dyn LoggedUser>,
  ) -> Self {
    let cancel_token = CancellationToken::new();
    let consumers = Arc::new(RwLock::new(Vec::new()));
    Self {
      workspace_id,
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

  async fn is_workspace_changed(&self) -> bool {
    if let Some(logged_user) = self.logged_user.upgrade() {
      if let Ok(current_workspace_id) = logged_user.workspace_id() {
        return current_workspace_id != self.workspace_id;
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
    let views = index_views_from_folder(&folder_manager).await?;
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

    let chunk_size = 50;
    info!(
      "[Indexing] {} consumers start indexing {} unindexed documents",
      self.consumers.read().await.len(),
      unindex_ids.len()
    );
    let chunks = unindex_ids.chunks(chunk_size);
    for chunk in chunks.into_iter() {
      if self.is_workspace_changed().await {
        info!("[Indexing] cancelled: Workspace changed");
        break;
      }

      match self
        .index_views(uid, &workspace_id, chunk.to_vec(), view_by_view_id.clone())
        .await
      {
        Ok(unindexed) => {
          if self.cancel_token.is_cancelled() {
            info!("[Indexing] cancelled");
            break;
          }
          info!(
            "[Indexing] {} unindexed documents found in chunk",
            unindexed.len()
          );

          let consumers = self.consumers.read().await;
          for consumer in consumers.iter() {
            let consumer_tasks: Vec<_> = unindexed
              .iter()
              .map(|data| {
                let consumer_id = consumer.consumer_id();
                let object_id = data.object_id;
                async move {
                  trace!(
                    "[Indexing] {} consume {} unindexed data",
                    consumer_id,
                    object_id
                  );
                  if let Err(err) = consumer.consume_indexed_data(uid, data).await {
                    error!(
                      "[Indexing] Failed to consume unindexed data: {}: {:?}",
                      consumer_id, err
                    );
                  }
                }
              })
              .collect();

            futures::future::join_all(consumer_tasks).await;
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
                content_hash: v.data.map(|v| v.content_hash()).unwrap_or_default(),
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
      if self.is_workspace_changed().await {
        info!("[Indexing] Indexing cancelled: Workspace changed");
        break;
      }

      tokio::time::sleep(std::time::Duration::from_secs(5)).await;
    }
    Ok(())
  }

  pub async fn index_views(
    &self,
    uid: i64,
    workspace_id: &Uuid,
    unindex_ids: Vec<String>,
    view_by_id: Arc<HashMap<String, Arc<View>>>,
  ) -> FlowyResult<Vec<UnindexedCollab>> {
    // Early return for empty input
    if unindex_ids.is_empty() {
      return Ok(Vec::new());
    }

    let collab_db = self
      .logged_user
      .upgrade()
      .and_then(|u| u.get_collab_db(uid).ok())
      .and_then(|c| c.upgrade())
      .ok_or_else(|| FlowyError::internal().with_context("Failed to upgrade CollabKVDB"))?;

    // Filter out views that don't exist before the blocking task
    let filtered_ids: Vec<_> = unindex_ids
      .into_iter()
      .filter(|id| view_by_id.contains_key(id))
      .collect();

    // Move everything needed into the blocking closure
    let workspace_id = *workspace_id;
    let handle = tokio::task::spawn_blocking(move || -> FlowyResult<Vec<UnindexedCollab>> {
      let read_txn = collab_db.read_txn();
      let mut results = Vec::with_capacity(filtered_ids.len());

      for object_str in filtered_ids {
        // We know the view exists because of the pre-filtering
        let view = &view_by_id[&object_str];

        // Skip Chat views immediately
        let collab_type = match view.layout {
          ViewLayout::Document => CollabType::Document,
          ViewLayout::Grid | ViewLayout::Board | ViewLayout::Calendar => CollabType::Database,
          ViewLayout::Chat => continue,
        };

        // Parse UUID once, outside the match
        let object_id = match Uuid::parse_str(&object_str) {
          Ok(id) => id,
          Err(_) => continue, // Skip invalid UUIDs
        };

        // Create metadata once for reuse
        let metadata = UnindexedCollabMetadata {
          name: Some(view.name.clone()),
          icon: view.icon.as_ref().map(|icon| ViewIcon {
            ty: IconType::from(icon.ty.clone() as u8),
            value: icon.value.clone(),
          }),
        };

        match collab_type {
          CollabType::Document => {
            // 1) Load into a Collab
            let mut collab = Collab::new(uid, &object_str, "indexing_device", vec![], false);
            let load_success = {
              let mut txn = collab.transact_mut();
              read_txn
                .load_doc_with_txn(uid, &workspace_id.to_string(), &object_str, &mut txn)
                .is_ok()
            };

            if load_success {
              let data = unindexed_data_form_collab(&collab, &collab_type);
              results.push(UnindexedCollab {
                workspace_id,
                object_id,
                collab_type,
                data,
                metadata,
              });
            } else {
              results.push(UnindexedCollab {
                workspace_id,
                object_id,
                collab_type,
                data: None,
                metadata,
              });
            }
          },
          CollabType::Database => {
            results.push(UnindexedCollab {
              workspace_id,
              object_id,
              collab_type: CollabType::Database,
              data: None,
              metadata,
            });
          },
          _ => {
            // do nothing for other types
          },
        }
      }

      Ok(results)
    });

    handle
      .await
      .map_err(|e| FlowyError::internal().with_context(format!("Join error: {}", e)))?
  }
}
