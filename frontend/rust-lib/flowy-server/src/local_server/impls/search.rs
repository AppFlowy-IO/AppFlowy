use crate::af_cloud::define::LoggedUser;
use crate::util::tanvity_local_search;
use flowy_ai::local_ai::controller::LocalAIController;
use flowy_error::FlowyError;
use flowy_search_pub::cloud::{
  SearchCloudService, SearchDocumentResponseItem, SearchResult, SearchSummaryResult,
};
use flowy_search_pub::tantivy_state::DocumentTantivyState;
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

#[async_trait]
impl SearchCloudService for LocalSearchServiceImpl {
  async fn document_search(
    &self,
    workspace_id: &Uuid,
    query: String,
  ) -> Result<Vec<SearchDocumentResponseItem>, FlowyError> {
    let mut results = vec![];
    #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
    {
      if let Ok(scheduler) = flowy_ai::embeddings::context::EmbedContext::shared().get_scheduler() {
        match scheduler.search(workspace_id, &query).await {
          Ok(items) => results = items,
          Err(err) => tracing::error!("[Search] Local AI search failed: {:?}", err),
        }
      } else {
        tracing::error!("[Search] Could not acquire local AI scheduler");
      }
    }

    if !results.is_empty() {
      return Ok(results);
    }

    trace!("[Search] Local AI search returned no results, falling back to local search");
    let items = tanvity_local_search(&self.state, workspace_id, &query)
      .await
      .unwrap_or_default();
    Ok(items)
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
