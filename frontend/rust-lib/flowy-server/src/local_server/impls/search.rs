use crate::af_cloud::define::LoggedUser;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_ai_pub::cloud::search_dto::{
  SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_error::FlowyError;
use flowy_search_pub::cloud::SearchCloudService;
use flowy_search_pub::entities::TanvitySearchResponseItem;
use flowy_search_pub::tantivy_state::DocumentTantivyState;
use flowy_server_pub::search_dto::SearchContentType;
use lib_infra::async_trait::async_trait;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;
use tracing::trace;
use uuid::Uuid;

pub struct LocalSearchServiceImpl {
  #[allow(dead_code)]
  pub logged_user: Arc<dyn LoggedUser>,
  pub local_ai: Arc<LocalAIController>,
  pub state: Option<Weak<RwLock<DocumentTantivyState>>>,
}

impl LocalSearchServiceImpl {
  async fn local_search(
    &self,
    workspace_id: &Uuid,
    query: &str,
  ) -> Option<Vec<SearchDocumentResponseItem>> {
    match self.state.as_ref().and_then(|v| v.upgrade()) {
      None => {
        trace!("[Search] tanvity state is None");
        None
      },
      Some(state) => {
        let results = state.read().await.search(workspace_id, query, None).ok()?;
        let items = results
          .into_iter()
          .flat_map(|v| tanvity_document_to_search_document(*workspace_id, v))
          .collect::<Vec<_>>();
        Some(items)
      },
    }
  }
}

fn tanvity_document_to_search_document(
  workspace_id: Uuid,
  doc: TanvitySearchResponseItem,
) -> Option<SearchDocumentResponseItem> {
  let object_id = Uuid::parse_str(&doc.id).ok()?;
  Some(SearchDocumentResponseItem {
    object_id,
    workspace_id,
    score: 1.0,
    content_type: Some(SearchContentType::PlainText),
    content: doc.content,
    preview: None,
    created_by: "".to_string(),
    created_at: Default::default(),
  })
}

#[async_trait]
impl SearchCloudService for LocalSearchServiceImpl {
  async fn document_search(
    &self,
    workspace_id: &Uuid,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      if let Ok(scheduler) = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler() {
        match scheduler.search(workspace_id, &query).await {
          Ok(results) => {
            return if results.is_empty() {
              trace!("[Search] Local AI search returned no results, falling back to local search");
              let items = self
                .local_search(workspace_id, &query)
                .await
                .unwrap_or_default();
              trace!("[Search] Local search returned {} results", items.len());
              Ok(items)
            } else {
              Ok(results)
            }
          },
          Err(err) => tracing::error!("[Search] Local AI search failed: {:?}", err),
        }
      } else {
        tracing::error!("[Search] Could not acquire local AI scheduler");
      }
    }

    Ok(Vec::new())
  }

  async fn generate_search_summary(
    &self,
    _workspace_id: &Uuid,
    query: String,
    search_results: Vec<SearchResult>,
  ) -> Result<SearchSummaryResult, FlowyError> {
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      if search_results.is_empty() {
        trace!("[Search] No search results to summarize");
        return Ok(SearchSummaryResult { summaries: vec![] });
      }

      if let Ok(scheduler) = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler() {
        let setting = self.local_ai.get_local_ai_setting();
        match scheduler
          .generate_summary(&query, &setting.chat_model_name, search_results)
          .await
        {
          Ok(results) => return Ok(results),
          Err(err) => tracing::error!("Local AI search failed: {:?}", err),
        }
      } else {
        tracing::error!("Could not acquire local AI scheduler");
      }
    }

    //
    Ok(SearchSummaryResult { summaries: vec![] })
  }
}
