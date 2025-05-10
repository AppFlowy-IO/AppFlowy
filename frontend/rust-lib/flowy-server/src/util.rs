use flowy_ai_pub::cloud::search_dto::{SearchContentType, SearchDocumentResponseItem};
use flowy_search_pub::entities::TanvitySearchResponseItem;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use serde::{Deserialize, Deserializer};
use std::sync::Weak;
use tokio::sync::RwLock;
use tracing::trace;
use uuid::Uuid;

/// Handles the case where the value is null. If the value is null, return the default value of the
/// type. Otherwise, deserialize the value.
#[allow(dead_code)]
pub(crate) fn deserialize_null_or_default<'de, D, T>(deserializer: D) -> Result<T, D::Error>
where
  T: Default + Deserialize<'de>,
  D: Deserializer<'de>,
{
  let opt = Option::deserialize(deserializer)?;
  Ok(opt.unwrap_or_default())
}

pub async fn tanvity_local_search(
  state: &Option<Weak<RwLock<DocumentTantivyState>>>,
  workspace_id: &Uuid,
  query: &str,
  object_ids: Option<Vec<String>>,
  limit: usize,
  score_threshold: f32,
) -> Option<Vec<SearchDocumentResponseItem>> {
  match state.as_ref().and_then(|v| v.upgrade()) {
    None => {
      trace!("[Search] tanvity state is None");
      None
    },
    Some(state) => {
      let results = state
        .read()
        .await
        .search(workspace_id, query, object_ids, limit, score_threshold)
        .ok()?;
      let items = results
        .into_iter()
        .flat_map(|v| tanvity_document_to_search_document(*workspace_id, v))
        .collect::<Vec<_>>();
      trace!("[Search] Local search returned {} results", items.len());
      Some(items)
    },
  }
}

pub(crate) fn tanvity_document_to_search_document(
  workspace_id: Uuid,
  doc: TanvitySearchResponseItem,
) -> Option<SearchDocumentResponseItem> {
  let object_id = Uuid::parse_str(&doc.id).ok()?;
  Some(SearchDocumentResponseItem {
    object_id,
    workspace_id,
    score: doc.score as f64,
    content_type: Some(SearchContentType::PlainText),
    content: doc.content,
    preview: None,
    created_by: "".to_string(),
    created_at: Default::default(),
  })
}
