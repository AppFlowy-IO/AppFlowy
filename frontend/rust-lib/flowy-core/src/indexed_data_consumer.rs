use crate::full_indexed_data_provider::FullIndexedDataConsumer;
use collab_entity::CollabObject;
use collab_folder::{IconType, ViewIcon};
use collab_integrate::instant_indexed_data_provider::InstantIndexedDataConsumer;
use dashmap::DashMap;
use flowy_ai_pub::entities::{UnindexedCollab, UnindexedCollabMetadata, UnindexedData};
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::manager::FolderManager;
use flowy_search::document::local_search_handler::DocumentTantivyState;
use lib_infra::async_trait::async_trait;
use once_cell::sync::Lazy;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::{error, info, trace};
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
    if data.data.is_empty() {
      return Ok(());
    }

    let scheduler = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler()?;
    scheduler.index_collab(data.clone()).await?;
    Ok(())
  }
}

pub struct EmbeddingsInstantConsumerImpl {
  consume_history: DashMap<String, String>,
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
    collab_object: &CollabObject,
    data: UnindexedData,
  ) -> Result<bool, FlowyError> {
    if data.is_empty() {
      return Ok(false);
    }

    let content_hash = data.content_hash();
    if let Some(entry) = self.consume_history.get(&collab_object.object_id) {
      if entry.value() == &content_hash {
        trace!(
          "[Indexing] {} instant embedding already indexed, skipping",
          collab_object.object_id
        );
        return Ok(false);
      }
    }

    self
      .consume_history
      .insert(collab_object.object_id.clone(), content_hash);

    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      use flowy_ai::embeddings::context::EmbedContext;
      if let Ok(scheduler) = EmbedContext::shared().get_scheduler() {
        let unindex_collab = UnindexedCollab {
          workspace_id: Uuid::parse_str(&collab_object.workspace_id)?,
          object_id: Uuid::parse_str(&collab_object.object_id)?,
          collab_type: collab_object.collab_type,
          data,
          metadata: UnindexedCollabMetadata {
            name: "".to_string(),
            icon: None,
          }, // metadata: UnindexedCollabMetadata {
             //   name: view.name.clone(),
             //   icon: view.icon.clone().map(|v| workspace_dto::ViewIcon {
             //     ty: workspace_dto::IconType::from(v.ty.clone() as u8),
             //     value: v.value,
             //   }),
             // },
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
/// Global map: workspace_id → a *weak* handle to its index state.
type DocIndexMap = DashMap<Uuid, Arc<RwLock<DocumentTantivyState>>>;
static SEARCH_INDEX: Lazy<DocIndexMap> = Lazy::new(DocIndexMap::new);

/// Returns a strong handle, creating it if needed.
fn get_or_init_document_tantivy_state(
  workspace_id: Uuid,
  data_path: PathBuf,
) -> FlowyResult<Arc<RwLock<DocumentTantivyState>>> {
  let to_remove: Vec<Uuid> = SEARCH_INDEX
    .iter()
    .map(|r| *r.key())
    .filter(|k| *k != workspace_id)
    .collect();
  for k in to_remove {
    SEARCH_INDEX.remove(&k);
  }

  Ok(
    SEARCH_INDEX
      .entry(workspace_id)
      .or_try_insert_with(|| {
        info!(
          "[Indexing] Creating new tantivy state for workspace: {}",
          workspace_id
        );
        let state = DocumentTantivyState::new(&workspace_id, data_path.clone())?;
        let arc_state = Arc::new(RwLock::new(state));
        Ok::<_, FlowyError>(arc_state)
      })?
      .clone(),
  )
}

pub fn get_document_tantivy_state(
  workspace_id: &Uuid,
) -> Option<Weak<RwLock<DocumentTantivyState>>> {
  if let Some(existing) = SEARCH_INDEX.get(workspace_id) {
    return Some(Arc::downgrade(existing.value()));
  }
  None
}
/// -----------------------------------------------------
/// Full‐index consumer holds only a Weak reference:
/// -----------------------------------------------------
pub struct SearchFullIndexConsumer {
  state: Weak<RwLock<DocumentTantivyState>>,
}

impl SearchFullIndexConsumer {
  pub fn new(workspace_id: &Uuid, data_path: PathBuf) -> FlowyResult<Self> {
    let strong = get_or_init_document_tantivy_state(*workspace_id, data_path)?;
    Ok(Self {
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
    let strong = self
      .state
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Tantivy state dropped"))?;
    let object_id = data.object_id.to_string();
    let content = data.data.clone().into_string();

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
  state: Weak<RwLock<DocumentTantivyState>>,
  consume_history: DashMap<String, String>,
  folder_manager: Weak<FolderManager>,
}

impl SearchInstantIndexImpl {
  pub fn new(
    workspace_id: &Uuid,
    data_path: PathBuf,
    folder_manager: Weak<FolderManager>,
  ) -> FlowyResult<Self> {
    let strong = get_or_init_document_tantivy_state(*workspace_id, data_path)?;
    Ok(Self {
      state: Arc::downgrade(&strong),
      consume_history: Default::default(),
      folder_manager,
    })
  }
}

#[async_trait]
impl InstantIndexedDataConsumer for SearchInstantIndexImpl {
  fn consumer_id(&self) -> String {
    "search_instant_index_consumer".into()
  }

  async fn consume_collab(
    &self,
    collab_object: &CollabObject,
    data: UnindexedData,
  ) -> Result<bool, FlowyError> {
    let folder_manager = self
      .folder_manager
      .upgrade()
      .ok_or_else(FlowyError::ref_drop)?;
    let view = folder_manager.get_view(&collab_object.object_id).await?;

    // Create a combined hash that includes content + view name + icon
    let content_hash = data.content_hash();
    let name_hash = format!("{}:{}", content_hash, view.name);
    let combined_hash = if let Some(icon) = &view.icon {
      format!("{}:{}:{}", name_hash, icon.ty.clone() as u8, icon.value)
    } else {
      name_hash
    };

    if let Some(entry) = self.consume_history.get(&collab_object.object_id) {
      if entry.value() == &combined_hash {
        return Ok(false);
      }
    }

    self
      .consume_history
      .insert(collab_object.object_id.clone(), combined_hash);

    let strong = self
      .state
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("Tantivy state dropped"))?;
    let content = data.into_string();

    strong.write().await.add_document(
      &collab_object.object_id,
      content,
      view.name.clone(),
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
