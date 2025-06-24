use crate::folder_view_observer::FolderViewObserverImpl;
use crate::full_indexed_data_provider::FullIndexedDataConsumer;
use collab_entity::CollabType;
use collab_folder::folder_diff::FolderViewChange;
use collab_folder::{IconType, View, ViewIcon};
use collab_integrate::instant_indexed_data_provider::InstantIndexedDataConsumer;
use dashmap::DashMap;
use flowy_ai_pub::entities::{UnindexedCollab, UnindexedCollabMetadata, UnindexedData};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::FolderManager;
use flowy_search_pub::entities::FolderViewObserver;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use flowy_search_pub::tantivy_state_init::get_or_init_document_tantivy_state;
use flowy_server::af_cloud::define::LoggedUser;
use lib_infra::async_trait::async_trait;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::{error, trace};
use uuid::Uuid;

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
pub struct EmbeddingFullIndexConsumer;

#[cfg(any(target_os = "linux", target_os = "macos", target_os = "windows"))]
#[async_trait]
impl FullIndexedDataConsumer for EmbeddingFullIndexConsumer {
  fn consumer_id(&self) -> String {
    "embedding_full_index_consumer".to_string()
  }

  async fn consume_indexed_data(&self, _uid: i64, data: &UnindexedCollab) -> FlowyResult<()> {
    if !matches!(data.collab_type, CollabType::Document) {
      return Ok(());
    }

    match data.data.as_ref() {
      None => {
        return Ok(());
      },
      Some(data) => {
        if data.is_empty() {
          return Ok(());
        }
      },
    }

    let scheduler = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler()?;
    scheduler.index_collab(data.clone()).await?;
    Ok(())
  }
}

pub struct EmbeddingsInstantConsumerImpl {
  consume_history: DashMap<Uuid, String>,
}

impl EmbeddingsInstantConsumerImpl {
  pub fn new() -> Self {
    Self {
      consume_history: Default::default(),
    }
  }
}

#[async_trait]
impl InstantIndexedDataConsumer for EmbeddingsInstantConsumerImpl {
  fn consumer_id(&self) -> String {
    "embedding_instant_index_consumer".to_string()
  }

  async fn consume_collab(
    &self,
    workspace_id: &Uuid,
    data: Option<UnindexedData>,
    object_id: &Uuid,
    collab_type: CollabType,
  ) -> Result<bool, FlowyError> {
    if data.is_none() {
      return Ok(false);
    }

    let data = data.unwrap();
    if data.is_empty() {
      return Ok(false);
    }

    let content_hash = data.content_hash();
    if let Some(entry) = self.consume_history.get(object_id) {
      if entry.value() == &content_hash {
        trace!(
          "[Indexing] {} instant embedding already indexed, hash:{}, skipping",
          object_id,
          content_hash,
        );
        return Ok(false);
      }
    }

    self.consume_history.insert(*object_id, content_hash);

    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      use flowy_ai::embeddings::context::EmbedContext;
      if let Ok(scheduler) = EmbedContext::shared().get_scheduler() {
        let unindex_collab = UnindexedCollab {
          workspace_id: *workspace_id,
          object_id: *object_id,
          collab_type,
          data: Some(data),
          metadata: UnindexedCollabMetadata::default(),
        };

        if let Err(err) = scheduler.index_collab(unindex_collab).await {
          error!("[Embedding] error generating embedding: {}", err);
        }
      }
    }

    Ok(true)
  }

  async fn did_delete_collab(
    &self,
    workspace_id: &Uuid,
    object_id: &Uuid,
  ) -> Result<(), FlowyError> {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      use flowy_ai::embeddings::context::EmbedContext;
      if let Ok(scheduler) = EmbedContext::shared().get_scheduler() {
        if let Err(err) = scheduler.delete_collab(workspace_id, object_id).await {
          error!("[Embedding] error generating embedding: {}", err);
        }
      }
    }

    Ok(())
  }
}

/// -----------------------------------------------------
/// Full‐index consumer holds only a Weak reference:
/// -----------------------------------------------------
pub struct SearchFullIndexConsumer {
  workspace_id: Uuid,
  state: Weak<RwLock<DocumentTantivyState>>,
}

impl SearchFullIndexConsumer {
  pub fn new(workspace_id: &Uuid, data_path: PathBuf) -> FlowyResult<Self> {
    let strong = get_or_init_document_tantivy_state(*workspace_id, data_path)?;
    Ok(Self {
      workspace_id: *workspace_id,
      state: Arc::downgrade(&strong),
    })
  }
}

#[async_trait]
impl FullIndexedDataConsumer for SearchFullIndexConsumer {
  fn consumer_id(&self) -> String {
    "search_full_index_consumer".into()
  }

  async fn consume_indexed_data(&self, _uid: i64, data: &UnindexedCollab) -> FlowyResult<()> {
    if self.workspace_id != data.workspace_id {
      return Ok(());
    }

    let strong = self
      .state
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Tantivy state dropped"))?;
    let object_id = data.object_id.to_string();
    let content = data.data.clone().map(|v| v.into_string());

    strong.write().await.add_document(
      &object_id,
      content,
      data.metadata.name.clone(),
      data.metadata.icon.clone().map(|v| ViewIcon {
        ty: IconType::from(v.ty as u8),
        value: v.value,
      }),
    )?;
    Ok(())
  }
}

/// -----------------------------------------------------
/// Instant‐index consumer also holds a Weak:
/// -----------------------------------------------------
pub struct SearchInstantIndexImpl {
  workspace_id: Uuid,
  state: Weak<RwLock<DocumentTantivyState>>,
  consume_history: DashMap<Uuid, String>,
  folder_manager: Weak<FolderManager>,
  #[allow(dead_code)]
  // bind the folder_observer lifetime to the SearchInstantIndexImpl
  folder_observer: FolderViewObserverImpl,
  logged_user: Weak<dyn LoggedUser>,
}

impl SearchInstantIndexImpl {
  pub async fn new(
    workspace_id: &Uuid,
    data_path: PathBuf,
    folder_manager: Weak<FolderManager>,
    logged_user: Weak<dyn LoggedUser>,
  ) -> FlowyResult<Self> {
    let state = get_or_init_document_tantivy_state(*workspace_id, data_path)?;
    let folder_observer = FolderViewObserverImpl::new(workspace_id, Arc::downgrade(&state));
    if let Some(folder_manager) = folder_manager.upgrade() {
      if let Ok(rx) = folder_manager.subscribe_folder_change_rx().await {
        folder_observer.set_observer_rx(rx).await;
      } else {
        error!("[Indexing] Failed to subscribe to folder changes");
      }
    }

    Ok(Self {
      workspace_id: *workspace_id,
      state: Arc::downgrade(&state),
      consume_history: Default::default(),
      folder_manager,
      folder_observer,
      logged_user,
    })
  }

  pub fn refresh_search_index(&self) {
    let weak_state = self.state.clone();
    let folder_manager = self.folder_manager.clone();
    let weak_logged_user = self.logged_user.clone();
    let expected_workspace_id = self.workspace_id;

    tokio::spawn(async move {
      if weak_logged_user
        .upgrade()
        .and_then(|user| user.workspace_id().ok())
        != Some(expected_workspace_id)
      {
        return Ok(());
      }

      if let (Some(folder_manager), Some(state)) = (folder_manager.upgrade(), weak_state.upgrade())
      {
        if let Ok(changes) = folder_manager.consumer_recent_workspace_changes().await {
          let views = index_views_from_folder(&folder_manager).await?;
          let views_map: std::collections::HashMap<String, _> = views
            .into_iter()
            .map(|view| (view.id.clone(), view))
            .collect();

          for change in changes {
            match change {
              FolderViewChange::Inserted { view_id } | FolderViewChange::Updated { view_id } => {
                if let Some(view) = views_map.get(&view_id) {
                  let _ = state.write().await.add_document_metadata(
                    &view.id,
                    Some(view.name.clone()),
                    view.icon.clone().map(|v| ViewIcon {
                      ty: IconType::from(v.ty as u8),
                      value: v.value,
                    }),
                  );
                }
              },
              FolderViewChange::Deleted { view_ids } => {
                let _ = state.write().await.delete_documents(
                  &view_ids
                    .iter()
                    .map(|id| id.to_string())
                    .collect::<Vec<String>>(),
                );
              },
            }
          }
        }
      }

      Ok::<_, FlowyError>(())
    });
  }
}

#[async_trait]
impl InstantIndexedDataConsumer for SearchInstantIndexImpl {
  fn consumer_id(&self) -> String {
    "search_instant_index_consumer".into()
  }

  async fn consume_collab(
    &self,
    workspace_id: &Uuid,
    data: Option<UnindexedData>,
    object_id: &Uuid,
    _collab_type: CollabType,
  ) -> Result<bool, FlowyError> {
    if self.workspace_id != *workspace_id {
      return Ok(false);
    }

    let state = self
      .state
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Tantivy state dropped"))?;

    let folder_manager = self
      .folder_manager
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)?;
    let view = folder_manager.get_view(&object_id.to_string()).await?;

    // Create a combined hash that includes content + view name + icon
    let content_hash = match &data {
      None => "".to_string(),
      Some(data) => data.content_hash(),
    };

    let name_hash = format!("{}:{}", content_hash, view.name);
    let combined_hash = if let Some(icon) = &view.icon {
      format!("{}:{}:{}", name_hash, icon.ty.clone() as u8, icon.value)
    } else {
      name_hash
    };

    if let Some(entry) = self.consume_history.get(object_id) {
      if entry.value() == &content_hash {
        trace!(
          "[Indexing] {} instant search already indexed, hash:{}, skipping",
          object_id,
          content_hash,
        );
        return Ok(false);
      }

      if entry.value() == &combined_hash {
        return Ok(false);
      }
    }

    self.consume_history.insert(*object_id, combined_hash);
    state.write().await.add_document(
      &object_id.to_string(),
      data.map(|v| v.into_string()),
      Some(view.name.clone()),
      view.icon.clone().map(|v| ViewIcon {
        ty: IconType::from(v.ty as u8),
        value: v.value,
      }),
    )?;
    Ok(true)
  }

  async fn did_delete_collab(
    &self,
    _workspace_id: &Uuid,
    object_id: &Uuid,
  ) -> Result<(), FlowyError> {
    let strong = self
      .state
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Tantivy state dropped"))?;
    strong
      .write()
      .await
      .delete_document(&object_id.to_string())?;
    Ok(())
  }
}

pub(crate) async fn index_views_from_folder(
  folder_manager: &FolderManager,
) -> FlowyResult<Vec<Arc<View>>> {
  Ok(
    folder_manager
      .get_all_views()
      .await?
      .into_iter()
      .filter(|v| v.space_info().is_none() && v.layout.is_document())
      .collect::<Vec<_>>(),
  )
}
