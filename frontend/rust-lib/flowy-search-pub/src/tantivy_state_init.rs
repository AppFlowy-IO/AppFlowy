use crate::tantivy_state::DocumentTantivyState;
use dashmap::DashMap;
use flowy_error::{FlowyError, FlowyResult};
use once_cell::sync::Lazy;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::info;
use uuid::Uuid;

/// Global map: workspace_id → a *weak* handle to its index state.
type DocIndexMap = DashMap<Uuid, Arc<RwLock<DocumentTantivyState>>>;
static SEARCH_INDEX: Lazy<DocIndexMap> = Lazy::new(DocIndexMap::new);

/// Returns a strong handle, creating it if needed.
pub fn get_or_init_document_tantivy_state(
  workspace_id: Uuid,
  data_path: PathBuf,
) -> FlowyResult<Arc<RwLock<DocumentTantivyState>>> {
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

pub fn close_document_tantivy_state(workspace_id: &Uuid) {
  if SEARCH_INDEX.remove(workspace_id).is_some() {
    info!(
      "[Indexing] close tantivy state for workspace: {}",
      workspace_id
    );
  }
}

pub fn get_document_tantivy_state(
  workspace_id: &Uuid,
) -> Option<Weak<RwLock<DocumentTantivyState>>> {
  if let Some(existing) = SEARCH_INDEX.get(workspace_id) {
    return Some(Arc::downgrade(existing.value()));
  }
  None
}
